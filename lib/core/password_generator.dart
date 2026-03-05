import 'dart:math';

class PasswordGenerator {
  static const String upperCase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String lowerCase = 'abcdefghijklmnopqrstuvwxyz';
  static const String numbers = '0123456789';
  static const String symbols = '!@#\$%^&*()-_=+[]{}|;:,.<>?';

  static String generate({
    int length = 16,
    bool useUppercase = true,
    bool useNumbers = true,
    bool useSymbols = true,
  }) {
    String charset = lowerCase;
    if (useUppercase) charset += upperCase;
    if (useNumbers) charset += numbers;
    if (useSymbols) charset += symbols;

    final Random random = Random.secure();
    return List.generate(length, (index) => charset[random.nextInt(charset.length)]).join();
  }

  static double checkStrength(String password) {
    if (password.isEmpty) return 0.0;
    double strength = 0;
    if (password.length >= 8) strength += 0.2;
    if (password.length >= 12) strength += 0.2;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.2;
    if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) strength += 0.2;
    return strength;
  }
}
