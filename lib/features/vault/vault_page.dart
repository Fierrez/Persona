import 'package:flutter/material.dart';
import 'package:persona_app/core/password_generator.dart';
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Password Generator", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        generatedPassword,
                        style: const TextStyle(fontSize: 18, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
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
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Slider(
                value: length.toDouble(),
                min: 8,
                max: 32,
                divisions: 24,
                label: "Length: $length",
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
              SwitchListTile(
                title: const Text("Uppercase Letters"),
                value: useUpper,
                onChanged: (val) => setModalState(() => useUpper = val),
              ),
              SwitchListTile(
                title: const Text("Numbers"),
                value: useNumbers,
                onChanged: (val) => setModalState(() => useNumbers = val),
              ),
              SwitchListTile(
                title: const Text("Symbols"),
                value: useSymbols,
                onChanged: (val) => setModalState(() => useSymbols = val),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Done"),
              ),
            ],
          ),
        ),
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
