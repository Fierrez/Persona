import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';
import 'package:persona_app/shared/themes.dart';
import 'package:persona_app/core/theme_provider.dart';
import 'package:persona_app/core/security_provider.dart';
import 'package:persona_app/core/notification_service.dart';
import 'package:persona_app/features/dashboard/dashboard_page.dart';
import 'package:persona_app/features/vault/vault_page.dart';
import 'package:persona_app/features/authenticator/authenticator_page.dart';
import 'package:persona_app/features/planner/planner_page.dart';
import 'package:persona_app/features/profile/profile_page.dart';
import 'package:persona_app/features/onboarding/onboarding_page.dart';
import 'package:persona_app/core/secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  
  final storage = SecureStorageService();
  final hasSeenOnboarding = await storage.read('has_seen_onboarding');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SecurityProvider()),
      ],
      child: PersonaApp(showOnboarding: hasSeenOnboarding != 'true'),
    ),
  );
}

class PersonaApp extends StatelessWidget {
  final bool showOnboarding;
  const PersonaApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final securityProvider = Provider.of<SecurityProvider>(context);

    Widget home;
    if (showOnboarding) {
      home = const OnboardingPage();
    } else if (securityProvider.isAppLockEnabled && !securityProvider.isAuthenticated) {
      home = const LockScreen();
    } else {
      home = const MainNavigationWrapper();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Persona',
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeProvider.themeMode,
      home: home,
    );
  }
}

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const VaultPage(),
    const AuthenticatorPage(),
    const PlannerPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
          return FadeThroughTransition(
            animation: primaryAnimation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.lock_rounded), label: "Vault"),
          BottomNavigationBarItem(icon: Icon(Icons.token_rounded), label: "Auth"),
          BottomNavigationBarItem(icon: Icon(Icons.event_note_rounded), label: "Tasks"),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profile"),
        ],
      ),
    );
  }
}

class LockScreen extends StatelessWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_rounded, size: 80, color: Colors.white),
            const SizedBox(height: 24),
            const Text(
              "Persona is Locked",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () => Provider.of<SecurityProvider>(context, listen: false).authenticate(),
              icon: const Icon(Icons.lock_open_rounded),
              label: const Text("Unlock"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue.shade800,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
