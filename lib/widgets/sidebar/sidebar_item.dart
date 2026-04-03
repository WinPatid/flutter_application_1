// ไฟล์: lib/widgets/sidebar/sidebar_item.dart
import 'package:flutter/material.dart';
import '../../core/theme.dart';

class SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const SidebarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == index;
    return ListTile(
      leading: Icon(icon,
        color: isSelected ? Colors.blueAccent : Colors.white54, size: 20),
      title: Text(label, style: TextStyle(
        color: isSelected ? AppColors.sidebarActive : AppColors.sidebarText,
        fontSize: 14,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      tileColor: isSelected ? Colors.white.withOpacity(0.08) : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      onTap: () => onTap(index),
    );
  }
}