import 'package:flutter/material.dart';
import 'package:persona_app/core/password_generator.dart';
import 'package:persona_app/core/clipboard_service.dart';
import 'credentials_page.dart';
import 'recovery_codes_page.dart';
import '../notes/notes_page.dart';

class VaultPage extends StatefulWidget {
  const VaultPage({super.key});

  @override
  State<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends State<VaultPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showPasswordGenerator() {
    int length = 16;
    bool useUpper = true;
    bool useNumbers = true;
    bool useSymbols = true;
    String generatedPassword = PasswordGenerator.generate();

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
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text("Password Generator", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D62ED).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2D62ED).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        generatedPassword,
                        style: const TextStyle(fontSize: 20, fontFamily: 'monospace', fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2D62ED)),
                      onPressed: () {
                        setModalState(() {
                          generatedPassword = PasswordGenerator.generate(
                            length: length,
                            useUppercase: useUpper,
                            useNumbers: useNumbers,
                            useSymbols: useSymbols,
                          );
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: Color(0xFF2D62ED)),
                      onPressed: () {
                        ClipboardService.copyWithAutoClear(generatedPassword);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password copied")));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Length", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("$length", style: const TextStyle(color: Color(0xFF2D62ED), fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: length.toDouble(),
                min: 8,
                max: 32,
                divisions: 24,
                activeColor: const Color(0xFF2D62ED),
                onChanged: (val) {
                  setModalState(() {
                    length = val.toInt();
                    generatedPassword = PasswordGenerator.generate(
                      length: length,
                      useUppercase: useUpper,
                      useNumbers: useNumbers,
                      useSymbols: useSymbols,
                    );
                  });
                },
              ),
              const SizedBox(height: 12),
              _buildGeneratorToggle("Uppercase Letters", useUpper, (val) {
                setModalState(() {
                  useUpper = val;
                  generatedPassword = PasswordGenerator.generate(length: length, useUppercase: useUpper, useNumbers: useNumbers, useSymbols: useSymbols);
                });
              }),
              _buildGeneratorToggle("Numbers", useNumbers, (val) {
                setModalState(() {
                  useNumbers = val;
                  generatedPassword = PasswordGenerator.generate(length: length, useUppercase: useUpper, useNumbers: useNumbers, useSymbols: useSymbols);
                });
              }),
              _buildGeneratorToggle("Symbols", useSymbols, (val) {
                setModalState(() {
                  useSymbols = val;
                  generatedPassword = PasswordGenerator.generate(length: length, useUppercase: useUpper, useNumbers: useNumbers, useSymbols: useSymbols);
                });
              }),
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Use This Password", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneratorToggle(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SwitchListTile(
        title: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        value: value,
        activeColor: const Color(0xFF2D62ED),
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vault"),
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key_rounded),
            onPressed: _showPasswordGenerator,
            tooltip: "Password Generator",
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: "Credentials"),
            Tab(text: "Recovery Codes"),
            Tab(text: "Secure Notes"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CredentialsPage(),
          RecoveryCodesPage(),
          NotesPage(),
        ],
      ),
    );
  }
}
