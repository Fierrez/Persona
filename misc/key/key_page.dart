import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:persona_app/core/secure_storage.dart';
import 'package:otp/otp.dart';
import 'package:uuid/uuid.dart';
import 'authenticator_model.dart';
import 'qr_scanner_page.dart';

class KeyPage extends StatefulWidget {
  const KeyPage({super.key});

  @override
  State<KeyPage> createState() => _KeyPageState();
}

class _KeyPageState extends State<KeyPage> {
  final SecureStorageService _storage = SecureStorageService();
  List<AuthenticatorEntry> _entries = [];
  Timer? _timer;
  int _secondsRemaining = 30;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsRemaining = 30 - (DateTime.now().second % 30);
        });
      }
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

  void _parseUri(String uri) {
    try {
      final parsedUri = Uri.parse(uri);
      if (parsedUri.scheme == 'otpauth' && parsedUri.host == 'totp') {
        final label = Uri.decodeComponent(parsedUri.path.replaceFirst('/', ''));
        final secret = parsedUri.queryParameters['secret'];
        final issuer = parsedUri.queryParameters['issuer'] ?? label.split(':').first;
        final account = label.contains(':') ? label.split(':').last.trim() : label;

        if (secret != null) {
          final newEntry = AuthenticatorEntry(
            id: _uuid.v4(),
            serviceName: issuer,
            accountName: account,
            secretKey: secret,
          );
          setState(() {
            _entries.add(newEntry);
          });
          _saveEntries();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid QR Code")));
    }
  }

  Future<void> _scanQR() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerPage()),
    );
    if (result != null) {
      _parseUri(result);
    }
  }

  void _showAddDialog() {
    final serviceController = TextEditingController();
    final accountController = TextEditingController();
    final secretController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add 2FA Account"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: serviceController, decoration: const InputDecoration(labelText: "Service (e.g. Google)")),
            TextField(controller: accountController, decoration: const InputDecoration(labelText: "Account Name")),
            TextField(controller: secretController, decoration: const InputDecoration(labelText: "Secret Key")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (serviceController.text.isNotEmpty && secretController.text.isNotEmpty) {
                final newEntry = AuthenticatorEntry(
                  id: _uuid.v4(),
                  serviceName: serviceController.text,
                  accountName: accountController.text,
                  secretKey: secretController.text,
                );
                setState(() {
                  _entries.add(newEntry);
                });
                await _saveEntries();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Authenticator"),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(child: Text("$_secondsRemaining", style: const TextStyle(fontWeight: FontWeight.bold))),
          )
        ],
      ),
      body: ListView.builder(
        itemCount: _entries.length,
        itemBuilder: (context, index) {
          final entry = _entries[index];
          final code = _generateTOTP(entry.secretKey);
          
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(entry.serviceName),
              subtitle: Text(entry.accountName),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    code.length >= 6 ? "${code.substring(0, 3)} ${code.substring(3)}" : code,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Code copied")));
                    },
                  ),
                ],
              ),
              onLongPress: () => _deleteAccount(index),
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "scan_qr",
            onPressed: _scanQR,
            child: const Icon(Icons.qr_code_scanner),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "add_manual",
            onPressed: _showAddDialog,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  void _deleteAccount(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account?"),
        content: Text("Are you sure you want to delete ${_entries[index].serviceName}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              setState(() => _entries.removeAt(index));
              _saveEntries();
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
