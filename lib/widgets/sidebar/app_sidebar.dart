// ไฟล์: lib/widgets/sidebar/app_sidebar.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme.dart';
import 'sidebar_item.dart';

class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTap;
  final VoidCallback onLogout;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemTap,
    required this.onLogout,
  });

  static const List<_SidebarEntry> _entries = [
    _SidebarEntry(Icons.dashboard_outlined,   'Dashboard',        0),
    _SidebarEntry(Icons.add_circle_outline,   'Search & Reserve', 1),
    _SidebarEntry(Icons.hub_outlined,         'Topology Map',     2),
    _SidebarEntry(Icons.upload_file_outlined, 'Bulk Import',      3),
    _SidebarEntry(Icons.dns_outlined,         'Domain & IP',      4),
    _SidebarEntry(Icons.memory_outlined,      'Models',           5),
    _SidebarEntry(Icons.business_outlined,    'Site Code',        6),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: AppColors.sidebarBg,
      child: Column(children: [

        // ─── Logo ───
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SvgPicture.asset(
              'assets/images/logo.svg',
              width: 80,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            const SizedBox(height: 8),
            Text('Network Management',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11,
                letterSpacing: 0.5)),
          ]),
        ),

        const Divider(color: Colors.white12, height: 1),
        const SizedBox(height: 8),

        // ─── Menu items ───
        ..._entries.map((e) => SidebarItem(
          icon: e.icon, label: e.label, index: e.index,
          selectedIndex: selectedIndex, onTap: onItemTap)),

        const Spacer(),
        const Divider(color: Colors.white12, height: 1),

        // ─── Logout ───
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
          title: const Text('Logout',
            style: TextStyle(color: Colors.redAccent, fontSize: 14)),
          onTap: onLogout,
        ),
        const SizedBox(height: 8),
      ]),
    );
  }
}

class _SidebarEntry {
  final IconData icon;
  final String label;
  final int index;
  const _SidebarEntry(this.icon, this.label, this.index);
}