import 'dart:async';
import 'package:flutter/material.dart';
import 'package:persona_app/core/secure_storage.dart';
import 'auth_service.dart';

class SecurityProvider with ChangeNotifier {
  final SecureStorageService _storage = SecureStorageService();
  
  bool _isAppLockEnabled = false;
  bool _isAutoLockEnabled = true;
  int _clearClipboardSeconds = 30; 
  bool _isBlockScreenshotsEnabled = true;
  
  bool _isAuthenticated = false;
  Timer? _lockTimer;

  bool get isAppLockEnabled => _isAppLockEnabled;
  bool get isAutoLockEnabled => _isAutoLockEnabled;
  int get clearClipboardSeconds => _clearClipboardSeconds;
  bool get isBlockScreenshotsEnabled => _isBlockScreenshotsEnabled;
  bool get isAuthenticated => _isAuthenticated;

  SecurityProvider() {
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    _isAppLockEnabled = (await _storage.read("app_lock_enabled")) == "true";
    _isAutoLockEnabled = (await _storage.read("auto_lock_enabled")) != "false";
    
    final clipDur = await _storage.read("clear_clipboard_seconds");
    if (clipDur != null) {
      _clearClipboardSeconds = int.tryParse(clipDur) ?? 30;
    }
    
    _isBlockScreenshotsEnabled = (await _storage.read("block_screenshots_enabled")) != "false";

    // Set initial auth state
    _isAuthenticated = !_isAppLockEnabled;
    notifyListeners();
  }

  Future<void> toggleAppLock(bool value) async {
    _isAppLockEnabled = value;
    await _storage.write("app_lock_enabled", value.toString());
    if (!value) {
      _isAuthenticated = true;
      _lockTimer?.cancel();
    } else {
      _isAuthenticated = false;
    }
    notifyListeners();
  }

  Future<void> toggleAutoLock(bool value) async {
    _isAutoLockEnabled = value;
    await _storage.write("auto_lock_enabled", value.toString());
    notifyListeners();
  }

  Future<void> setClearClipboardSeconds(int seconds) async {
    _clearClipboardSeconds = seconds;
    await _storage.write("clear_clipboard_seconds", seconds.toString());
    notifyListeners();
  }

  Future<void> toggleBlockScreenshots(bool value) async {
    _isBlockScreenshotsEnabled = value;
    await _storage.write("block_screenshots_enabled", value.toString());
    notifyListeners();
  }

  Future<bool> requestAuthentication() async {
    final success = await AuthService.authenticate();
    if (success) {
      _isAuthenticated = true;
      _lockTimer?.cancel();
      notifyListeners();
    }
    return success;
  }

  Future<void> authenticate() async {
    if (!_isAppLockEnabled) {
      _isAuthenticated = true;
      notifyListeners();
      return;
    }
    await requestAuthentication();
  }

  void startLockTimer() {
    // If App Lock is on and Auto Lock is on, we should lock when backgrounded
    if (!_isAppLockEnabled || !_isAutoLockEnabled) return;
    
    // We lock after a short delay to allow quick app switching
    _lockTimer?.cancel();
    _lockTimer = Timer(const Duration(seconds: 5), () {
      _isAuthenticated = false;
      notifyListeners();
    });
  }

  void cancelLockTimer() {
    _lockTimer?.cancel();
  }

  void lockImmediate() {
    if (!_isAppLockEnabled) return;
    _isAuthenticated = false;
    _lockTimer?.cancel();
    notifyListeners();
  }
}
