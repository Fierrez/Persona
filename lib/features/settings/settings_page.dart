import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme_provider.dart';
import '../../core/security_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final securityProvider = Provider.of<SecurityProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Appearance", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          ListTile(
            title: const Text("Theme Mode"),
            subtitle: Text(_getThemeName(themeProvider.themeMode)),
            leading: const Icon(Icons.palette_outlined),
            onTap: () => _showThemeDialog(context, themeProvider),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Security", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          SwitchListTile(
            title: const Text("App Lock"),
            subtitle: const Text("Require screen lock to open app"),
            secondary: const Icon(Icons.security_rounded),
            value: securityProvider.isAppLockEnabled,
            onChanged: (bool value) async {
              final success = await securityProvider.requestAuthentication();
              if (success) {
                await securityProvider.toggleAppLock(value);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Authentication required to change this setting")),
                  );
                }
              }
            },
          ),
          SwitchListTile(
            title: const Text("Auto-lock Vault"),
            subtitle: const Text("Lock app when moved to background"),
            secondary: const Icon(Icons.lock_clock_outlined),
            value: securityProvider.isAutoLockEnabled,
            onChanged: (bool value) => securityProvider.toggleAutoLock(value),
          ),
          ListTile(
            title: const Text("Clear Clipboard"),
            subtitle: Text(_getClipboardDurationName(securityProvider.clearClipboardSeconds)),
            leading: const Icon(Icons.timer_outlined),
            onTap: () => _showClipboardDurationDialog(context, securityProvider),
          ),
          SwitchListTile(
            title: const Text("Block Screenshots"),
            subtitle: const Text("Prevent screenshots and hide preview"),
            secondary: const Icon(Icons.screenshot_rounded),
            value: securityProvider.isBlockScreenshotsEnabled,
            onChanged: (bool value) {
              securityProvider.toggleBlockScreenshots(value);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Screenshot protection updated")),
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("About", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          const ListTile(
            title: Text("Version"),
            subtitle: Text("1.0.0"),
            leading: Icon(Icons.info_outline),
          ),
        ],
      ),
    );
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return "System Default";
      case ThemeMode.light: return "Light Mode";
      case ThemeMode.dark: return "Dark Mode";
    }
  }

  String _getClipboardDurationName(int seconds) {
    if (seconds == 30) return "30 seconds";
    if (seconds == 60) return "1 minute";
    if (seconds == 300) return "5 minutes";
    if (seconds == 600) return "10 minutes";
    if (seconds == 900) return "15 minutes";
    if (seconds == 1800) return "30 minutes";
    return "$seconds seconds";
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

  void _showClipboardDurationDialog(BuildContext context, SecurityProvider provider) {
    final options = {
      30: "30 seconds",
      60: "1 minute",
      300: "5 minutes",
      600: "10 minutes",
      900: "15 minutes",
      1800: "30 minutes",
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear Clipboard After"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.entries.map((e) => RadioListTile<int>(
            title: Text(e.value),
            value: e.key,
            groupValue: provider.clearClipboardSeconds,
            onChanged: (val) {
              if (val != null) provider.setClearClipboardSeconds(val);
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }
}
