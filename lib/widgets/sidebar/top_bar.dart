// ไฟล์: lib/widgets/sidebar/top_bar.dart
import 'package:flutter/material.dart';
import '../../core/theme.dart';

class TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onAvatarTap;

  static const List<String> _titles = [
    'Dashboard', 'Search & Reserve', 'Topology Map',
    'Bulk Import', 'Domain & IP', 'Models', 'Site Code',
  ];

  static String titleForIndex(int index) =>
    index < _titles.length ? _titles[index] : '';

  const TopBar({super.key, required this.title, required this.onAvatarTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 4, offset: const Offset(0, 2))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.pageTitle),
          InkWell(
            onTap: onAvatarTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft, end: Alignment.bottomRight)),
                  child: const Icon(Icons.person, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Admin User', style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.dark)),
                  Text('Network Engineer',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ]),
                const SizedBox(width: 8),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade400, size: 18),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}