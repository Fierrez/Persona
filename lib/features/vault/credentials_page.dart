import 'package:flutter/material.dart';
import 'package:persona_app/core/secure_storage.dart';
import 'package:persona_app/core/clipboard_service.dart';
import 'package:persona_app/core/password_generator.dart';
import 'package:persona_app/shared/brand_icons.dart';
import 'package:uuid/uuid.dart';
import 'vault_model.dart';
import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class CredentialsPage extends StatefulWidget {
  const CredentialsPage({super.key});

  @override
  State<CredentialsPage> createState() => _CredentialsPageState();
}

class _CredentialsPageState extends State<CredentialsPage> {
  final SecureStorageService _storage = SecureStorageService();
  List<VaultEntry> _entries = [];
  final _uuid = const Uuid();
  final bool _showPasswords = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final data = await _storage.readList("vault_credentials");
    setState(() {
      _entries = data.map((item) => VaultEntry.fromJson(item)).toList();
    });
  }

  Future<void> _saveEntries() async {
    await _storage.write("vault_credentials", _entries.map((e) => e.toJson()).toList());
  }

  Future<void> _addEntry(String service, String user, String pass, String category) async {
    final newEntry = VaultEntry(
      id: _uuid.v4(),
      serviceName: service,
      username: user,
      password: pass,
      category: category,
    );
    setState(() {
      _entries.add(newEntry);
    });
    await _saveEntries();
  }

  Future<void> _deleteEntry(int index) async {
    setState(() {
      _entries.removeAt(index);
    });
    await _saveEntries();
  }

  void _showDetailsDialog(VaultEntry entry) {
    bool localObscure = true;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(BrandIcons.getIcon(entry.serviceName), color: BrandIcons.getBrandColor(entry.serviceName)),
              const SizedBox(width: 12),
              Expanded(child: Text(entry.serviceName)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow("Username/Email", entry.username),
              const SizedBox(height: 12),
              const Text("Password", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      localObscure ? "••••••••" : entry.password,
                      style: const TextStyle(fontSize: 16, fontFamily: 'monospace'),
                    ),
                  ),
                  IconButton(
                    icon: Icon(localObscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setDialogState(() => localObscure = !localObscure),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      ClipboardService.copyWithAutoClear(entry.password);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password copied (clears in 30s)")));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _buildStrengthIndicator(entry.password),
              const SizedBox(height: 12),
              _infoRow("Category", entry.category),
              if (entry.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                _infoRow("Notes", entry.notes),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthIndicator(String password) {
    double strength = PasswordGenerator.checkStrength(password);
    Color color = Colors.red;
    String label = "Weak";
    if (strength > 0.4) { color = Colors.orange; label = "Fair"; }
    if (strength > 0.7) { color = Colors.green; label = "Strong"; }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: strength,
          backgroundColor: Colors.grey.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 4,
        ),
        const SizedBox(height: 4),
        Text("Strength: $label", style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
        Row(
          children: [
            Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              onPressed: () {
                ClipboardService.copyWithAutoClear(value);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$label copied (clears in 30s)")));
              },
            ),
          ],
        ),
      ],
    );
  }

  void _showAddDialog() {
    final serviceController = TextEditingController();
    final userController = TextEditingController();
    final passController = TextEditingController();
    String selectedCategory = 'General';
    bool obscure = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add Credential"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: serviceController, decoration: const InputDecoration(labelText: "Service (e.g. Google)")),
                TextField(controller: userController, decoration: const InputDecoration(labelText: "Username/Email")),
                TextField(
                  controller: passController,
                  decoration: InputDecoration(
                    labelText: "Password",
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setDialogState(() => obscure = !obscure),
                    ),
                  ),
                  obscureText: obscure,
                  onChanged: (val) => setDialogState(() {}),
                ),
                const SizedBox(height: 8),
                _buildStrengthIndicator(passController.text),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(labelText: "Category"),
                  items: ['General', 'Work', 'Social', 'Finance', 'Shopping'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setDialogState(() => selectedCategory = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (serviceController.text.isNotEmpty && passController.text.isNotEmpty) {
                  _addEntry(serviceController.text, userController.text, passController.text, selectedCategory);
                  Navigator.pop(context);
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToCSV() async {
    if (_entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No credentials to export")));
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Security Warning"),
        content: const Text("Unencrypted CSV export. Continue?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Export Unsafe")),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      List<List<dynamic>> rows = [["Service", "Username", "Password", "Category", "Notes"]];
      for (var entry in _entries) {
        rows.add([entry.serviceName, entry.username, entry.password, entry.category, entry.notes]);
      }
      String csv = const ListToCsvConverter().convert(rows);
      final directory = await getTemporaryDirectory();
      final file = File("${directory.path}/credentials_export.csv");
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(file.path)], text: 'Persona Credentials Export');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Export failed: $e")));
    }
  }

  Future<void> _importCredentials() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any, withData: true);
      if (result != null && result.files.single.bytes != null) {
        final content = utf8.decode(result.files.single.bytes!);
        List<List<dynamic>> rows = const CsvToListConverter().convert(content);
        if (rows.isEmpty) return;
        
        for (int i = 1; i < rows.length; i++) {
          if (rows[i].length >= 3) {
            _entries.add(VaultEntry(
              id: _uuid.v4(),
              serviceName: rows[i][0].toString(),
              username: rows[i][1].toString(),
              password: rows[i][2].toString(),
              category: rows[i].length > 3 ? rows[i][3].toString() : 'General',
            ));
          }
        }
        await _saveEntries();
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Import failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredEntries = _entries.where((e) => 
      e.serviceName.toLowerCase().contains(_searchQuery.toLowerCase()) || 
      e.username.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: "Search credentials...",
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: filteredEntries.length,
        itemBuilder: (context, index) {
          final entry = filteredEntries[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              onTap: () => _showDetailsDialog(entry),
              leading: CircleAvatar(
                backgroundColor: BrandIcons.getBrandColor(entry.serviceName).withOpacity(0.1),
                child: Icon(BrandIcons.getIcon(entry.serviceName), color: BrandIcons.getBrandColor(entry.serviceName), size: 20),
              ),
              title: Text(entry.serviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(entry.username),
              trailing: IconButton(
                icon: const Icon(Icons.copy_rounded, size: 20),
                onPressed: () {
                  ClipboardService.copyWithAutoClear(entry.password);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password copied")));
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(heroTag: "import", onPressed: _importCredentials, mini: true, child: const Icon(Icons.upload_file)),
          const SizedBox(height: 8),
          FloatingActionButton(heroTag: "export", onPressed: _exportToCSV, mini: true, child: const Icon(Icons.download)),
          const SizedBox(height: 8),
          FloatingActionButton(heroTag: "add", onPressed: _showAddDialog, child: const Icon(Icons.add)),
        ],
      ),
    );
  }
}
