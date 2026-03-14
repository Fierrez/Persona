import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:persona_app/core/theme_provider.dart';
import 'package:persona_app/core/security_provider.dart';
import 'package:persona_app/core/profile_provider.dart';
import 'package:persona_app/core/vault_provider.dart';
import 'package:persona_app/core/planner_provider.dart';
import 'package:persona_app/core/secure_storage.dart';
import 'package:persona_app/core/error_handler.dart';
import 'package:persona_app/features/settings/settings_page.dart';
import 'package:persona_app/features/backup/backup_page.dart';
import 'package:persona_app/main.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _pickImage(BuildContext context, ProfileProvider provider) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null) {
        await provider.updateImage(image.path);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error picking image: $e")),
        );
      }
    }
  }

  void _showEditProfileDialog(BuildContext context, ProfileProvider provider) {
    final nameController = TextEditingController(text: provider.name);
    final bioController = TextEditingController(text: provider.bio);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text("Edit Profile", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Display Name",
                prefixIcon: const Icon(Icons.person_outline_rounded),
                filled: true,
                fillColor: Theme.of(context).cardTheme.color,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bioController,
              decoration: InputDecoration(
                labelText: "Bio",
                prefixIcon: const Icon(Icons.info_outline_rounded),
                filled: true,
                fillColor: Theme.of(context).cardTheme.color,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    provider.updateProfile(nameController.text, bioController.text);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                child: const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<ThemeProvider, SecurityProvider, ProfileProvider, VaultProvider>(
      builder: (context, themeProvider, securityProvider, profileProvider, vaultProvider, child) {
        final theme = Theme.of(context);
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                stretch: true,
                backgroundColor: theme.colorScheme.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withBlue(200),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        GestureDetector(
                          onTap: () => _pickImage(context, profileProvider),
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 4),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, spreadRadius: 2)
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.white24,
                                  backgroundImage: profileProvider.imagePath != null
                                      ? FileImage(File(profileProvider.imagePath!))
                                      : null,
                                  child: profileProvider.imagePath == null
                                      ? const Icon(Icons.person_rounded, size: 70, color: Colors.white)
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                                  ),
                                  child: Icon(Icons.camera_alt_rounded, size: 18, color: theme.colorScheme.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          profileProvider.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black26, blurRadius: 8)],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profileProvider.bio,
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader("ACCOUNT SETTINGS"),
                      _buildProfileTile(
                        context,
                        icon: Icons.edit_rounded,
                        title: "Edit Profile",
                        subtitle: "Update your name and bio",
                        color: Colors.orange,
                        onTap: () => _showEditProfileDialog(context, profileProvider),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader("SECURITY & PRIVACY"),
                      _buildProfileTile(
                        context,
                        icon: Icons.fingerprint_rounded,
                        title: "Biometric Lock",
                        subtitle: "Secure app access",
                        color: Colors.blue,
                        trailing: Switch(
                          value: securityProvider.isAppLockEnabled,
                          activeColor: theme.colorScheme.primary,
                          onChanged: (val) async {
                            final success = await securityProvider.requestAuthentication();
                            if (success) {
                              securityProvider.toggleAppLock(val);
                            }
                          },
                        ),
                      ),
                      _buildProfileTile(
                        context,
                        icon: Icons.cloud_upload_rounded,
                        title: "Backup & Export",
                        subtitle: "Keep your data safe offline",
                        color: Colors.green,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const BackupPage()));
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader("PREFERENCES"),
                      _buildProfileTile(
                        context,
                        icon: Icons.dark_mode_rounded,
                        title: "Theme Mode",
                        subtitle: "Current: ${themeProvider.themeMode.toString().split('.').last.toUpperCase()}",
                        color: Colors.purple,
                        onTap: () => _showThemeDialog(context, themeProvider),
                      ),
                      _buildProfileTile(
                        context,
                        icon: Icons.settings_rounded,
                        title: "General Settings",
                        color: Colors.blueGrey,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
                        },
                      ),
                      const SizedBox(height: 32),
                      _buildSectionHeader("DANGER ZONE"),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.red.withOpacity(0.1)),
                        ),
                        child: _buildProfileTile(
                          context,
                          icon: Icons.delete_forever_rounded,
                          title: "Wipe All Data",
                          subtitle: "Permanently delete everything",
                          color: Colors.red,
                          textColor: Colors.red,
                          onTap: () => _showDeleteDataConfirm(context),
                        ),
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12, 
          fontWeight: FontWeight.bold, 
          color: Colors.grey.shade600, 
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildProfileTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: theme.cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: TextStyle(color: textColor ?? theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)) : null,
        trailing: trailing ?? Icon(Icons.chevron_right_rounded, size: 24, color: Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }

  void _showThemeDialog(BuildContext context, ThemeProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text("Select Theme", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildThemeOption(context, "System Default", Icons.brightness_auto_rounded, ThemeMode.system, provider),
            _buildThemeOption(context, "Light Mode", Icons.light_mode_rounded, ThemeMode.light, provider),
            _buildThemeOption(context, "Dark Mode", Icons.dark_mode_rounded, ThemeMode.dark, provider),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, String title, IconData icon, ThemeMode mode, ThemeProvider provider) {
    final isSelected = provider.themeMode == mode;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey),
      title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary) : null,
      onTap: () {
        provider.setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  void _showDeleteDataConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Clear All Data?"),
        content: const Text(
          "This will permanently delete all your tasks, passwords, and 2FA keys. This action cannot be undone.",
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade100, 
              foregroundColor: Colors.red.shade800,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              await SecureStorageService().clearAll();
              Provider.of<VaultProvider>(context, listen: false).reset();
              Provider.of<PlannerProvider>(context, listen: false).reset();
              Provider.of<ProfileProvider>(context, listen: false).reset();
              ErrorHandler.resetKey();
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AppLoader()),
                  (route) => false,
                );
              }
            },
            child: const Text("Wipe Everything"),
          ),
        ],
      ),
    );
  }
}
