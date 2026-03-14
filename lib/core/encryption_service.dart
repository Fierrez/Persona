import 'package:encrypt/encrypt.dart';
import 'package:persona_app/core/secure_storage.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final _storage = SecureStorageService();
  Key? _key;
  IV? _iv;

  Future<void> init() async {
    String? storedKey = await _storage.read('encryption_key');
    String? storedIv = await _storage.read('encryption_iv');

    if (storedKey == null || storedIv == null || storedKey == 'null') {
      final key = Key.fromSecureRandom(32);
      final iv = IV.fromSecureRandom(16);
      await _storage.write('encryption_key', key.base64);
      await _storage.write('encryption_iv', iv.base64);
      _key = key;
      _iv = iv;
    } else {
      try {
        _key = Key.fromBase64(_sanitize(storedKey));
        _iv = IV.fromBase64(_sanitize(storedIv));
      } catch (e) {
        // Fallback: if keys are corrupted, generate new ones
        final key = Key.fromSecureRandom(32);
        final iv = IV.fromSecureRandom(16);
        await _storage.write('encryption_key', key.base64);
        await _storage.write('encryption_iv', iv.base64);
        _key = key;
        _iv = iv;
      }
    }
  }

  String _sanitize(String value) {
    String sanitized = value.trim();
    if (sanitized.startsWith('"') && sanitized.endsWith('"') && sanitized.length >= 2) {
      sanitized = sanitized.substring(1, sanitized.length - 1);
    }
    return sanitized;
  }

  String encrypt(String text) {
    if (_key == null || _iv == null) return text;
    final encrypter = Encrypter(AES(_key!));
    return encrypter.encrypt(text, iv: _iv).base64;
  }

  String decrypt(String encryptedText) {
    if (_key == null || _iv == null) return encryptedText;
    try {
      final encrypter = Encrypter(AES(_key!));
      return encrypter.decrypt64(encryptedText, iv: _iv);
    } catch (e) {
      return encryptedText; 
    }
  }

  String hash(String text) {
    return sha256.convert(utf8.encode(text)).toString();
  }
}
