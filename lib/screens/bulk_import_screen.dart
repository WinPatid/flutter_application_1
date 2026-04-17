// ไฟล์: lib/screens/bulk_import_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../services/api_service.dart';
import '../core/theme.dart';

class BulkImportScreen extends StatefulWidget {
  final bool canEdit;
  const BulkImportScreen({super.key, this.canEdit = true});
  @override
  State<BulkImportScreen> createState() => _BulkImportScreenState();
}

class _BulkImportScreenState extends State<BulkImportScreen> {
  final _api = ApiService();

  static const List<String> _requiredCols = [
    'node_ac_id','domain','ip_access','model','port_access',
    'site_code','node_nw_id','ip_network','port_network',
  ];
  static const List<String> _allCols = [
    'node_ac_id','area_group','domain','ip_access','model','port_access',
    'site_code','node_nw_id','ip_network','port_network','cid','status',
  ];

  // ── State ──
  List<Map<String, dynamic>> _rawRows    = [];   // parsed CSV rows
  List<Map<String, dynamic>> _validated  = [];   // after validate API
  List<Map<String, dynamic>> _resultRows = [];   // after import
  bool   _isParsing    = false;
  bool   _isValidating = false;
  bool   _isImporting  = false;
  bool   _isDone       = false;
  String? _fileName;

  // ── Stats ──
  int get _totalRows   => _rawRows.length;
  int get _passCount   => _validated.where((r) => r['_status'] == 'pass').length;
  int get _dupCount    => _validated.where((r) => r['_status'] == 'dup').length;
  int get _failCount   => _validated.where((r) => r['_status'] == 'fail').length;
  int get _successCount => _resultRows.where((r) => r['success'] == true).length;
  int get _importFail  => _resultRows.where((r) => r['success'] == false).length;

  // ════════════════════════════════════════════
  //  STEP 1: PICK FILE
  // ════════════════════════════════════════════
  Future<void> _pickFile() async {
    setState(() { _isParsing = true; _rawRows = []; _validated = []; _isDone = false; });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['csv'], withData: true);
      if (result == null || result.files.isEmpty) {
        setState(() => _isParsing = false); return;
      }
      final file = result.files.first;
      _fileName = file.name;
      final content = utf8.decode(file.bytes!);
      final rows = const CsvToListConverter(eol: '\n').convert(content);
      if (rows.isEmpty) { _showSnack('ไฟล์ว่างเปล่า', Colors.orange); setState(() => _isParsing = false); return; }

      final headers = rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
      final missing = _requiredCols.where((c) => !headers.contains(c)).toList();
      if (missing.isNotEmpty) {
        _showSnack('ขาด column: ${missing.join(', ')}', Colors.red);
        setState(() => _isParsing = false); return;
      }

      final parsed = <Map<String, dynamic>>[];
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.every((e) => e.toString().trim().isEmpty)) continue;
        final map = <String, dynamic>{'row': i};
        for (var j = 0; j < headers.length && j < row.length; j++) {
          map[headers[j]] = row[j].toString().trim();
        }
        parsed.add(map);
      }
      setState(() { _rawRows = parsed; _isParsing = false; });
      // validate ทันทีหลังอ่านไฟล์
      await _validateRows();
    } catch (e) {
      _showSnack('Parse error: $e', Colors.red);
      setState(() => _isParsing = false);
    }
  }

  // ════════════════════════════════════════════
  //  STEP 2: VALIDATE
  // ════════════════════════════════════════════
  Future<void> _validateRows() async {
    setState(() => _isValidating = true);
    try {
      // เช็คซ้ำภายใน CSV เอง
      final seenIds = <String>{};
      final dupIds  = <String>{};
      for (final r in _rawRows) {
        final key = '${r['node_ac_id']}_${r['ip_access']}';
        if (seenIds.contains(key)) dupIds.add(key);
        else seenIds.add(key);
      }

      // validate กับ DB
      final payload = _rawRows.map((r) => {
        'row':          r['row'],
        'node_ac_id':   int.tryParse(r['node_ac_id'] ?? '') ?? 0,
        'area_group':   r['area_group'] ?? '',
        'domain':       r['domain'] ?? '',
        'ip_access':    r['ip_access'] ?? '',
        'model':        r['model'] ?? '',
        'port_access':  r['port_access'] ?? '',
        'site_code':    r['site_code'] ?? '',
        'node_nw_id':   int.tryParse(r['node_nw_id'] ?? '') ?? 0,
        'ip_network':   r['ip_network'] ?? '',
        'port_network': r['port_network'] ?? '',
        'cid':          r['cid']?.toString().isNotEmpty == true ? r['cid'] : null,
        'status':       r['status']?.toString().isNotEmpty == true ? r['status'] : 'planned',
      }).toList();

      // ยิง validate endpoint
      final res = await _api.validateBulkImport(payload);

      // รวม result
      final validated = <Map<String, dynamic>>[];
      for (var i = 0; i < _rawRows.length; i++) {
        final raw    = _rawRows[i];
        final key    = '${raw['node_ac_id']}_${raw['ip_access']}';
        final isDup  = dupIds.contains(key) && validated.any((v) =>
          '${v['node_ac_id']}_${v['ip_access']}' == key);
        final apiRow = res != null && i < res.length ? res[i] : null;
        final valid  = apiRow?['valid'] == true;
        final errors = List<String>.from(apiRow?['errors'] ?? []);

        validated.add({
          ...raw,
          '_status': isDup ? 'dup' : (valid ? 'pass' : 'fail'),
          '_errors': isDup ? ['ซ้ำกับ row ก่อนหน้าใน CSV'] : errors,
        });
      }

      setState(() { _validated = validated; _isValidating = false; });
    } catch (e) {
      _showSnack('Validate error: $e', Colors.red);
      setState(() => _isValidating = false);
    }
  }

  // ════════════════════════════════════════════
  //  STEP 3: IMPORT (เฉพาะ pass)
  // ════════════════════════════════════════════
  Future<void> _confirmImport() async {
    final passRows = _validated.where((r) => r['_status'] == 'pass').toList();
    if (passRows.isEmpty) { _showSnack('ไม่มี row ที่ผ่าน validate', Colors.orange); return; }

    setState(() => _isImporting = true);
    try {
      final payload = passRows.map((r) => {
        'row':          r['row'],
        'node_ac_id':   int.tryParse(r['node_ac_id'] ?? '') ?? 0,
        'area_group':   r['area_group'] ?? '',
        'domain':       r['domain'] ?? '',
        'ip_access':    r['ip_access'] ?? '',
        'model':        r['model'] ?? '',
        'port_access':  r['port_access'] ?? '',
        'site_code':    r['site_code'] ?? '',
        'node_nw_id':   int.tryParse(r['node_nw_id'] ?? '') ?? 0,
        'ip_network':   r['ip_network'] ?? '',
        'port_network': r['port_network'] ?? '',
        'cid':          r['cid']?.toString().isNotEmpty == true ? r['cid'] : null,
        'status':       r['status']?.toString().isNotEmpty == true ? r['status'] : 'planned',
      }).toList();

      final result = await _api.bulkImport(payload);
      setState(() {
        _resultRows  = List<Map<String, dynamic>>.from(result['results'] ?? []);
        _isImporting = false;
        _isDone      = true;
      });
    } catch (e) {
      _showSnack('Import error: $e', Colors.red);
      setState(() => _isImporting = false);
    }
  }

  void _reset() => setState(() {
    _rawRows = []; _validated = []; _resultRows = [];
    _isDone = false; _fileName = null;
  });

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    AppSnackbar.show(context, msg, color: color);
  }

  // ════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        _buildUploadZone(),
        const SizedBox(height: 24),

        // Column guide
        if (_rawRows.isEmpty && !_isDone) _buildColumnGuide(),

        // Validate summary + table
        if (_validated.isNotEmpty && !_isDone) ...[
          _buildValidateSummary(),
          const SizedBox(height: 16),
          _buildValidateTable(),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            OutlinedButton(onPressed: _reset, child: const Text('Cancel')),
            const SizedBox(width: 12),
            if (widget.canEdit)
            ElevatedButton.icon(
              onPressed: (_isImporting || _passCount == 0) ? null : _confirmImport,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
              icon: _isImporting
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.upload),
              label: Text(_isImporting
                ? 'กำลัง Import...'
                : 'Import $_passCount rows ที่ผ่าน',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
          ]),
        ],

        // Result
        if (_isDone) ...[
          _buildResultSummary(),
          const SizedBox(height: 16),
          _buildResultTable(),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _reset,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
            icon: const Icon(Icons.refresh),
            label: const Text('Import ใหม่', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ]),
    );
  }

  // ════════════════════════════════════════════
  //  WIDGETS
  // ════════════════════════════════════════════

  Widget _buildUploadZone() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 2)),
      child: Column(children: [
        Icon(Icons.upload_file_outlined, size: 52,
          color: _fileName != null ? AppColors.primary : Colors.grey.shade400),
        const SizedBox(height: 12),
        Text(_fileName != null ? _fileName! : 'อัพโหลดไฟล์ Bulk Import CSV',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
            color: _fileName != null ? AppColors.primary : AppColors.dark)),
        const SizedBox(height: 6),
        Text('รองรับเฉพาะ .csv', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: (_isParsing || _isValidating) ? null : _pickFile,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12)),
          icon: (_isParsing || _isValidating)
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.folder_open),
          label: Text(_isParsing ? 'กำลังอ่าน...' : _isValidating ? 'กำลัง Validate...' : 'เลือกไฟล์',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
      ]),
    );
  }

  Widget _buildColumnGuide() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 16),
          const SizedBox(width: 8),
          Text('Columns ที่ต้องมีใน CSV',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: _allCols.map((col) {
          final req = _requiredCols.contains(col);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: req ? Colors.blue.shade100 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: req ? Colors.blue.shade300 : Colors.grey.shade300)),
            child: Text(col, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
              color: req ? Colors.blue.shade800 : Colors.grey.shade600)));
        }).toList()),
        const SizedBox(height: 8),
        Text('สีน้ำเงิน = required, สีเทา = optional',
          style: TextStyle(fontSize: 11, color: Colors.blue.shade600)),
      ]),
    );
  }

  // ── Validate Summary Cards ──
  Widget _buildValidateSummary() {
    return Row(children: [
      _summaryCard('Total',   '$_totalRows', AppColors.primary,  Icons.list_alt_outlined),
      const SizedBox(width: 12),
      _summaryCard('ผ่าน ✓',  '$_passCount', AppColors.success,  Icons.check_circle_outline),
      const SizedBox(width: 12),
      _summaryCard('ซ้ำ ⚠',   '$_dupCount',  Colors.orange,     Icons.content_copy_outlined),
      const SizedBox(width: 12),
      _summaryCard('ไม่ผ่าน ✗','$_failCount', Colors.red,        Icons.cancel_outlined),
    ]);
  }

  Widget _summaryCard(String label, String value, Color color, IconData icon) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25))),
      child: Row(children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
        ]),
      ]),
    ));
  }

  // ── Validate Table ──
  Widget _buildValidateTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        // header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border(bottom: BorderSide(color: AppColors.border))),
          child: Row(children: [
            const SizedBox(width: 44, child: Text('#',    style: _hdStyle)),
            const SizedBox(width: 90, child: Text('STATUS', style: _hdStyle)),
            const SizedBox(width: 80, child: Text('NODE ID', style: _hdStyle)),
            const SizedBox(width: 120, child: Text('IP ACCESS', style: _hdStyle)),
            const SizedBox(width: 120, child: Text('IP NETWORK', style: _hdStyle)),
            const SizedBox(width: 80, child: Text('SITE', style: _hdStyle)),
            const Expanded(child: Text('REMARK', style: _hdStyle)),
          ]),
        ),
        ..._validated.map((r) {
          final status = r['_status'] as String;
          final errors = r['_errors'] as List<String>;
          Color bg, fg, borderC;
          String badge;
          IconData badgeIcon;
          switch (status) {
            case 'pass':
              bg = AppColors.availableBg; fg = AppColors.availableText;
              borderC = AppColors.availableBorder; badge = 'ผ่าน'; badgeIcon = Icons.check_circle;
              break;
            case 'dup':
              bg = Colors.orange.shade50; fg = Colors.orange.shade800;
              borderC = Colors.orange.shade200; badge = 'ซ้ำ'; badgeIcon = Icons.content_copy;
              break;
            default:
              bg = Colors.red.shade50; fg = Colors.red.shade800;
              borderC = Colors.red.shade200; badge = 'ไม่ผ่าน'; badgeIcon = Icons.cancel;
          }
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: bg.withOpacity(0.4),
              border: Border(
                top: BorderSide(color: AppColors.border),
                left: BorderSide(color: fg, width: 3))),
            child: Row(children: [
              SizedBox(width: 44,
                child: Text('${r['row']}', style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade600))),
              SizedBox(width: 90, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderC)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(badgeIcon, size: 12, color: fg),
                  const SizedBox(width: 4),
                  Text(badge, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
                ]))),
              SizedBox(width: 80, child: Text(r['node_ac_id']?.toString() ?? '-',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              SizedBox(width: 120, child: Text(r['ip_access']?.toString() ?? '-',
                style: const TextStyle(fontSize: 12))),
              SizedBox(width: 120, child: Text(r['ip_network']?.toString() ?? '-',
                style: const TextStyle(fontSize: 12))),
              SizedBox(width: 80, child: Text(r['site_code']?.toString() ?? '-',
                style: const TextStyle(fontSize: 12))),
              Expanded(child: errors.isEmpty
                ? Text('OK', style: TextStyle(fontSize: 11, color: Colors.grey.shade500))
                : Text(errors.join(' / '),
                    style: TextStyle(fontSize: 11, color: fg),
                    overflow: TextOverflow.ellipsis)),
            ]),
          );
        }),
      ]),
    );
  }

  // ── Result Summary ──
  Widget _buildResultSummary() {
    return Row(children: [
      _summaryCard('นำเข้าทั้งหมด', '$_passCount',    AppColors.primary, Icons.upload),
      const SizedBox(width: 12),
      _summaryCard('สำเร็จ',        '$_successCount',  AppColors.success, Icons.check_circle_outline),
      const SizedBox(width: 12),
      _summaryCard('ล้มเหลว',       '$_importFail',    Colors.red,        Icons.cancel_outlined),
      const SizedBox(width: 12),
      _summaryCard('ข้ามไป (ซ้ำ/ไม่ผ่าน)', '${_dupCount + _failCount}',
        Colors.orange, Icons.skip_next_outlined),
    ]);
  }

  Widget _buildResultTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border(bottom: BorderSide(color: AppColors.border))),
          child: const Row(children: [
            SizedBox(width: 48, child: Text('ROW',    style: _hdStyle)),
            SizedBox(width: 90, child: Text('STATUS', style: _hdStyle)),
            SizedBox(width: 160, child: Text('CID',   style: _hdStyle)),
            Expanded(      child: Text('MESSAGE',     style: _hdStyle)),
          ]),
        ),
        ..._resultRows.map((r) {
          final ok = r['success'] == true;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: ok ? Colors.green.shade50 : Colors.red.shade50,
              border: Border(top: BorderSide(color: AppColors.border),
                left: BorderSide(color: ok ? AppColors.success : Colors.red, width: 3))),
            child: Row(children: [
              SizedBox(width: 48,
                child: Text('${r['row']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              SizedBox(width: 90, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ok ? AppColors.availableBg : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ok ? AppColors.availableBorder : Colors.red.shade300)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(ok ? Icons.check_circle : Icons.cancel, size: 12,
                    color: ok ? AppColors.availableText : Colors.red.shade700),
                  const SizedBox(width: 4),
                  Text(ok ? 'OK' : 'FAIL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                    color: ok ? AppColors.availableText : Colors.red.shade700)),
                ]))),
              SizedBox(width: 160,
                child: Text(r['cid']?.toString() ?? '-',
                  style: const TextStyle(fontSize: 12))),
              Expanded(child: Text(r['message']?.toString() ?? '',
                style: TextStyle(fontSize: 12,
                  color: ok ? Colors.green.shade700 : Colors.red.shade700))),
            ]),
          );
        }),
      ]),
    );
  }

  static const _hdStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 11,
    color: Colors.grey, letterSpacing: 0.5);
}