import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme_provider.dart';
import '../../core/security_provider.dart';
import '../settings/settings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final securityProvider = Provider.of<SecurityProvider>(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Persona User",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Secure & Private",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Account Security"),
                  _buildProfileTile(
                    icon: Icons.security,
                    title: "App Lock",
                    trailing: Switch(
                      value: securityProvider.isAppLockEnabled,
                      onChanged: (val) async {
                        final success = await securityProvider.requestAuthentication();
                        if (success) {
                          securityProvider.toggleAppLock(val);
                        }
                      },
                    ),
                  ),
                  _buildProfileTile(
                    icon: Icons.fingerprint,
                    title: "Biometric Settings",
                    onTap: () {},
                  ),
                  const SizedBox(height: 20),
                  _buildSectionHeader("App Settings"),
                  _buildProfileTile(
                    icon: Icons.palette,
                    title: "Theme Mode",
                    subtitle: themeProvider.themeMode.toString().split('.').last,
                    onTap: () => _showThemeDialog(context, themeProvider),
                  ),
                  _buildProfileTile(
                    icon: Icons.settings,
                    title: "Advanced Settings",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildSectionHeader("Data Management"),
                  _buildProfileTile(
                    icon: Icons.backup,
                    title: "Backup & Restore",
                    onTap: () {},
                  ),
                  _buildProfileTile(
                    icon: Icons.delete_forever,
                    title: "Clear All Data",
                    textColor: Colors.red,
                    onTap: () => _showDeleteDataConfirm(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: textColor ?? Colors.blue),
        title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }

  void _showThemeDialog(BuildContext context, ThemeProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Theme"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text("System Default"),
              value: ThemeMode.system,
              groupValue: provider.themeMode,
              onChanged: (val) {
                if (val != null) provider.setThemeMode(val);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text("Light Mode"),
              value: ThemeMode.light,
              groupValue: provider.themeMode,
              onChanged: (val) {
                if (val != null) provider.setThemeMode(val);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text("Dark Mode"),
              value: ThemeMode.dark,
              groupValue: provider.themeMode,
              onChanged: (val) {
                if (val != null) provider.setThemeMode(val);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDataConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear All Data?"),
        content: const Text("This will permanently delete all your tasks, passwords, and 2FA keys. This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              // Implementation for clearing all data
              Navigator.pop(context);
            },
            child: const Text("Clear Everything"),
          ),
        ],
      ),
    );
  }
}
