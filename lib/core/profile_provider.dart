import 'package:flutter/material.dart';
import 'package:persona_app/core/secure_storage.dart';

class ProfileProvider with ChangeNotifier {
  final SecureStorageService _storage = SecureStorageService();
  String _name = "User";
  String _bio = "Secure & Private";
  String? _imagePath;

  String get name => _name;
  String get bio => _bio;
  String? get imagePath => _imagePath;

  ProfileProvider() {
    _loadProfile();
  }

  void reset() {
    _name = "User";
    _bio = "Secure & Private";
    _imagePath = null;
    notifyListeners();
  }

  Future<void> _loadProfile() async {
    try {
      final storedName = await _storage.read("profile_name");
      final storedBio = await _storage.read("profile_bio");
      final storedImage = await _storage.read("profile_image");
      
      if (storedName != null && storedName.isNotEmpty) _name = storedName;
      if (storedBio != null && storedBio.isNotEmpty) _bio = storedBio;
      if (storedImage != null && storedImage.isNotEmpty) _imagePath = storedImage;
      
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading profile: \$e");
    }
  }

  Future<void> updateProfile(String newName, String newBio) async {
    _name = newName.isNotEmpty ? newName : "User";
    _bio = newBio.isNotEmpty ? newBio : "Secure & Private";
    await _storage.write("profile_name", _name);
    await _storage.write("profile_bio", _bio);
    notifyListeners();
  }

  Future<void> updateImage(String? path) async {
    _imagePath = path;
    if (path != null) {
      await _storage.write("profile_image", path);
    } else {
      await _storage.delete("profile_image");
    }
    notifyListeners();
  }
}
