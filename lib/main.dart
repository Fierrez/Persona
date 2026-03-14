import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:persona_app/shared/themes.dart';
import 'package:persona_app/core/theme_provider.dart';
import 'package:persona_app/core/security_provider.dart';
import 'package:persona_app/core/profile_provider.dart';
import 'package:persona_app/core/vault_provider.dart';
import 'package:persona_app/core/planner_provider.dart';
import 'package:persona_app/core/dev_provider.dart';
import 'package:persona_app/core/notification_service.dart';
import 'package:persona_app/core/error_handler.dart';
import 'package:persona_app/features/dashboard/dashboard_page.dart';
import 'package:persona_app/features/vault/vault_page.dart';
import 'package:persona_app/features/authenticator/authenticator_page.dart';
import 'package:persona_app/features/planner/planner_page.dart';
import 'package:persona_app/features/profile/profile_page.dart';
import 'package:persona_app/features/onboarding/onboarding_page.dart';
import 'package:persona_app/core/secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationService.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SecurityProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => VaultProvider()),
        ChangeNotifierProvider(create: (_) => PlannerProvider()),
        ChangeNotifierProvider(create: (_) => DevProvider()),
      ],
      child: const AppLoader(),
    ),
  );
}

class AppLoader extends StatelessWidget {
  const AppLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: SecureStorageService().read('has_seen_onboarding'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Material(
            child: Center(child: CircularProgressIndicator(color: Color(0xFF2D62ED))),
          );
        }
        return PersonaApp(showOnboarding: snapshot.data != 'true');
      },
    );
  }
}

class PersonaApp extends StatefulWidget {
  final bool showOnboarding;
  const PersonaApp({super.key, required this.showOnboarding});

  @override
  State<PersonaApp> createState() => _PersonaAppState();
}

class _PersonaAppState extends State<PersonaApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final securityProvider = Provider.of<SecurityProvider>(context, listen: false);
    if (state == AppLifecycleState.paused) {
      securityProvider.handleAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      securityProvider.handleAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final securityProvider = Provider.of<SecurityProvider>(context);

    Widget home;
    if (widget.showOnboarding) {
      home = const OnboardingPage();
    } else if (securityProvider.isAppLockEnabled && !securityProvider.isAuthenticated) {
      home = const LockScreen();
    } else {
      home = const MainNavigationWrapper();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: ErrorHandler.messengerKey,
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
  int _currentIndex = 2;

  // Use IndexedStack to keep tabs alive and eliminate transition lag
  final List<Widget> _pages = const [
    AuthenticatorPage(),
    VaultPage(),
    DashboardPage(),
    PlannerPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false, // Prevents keyboard from triggering full app relayout
      body: RepaintBoundary(
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        heroTag: "home_fab",
        onPressed: () => setState(() => _currentIndex = 2),
        backgroundColor: _currentIndex == 2 ? const Color(0xFF2D62ED) : Colors.grey.shade300,
        elevation: 4,
        shape: const CircleBorder(),
        child: Icon(
          Icons.home_rounded, 
          color: _currentIndex == 2 ? Colors.white : Colors.grey.shade600,
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: theme.cardTheme.color,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.token_rounded, 0),
            _buildNavItem(Icons.lock_rounded, 1),
            const SizedBox(width: 40),
            _buildNavItem(Icons.calendar_today_rounded, 3),
            _buildNavItem(Icons.person_rounded, 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _currentIndex == index;
    return IconButton(
      icon: Icon(icon),
      color: isSelected ? const Color(0xFF2D62ED) : Colors.grey.shade400,
      onPressed: () => setState(() => _currentIndex = index),
    );
  }
}

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _authenticate());
  }

  Future<void> _authenticate() async {
    await Provider.of<SecurityProvider>(context, listen: false).authenticate();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
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
              onPressed: _authenticate,
              icon: const Icon(Icons.lock_open_rounded),
              label: const Text("Unlock"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: theme.colorScheme.primary,
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
