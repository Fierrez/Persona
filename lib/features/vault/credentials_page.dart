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
  List<VaultEntry> _filteredEntries = [];
  final _uuid = const Uuid();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEntries = _entries.where((e) => 
        e.serviceName.toLowerCase().contains(query) || 
        e.username.toLowerCase().contains(query)
      ).toList();
    });
  }

  Future<void> _loadEntries() async {
    final data = await _storage.readList("vault_credentials");
    final loaded = data.map((item) => VaultEntry.fromJson(item)).toList();
    setState(() {
      _entries = loaded;
      _filteredEntries = loaded;
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
      _onSearchChanged(); // Refresh filtered list
    });
    await _saveEntries();
  }

  void _showDetailsDialog(VaultEntry entry) {
    bool localObscure = true;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password copied")));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _buildStrengthIndicator(entry.password),
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
    Color color = strength > 0.7 ? Colors.green : (strength > 0.4 ? Colors.orange : Colors.red);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(value: strength, backgroundColor: color.withOpacity(0.1), valueColor: AlwaysStoppedAnimation(color)),
        Text("Strength: ${strength > 0.7 ? 'Strong' : (strength > 0.4 ? 'Fair' : 'Weak')}", style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
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
            IconButton(icon: const Icon(Icons.copy, size: 20), onPressed: () => ClipboardService.copyWithAutoClear(value)),
          ],
        ),
      ],
    );
  }

  void _showAddDialog() {
    final serviceController = TextEditingController();
    final userController = TextEditingController();
    final passController = TextEditingController();
    String category = 'General';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Add Credential"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: serviceController, decoration: const InputDecoration(labelText: "Service")),
              TextField(controller: userController, decoration: const InputDecoration(labelText: "Username")),
              TextField(controller: passController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              _addEntry(serviceController.text, userController.text, passController.text, category);
              Navigator.pop(context);
            },
            child: const Text("Save"),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: "Search...",
                hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                filled: true,
                fillColor: theme.cardTheme.color,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 120),
              itemCount: _filteredEntries.length,
              itemBuilder: (context, index) {
                final entry = _filteredEntries[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  color: theme.cardTheme.color,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.05)),
                  ),
                  child: ListTile(
                    onTap: () => _showDetailsDialog(entry),
                    leading: CircleAvatar(
                      backgroundColor: BrandIcons.getBrandColor(entry.serviceName).withOpacity(0.1),
                      child: Icon(BrandIcons.getIcon(entry.serviceName), color: BrandIcons.getBrandColor(entry.serviceName), size: 20),
                    ),
                    title: Text(entry.serviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(entry.username, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))),
                    trailing: IconButton(
                      icon: Icon(Icons.copy_rounded, size: 20, color: theme.colorScheme.primary),
                      onPressed: () {
                        ClipboardService.copyWithAutoClear(entry.password);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password copied")));
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: "import_c", 
              onPressed: () {}, 
              mini: true, 
              backgroundColor: theme.cardTheme.color,
              foregroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.upload_file),
            ),
            const SizedBox(height: 10),
            FloatingActionButton(
              heroTag: "add_c", 
              onPressed: _showAddDialog, 
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}
