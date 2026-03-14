import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:persona_app/core/secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class BackupService {
  static final SecureStorageService _storage = SecureStorageService();

  static String _cleanInput(String input) {
    var result = input.trim();
    if (result.startsWith('"') && result.endsWith('"')) {
      result = result.substring(1, result.length - 1);
    }
    return result;
  }

  static Future<void> checkAndRunWeeklyBackup(String? password) async {
    if (password == null || password.isEmpty) return;
    final lastBackupStr = await _storage.read("last_auto_backup_date");
    final now = DateTime.now();
    if (lastBackupStr != null) {
      try {
        final lastBackup = DateTime.parse(_cleanInput(lastBackupStr));
        if (now.difference(lastBackup).inDays < 7) return;
      } catch (e) {}
    }
    await runAutomaticBackup(password);
  }

  static Future<bool> runAutomaticBackup(String password) async {
    try {
      final encryptedData = await getEncryptedBackupData(password);
      if (encryptedData == null) return false;
      final directory = await getApplicationDocumentsPlatformDirectory();
      final backupDir = Directory('${directory.path}/backups');
      if (!await backupDir.exists()) await backupDir.create(recursive: true);
      final date = DateFormat('yyyyMMdd').format(DateTime.now());
      final file = File('${backupDir.path}/auto_backup_$date.enc');
      await file.writeAsString(encryptedData);
      await _storage.write("last_auto_backup_date", DateTime.now().toIso8601String());
      await _cleanupOldBackups(backupDir);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> restoreLatestAutoBackup(String password) async {
    try {
      final directory = await getApplicationDocumentsPlatformDirectory();
      final backupDir = Directory('${directory.path}/backups');
      if (!await backupDir.exists()) return false;
      final files = backupDir.listSync().whereType<File>().toList();
      if (files.isEmpty) return false;
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      final content = await files.first.readAsString();
      return await restoreEncryptedBackup(content, password);
    } catch (e) {
      return false;
    }
  }

  static Future<void> _cleanupOldBackups(Directory backupDir) async {
    try {
      final files = backupDir.listSync().whereType<File>().toList();
      if (files.length > 4) {
        files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
        for (int i = 0; i < files.length - 4; i++) await files[i].delete();
      }
    } catch (e) {}
  }

  static Future<Directory> getApplicationDocumentsPlatformDirectory() async {
    if (Platform.isAndroid) return await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    return await getApplicationDocumentsDirectory();
  }

  static Future<Map<String, dynamic>> getRawData() async => await _storage.readAll();

  static Future<String> generateTextSummary() async {
    final data = await _storage.readAll();
    final buffer = StringBuffer();
    buffer.writeln("PERSONA VAULT SUMMARY - ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}");
    buffer.writeln("==========================================\n");
    
    data.forEach((key, value) {
      if (!key.startsWith('last_') && !key.contains('backup')) {
        buffer.writeln("[$key]: $value");
      }
    });
    return buffer.toString();
  }

  static Future<bool> restoreFromJson(String jsonString) async {
    try {
      final cleanedJson = _cleanInput(jsonString);
      final Map<String, dynamic> data = jsonDecode(cleanedJson);
      for (var entry in data.entries) {
        await _storage.write(entry.key, entry.value);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> getEncryptedBackupData(String password) async {
    try {
      final allData = await _storage.readAll();
      return _encryptData(jsonEncode(allData), password);
    } catch (e) {
      return null;
    }
  }

  static Future<bool> restoreEncryptedBackup(String encryptedContent, String password) async {
    try {
      final cleanedContent = _cleanInput(encryptedContent);
      final jsonString = _decryptData(cleanedContent, password);
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
    final autoDate = await _storage.read("last_auto_backup_date");
    return {"date": _cleanInput(date ?? ""), "autoDate": _cleanInput(autoDate ?? "")};
  }

  static encrypt.Key _deriveKey(String password) {
    final digest = sha256.convert(utf8.encode(password));
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
    final iv = encrypt.IV.fromBase64(_cleanInput(parts[0]));
    final encrypted = encrypt.Encrypted.fromBase64(_cleanInput(parts[1]));
    final key = _deriveKey(password);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    return encrypter.decrypt(encrypted, iv: iv);
  }
}
