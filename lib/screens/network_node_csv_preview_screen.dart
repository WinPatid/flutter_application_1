// ไฟล์: lib/screens/network_node_csv_preview_screen.dart
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/api_service.dart';

class NetworkNodeCsvPreviewScreen extends StatefulWidget {
  final List<Map<String, dynamic>> rawRows;
  const NetworkNodeCsvPreviewScreen({super.key, required this.rawRows});

  @override
  State<NetworkNodeCsvPreviewScreen> createState() =>
      _NetworkNodeCsvPreviewScreenState();
}

class _NetworkNodeCsvPreviewScreenState
    extends State<NetworkNodeCsvPreviewScreen> {
  final _api = ApiService();

  List<Map<String, dynamic>> _rows = [];
  int _validCount   = 0;
  int _invalidCount = 0;
  bool _validating  = true;
  bool _importing   = false;

  @override
  void initState() {
    super.initState();
    _validate();
  }

  Future<void> _validate() async {
    setState(() => _validating = true);
    final result = await _api.validateNetworkNodesCsv(widget.rawRows);
    if (result == null || result['error'] != null) {
      if (mounted) AppSnackbar.error(context, result?['error'] ?? 'Validate ไม่สำเร็จ');
      setState(() => _validating = false);
      return;
    }
    setState(() {
      _rows         = List<Map<String, dynamic>>.from(result['rows']);
      _validCount   = result['valid_count'];
      _invalidCount = result['invalid_count'];
      _validating   = false;
    });
  }

  Future<void> _doImport() async {
    final validRows = _rows.where((r) => r['valid'] == true).toList();
    if (validRows.isEmpty) {
      AppSnackbar.warning(context, 'ไม่มี row ที่ valid');
      return;
    }
    setState(() => _importing = true);
    final result = await _api.bulkImportNetworkNodes(validRows);
    setState(() => _importing = false);

    if (!mounted) return;
    if (result != null && result['error'] == null) {
      final created = result['created'] ?? 0;
      final failed  = (result['failed'] as List?)?.length ?? 0;
      AppSnackbar.success(context, 'Import สำเร็จ $created Nodes${failed > 0 ? " (ล้มเหลว $failed)" : ""}');
      Navigator.pop(context, true);
    } else {
      AppSnackbar.error(context, result?['error'] ?? 'Import ไม่สำเร็จ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Preview — Import Network Nodes',
          style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.dark,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border)),
        actions: [
          if (!_validating)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                // Re-validate
                OutlinedButton.icon(
                  onPressed: _validate,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Re-validate'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary)),
                ),
                const SizedBox(width: 10),
                // Import valid only
                ElevatedButton.icon(
                  onPressed: _validCount == 0 || _importing ? null : _doImport,
                  icon: _importing
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.upload, size: 18),
                  label: Text(_importing
                    ? 'กำลัง Import...'
                    : 'Import $_validCount Nodes'),
                  style: AppButtonStyles.success(),
                ),
              ]),
            ),
        ],
      ),
      body: _validating
        ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('กำลังตรวจสอบข้อมูล...'),
            ]))
        : _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(children: [
      // ── Summary bar ──
      _buildSummary(),

      // ── Table header ──
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        color: AppColors.surface,
        child: Row(children: [
          _hdr('NODE ID',   1),
          _hdr('NODE NAME', 2),
          _hdr('IP',        2),
          _hdr('MODEL',     2),
          _hdr('SITE',      2),
          _hdr('STATUS',    2),
          _hdr('ERRORS',    4),
        ]),
      ),
      Divider(height: 1, color: Colors.grey.shade200),

      // ── Rows ──
      Expanded(child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _rows.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (_, i) => _buildRow(_rows[i]),
      )),
    ]);
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(children: [
        _summaryBox('ทั้งหมด',    '${_rows.length}',  AppColors.primary),
        const SizedBox(width: 12),
        _summaryBox('Valid ✓',    '$_validCount',     AppColors.success),
        const SizedBox(width: 12),
        _summaryBox('Invalid ✗', '$_invalidCount',   AppColors.danger),
        const Spacer(),
        if (_invalidCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.dangerLight,
              borderRadius: BorderRadius.circular(6)),
            child: Row(children: [
              const Icon(Icons.warning_amber_outlined,
                color: AppColors.danger, size: 16),
              const SizedBox(width: 6),
              Text('มี $_invalidCount rows ที่ไม่ valid — จะถูกข้ามไป',
                style: const TextStyle(color: AppColors.danger,
                  fontSize: 12, fontWeight: FontWeight.w500)),
            ]),
          ),
      ]),
    );
  }

  Widget _summaryBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3))),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ]),
    );
  }

  Widget _buildRow(Map<String, dynamic> row) {
    final isValid  = row['valid'] == true;
    final errors   = List<String>.from(row['errors'] ?? []);
    final resolved = row['resolved'] as Map? ?? {};

    return Container(
      color: isValid
        ? Colors.white
        : AppColors.dangerLight.withOpacity(0.3),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Node ID
        Expanded(flex: 1, child: _cell(
          row['node_id']?.toString() ?? '-',
          bold: true, valid: isValid)),
        // Node Name
        Expanded(flex: 2, child: _cell(
          row['node_name']?.toString() ?? '-', valid: isValid)),
        // IP
        Expanded(flex: 2, child: _cell(
          resolved['ip']?.toString() ?? row['ip']?.toString() ?? '-',
          valid: isValid && resolved.containsKey('ip'))),
        // Model
        Expanded(flex: 2, child: _cell(
          resolved['model_name']?.toString() ?? row['model_name']?.toString() ?? '-',
          valid: isValid && resolved.containsKey('model_name'))),
        // Site
        Expanded(flex: 2, child: _cell(
          resolved['site_code']?.toString() ?? row['site_code']?.toString() ?? '-',
          valid: isValid && resolved.containsKey('site_code'))),
        // Status badge
        Expanded(flex: 2, child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isValid ? AppColors.availableBg : AppColors.dangerLight,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isValid ? AppColors.availableBorder : AppColors.danger.withOpacity(0.3))),
            child: Text(
              isValid ? '✓ Valid' : '✗ Invalid',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold,
                color: isValid ? AppColors.availableText : AppColors.danger),
              textAlign: TextAlign.center),
          ),
        )),
        // Errors
        Expanded(flex: 4, child: errors.isEmpty
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: errors.map((e) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline,
                      size: 13, color: AppColors.danger),
                    const SizedBox(width: 4),
                    Expanded(child: Text(e,
                      style: const TextStyle(fontSize: 11,
                        color: AppColors.danger))),
                  ])).toList()),
            )),
      ]),
    );
  }

  Widget _hdr(String label, int flex) => Expanded(
    flex: flex,
    child: Text(label,
      style: AppTextStyles.tableHeader.copyWith(color: Colors.grey.shade600)));

  Widget _cell(String value, {bool bold = false, bool valid = true}) =>
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: valid ? AppColors.textPrimary : AppColors.danger),
        overflow: TextOverflow.ellipsis));
}