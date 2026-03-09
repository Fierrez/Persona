import 'package:flutter/material.dart';
import 'package:persona_app/core/secure_storage.dart';

class DevProvider with ChangeNotifier {
  final SecureStorageService _storage = SecureStorageService();
  
  /// --- MASTER CODE SWITCH ---
  /// Set this to 'false' to hide the entire Development group from users.
  static const bool isDevelopmentEnabled = true; 

  bool _isDevMenuVisible = true; 
  bool _showErrorAlerts = false;

  /// Returns true only if both the master switch is ON and the internal visibility is true.
  bool get isDevMenuVisible => isDevelopmentEnabled && _isDevMenuVisible;
  bool get showErrorAlerts => _showErrorAlerts;

  DevProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final devMenuEnabled = await _storage.read("dev_show_menu");
      // Default to TRUE if not set, or check the stored value
      _isDevMenuVisible = devMenuEnabled == null ? true : (devMenuEnabled == "true");

      final showErrors = await _storage.read("dev_show_errors");
      _showErrorAlerts = showErrors == "true";
      notifyListeners();
    } catch (e) {
      debugPrint("DevProvider load error: $e");
    }
  }

  Future<void> toggleShowErrors(bool value) async {
    _showErrorAlerts = value;
    await _storage.write("dev_show_errors", value.toString());
    notifyListeners();
  }

  Future<void> toggleDevMenu(bool value) async {
    _isDevMenuVisible = value;
    await _storage.write("dev_show_menu", value.toString());
    notifyListeners();
  }

  Future<void> resetOnboarding() async {
    await _storage.delete("has_seen_onboarding");
    // We notify listeners so the UI knows we've triggered a state change
    notifyListeners();
  }
}
