// ไฟล์: lib/screens/subnet_csv_preview_screen.dart
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/api_service.dart';

class SubnetCsvPreviewScreen extends StatefulWidget {
  final List<Map<String, dynamic>> rawRows;
  const SubnetCsvPreviewScreen({super.key, required this.rawRows});

  @override
  State<SubnetCsvPreviewScreen> createState() => _SubnetCsvPreviewScreenState();
}

class _SubnetCsvPreviewScreenState extends State<SubnetCsvPreviewScreen> {
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
    final result = await _api.validateSubnetCsv(widget.rawRows);
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
    if (validRows.isEmpty) { AppSnackbar.warning(context, 'ไม่มี row ที่ valid'); return; }

    setState(() => _importing = true);
    final result = await _api.importSubnetCsv(validRows);
    setState(() => _importing = false);

    if (!mounted) return;
    if (result != null && result['error'] == null) {
      final inserted = result['inserted'] ?? 0;
      final skipped  = result['skipped']  ?? 0;
      final failed   = (result['failed'] as List?)?.length ?? 0;
      AppSnackbar.success(context,
        'Import สำเร็จ — เพิ่ม $inserted IPs, ข้าม $skipped${failed > 0 ? ", ล้มเหลว $failed" : ""}');
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
        title: const Text('Preview — Import Subnet CSV',
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
                OutlinedButton.icon(
                  onPressed: _validate,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Re-validate'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary)),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _validCount == 0 || _importing ? null : _doImport,
                  icon: _importing
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.upload, size: 18),
                  label: Text(_importing
                    ? 'กำลัง Import...'
                    : 'Import $_validCount Subnets'),
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
              Text('กำลังตรวจสอบ subnet...'),
            ]))
        : _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(children: [
      _buildSummary(),
      // Table header
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        color: AppColors.surface,
        child: Row(children: [
          _hdr('DOMAIN',  2),
          _hdr('SUBNET',  2),
          _hdr('PREFIX',  1),
          _hdr('IP COUNT',1),
          _hdr('NETWORK', 2),
          _hdr('STATUS',  2),
          _hdr('ERRORS / WARNINGS', 4),
        ]),
      ),
      Divider(height: 1, color: Colors.grey.shade200),
      Expanded(child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _rows.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (_, i) => _buildRow(_rows[i]),
      )),
    ]);
  }

  Widget _buildSummary() {
    final totalIps = _rows.where((r) => r['valid'] == true)
        .fold(0, (sum, r) => sum + ((r['ip_count'] as int?) ?? 0));
    final warnings = _rows.where((r) =>
        (r['warnings'] as List?)?.isNotEmpty == true).length;

    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(children: [
        _summaryBox('ทั้งหมด',     '${_rows.length}', AppColors.primary),
        const SizedBox(width: 12),
        _summaryBox('Valid ✓',     '$_validCount',    AppColors.success),
        const SizedBox(width: 12),
        _summaryBox('Invalid ✗',  '$_invalidCount',  AppColors.danger),
        const SizedBox(width: 12),
        _summaryBox('IPs ที่จะเพิ่ม', '$totalIps',  AppColors.info),
        if (warnings > 0) ...[
          const SizedBox(width: 12),
          _summaryBox('มีคำเตือน', '$warnings',      AppColors.warning),
        ],
      ]),
    );
  }

  Widget _summaryBox(String label, String value, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.3))),
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      Text(label,  style: TextStyle(fontSize: 11, color: color)),
    ]));

  Widget _buildRow(Map<String, dynamic> row) {
    final isValid   = row['valid'] == true;
    final errors    = List<String>.from(row['errors']   ?? []);
    final warnings  = List<String>.from(row['warnings'] ?? []);
    final resolved  = row['resolved'] as Map? ?? {};

    Color rowBg = Colors.white;
    if (!isValid)              rowBg = AppColors.dangerLight.withOpacity(0.25);
    else if (warnings.isNotEmpty) rowBg = const Color(0xFFFEF9E7);

    return Container(
      color: rowBg,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Domain
        Expanded(flex: 2, child: _cell(row['domain_name']?.toString() ?? '-',
          valid: isValid || resolved.containsKey('domain_id'))),

        // Subnet
        Expanded(flex: 2, child: _cell(row['subnet']?.toString() ?? '-')),

        // Prefix
        Expanded(flex: 1, child: _cell('/${row['prefix'] ?? '-'}')),

        // IP Count
        Expanded(flex: 1, child: _cell(
          isValid ? '${row['ip_count']}' : '-',
          color: AppColors.info)),

        // Network
        Expanded(flex: 2, child: _cell(
          resolved['network']?.toString() ?? '-',
          bold: true)),

        // Status
        Expanded(flex: 2, child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _statusBadge(isValid, warnings.isNotEmpty))),

        // Errors + Warnings
        Expanded(flex: 4, child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ...errors.map((e) => _msgRow(e, AppColors.danger, Icons.error_outline)),
            ...warnings.map((w) => _msgRow(w, AppColors.warning, Icons.warning_amber_outlined)),
          ]),
        )),
      ]),
    );
  }

  Widget _statusBadge(bool valid, bool hasWarning) {
    Color bg, border, fg;
    String label;
    if (!valid) {
      bg = AppColors.dangerLight; border = AppColors.danger.withOpacity(0.4);
      fg = AppColors.danger; label = '✗ Invalid';
    } else if (hasWarning) {
      bg = const Color(0xFFFEF9E7); border = AppColors.warning.withOpacity(0.5);
      fg = AppColors.warning; label = '⚠ Warning';
    } else {
      bg = AppColors.availableBg; border = AppColors.availableBorder;
      fg = AppColors.availableText; label = '✓ Valid';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border)),
      child: Text(label, style: TextStyle(fontSize: 11,
        fontWeight: FontWeight.bold, color: fg),
        textAlign: TextAlign.center));
  }

  Widget _msgRow(String msg, Color color, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 4),
      Expanded(child: Text(msg,
        style: TextStyle(fontSize: 11, color: color))),
    ]));

  Widget _hdr(String label, int flex) => Expanded(
    flex: flex,
    child: Text(label, style: AppTextStyles.tableHeader
      .copyWith(color: Colors.grey.shade600)));

  Widget _cell(String value, {bool bold = false,
      bool valid = true, Color? color}) =>
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(value, style: TextStyle(
        fontSize: 13,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        color: color ?? (valid ? AppColors.textPrimary : AppColors.danger)),
        overflow: TextOverflow.ellipsis));
}