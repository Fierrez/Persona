import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:persona_app/core/secure_storage.dart';
import 'package:persona_app/core/clipboard_service.dart';
import 'package:persona_app/core/password_generator.dart';
import 'package:persona_app/shared/brand_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'vault_model.dart';

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
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'General', 'Social', 'Work', 'Finance', 'Games', 'Entertainment', 'Shopping'];

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
    _filterEntries();
  }

  void _filterEntries() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEntries = _entries.where((e) {
        final matchesQuery = e.serviceName.toLowerCase().contains(query) || 
                             e.username.toLowerCase().contains(query);
        final matchesCategory = _selectedCategory == 'All' || e.category == _selectedCategory;
        return matchesQuery && matchesCategory;
      }).toList();
    });
  }

  Future<void> _loadEntries() async {
    final data = await _storage.readList("vault_credentials");
    final loaded = data.map((item) => VaultEntry.fromJson(item)).toList();
    setState(() {
      _entries = loaded;
      _filterEntries();
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
      _filterEntries();
    });
    await _saveEntries();
  }

  Future<void> _importFromCSV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result != null) {
        String content;
        if (result.files.single.bytes != null) {
          content = utf8.decode(result.files.single.bytes!);
        } else if (result.files.single.path != null) {
          content = await File(result.files.single.path!).readAsString();
        } else {
          return;
        }
        
        final List<List<dynamic>> rows = const CsvToListConverter().convert(content);
        if (rows.length < 2) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No data found in CSV")));
          return;
        }

        final header = rows[0].map((e) => e.toString().toLowerCase()).toList();
        int serviceIdx = header.indexWhere((h) => h.contains('service') || h.contains('name') || h.contains('title') || h.contains('url'));
        int userIdx = header.indexWhere((h) => h.contains('user') || h.contains('login') || h.contains('email'));
        int passIdx = header.indexWhere((h) => h.contains('pass'));
        int categoryIdx = header.indexWhere((h) => h.contains('cat') || h.contains('folder') || h.contains('group'));

        if (serviceIdx == -1) serviceIdx = 0;
        if (userIdx == -1) userIdx = 1;
        if (passIdx == -1) passIdx = 2;

        int importedCount = 0;
        setState(() {
          for (int i = 1; i < rows.length; i++) {
            final row = rows[i];
            if (row.length > serviceIdx && row.length > passIdx) {
              String service = row[serviceIdx].toString();
              if (service.isEmpty) continue;
              
              String username = row.length > userIdx ? row[userIdx].toString() : '';
              String password = row[passIdx].toString();
              String category = (categoryIdx != -1 && row.length > categoryIdx) ? row[categoryIdx].toString() : 'General';
              
              _entries.add(VaultEntry(
                id: _uuid.v4(),
                serviceName: service,
                username: username,
                password: password,
                category: category,
              ));
              importedCount++;
            }
          }
          _filterEntries();
        });
        await _saveEntries();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Successfully imported $importedCount credentials"),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            )
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error importing: Check file format"), backgroundColor: Colors.red)
        );
      }
    }
  }

  void _showDetailsDialog(VaultEntry entry) {
    bool localObscure = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: BrandIcons.getBrandColor(entry.serviceName).withOpacity(0.1),
                    child: Icon(BrandIcons.getIcon(entry.serviceName), color: BrandIcons.getBrandColor(entry.serviceName)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.serviceName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(entry.category, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _infoRow("Username/Email", entry.username, context),
              const SizedBox(height: 20),
              const Text("Password", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        localObscure ? "••••••••" : entry.password,
                        style: const TextStyle(fontSize: 18, fontFamily: 'monospace', fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: Icon(localObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setModalState(() => localObscure = !localObscure),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded),
                      onPressed: () {
                        ClipboardService.copyWithAutoClear(entry.password);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password copied")));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildStrengthIndicator(entry.password),
              const SizedBox(height: 32),
            ],
          ),
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
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: strength, 
            backgroundColor: color.withOpacity(0.1), 
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Security Level: ${strength > 0.7 ? 'Strong' : (strength > 0.4 ? 'Fair' : 'Weak')}", 
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(child: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 20), 
                onPressed: () => ClipboardService.copyWithAutoClear(value)
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddDialog() {
    final serviceController = TextEditingController();
    final userController = TextEditingController();
    final passController = TextEditingController();
    String category = _categories[1]; 
    bool obscure = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text("Add Credential", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextField(
                  controller: serviceController, 
                  decoration: InputDecoration(
                    labelText: "Service",
                    hintText: "e.g. Google, Netflix",
                    prefixIcon: const Icon(Icons.business_rounded),
                    filled: true,
                    fillColor: Theme.of(context).cardTheme.color,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: InputDecoration(
                    labelText: "Category",
                    prefixIcon: const Icon(Icons.category_rounded),
                    filled: true,
                    fillColor: Theme.of(context).cardTheme.color,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                  items: _categories.where((c) => c != 'All').map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setModalState(() => category = val!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: userController, 
                  decoration: InputDecoration(
                    labelText: "Username/Email",
                    prefixIcon: const Icon(Icons.person_rounded),
                    filled: true,
                    fillColor: Theme.of(context).cardTheme.color,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passController, 
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setModalState(() => obscure = !obscure),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardTheme.color,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D62ED),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (serviceController.text.isNotEmpty && passController.text.isNotEmpty) {
                        _addEntry(serviceController.text, userController.text, passController.text, category);
                        Navigator.pop(context);
                      }
                    },
                    child: const Text("Save Credential", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: "Search credentials...",
                hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                filled: true,
                fillColor: theme.cardTheme.color,
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                          _filterEntries();
                        });
                      }
                    },
                    selectedColor: const Color(0xFF2D62ED),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: theme.cardTheme.color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    side: BorderSide.none,
                    showCheckmark: false,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _filteredEntries.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text("No credentials found", style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 120),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
