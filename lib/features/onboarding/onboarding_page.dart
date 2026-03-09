import 'dart:io';
import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:persona_app/core/secure_storage.dart';
import 'package:persona_app/core/profile_provider.dart';
import 'package:persona_app/main.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _nameController = TextEditingController();
  String? _tempImagePath;
  bool _isProcessing = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _tempImagePath = image.path;
      });
    }
  }

  Future<void> _onIntroEnd(BuildContext context) async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final storage = SecureStorageService();
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      
      final name = _nameController.text.trim();
      await profileProvider.updateProfile(
        name.isNotEmpty ? name : "User", 
        "Secure & Private"
      );
      
      if (_tempImagePath != null) {
        await profileProvider.updateImage(_tempImagePath);
      }
      
      // Mark onboarding as complete
      await storage.write('has_seen_onboarding', 'true');
      
      if (context.mounted) {
        // IMPORTANT: Navigate to MainNavigationWrapper, NOT AppLoader.
        // AppLoader contains a MaterialApp, and pushing it would create 
        // a nested MaterialApp with a duplicate GlobalKey, causing a crash.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigationWrapper()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Onboarding completion error: $e");
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Something went wrong. Please try again.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          IntroductionScreen(
            pages: [
              _buildPageModel(
                title: "Secure Vault",
                body: "Keep your passwords and secrets safe with industry leading encryption.",
                color: const Color(0xFFFB4B93),
                icon: Icons.lock_person_rounded,
              ),
              _buildPageModel(
                title: "Offline Privacy",
                body: "Your data stays on your device. We never track or upload your info.",
                color: const Color(0xFF00D27F),
                icon: Icons.security_rounded,
              ),
              PageViewModel(
                title: "",
                bodyWidget: Column(
                  children: [
                    const SizedBox(height: 80),
                    const Text(
                      "Setup Profile",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Tell us who you are (Optional)",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 40),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 70,
                            backgroundColor: const Color(0xFFA066FF).withOpacity(0.1),
                            backgroundImage: _tempImagePath != null ? FileImage(File(_tempImagePath!)) : null,
                            child: _tempImagePath == null 
                              ? const Icon(Icons.person_add_rounded, size: 50, color: Color(0xFFA066FF)) 
                              : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: Color(0xFFA066FF), shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    TextField(
                      controller: _nameController,
                      autofocus: false,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: "Your Name",
                        hintText: "Enter display name",
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                      ),
                    ),
                  ],
                ),
                decoration: const PageDecoration(
                  contentMargin: EdgeInsets.symmetric(horizontal: 32),
                  titlePadding: EdgeInsets.zero,
                  bodyPadding: EdgeInsets.zero,
                ),
              ),
            ],
            onDone: () => _onIntroEnd(context),
            showSkipButton: !_isProcessing,
            skip: const Text("Skip", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
            next: _buildCustomButton("Next", const Color(0xFFFB4B93)), 
            done: _buildCustomButton("Start", const Color(0xFFA066FF)),
            dotsDecorator: DotsDecorator(
              size: const Size.square(10.0),
              activeSize: const Size(20.0, 10.0),
              activeColor: const Color(0xFF2D62ED),
              color: Colors.black12,
              spacing: const EdgeInsets.symmetric(horizontal: 3.0),
              activeShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
            ),
            controlsPadding: const EdgeInsets.all(16),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF2D62ED)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomButton(String label, Color color) {
    return Container(
      width: 100,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  PageViewModel _buildPageModel({
    required String title,
    required String body,
    required Color color,
    required IconData icon,
  }) {
    return PageViewModel(
      title: "",
      image: Container(
        width: double.infinity,
        child: ClipPath(
          clipper: CustomWaveClipper(),
          child: Container(
            height: 400,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withOpacity(0.7), color],
              ),
            ),
            child: Center(
              child: Icon(icon, size: 100, color: Colors.white.withOpacity(0.9)),
            ),
          ),
        ),
      ),
      bodyWidget: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5),
            ),
          ),
        ],
      ),
      decoration: const PageDecoration(
        contentMargin: EdgeInsets.zero,
        imagePadding: EdgeInsets.zero,
        titlePadding: EdgeInsets.zero,
        bodyPadding: EdgeInsets.zero,
        imageFlex: 0,
        imageAlignment: Alignment.topCenter,
      ),
    );
  }
}

class CustomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 100);

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2.25, size.height - 50);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width - (size.width / 3.25), size.height - 120);
    var secondEndPoint = Offset(size.width, size.height - 20);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
