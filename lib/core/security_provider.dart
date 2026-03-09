import 'dart:async';
import 'package:flutter/material.dart';
import 'package:persona_app/core/secure_storage.dart';
import 'package:persona_app/features/backup/backup_service.dart';
import 'auth_service.dart';

class SecurityProvider with ChangeNotifier {
  final SecureStorageService _storage = SecureStorageService();
  
  bool _isAppLockEnabled = false;
  bool _isAutoLockEnabled = true;
  int _clearClipboardSeconds = 30; 
  bool _isBlockScreenshotsEnabled = true;
  bool _isPrivacyModeEnabled = false;
  
  bool _isAuthenticated = false;
  Timer? _lockTimer;
  DateTime? _lastPausedTime;

  bool get isAppLockEnabled => _isAppLockEnabled;
  bool get isAutoLockEnabled => _isAutoLockEnabled;
  int get clearClipboardSeconds => _clearClipboardSeconds;
  bool get isBlockScreenshotsEnabled => _isBlockScreenshotsEnabled;
  bool get isPrivacyModeEnabled => _isPrivacyModeEnabled;
  bool get isAuthenticated => _isAuthenticated;

  SecurityProvider() {
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    _isAppLockEnabled = (await _storage.read("app_lock_enabled")) == "true";
    _isAutoLockEnabled = (await _storage.read("auto_lock_enabled")) != "false";
    _isPrivacyModeEnabled = (await _storage.read("privacy_mode_enabled")) == "true";
    
    final clipDur = await _storage.read("clear_clipboard_seconds");
    if (clipDur != null) {
      _clearClipboardSeconds = int.tryParse(clipDur) ?? 30;
    }
    
    _isBlockScreenshotsEnabled = (await _storage.read("block_screenshots_enabled")) != "false";

    _isAuthenticated = !_isAppLockEnabled;
    notifyListeners();
  }

  Future<void> togglePrivacyMode(bool value) async {
    _isPrivacyModeEnabled = value;
    await _storage.write("privacy_mode_enabled", value.toString());
    notifyListeners();
  }

  Future<void> toggleAppLock(bool value) async {
    _isAppLockEnabled = value;
    await _storage.write("app_lock_enabled", value.toString());
    if (!value) {
      _isAuthenticated = true;
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

  void handleAppPaused() {
    _lastPausedTime = DateTime.now();
  }

  void handleAppResumed() {
    if (!_isAppLockEnabled || !_isAutoLockEnabled) return;
    
    if (_lastPausedTime != null) {
      final difference = DateTime.now().difference(_lastPausedTime!);
      // Only lock if the app was in the background for more than 30 seconds
      // This prevents annoying biometric prompts during quick app switches
      if (difference.inSeconds > 30) {
        _isAuthenticated = false;
        notifyListeners();
      }
    }
    _lastPausedTime = null;
  }

  Future<bool> requestAuthentication() async {
    if (!_isAppLockEnabled) return true;
    
    final success = await AuthService.authenticate();
    if (success) {
      _isAuthenticated = true;
      notifyListeners();
      
      // Attempt weekly automatic backup upon successful authentication
      // We use a default backup password for automatic backups
      _triggerAutoBackup();
    }
    return success;
  }

  Future<void> _triggerAutoBackup() async {
    try {
      // In a real app, you might use a derived key from the user's PIN/biometric context
      // For now, we use a consistent internal password for automatic encrypted backups
      await BackupService.checkAndRunWeeklyBackup("persona_internal_auto_backup_key");
    } catch (e) {
      debugPrint("Automatic backup failed: $e");
    }
  }

  Future<void> authenticate() async {
    if (!_isAppLockEnabled) {
      _isAuthenticated = true;
      notifyListeners();
      _triggerAutoBackup();
      return;
    }
    await requestAuthentication();
  }
}
