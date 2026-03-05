import 'dart:async';
import 'package:flutter/services.dart';
import 'package:persona_app/core/secure_storage.dart';

class ClipboardService {
  static Timer? _timer;
  static final SecureStorageService _storage = SecureStorageService();

  static Future<void> copyWithAutoClear(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    
    _timer?.cancel();

    // Get the latest preference from storage
    final durStr = await _storage.read("clear_clipboard_seconds");
    final seconds = durStr != null ? (int.tryParse(durStr) ?? 30) : 30;

    _timer = Timer(Duration(seconds: seconds), () async {
      final currentData = await Clipboard.getData(Clipboard.kTextPlain);
      // Only clear if the user hasn't copied something else in the meantime
      if (currentData?.text == text) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    });
  }
}
