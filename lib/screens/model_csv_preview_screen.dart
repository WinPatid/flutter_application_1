// ไฟล์: lib/screens/model_csv_preview_screen.dart
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/api_service.dart';

class ModelCsvPreviewScreen extends StatefulWidget {
  final List<Map<String, dynamic>> rows;

  const ModelCsvPreviewScreen({super.key, required this.rows});

  @override
  State<ModelCsvPreviewScreen> createState() => _ModelCsvPreviewScreenState();
}

class _ModelCsvPreviewScreenState extends State<ModelCsvPreviewScreen> {
  final _api = ApiService();

  // grouped: model_name → list of port rows (editable)
  late Map<String, List<_PortRow>> _groups;
  Map<String, bool> _existingModels = {}; // model_name → exists in DB
  bool _checking = true;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _buildGroups();
    _checkExisting();
  }

  void _buildGroups() {
    final map = <String, List<_PortRow>>{};
    for (final r in widget.rows) {
      final name = r['model_name'].toString();
      map.putIfAbsent(name, () => []).add(_PortRow(
        interfaceType: r['interface_type'].toString(),
        speed:        r['speed']?.toString() ?? '',
        cableType:    r['cable_type']?.toString() ?? '',
        count:        int.tryParse(r['count'].toString()) ?? 0,
      ));
    }
    _groups = map;
  }

  Future<void> _checkExisting() async {
    setState(() => _checking = true);
    final models = await _api.fetchModels();
    final existing = {for (final m in models) m['Model_Name'].toString(): true};
    setState(() { _existingModels = existing; _checking = false; });
  }

  List<String> _genPortNamesForRow(String modelName, _PortRow row) {
    final group = _groups[modelName] ?? [];
    int offset = 0;
    for (final r in group) {
      if (r == row) break;
      if (r.interfaceType.toUpperCase() == row.interfaceType.toUpperCase()) {
        offset += r.count;
      }
    }
    return List.generate(row.count, (i) => '${row.interfaceType.toUpperCase()}${offset + i + 1}');
  }

  Future<void> _doImport() async {
    setState(() => _importing = true);
    final rows = <Map<String, dynamic>>[];
    for (final entry in _groups.entries) {
      for (final r in entry.value) {
        if (r.count <= 0) continue;
        rows.add({
          'model_name':     entry.key,
          'interface_type': r.interfaceType,
          'speed':          r.speed,
          'cable_type':     r.cableType,
          'count':          r.count,
        });
      }
    }
    final result = await _api.importModelsCsv(rows);
    setState(() => _importing = false);

    if (!mounted) return;
    if (result != null && result['error'] == null) {
      AppSnackbar.success(context,
        'สร้าง ${result['created_models']} Models, ${result['created_ports']} Ports สำเร็จ');
      Navigator.pop(context, true); // true = refresh
    } else {
      AppSnackbar.error(context, result?['error'] ?? 'Import ไม่สำเร็จ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Preview CSV Import',
          style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.dark,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border)),
        actions: [
          if (!_checking)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: _importing ? null : _doImport,
                icon: _importing
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.upload, size: 18),
                label: Text(_importing ? 'กำลัง Import...' : 'Import ทั้งหมด'),
                style: AppButtonStyles.success(),
              ),
            ),
        ],
      ),
      body: _checking
        ? const Center(child: CircularProgressIndicator())
        : _buildBody(),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Summary bar
        _buildSummaryBar(),
        const SizedBox(height: 20),

        // Each model group
        ..._groups.entries.map((e) => _buildModelCard(e.key, e.value)),
      ],
    );
  }

  Widget _buildSummaryBar() {
    final total     = _groups.length;
    final existing  = _groups.keys.where((k) => _existingModels[k] == true).length;
    final newModels = total - existing;
    final totalPorts = _groups.values
        .expand((rows) => rows)
        .fold(0, (sum, r) => sum + r.count);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border)),
      child: Row(children: [
        _summaryChip('Models ใหม่',   '$newModels', AppColors.success),
        const SizedBox(width: 12),
        _summaryChip('มีอยู่แล้ว',    '$existing',  AppColors.warning),
        const SizedBox(width: 12),
        _summaryChip('Port ทั้งหมด', '$totalPorts', AppColors.primary),
      ]),
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3))),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ]),
    );
  }

  Widget _buildModelCard(String modelName, List<_PortRow> rows) {
    final isExisting = _existingModels[modelName] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isExisting ? AppColors.warning.withOpacity(0.4) : AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Model header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isExisting
              ? AppColors.warning.withOpacity(0.08)
              : AppColors.primarySurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
          child: Row(children: [
            Icon(Icons.memory_outlined,
              size: 18,
              color: isExisting ? AppColors.warning : AppColors.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(modelName,
              style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15,
                color: isExisting ? AppColors.warning : AppColors.primary))),
            if (isExisting)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4)),
                child: const Text('มีอยู่แล้ว — จะ add port เพิ่ม',
                  style: TextStyle(fontSize: 11, color: AppColors.warning,
                    fontWeight: FontWeight.bold))),
          ]),
        ),

        // Port rows
        ...rows.asMap().entries.map((entry) {
          final idx = entry.key;
          final row = entry.value;
          return _buildPortRow(modelName, idx, row);
        }),

        // Add port type button
        TextButton.icon(
          onPressed: () => _addPortRow(modelName),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('เพิ่ม Port Type'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
        ),
      ]),
    );
  }

  Widget _buildPortRow(String modelName, int idx, _PortRow row) {
    final portNames = _genPortNamesForRow(modelName, row);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // Interface Type dropdown
          SizedBox(width: 110, child: _dropdownField(
            label: 'Type',
            value: row.interfaceType,
            items: _interfaceTypes,
            onChanged: (v) => setState(() => row.interfaceType = v ?? row.interfaceType),
          )),
          const SizedBox(width: 8),
          // Speed dropdown
          SizedBox(width: 100, child: _dropdownField(
            label: 'Speed',
            value: row.speed,
            items: _speeds,
            onChanged: (v) => setState(() => row.speed = v ?? row.speed),
          )),
          const SizedBox(width: 8),
          // Cable dropdown
          SizedBox(width: 110, child: _dropdownField(
            label: 'Cable',
            value: row.cableType,
            items: _cableTypes,
            onChanged: (v) => setState(() => row.cableType = v ?? row.cableType),
          )),
          const SizedBox(width: 8),
          // Count text field
          SizedBox(width: 70, child: _editField(
            value: row.count.toString(),
            label: 'Count',
            isNumber: true,
            onChanged: (v) => setState(() => row.count = int.tryParse(v) ?? 0),
          )),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            color: Colors.red.shade300,
            onPressed: () => setState(() => _groups[modelName]!.removeAt(idx)),
          ),
        ]),
        const SizedBox(height: 6),
        // Port preview
        if (row.count > 0)
          Wrap(spacing: 4, runSpacing: 4, children: [
            Text('Ports: ', style: AppTextStyles.bodySmall),
            ...portNames.take(8).map((p) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.info.withOpacity(0.3))),
              child: Text(p, style: const TextStyle(
                fontSize: 11, color: AppColors.info, fontWeight: FontWeight.bold)),
            )),
            if (portNames.length > 8)
              Text('... +${portNames.length - 8} more',
                style: AppTextStyles.bodySmall),
          ]),
      ]),
    );
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final safeValue = items.contains(value) ? value : null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.label.copyWith(fontSize: 10)),
      const SizedBox(height: 4),
      DropdownButtonFormField<String>(
        value: safeValue,
        isDense: true,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          filled: true, fillColor: Colors.white,
        ),
        items: items.map((v) => DropdownMenuItem(
          value: v, child: Text(v, style: const TextStyle(fontSize: 12)))).toList(),
        onChanged: onChanged,
      ),
    ]);
  }

  Widget _editField({
    required String value,
    required String label,
    required ValueChanged<String> onChanged,
    bool isNumber = false,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.label.copyWith(fontSize: 10)),
      const SizedBox(height: 4),
      TextFormField(
        initialValue: value,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(fontSize: 13),
        onChanged: onChanged,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          filled: true, fillColor: Colors.white,
        ),
      ),
    ]);
  }

  void _addPortRow(String modelName) {
    setState(() {
      _groups[modelName]!.add(_PortRow(
        interfaceType: 'GE',
        speed:         '1G',
        cableType:     'SFP',
        count:         1,
      ));
    });
  }
}

// ─── Dropdown options ───
const _interfaceTypes = ['GE', 'FE', 'XGE', '40GE', '100GE'];
const _speeds         = ['100M', '1G', '10G', '40G', '100G'];
const _cableTypes     = ['UTP', 'SFP', 'SFP+', 'QSFP+', 'QSFP28'];

class _PortRow {
  String interfaceType;
  String speed;
  String cableType;
  int    count;

  _PortRow({
    required this.interfaceType,
    required this.speed,
    required this.cableType,
    required this.count,
  });
}