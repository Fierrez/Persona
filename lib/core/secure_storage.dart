import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  String _cleanValue(String value) {
    var result = value.trim();
    if (result.startsWith('"') && result.endsWith('"') && result.length >= 2) {
      result = result.substring(1, result.length - 1);
    }
    return result;
  }

  Future<void> write(String key, dynamic value) async {
    try {
      // Always store as JSON encoded string to handle types consistently
      await _storage.write(key: key, value: jsonEncode(value));
    } catch (e) {
      await _storage.write(key: key, value: value.toString());
    }
  }

  Future<String?> read(String key) async {
    try {
      final data = await _storage.read(key: key);
      if (data == null || data == 'null' || data.isEmpty) return null;
      
      try {
        final decoded = jsonDecode(data);
        if (decoded == null) return null;
        return _cleanValue(decoded.toString());
      } catch (e) {
        // If not JSON, return cleaned raw data
        return _cleanValue(data);
      }
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>> readList(String key) async {
    try {
      final data = await _storage.read(key: key);
      if (data == null || data == 'null' || data.isEmpty) return [];
      
      try {
        final decoded = jsonDecode(data);
        if (decoded is List) return decoded;
        if (decoded is String) {
          final innerDecoded = jsonDecode(decoded);
          if (innerDecoded is List) return innerDecoded;
        }
        return [];
      } catch (e) {
        return [];
      }
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
    final rawData = await _storage.readAll();
    final Map<String, String> cleanedData = {};
    
    rawData.forEach((key, value) {
      try {
        final decoded = jsonDecode(value);
        cleanedData[key] = _cleanValue(decoded?.toString() ?? value);
      } catch (e) {
        cleanedData[key] = _cleanValue(value);
      }
    });
    
    return cleanedData;
  }
}
