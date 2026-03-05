import 'dart:convert';
import 'dart:typed_data';
import 'package:persona_app/core/secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';

class BackupService {
  static final SecureStorageService _storage = SecureStorageService();

  static Future<String?> getEncryptedBackupData(String password) async {
    try {
      final allData = await _storage.readAll();
      final jsonString = jsonEncode(allData);
      return _encryptData(jsonString, password);
    } catch (e) {
      return null;
    }
  }

  static Future<bool> restoreEncryptedBackup(String encryptedContent, String password) async {
    try {
      final jsonString = _decryptData(encryptedContent, password);
      final Map<String, dynamic> data = jsonDecode(jsonString);
      for (var entry in data.entries) {
        await _storage.write(entry.key, entry.value);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> updateBackupInfo(int size) async {
    await _storage.write("last_backup_date", DateTime.now().toIso8601String());
    await _storage.write("last_backup_size", size.toString());
  }

  static Future<Map<String, String?>> getBackupInfo() async {
    final date = await _storage.read("last_backup_date");
    final size = await _storage.read("last_backup_size");
    String? clean(String? val) {
      if (val == null) return null;
      if (val.startsWith('"') && val.endsWith('"')) return val.substring(1, val.length - 1);
      return val;
    }
    return {"date": clean(date), "size": clean(size)};
  }

  static encrypt.Key _deriveKey(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return encrypt.Key(Uint8List.fromList(digest.bytes));
  }

  static String _encryptData(String plainText, String password) {
    final key = _deriveKey(password);
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return "${iv.base64}:${encrypted.base64}";
  }

  static String _decryptData(String encryptedText, String password) {
    final parts = encryptedText.split(':');
    if (parts.length != 2) throw Exception("Invalid format");
    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
    final key = _deriveKey(password);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    return encrypter.decrypt(encrypted, iv: iv);
  }
}
