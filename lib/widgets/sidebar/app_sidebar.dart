// ไฟล์: lib/widgets/sidebar/app_sidebar.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme.dart';
import 'sidebar_item.dart';

class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTap;
  final VoidCallback onLogout;
  final Map<String, dynamic> pageAccess;
  final Map<String, dynamic>? currentUser;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemTap,
    required this.onLogout,
    this.pageAccess = const {},
    this.currentUser,
  });

  static const List<_SidebarEntry> _allEntries = [
    _SidebarEntry(Icons.dashboard_outlined,       'Dashboard',        0),
    _SidebarEntry(Icons.add_circle_outline,       'Search & Reserve', 1),
    _SidebarEntry(Icons.hub_outlined,             'Topology Map',     2),
    _SidebarEntry(Icons.upload_file_outlined,     'Bulk Import',      3),
    _SidebarEntry(Icons.dns_outlined,             'Domain & IP',      4),
    _SidebarEntry(Icons.memory_outlined,          'Models',           5),
    _SidebarEntry(Icons.business_outlined,        'Site Code',        6),
    _SidebarEntry(Icons.device_hub_outlined,      'Network Nodes',    7),
    _SidebarEntry(Icons.manage_accounts_outlined, 'Users',            8),
  ];

  List<_SidebarEntry> get _visibleEntries {
    if (pageAccess.isEmpty) return _allEntries;
    return _allEntries.where((e) {
      if (e.label == 'Users') {
        return currentUser?['role_name'] == 'Manager' ||
               pageAccess['Users'] != null;
      }
      return pageAccess[e.label] != null;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final entries  = _visibleEntries;
    final userName = currentUser?['name']?.toString() ?? '';
    final roleName = currentUser?['role_name']?.toString() ?? '';

    return Container(
      width: 240, color: AppColors.sidebarBg,
      child: Column(children: [

        // Logo
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SvgPicture.asset('assets/images/logo.svg', width: 80,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
            const SizedBox(height: 8),
            Text('Network Management',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, letterSpacing: 0.5)),
          ]),
        ),

        // User info card
        if (userName.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              CircleAvatar(radius: 14,
                backgroundColor: AppColors.primary.withOpacity(0.3),
                child: Text(userName[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(userName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                Text(roleName, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
              ])),
            ]),
          ),

        const Divider(color: Colors.white12, height: 1),
        const SizedBox(height: 8),

        // Menu
        Expanded(child: ListView(
          children: entries.map((e) => SidebarItem(
            icon: e.icon, label: e.label, index: e.index,
            selectedIndex: selectedIndex, onTap: onItemTap)).toList())),

        const Divider(color: Colors.white12, height: 1),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
          title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
          onTap: onLogout),
        const SizedBox(height: 8),
      ]),
    );
  }
}

class _SidebarEntry {
  final IconData icon; final String label; final int index;
  const _SidebarEntry(this.icon, this.label, this.index);
}