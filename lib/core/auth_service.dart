import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'dart:io';

class AuthService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static bool _isAuthenticating = false;

  static Future<bool> canCheckBiometrics() async {
    if (!kIsWeb && Platform.isWindows) return false;
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      developer.log("Error checking biometrics: $e");
      return false;
    }
  }

  static Future<bool> authenticate() async {
    if (!kIsWeb && Platform.isWindows) return true; // Always allow on Windows for now
    if (_isAuthenticating) return false;

    try {
      _isAuthenticating = true;
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to open Persona',
      );
      _isAuthenticating = false;
      return didAuthenticate;
    } catch (e) {
      _isAuthenticating = false;
      developer.log("Authentication exception: $e");
      return false;
    }
  }
}
