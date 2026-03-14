import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:persona_app/core/secure_storage.dart';
import 'package:persona_app/features/backup/backup_service.dart';
import 'package:screen_protector/screen_protector.dart';
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
    
    // Apply screenshot protection based on saved setting
    _applyScreenshotProtection();

    // On Windows, we default to authenticated to avoid hangs/locked states if auth fails
    if (!kIsWeb && Platform.isWindows) {
      _isAuthenticated = true;
    } else {
      _isAuthenticated = !_isAppLockEnabled;
    }
    
    notifyListeners();
  }

  Future<void> _applyScreenshotProtection() async {
    // ScreenProtector is primarily for mobile. Skip on Windows to avoid hangs.
    if (!kIsWeb && Platform.isWindows) return;
    
    try {
      if (_isBlockScreenshotsEnabled) {
        await ScreenProtector.preventScreenshotOn();
      } else {
        await ScreenProtector.preventScreenshotOff();
      }
    } catch (e) {
      debugPrint("ScreenProtector error: $e");
    }
  }

  Future<void> togglePrivacyMode(bool value) async {
    _isPrivacyModeEnabled = value;
    await _storage.write("privacy_mode_enabled", value.toString());
    notifyListeners();
  }

  Future<void> toggleAppLock(bool value) async {
    _isAppLockEnabled = value;
    await _storage.write("app_lock_enabled", value.toString());
    if (!value || (!kIsWeb && Platform.isWindows)) {
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
    await _applyScreenshotProtection();
    notifyListeners();
  }

  void handleAppPaused() {
    _lastPausedTime = DateTime.now();
  }

  void handleAppResumed() {
    if (!kIsWeb && Platform.isWindows) return;
    if (!_isAppLockEnabled || !_isAutoLockEnabled) return;
    
    if (_lastPausedTime != null) {
      final difference = DateTime.now().difference(_lastPausedTime!);
      if (difference.inSeconds > 30) {
        _isAuthenticated = false;
        notifyListeners();
      }
    }
    _lastPausedTime = null;
  }

  Future<bool> requestAuthentication() async {
    if (!kIsWeb && Platform.isWindows) return true;
    if (!_isAppLockEnabled) return true;
    
    final success = await AuthService.authenticate();
    if (success) {
      _isAuthenticated = true;
      notifyListeners();
      _triggerAutoBackup();
    }
    return success;
  }

  Future<void> _triggerAutoBackup() async {
    try {
      await BackupService.checkAndRunWeeklyBackup("persona_internal_auto_backup_key");
    } catch (e) {
      debugPrint("Automatic backup failed: $e");
    }
  }

  Future<void> authenticate() async {
    if (!kIsWeb && Platform.isWindows) {
      _isAuthenticated = true;
      notifyListeners();
      return;
    }
    if (!_isAppLockEnabled) {
      _isAuthenticated = true;
      notifyListeners();
      _triggerAutoBackup();
      return;
    }
    await requestAuthentication();
  }
}
