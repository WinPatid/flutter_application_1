// ไฟล์: lib/widgets/dashboard/node_data_table.dart
import 'package:flutter/material.dart';
import '../../core/theme.dart';

class NodeDataTable extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String searchId;
  final String searchName;
  final ValueChanged<String> onSearchIdChanged;
  final ValueChanged<String> onSearchNameChanged;
  final Function(Map<String, dynamic>) onSelect;

  const NodeDataTable({
    super.key,
    required this.data,
    required this.searchId,
    required this.searchName,
    required this.onSearchIdChanged,
    required this.onSearchNameChanged,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = data.where((row) {
      final matchId   = row['id'].toString().contains(searchId);
      final matchName = row['name'].toString().toLowerCase()
          .contains(searchName.toLowerCase());
      return matchId && matchName;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            Expanded(child: TextField(
              onChanged: onSearchIdChanged,
              decoration: AppInputDecoration.search(hint: 'Search ID...'),
            )),
            const SizedBox(width: 16),
            Expanded(child: TextField(
              onChanged: onSearchNameChanged,
              decoration: AppInputDecoration.search(hint: 'Search Name...'),
            )),
          ]),
        ),
        const Divider(height: 1),

        // Table
        Expanded(child: SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.surface),
              columns: const [
                DataColumn(label: Text('Node ID',   style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Node Name', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status',    style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Action',    style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: filtered.map((node) {
                final isAvailable = node['isAvailable'] as bool;
                return DataRow(cells: [
                  DataCell(Text(node['id'],
                    style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(node['name'], overflow: TextOverflow.ellipsis)),
                  DataCell(_statusBadge(isAvailable)),
                  DataCell(_actionButton(isAvailable, node)),
                ]);
              }).toList(),
            ),
          ),
        )),
      ]),
    );
  }

  Widget _statusBadge(bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable ? AppColors.availableBg : AppColors.inUseBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isAvailable ? AppColors.availableBorder : AppColors.inUseBorder)),
      child: Text(isAvailable ? 'Available' : 'In Use',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
          color: isAvailable ? AppColors.availableText : AppColors.inUseText)),
    );
  }

  Widget _actionButton(bool isAvailable, Map<String, dynamic> node) {
    if (!isAvailable) return const SizedBox.shrink();
    return ElevatedButton.icon(
      onPressed: () => onSelect(node),
      icon: const Icon(Icons.touch_app, size: 16),
      label: const Text('เลือก',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 36),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
    );
  }
}