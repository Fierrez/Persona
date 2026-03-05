import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  // Use encryptedSharedPreferences for higher security on Android
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  Future<void> write(String key, dynamic value) async {
    await _storage.write(key: key, value: jsonEncode(value));
  }

  Future<String?> read(String key) async {
    final data = await _storage.read(key: key);
    if (data == null) return null;
    try {
      return jsonDecode(data).toString();
    } catch (e) {
      return data;
    }
  }

  Future<List<dynamic>> readList(String key) async {
    final data = await _storage.read(key: key);
    if (data == null) return [];
    try {
      return jsonDecode(data);
    } catch (e) {
      return [];
    }
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }
}
