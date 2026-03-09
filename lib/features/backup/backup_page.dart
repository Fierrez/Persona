import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:persona_app/shared/widget.dart';
import 'backup_service.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  String? _lastBackupDate;
  String? _lastAutoBackupDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBackupInfo();
  }

  Future<void> _loadBackupInfo() async {
    try {
      final info = await BackupService.getBackupInfo();
      if (mounted) {
        setState(() {
          _lastBackupDate = info["date"];
          _lastAutoBackupDate = info["autoDate"];
        });
      }
    } catch (e) {
      debugPrint("Error loading backup info: $e");
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty || dateStr == "null" || dateStr == "Never") return "Never";
    try {
      // Try parsing the date string safely
      final dateTime = DateTime.tryParse(dateStr);
      if (dateTime != null) {
        return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
      }
    } catch (e) {
      debugPrint("Date formatting error: $e");
    }
    return "Never";
  }

  Future<String?> _promptPassword(String title, String action) async {
    String password = '';
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Enter a password to $action this backup. You will need this password to restore your data."),
            const SizedBox(height: 12),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Backup Password",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
              onChanged: (val) => password = val,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D62ED), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, password),
            child: Text(action.toUpperCase()),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEncryptedBackup() async {
    final password = await _promptPassword("Secure Encrypted Backup", "encrypt");
    if (password == null || password.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final encryptedData = await BackupService.getEncryptedBackupData(password);
      if (encryptedData == null) throw Exception("Encryption failed");

      final bytes = utf8.encode(encryptedData);
      final date = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      
      String? result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Encrypted Backup',
        fileName: 'persona_backup_$date.enc',
        type: FileType.any,
        bytes: Uint8List.fromList(bytes),
      );

      if (result != null) {
        await BackupService.updateBackupInfo(bytes.length);
        await _loadBackupInfo();
        if (mounted) FloatingIslandToast.show(context, "Encrypted backup saved");
      }
    } catch (e) {
      if (mounted) FloatingIslandToast.show(context, "Backup failed: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleJsonExport() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Unencrypted JSON Export"),
        content: const Text("WARNING: This will export your data in plain text (JSON). Anyone with access to this file can see your secrets. Are you sure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Export anyway", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final allData = await BackupService.getRawData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(allData);
      final bytes = utf8.encode(jsonString);
      final date = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());

      String? result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Data as JSON',
        fileName: 'persona_export_$date.json',
        type: FileType.any,
        bytes: Uint8List.fromList(bytes),
      );

      if (result != null && mounted) {
        FloatingIslandToast.show(context, "JSON export successful");
      }
    } catch (e) {
      if (mounted) FloatingIslandToast.show(context, "Export failed: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRunAutoBackup() async {
    setState(() => _isLoading = true);
    try {
      final success = await BackupService.runAutomaticBackup("persona_internal_auto_backup_key");
      if (success) {
        await _loadBackupInfo();
        if (mounted) FloatingIslandToast.show(context, "Internal backup completed");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestore() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: 'Select Backup File (.enc or .json)',
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final fileName = result.files.single.name.toLowerCase();

        bool success = false;
        if (fileName.endsWith('.enc')) {
          final password = await _promptPassword("Decrypt Backup", "decrypt");
          if (password == null || password.isEmpty) return;
          success = await BackupService.restoreEncryptedBackup(content, password);
        } else if (fileName.endsWith('.json')) {
          success = await BackupService.restoreFromJson(content);
        } else {
          throw Exception("Unsupported file format. Please use .enc or .json");
        }
        
        if (success && mounted) {
          FloatingIslandToast.show(context, "Restore successful! Restart app.");
        } else {
          throw Exception("Invalid backup file or password");
        }
      }
    } catch (e) {
      if (mounted) FloatingIslandToast.show(context, "Restore failed: $e", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Export')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              _buildInfoCard(_formatDate(_lastBackupDate), _formatDate(_lastAutoBackupDate)),
              const SizedBox(height: 32),
              
              Text("SECURE BACKUP", style: theme.textTheme.labelLarge?.copyWith(color: Colors.grey, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              _actionTile(
                icon: Icons.enhanced_encryption_rounded,
                title: "Encrypted Backup (.enc)",
                subtitle: "Full secure backup protected by password",
                color: const Color(0xFF2D62ED),
                onTap: _handleEncryptedBackup,
              ),
              
              const SizedBox(height: 24),
              Text("PORTABLE EXPORT", style: theme.textTheme.labelLarge?.copyWith(color: Colors.grey, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              _actionTile(
                icon: Icons.code_rounded,
                title: "JSON Export (.json)",
                subtitle: "Readable file for advanced users (Unencrypted)",
                color: Colors.orange,
                onTap: _handleJsonExport,
              ),
              
              const SizedBox(height: 24),
              Text("INTERNAL SAFETY", style: theme.textTheme.labelLarge?.copyWith(color: Colors.grey, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              _actionTile(
                icon: Icons.auto_mode_rounded,
                title: "Run Automatic Backup Now",
                subtitle: "Create a fresh internal safety point",
                color: Colors.purple,
                onTap: _handleRunAutoBackup,
              ),
              
              const SizedBox(height: 24),
              Text("RESTORE", style: theme.textTheme.labelLarge?.copyWith(color: Colors.grey, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              _actionTile(
                icon: Icons.settings_backup_restore_rounded,
                title: "Import Data",
                subtitle: "Restore from .enc or .json file",
                color: Colors.green,
                onTap: _handleRestore,
              ),

              const SizedBox(height: 40),
            ],
          ),
    );
  }

  Widget _buildInfoCard(String date, String autoDate) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF2D62ED), const Color(0xFF2D62ED).withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF2D62ED).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.cloud_done_rounded, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text("Backup Status", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Last Manual", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                    Text(date, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: Colors.white.withOpacity(0.2)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Last Automatic", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                    Text(autoDate, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionTile({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      ),
    );
  }
}
