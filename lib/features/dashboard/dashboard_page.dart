import 'package:flutter/material.dart';
import 'package:persona_app/features/dashboard/dashboard_card.dart';
import 'package:persona_app/features/planner/planner_page.dart';
import 'package:persona_app/features/vault/vault_page.dart';
import 'package:persona_app/features/authenticator/authenticator_page.dart';
import 'package:persona_app/features/backup/backup_page.dart';
import 'package:provider/provider.dart';
import 'package:persona_app/core/security_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final securityProvider = Provider.of<SecurityProvider>(context);

    int crossAxisCount = width > 800 ? 4 : 2;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text("Persona", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark 
                      ? [const Color(0xFF1E3A8A), const Color(0xFF0F172A)]
                      : [const Color(0xFF1E40AF), const Color(0xFF3B82F6)],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.shield_outlined, size: 60, color: Colors.white24),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.lock_outline, color: Colors.white),
                onPressed: () => securityProvider.lockImmediate(),
                tooltip: "Panic Lock",
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20.0),
            sliver: SliverGrid.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                DashboardCard(
                  title: 'Vault',
                  icon: Icons.lock_person_rounded,
                  destination: const VaultPage(),
                ),
                DashboardCard(
                  title: 'Authenticator',
                  icon: Icons.token_rounded,
                  destination: const AuthenticatorPage(),
                ),
                DashboardCard(
                  title: 'Planner',
                  icon: Icons.calendar_today_rounded,
                  destination: const PlannerPage(),
                ),
                DashboardCard(
                  title: 'Backup',
                  icon: Icons.cloud_done_rounded,
                  destination: const BackupPage(),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: "Search across Persona...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text("Global Search for '$_searchQuery' coming soon..."),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
