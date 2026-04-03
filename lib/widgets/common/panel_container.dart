// ไฟล์: lib/widgets/common/panel_container.dart
import 'package:flutter/material.dart';
import '../../core/theme.dart';

class PanelContainer extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onAdd;
  final String addLabel;
  final Color addColor;

  const PanelContainer({
    super.key,
    required this.title,
    required this.child,
    this.onAdd,
    this.addLabel = 'Add',
    this.addColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(title,
          style: AppTextStyles.sectionTitle, overflow: TextOverflow.ellipsis)),
        if (onAdd != null) ...[
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: addColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 32),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              elevation: 0),
            child: Text(addLabel),
          ),
        ],
      ]),
      const SizedBox(height: 8),
      Expanded(child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: child),
      )),
    ]);
  }
}