import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:persona_app/core/security_provider.dart';
import 'package:persona_app/core/profile_provider.dart';
import 'package:persona_app/core/vault_provider.dart';
import 'package:persona_app/core/planner_provider.dart';
import 'package:persona_app/core/password_generator.dart';
import 'package:persona_app/features/planner/planner_page.dart';
import 'package:persona_app/features/vault/vault_page.dart';
import 'package:persona_app/features/backup/backup_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning";
    if (hour < 17) return "Good afternoon";
    return "Good evening";
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<ProfileProvider, SecurityProvider, VaultProvider, PlannerProvider>(
      builder: (context, profile, security, vault, planner, _) {
        final upcomingTasks = planner.getUpcomingTasks(limit: 2);
        final weakPasswords = vault.credentials.where((c) => PasswordGenerator.checkStrength(c.password) < 0.4).length;
        
        // Ensure name isn't null and handle empty name
        final displayName = profile.name.trim().isNotEmpty ? profile.name.split(' ')[0] : "User";

        return Scaffold(
          backgroundColor: const Color(0xFFF3F6FF),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${_getGreeting()}, $displayName",
                                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                security.isPrivacyModeEnabled ? "Privacy Mode Active" : "Your security overview",
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => security.togglePrivacyMode(!security.isPrivacyModeEnabled),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: security.isPrivacyModeEnabled ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              security.isPrivacyModeEnabled ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: security.isPrivacyModeEnabled ? Colors.blue : Colors.grey,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- Status Cards ---
                  SizedBox(
                    height: 190,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _StatusCard(
                          title: "Vault Security",
                          count: "${vault.credentials.length} Items",
                          subtitle: weakPasswords > 0 ? "$weakPasswords weak passwords" : "All passwords strong",
                          color: weakPasswords > 0 ? const Color(0xFFFB4B93) : const Color(0xFF2D62ED),
                          icon: Icons.shield_rounded,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VaultPage())),
                        ),
                        _StatusCard(
                          title: "Active Reminders",
                          count: "${planner.tasks.where((t) => !t.isCompleted).length} Tasks",
                          subtitle: upcomingTasks.isNotEmpty ? "Next: ${upcomingTasks[0].title}" : "No pending tasks",
                          color: const Color(0xFF00D27F),
                          icon: Icons.notifications_active_rounded,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlannerPage())),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- Upcoming Tasks Section ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Upcoming Schedule",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlannerPage())),
                              child: const Text("View All"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (upcomingTasks.isEmpty)
                          _EmptyState(icon: Icons.check_circle_outline_rounded, message: "You're all caught up!")
                        else
                          ...upcomingTasks.map((task) => _TaskItem(
                            title: security.isPrivacyModeEnabled ? "••••••••" : task.title,
                            time: task.dueDate != null ? "${task.dueDate!.hour}:${task.dueDate!.minute.toString().padLeft(2, '0')}" : "No time",
                            dotColor: const Color(0xFF00D27F),
                            icon: Icons.calendar_today_rounded,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlannerPage())),
                          )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String count;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _StatusCard({required this.title, required this.count, required this.subtitle, required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const Spacer(),
            Text(count, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final String title;
  final String time;
  final Color dotColor;
  final IconData icon;
  final VoidCallback onTap;

  const _TaskItem({required this.title, required this.time, required this.dotColor, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF3F6FF), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: const Color(0xFF2D62ED), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                  const SizedBox(height: 2),
                  Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
            Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
        ],
      ),
    );
  }
}
