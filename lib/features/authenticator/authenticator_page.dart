import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:persona_app/core/secure_storage.dart';
import 'package:otp/otp.dart';
import 'package:uuid/uuid.dart';
import 'package:persona_app/shared/brand_icons.dart';
import 'authenticator_model.dart';
import 'qr_scanner_page.dart';

class AuthenticatorPage extends StatefulWidget {
  const AuthenticatorPage({super.key});

  @override
  State<AuthenticatorPage> createState() => _AuthenticatorPageState();
}

class _AuthenticatorPageState extends State<AuthenticatorPage> {
  final SecureStorageService _storage = SecureStorageService();
  List<AuthenticatorEntry> _entries = [];
  Timer? _timer;
  final ValueNotifier<double> _progressNotifier = ValueNotifier(1.0);
  final ValueNotifier<int> _secondsNotifier = ValueNotifier(30);
  final _uuid = const Uuid();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressNotifier.dispose();
    _secondsNotifier.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      final now = DateTime.now();
      final seconds = now.second % 30;
      final milliseconds = now.millisecond;
      _secondsNotifier.value = 30 - seconds;
      _progressNotifier.value = (30 - (seconds + milliseconds / 1000)) / 30;
    });
  }

  Future<void> _loadEntries() async {
    final data = await _storage.readList("authenticator_entries");
    setState(() {
      _entries = data.map((item) => AuthenticatorEntry.fromJson(item)).toList();
    });
  }

  Future<void> _saveEntries() async {
    await _storage.write("authenticator_entries", _entries.map((e) => e.toJson()).toList());
  }

  String _generateTOTP(String secret) {
    try {
      final normalizedSecret = secret.replaceAll(' ', '').toUpperCase();
      return OTP.generateTOTPCodeString(
        normalizedSecret,
        DateTime.now().millisecondsSinceEpoch,
        length: 6,
        interval: 30,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
    } catch (e) {
      return "000000";
    }
  }

  void _showAddDialog() {
    final serviceController = TextEditingController();
    final accountController = TextEditingController();
    final secretController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Add Account", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(
                controller: serviceController,
                decoration: InputDecoration(
                  labelText: "Service Name",
                  filled: true,
                  fillColor: Theme.of(context).cardTheme.color,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: secretController,
                decoration: InputDecoration(
                  labelText: "Secret Key",
                  filled: true,
                  fillColor: Theme.of(context).cardTheme.color,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFB4B93),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: () async {
                    if (serviceController.text.isNotEmpty && secretController.text.isNotEmpty) {
                      final newEntry = AuthenticatorEntry(
                        id: _uuid.v4(),
                        serviceName: serviceController.text,
                        accountName: accountController.text,
                        secretKey: secretController.text,
                      );
                      setState(() => _entries.add(newEntry));
                      await _saveEntries();
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Save Account", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredEntries = _entries.where((e) => 
      e.serviceName.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("Authenticator"),
        backgroundColor: Colors.transparent,
        actions: [
          ValueListenableBuilder<double>(
            valueListenable: _progressNotifier,
            builder: (context, progress, _) => Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(progress < 0.2 ? Colors.red : const Color(0xFFFB4B93)),
                ),
                ValueListenableBuilder<int>(
                  valueListenable: _secondsNotifier,
                  builder: (context, seconds, _) => Text("$seconds", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Search accounts",
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: theme.cardTheme.color,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredEntries.length,
              itemBuilder: (context, index) {
                final entry = filteredEntries[index];
                final code = _generateTOTP(entry.secretKey);
                return _AuthenticatorTile(entry: entry, code: code);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFFFB4B93),
        label: const Text("Add Account"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class _AuthenticatorTile extends StatelessWidget {
  final AuthenticatorEntry entry;
  final String code;
  const _AuthenticatorTile({required this.entry, required this.code});

  @override
  Widget build(BuildContext context) {
    final brandColor = BrandIcons.getBrandColor(entry.serviceName);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: brandColor.withOpacity(0.1), child: Icon(BrandIcons.getIcon(entry.serviceName), color: brandColor)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.serviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(entry.accountName, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(code, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFB4B93))),
        ],
      ),
    );
  }
}
