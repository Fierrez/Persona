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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Profile"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Display Name",
                hintText: "Enter your name",
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bioController,
              decoration: const InputDecoration(
                labelText: "Bio",
                hintText: "A short bio about you",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                provider.updateProfile(nameController.text, bioController.text);
                Navigator.pop(context);
              }
            },
            child: const Text("Save Changes"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<ThemeProvider, SecurityProvider, ProfileProvider, VaultProvider>(
      builder: (context, themeProvider, securityProvider, profileProvider, vaultProvider, child) {
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                stretch: true,
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
                                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 55,
                                  backgroundColor: Colors.white24,
                                  backgroundImage: profileProvider.imagePath != null
                                      ? FileImage(File(profileProvider.imagePath!))
                                      : null,
                                  child: profileProvider.imagePath == null
                                      ? const Icon(Icons.person, size: 65, color: Colors.white)
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade700,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
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
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                          ),
                        ),
                        Text(
                          profileProvider.bio,
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader("ACCOUNT"),
                      _buildProfileTile(
                        icon: Icons.edit_rounded,
                        title: "Edit Name & Bio",
                        subtitle: "Customize your persona's identity",
                        onTap: () => _showEditProfileDialog(context, profileProvider),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader("SECURITY"),
                      _buildProfileTile(
                        icon: Icons.security_rounded,
                        title: "App Lock",
                        subtitle: "Manage device authentication",
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
                        icon: Icons.backup_rounded,
                        title: "Backup & Export",
                        subtitle: "Secure your data offline",
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const BackupPage()));
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader("PREFERENCES"),
                      _buildProfileTile(
                        icon: Icons.palette_outlined,
                        title: "Theme Mode",
                        subtitle: "Current: ${themeProvider.themeMode.toString().split('.').last}",
                        onTap: () => _showThemeDialog(context, themeProvider),
                      ),
                      _buildProfileTile(
                        icon: Icons.settings_outlined,
                        title: "Advanced Settings",
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader("DANGER ZONE"),
                      _buildProfileTile(
                        icon: Icons.delete_forever_rounded,
                        title: "Wipe All App Data",
                        textColor: Colors.red,
                        onTap: () => _showDeleteDataConfirm(context),
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
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
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
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: textColor ?? Colors.blue),
        title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await SecureStorageService().clearAll();
              
              // Reset all providers
              Provider.of<VaultProvider>(context, listen: false).reset();
              Provider.of<PlannerProvider>(context, listen: false).reset();
              Provider.of<ProfileProvider>(context, listen: false).reset();

              // Reset the GlobalKey for ScaffoldMessenger
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
