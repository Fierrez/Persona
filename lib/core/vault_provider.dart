import 'package:flutter/material.dart';
import 'package:persona_app/core/secure_storage.dart';
import 'package:persona_app/core/encryption_service.dart';
import 'package:persona_app/features/vault/vault_model.dart';
import 'package:persona_app/features/vault/recovery_code_model.dart';

class VaultProvider with ChangeNotifier {
  final _storage = SecureStorageService();
  final _encryption = EncryptionService();

  List<VaultEntry> _credentials = [];
  List<RecoveryCode> _recoveryCodes = [];
  bool _isLoading = false;

  List<VaultEntry> get credentials => _credentials;
  List<RecoveryCode> get recoveryCodes => _recoveryCodes;
  bool get isLoading => _isLoading;

  VaultProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    await _encryption.init();
    await loadAll();
    _isLoading = false;
    notifyListeners();
  }

  void reset() {
    _credentials = [];
    _recoveryCodes = [];
    notifyListeners();
  }

  Future<void> loadAll() async {
    await loadCredentials();
    await loadRecoveryCodes();
  }

  Future<void> loadCredentials() async {
    final data = await _storage.readList('vault_credentials');
    _credentials = data.map((item) {
      final entry = VaultEntry.fromJson(item);
      try {
        return VaultEntry(
          id: entry.id,
          serviceName: entry.serviceName,
          username: entry.username,
          password: _encryption.decrypt(entry.password),
          notes: entry.notes,
          category: entry.category,
          updatedAt: entry.updatedAt,
        );
      } catch (e) {
        // Handle decryption failure, maybe return a placeholder or log it
        return entry; // Or a version of it with an error state
      }
    }).toList();
    notifyListeners();
  }

  Future<void> addCredential(VaultEntry entry) async {
    _credentials.add(entry);
    await _saveCredentials();
    notifyListeners();
  }

  Future<void> deleteCredential(String id) async {
    _credentials.removeWhere((e) => e.id == id);
    await _saveCredentials();
    notifyListeners();
  }

  Future<void> _saveCredentials() async {
     final encryptedEntries = _credentials.map((e) {
      return VaultEntry(
        id: e.id,
        serviceName: e.serviceName,
        username: e.username,
        password: _encryption.encrypt(e.password),
        notes: e.notes,
        category: e.category,
        updatedAt: e.updatedAt,
      ).toJson();
    }).toList();
    await _storage.write('vault_credentials', encryptedEntries);
  }

  // Recovery Codes Logic
  Future<void> loadRecoveryCodes() async {
    final data = await _storage.readList('recovery_codes');
    _recoveryCodes = data.map((item) {
      final rc = RecoveryCode.fromJson(item);
       try {
        return RecoveryCode(
          id: rc.id,
          serviceName: rc.serviceName,
          code: _encryption.decrypt(rc.code),
          used: rc.used,
        );
      } catch (e) {
        return rc;
      }
    }).toList();
    notifyListeners();
  }

  Future<void> addRecoveryCodes(List<RecoveryCode> codes) async {
    _recoveryCodes.addAll(codes);
    await _saveRecoveryCodes();
    notifyListeners();
  }

  Future<void> toggleRecoveryCodeUsed(String id) async {
    final index = _recoveryCodes.indexWhere((c) => c.id == id);
    if (index != -1) {
      _recoveryCodes[index] = RecoveryCode(
        id: _recoveryCodes[index].id,
        serviceName: _recoveryCodes[index].serviceName,
        code: _recoveryCodes[index].code,
        used: !_recoveryCodes[index].used,
      );
      await _saveRecoveryCodes();
      notifyListeners();
    }
  }

  Future<void> deleteRecoveryCode(String id) async {
    _recoveryCodes.removeWhere((c) => c.id == id);
    await _saveRecoveryCodes();
    notifyListeners();
  }

  Future<void> _saveRecoveryCodes() async {
    final encryptedData = _recoveryCodes.map((rc) => {
      'id': rc.id,
      'serviceName': rc.serviceName,
      'code': _encryption.encrypt(rc.code),
      'used': rc.used,
    }).toList();
    await _storage.write('recovery_codes', encryptedData);
  }
}
