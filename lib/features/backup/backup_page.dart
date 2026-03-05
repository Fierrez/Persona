import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'backup_service.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  String? _lastBackupDate;
  String? _lastBackupSize;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBackupInfo();
  }

  Future<void> _loadBackupInfo() async {
    final info = await BackupService.getBackupInfo();
    setState(() {
      _lastBackupDate = info["date"];
      _lastBackupSize = info["size"];
    });
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
            Text("Enter a secure password to $action this backup."),
            const SizedBox(height: 12),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => password = val,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, password),
            child: Text(action.toUpperCase()),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSaveFile() async {
    final password = await _promptPassword("Encrypt Backup", "encrypt");
    if (password == null || password.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final encryptedData = await BackupService.getEncryptedBackupData(password);
      if (encryptedData == null) throw Exception("Encryption failed");

      final bytes = utf8.encode(encryptedData);
      final date = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String fileName = 'persona_backup_$date.enc';

      String? result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Encrypted Backup',
        fileName: fileName,
        type: FileType.any,
        bytes: Uint8List.fromList(bytes),
      );

      if (result != null) {
        await BackupService.updateBackupInfo(bytes.length);
        await _loadBackupInfo();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Backup saved successfully")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save backup: $e")),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestore() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();

        final password = await _promptPassword("Decrypt Backup", "decrypt");
        if (password == null || password.isEmpty) return;
        
        final success = await BackupService.restoreEncryptedBackup(content, password);
        
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Restore successful! Restart the app.")),
            );
          }
        } else {
          throw Exception("Invalid password or corrupted file");
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Restore failed: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = "Never";
    if (_lastBackupDate != null && _lastBackupDate!.isNotEmpty) {
      try {
        formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(_lastBackupDate!));
      } catch (e) {
        formattedDate = "Unknown";
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.shield, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Secure Encrypted Backup", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text("Last: $formattedDate", style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                const Text("Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                _actionCard(
                  icon: Icons.save_alt_rounded,
                  title: "Create Backup",
                  subtitle: "Save an AES-256 encrypted file",
                  onTap: _handleSaveFile,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                
                _actionCard(
                  icon: Icons.upload_file_rounded,
                  title: "Restore Backup",
                  subtitle: "Import and decrypt a file",
                  onTap: _handleRestore,
                  color: Colors.green,
                ),
                
                const SizedBox(height: 40),
                const Center(
                  child: Text(
                    "Backups are encrypted with your password.\nIf you lose the password, the data cannot be recovered.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _actionCard({
    required IconData icon, 
    required String title, 
    required String subtitle, 
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
