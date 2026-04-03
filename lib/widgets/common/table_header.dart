// ไฟล์: lib/widgets/common/table_header_row.dart
import 'package:flutter/material.dart';
import '../../core/theme.dart';

class TableHeaderRow extends StatelessWidget {
  final List<Widget> children;

  const TableHeaderRow({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
      child: Row(children: children),
    );
  }
}

/// Column header cell สำหรับใช้ใน TableHeaderRow
class TableHeaderCell extends StatelessWidget {
  final String label;
  final int flex;
  final TextAlign textAlign;

  const TableHeaderCell(
    this.label, {
    super.key,
    this.flex = 1,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(label,
        textAlign: textAlign,
        style: AppTextStyles.tableHeader.copyWith(color: Colors.grey.shade600)),
    );
  }
}