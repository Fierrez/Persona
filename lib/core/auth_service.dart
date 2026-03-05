import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;

class AuthService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static bool _isAuthenticating = false;

  static Future<bool> canCheckBiometrics() async {
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
    if (_isAuthenticating) return false;

    try {
      _isAuthenticating = true;

      // We use AuthenticationOptions if supported, otherwise fallback
      // catching ALL exceptions to prevent crashes on cancel/click-outside
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to open Persona',
        // options: const AuthenticationOptions(
        //   stickyAuth: true,
        //   biometricOnly: false,
        //   useErrorDialogs: true,
        // ),
      );

      _isAuthenticating = false;
      return didAuthenticate;
    } catch (e) {
      _isAuthenticating = false;
      developer.log("Authentication exception: $e");
      // This catches LocalAuthException, PlatformException, etc.
      // Returning false instead of crashing.
      return false;
    }
  }
}
