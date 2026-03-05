import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:persona_app/core/secure_storage.dart';
import '../../main.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  Future<void> _onIntroEnd(BuildContext context) async {
    final storage = SecureStorageService();
    await storage.write('has_seen_onboarding', 'true');
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationWrapper()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(fontSize: 16.0, color: Colors.black54);

    const pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w700, color: Colors.blue),
      bodyTextStyle: bodyStyle,
      bodyPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Colors.white,
      imagePadding: EdgeInsets.zero,
    );

    return IntroductionScreen(
      key: GlobalKey(),
      globalBackgroundColor: Colors.white,
      pages: [
        PageViewModel(
          title: "Your Secure Vault",
          body: "Store your passwords, recovery codes, and sensitive notes with industry-standard AES-256 encryption.",
          image: _buildImage(Icons.lock_person_rounded),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Offline-First Privacy",
          body: "Your data never leaves your device. No cloud, no tracking, just you and your data.",
          image: _buildImage(Icons.cloud_off_rounded),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Secure Backups",
          body: "Always keep an encrypted backup file. If you lose your phone, your backup password is the only way to recover your data.",
          image: _buildImage(Icons.backup_rounded),
          decoration: pageDecoration,
        ),
      ],
      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context),
      showSkipButton: true,
      skip: const Text("Skip", style: TextStyle(fontWeight: FontWeight.w600)),
      next: const Icon(Icons.arrow_forward),
      done: const Text("Get Started", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue)),
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),
      controlsPadding: const EdgeInsets.all(12),
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: Color(0xFFBDBDBD),
        activeSize: Size(22.0, 10.0),
        activeColor: Colors.blue,
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
    );
  }

  Widget _buildImage(IconData icon) {
    return Center(
      child: Icon(icon, size: 120, color: Colors.blue.shade700),
    );
  }
}
