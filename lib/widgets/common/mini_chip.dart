// ไฟล์: lib/widgets/common/mini_chip.dart
import 'package:flutter/material.dart';

class MiniChip extends StatelessWidget {
  final String label;
  final Color color;

  const MiniChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(
        fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}