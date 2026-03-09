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
  double _progress = 1.0;
  int _secondsRemaining = 30;
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
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        final now = DateTime.now();
        final seconds = now.second % 30;
        final milliseconds = now.millisecond;
        setState(() {
          _secondsRemaining = 30 - seconds;
          _progress = (30 - (seconds + milliseconds / 1000)) / 30;
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
        final issuer = parsedUri.queryParameters['issuer'] ?? (label.contains(':') ? label.split(':').first : label);
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
          HapticFeedback.lightImpact();
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Add Account", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: serviceController,
              decoration: InputDecoration(
                labelText: "Service Name",
                hintText: "e.g. Google, GitHub",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: accountController,
              decoration: InputDecoration(
                labelText: "Account Name",
                hintText: "e.g. user@example.com",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: secretController,
              decoration: InputDecoration(
                labelText: "Secret Key",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFB4B93),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
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
                child: const Text("Save Account", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredEntries = _entries.where((e) => 
      e.serviceName.toLowerCase().contains(_searchQuery.toLowerCase()) || 
      e.accountName.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Authenticator"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFFFB4B93)),
            onPressed: _scanQR,
            tooltip: 'Scan QR Code',
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 32,
            height: 32,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: _progress,
                  strokeWidth: 2.5,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(_progress < 0.2 ? Colors.red : const Color(0xFFFB4B93)),
                ),
                Text("$_secondsRemaining", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Search accounts",
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                filled: true,
                fillColor: theme.cardTheme.color ?? Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: filteredEntries.isEmpty 
        ? _buildEmptyState()
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
            itemCount: filteredEntries.length,
            itemBuilder: (context, index) {
              final entry = filteredEntries[index];
              final code = _generateTOTP(entry.secretKey);
              final brandColor = BrandIcons.getBrandColor(entry.serviceName);
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color ?? Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _copyCode(code),
                  onLongPress: () => _deleteAccount(entry),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: brandColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(BrandIcons.getIcon(entry.serviceName), color: brandColor, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.serviceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(entry.accountName, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              code.length >= 6 ? "${code.substring(0, 3)} ${code.substring(3)}" : code,
                              style: TextStyle(
                                fontSize: 24, 
                                fontWeight: FontWeight.bold, 
                                letterSpacing: 1.2,
                                color: _progress < 0.2 ? Colors.red : const Color(0xFFFB4B93)
                              ),
                            ),
                            const Text("TAP TO COPY", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0), // Lifted to avoid BottomAppBar overlap
        child: FloatingActionButton.extended(
          heroTag: "authenticator_add_account", // Unique tag to avoid Hero conflict
          onPressed: _showAddDialog,
          backgroundColor: const Color(0xFFFB4B93),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text("Add Account"),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text("No accounts yet", style: TextStyle(color: Colors.grey.shade600, fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const Text("Add your first 2FA account to get started", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _scanQR,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text("Scan QR Code"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFB4B93),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 12),
            Text("Verification code copied"),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF2D62ED),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deleteAccount(AuthenticatorEntry entry) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Account"),
        content: Text("Are you sure you want to remove ${entry.serviceName}? This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              setState(() => _entries.removeWhere((e) => e.id == entry.id));
              _saveEntries();
              Navigator.pop(context);
            },
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }
}
