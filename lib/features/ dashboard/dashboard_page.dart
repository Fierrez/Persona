// import 'package:flutter/material.dart';
// import 'dashboard_card.dart';
// import '../planner/planner_page.dart';
// import '../vault/vault_page.dart';
// import '../locker/key_page.dart';
// import '../archive/archive_page.dart';
// import '../settings/settings_page.dart';
//
// class DashboardPage extends StatelessWidget {
//   const DashboardPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final width = MediaQuery.of(context).size.width;
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//
//     int crossAxisCount;
//     if (width > 1200) {
//       crossAxisCount = 4;
//     } else if (width > 800) {
//       crossAxisCount = 2;
//     } else {
//       crossAxisCount = 2;
//     }
//
//     return Scaffold(
//       body: CustomScrollView(
//         slivers: [
//           SliverAppBar(
//             expandedHeight: 200.0,
//             floating: false,
//             pinned: true,
//             actions: [
//               IconButton(
//                 icon: const Icon(Icons.settings_outlined, color: Colors.white),
//                 onPressed: () => Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => const SettingsPage()),
//                 ),
//               ),
//             ],
//             flexibleSpace: FlexibleSpaceBar(
//               title: const Text("Persona", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
//               background: Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                     colors: isDark
//                       ? [const Color(0xFF1E3A8A), const Color(0xFF0F172A)]
//                       : [const Color(0xFF1E40AF), const Color(0xFF3B82F6)],
//                   ),
//                 ),
//                 child: const Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(Icons.shield_outlined, size: 60, color: Colors.white24),
//                       SizedBox(height: 8),
//                       Text(
//                         "Secure Personal Center",
//                         style: TextStyle(color: Colors.white70, fontSize: 14),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           SliverPadding(
//             padding: const EdgeInsets.all(20.0),
//             sliver: SliverGrid.count(
//               crossAxisCount: crossAxisCount,
//               crossAxisSpacing: 16,
//               mainAxisSpacing: 16,
//               children: const [
//                 DashboardCard(
//                   title: 'Planner',
//                   icon: Icons.calendar_today_rounded,
//                   destination: PlannerPage(),
//                 ),
//                 DashboardCard(
//                   title: 'Vault',
//                   icon: Icons.lock_person_rounded,
//                   destination: VaultPage(),
//                 ),
//                 DashboardCard(
//                   title: 'Authenticator',
//                   icon: Icons.token_rounded,
//                   destination: KeyPage(),
//                 ),
//                 DashboardCard(
//                   title: 'Backup',
//                   icon: Icons.cloud_done_rounded,
//                   destination: ArchivePage(),
//                 ),
//               ],
//             ),
//           ),
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
//               child: Text(
//                 "Quick Actions",
//                 style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
//               ),
//             ),
//           ),
//           SliverToBoxAdapter(
//             child: Container(
//               height: 100,
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: ListView(
//                 scrollDirection: Axis.horizontal,
//                 children: [
//                   _QuickAction(
//                     icon: Icons.add_task,
//                     label: "Add Task",
//                     onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PlannerPage())),
//                   ),
//                   _QuickAction(
//                     icon: Icons.vpn_key,
//                     label: "New Pass",
//                     onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VaultPage())),
//                   ),
//                   _QuickAction(
//                     icon: Icons.qr_code_scanner,
//                     label: "Scan 2FA",
//                     onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const KeyPage())),
//                   ),
//                   _QuickAction(
//                     icon: Icons.backup,
//                     label: "Backup",
//                     onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ArchivePage())),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const SliverToBoxAdapter(child: SizedBox(height: 40)),
//         ],
//       ),
//     );
//   }
// }
//
// class _QuickAction extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final VoidCallback onTap;
//
//   const _QuickAction({required this.icon, required this.label, required this.onTap});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 90,
//       margin: const EdgeInsets.only(right: 12),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(16),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircleAvatar(
//               backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
//               child: Icon(icon, color: Theme.of(context).colorScheme.primary),
//             ),
//             const SizedBox(height: 8),
//             Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
//           ],
//         ),
//       ),
//     );
//   }
// }
