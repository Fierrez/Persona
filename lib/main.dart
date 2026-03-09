import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';
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
          return Container(
            color: Colors.white,
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF2D62ED)),
            ),
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

  final List<Widget> _pages = [
    const AuthenticatorPage(),
    const VaultPage(),
    const DashboardPage(),
    const PlannerPage(),
    const ProfilePage(),
  ];

  final List<Color> _navColors = [
    const Color(0xFFFB4B93), // Authenticator
    const Color(0xFF2D62ED), // Vault
    const Color(0xFF2D62ED), // Home
    const Color(0xFF00D27F), // Planner
    const Color(0xFFA066FF), // Profile
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentColor = _navColors[_currentIndex];
    final bool isHomeActive = _currentIndex == 2;
    
    return Scaffold(
      extendBody: true, 
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.translationValues(0, isHomeActive ? -10 : 0, 0),
        child: FloatingActionButton(
          heroTag: "home_fab", // Added unique heroTag
          onPressed: () => setState(() => _currentIndex = 2),
          backgroundColor: isHomeActive ? currentColor : Colors.grey.shade300,
          elevation: isHomeActive ? 12 : 4,
          shape: const CircleBorder(),
          child: Icon(
            Icons.home_rounded, 
            color: isHomeActive ? Colors.white : Colors.grey.shade600, 
            size: 28
          ),
        ),
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: isHomeActive ? Colors.black.withOpacity(0.1) : currentColor.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 10.0,
          color: theme.cardTheme.color ?? Colors.white,
          elevation: 0,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.token_outlined, 
                  activeIcon: Icons.token_rounded, 
                  index: 0, 
                  current: _currentIndex, 
                  activeColor: _navColors[0],
                  onTap: (i) => setState(() => _currentIndex = i)
                ),
                _NavItem(
                  icon: Icons.lock_outline_rounded, 
                  activeIcon: Icons.lock_rounded, 
                  index: 1, 
                  current: _currentIndex, 
                  activeColor: _navColors[1],
                  onTap: (i) => setState(() => _currentIndex = i)
                ),
                const SizedBox(width: 48), // Space for FAB
                _NavItem(
                  icon: Icons.calendar_today_outlined, 
                  activeIcon: Icons.calendar_today_rounded, 
                  index: 3, 
                  current: _currentIndex, 
                  activeColor: _navColors[3],
                  onTap: (i) => setState(() => _currentIndex = i)
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded, 
                  activeIcon: Icons.person_rounded, 
                  index: 4, 
                  current: _currentIndex, 
                  activeColor: _navColors[4],
                  onTap: (i) => setState(() => _currentIndex = i)
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final int index;
  final int current;
  final Color activeColor;
  final Function(int) onTap;

  const _NavItem({
    required this.icon, 
    required this.activeIcon, 
    required this.index, 
    required this.current, 
    required this.activeColor,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == current;
    
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          padding: EdgeInsets.zero, 
          transform: Matrix4.translationValues(0, isSelected ? -12 : 0, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.all(isSelected ? 4 : 0), 
                decoration: BoxDecoration(
                  color: isSelected ? activeColor.withOpacity(0.1) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? activeColor : Colors.grey.shade400,
                  size: isSelected ? 24 : 22, 
                ),
              ),
              if (isSelected)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(top: 2),
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
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
