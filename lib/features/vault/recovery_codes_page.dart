import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:persona_app/core/secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'recovery_code_model.dart';

class RecoveryCodesPage extends StatefulWidget {
  const RecoveryCodesPage({super.key});

  @override
  State<RecoveryCodesPage> createState() => _RecoveryCodesPageState();
}

class _RecoveryCodesPageState extends State<RecoveryCodesPage> {
  final SecureStorageService _storage = SecureStorageService();
  List<RecoveryCode> _codes = [];
  final _serviceController = TextEditingController();
  final _codeController = TextEditingController();
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadCodes();
  }

  Future<void> _loadCodes() async {
    final data = await _storage.readList("recovery_codes");
    setState(() {
      _codes = data.map((item) => RecoveryCode.fromJson(item)).toList();
    });
  }

  Future<void> _saveCodes() async {
    await _storage.write("recovery_codes", _codes.map((e) => e.toJson()).toList());
  }

  Future<void> _addCode() async {
    if (_serviceController.text.isEmpty || _codeController.text.isEmpty) return;
    
    final newCode = RecoveryCode(
      id: _uuid.v4(),
      serviceName: _serviceController.text,
      code: _codeController.text,
      used: false,
    );

    setState(() {
      _codes.add(newCode);
      _serviceController.clear();
      _codeController.clear();
    });
    await _saveCodes();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _processBulkCodes(String content) async {
    final rawCodes = content.split(RegExp(r'\s+')).where((s) => s.trim().isNotEmpty).toList();
    
    if (rawCodes.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No codes found")));
      return;
    }

    final nameController = TextEditingController();
    
    if (mounted) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Import ${rawCodes.length} Codes"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: "Service Name (e.g. GitHub)",
              hintText: "Enter service name",
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), 
              child: const Text("Cancel")
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  Navigator.pop(context, true);
                }
              }, 
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Import")
            ),
          ],
        ),
      );

      if (confirm == true && nameController.text.isNotEmpty) {
        final serviceName = nameController.text;
        setState(() {
          for (var code in rawCodes) {
            _codes.add(RecoveryCode(
              id: _uuid.v4(),
              serviceName: serviceName,
              code: code,
              used: false,
            ));
          }
        });
        await _saveCodes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Successfully added ${rawCodes.length} codes"))
          );
        }
      }
    }
  }

  Future<void> _showPasteDialog() async {
    final pasteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Paste Recovery Codes"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Paste multiple codes separated by spaces or new lines.", style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: pasteController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: "Paste codes here...",
                filled: true,
                fillColor: Colors.grey.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final content = pasteController.text;
              Navigator.pop(context);
              _processBulkCodes(content);
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Next"),
          ),
        ],
      ),
    );
  }

  Future<void> _importFromTxt() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final content = utf8.decode(result.files.single.bytes!);
        await _processBulkCodes(content);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error importing file: $e"))
        );
      }
    }
  }

  Future<void> _exportToCSV() async {
    if (_codes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No codes to export")));
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text("Security Warning"),
          ],
        ),
        content: const Text(
          "You are about to export your recovery codes to an unencrypted CSV file.\n\n"
          "Anyone with access to this file can read your codes. "
          "Are you sure you want to continue?",
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, 
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Export Unsafe"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    List<List<dynamic>> rows = [["Service", "Recovery Code", "Used"]];
    for (var code in _codes) {
      rows.add([code.serviceName, code.code, code.used]);
    }
    String csv = const ListToCsvConverter().convert(rows);
    
    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/recovery_codes_export.csv";
    final file = File(path);
    await file.writeAsString(csv);
    
    await Share.shareXFiles([XFile(path)], text: 'Persona Recovery Codes Export');
  }

  Future<void> _toggleUsed(int index) async {
    setState(() {
      _codes[index].used = !_codes[index].used;
    });
    await _saveCodes();
  }

  Future<void> _deleteCode(int index) async {
    setState(() {
      _codes.removeAt(index);
    });
    await _saveCodes();
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Add Recovery Code"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _serviceController,
              decoration: const InputDecoration(labelText: "Service Name (e.g. GitHub)"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: "Recovery Code"),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: _addCode, 
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Add")
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _codes.isEmpty 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.vpn_key_outlined, size: 80, color: Colors.grey.withOpacity(0.3)),
                const SizedBox(height: 16),
                const Text("No recovery codes saved", style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.only(bottom: 120),
            itemCount: _codes.length,
            itemBuilder: (context, index) {
              final code = _codes[index];
              return Dismissible(
                key: Key(code.id),
                onDismissed: (_) => _deleteCode(index),
                background: Container(
                  color: Colors.red, 
                  alignment: Alignment.centerRight, 
                  padding: const EdgeInsets.only(right: 20), 
                  child: const Icon(Icons.delete, color: Colors.white)
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  title: Text(code.serviceName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface)),
                  subtitle: Text(code.code, style: TextStyle(
                    decoration: code.used ? TextDecoration.lineThrough : null,
                    fontFamily: 'monospace',
                    color: code.used ? Colors.grey : theme.colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 14,
                  )),
                  trailing: Checkbox(
                    value: code.used,
                    onChanged: (_) => _toggleUsed(index),
                    activeColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              );
            },
          ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90, right: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildFabMini(Icons.download, _exportToCSV, "Export", "export_csv", theme),
            const SizedBox(height: 12),
            _buildFabMini(Icons.file_upload, _importFromTxt, "Import File", "import_txt", theme),
            const SizedBox(height: 12),
            _buildFabMini(Icons.content_paste, _showPasteDialog, "Paste Bulk", "paste_bulk", theme),
            const SizedBox(height: 16),
            FloatingActionButton.extended(
              heroTag: "add_code",
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add),
              label: const Text("Add Code"),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFabMini(IconData icon, VoidCallback onPressed, String label, String heroTag, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        ),
        const SizedBox(width: 8),
        FloatingActionButton(
          heroTag: heroTag,
          onPressed: onPressed,
          mini: true,
          backgroundColor: theme.cardTheme.color,
          foregroundColor: theme.colorScheme.primary,
          child: Icon(icon),
        ),
      ],
    );
  }
}
