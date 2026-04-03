// ไฟล์: lib/widgets/common/status_badge.dart
import 'package:flutter/material.dart';
import '../../core/theme.dart';

class StatusBadge extends StatelessWidget {
  final bool inUse;
  final String? trueLabel;
  final String? falseLabel;

  const StatusBadge({
    super.key,
    required this.inUse,
    this.trueLabel,
    this.falseLabel,
  });

  @override
  Widget build(BuildContext context) {
    final label = inUse ? (trueLabel ?? 'In Use') : (falseLabel ?? 'Available');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: inUse ? AppColors.inUseBg : AppColors.availableBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: inUse ? AppColors.inUseBorder : AppColors.availableBorder)),
      child: Text(label, style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.bold,
        color: inUse ? AppColors.inUseText : AppColors.availableText)),
    );
  }
}