// ไฟล์: lib/screens/bulk_import_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../services/api_service.dart';

class BulkImportScreen extends StatefulWidget {
  const BulkImportScreen({super.key});

  @override
  State<BulkImportScreen> createState() => _BulkImportScreenState();
}

class _BulkImportScreenState extends State<BulkImportScreen> {
  final _api = ApiService();

  // ─── State ───
  List<Map<String, dynamic>> _previewRows = [];
  List<Map<String, dynamic>> _resultRows  = [];
  bool _isParsing   = false;
  bool _isImporting = false;
  bool _isDone      = false;
  int  _successCount = 0;
  int  _failedCount  = 0;
  String? _fileName;

  // ─── Column definitions ───
  static const List<String> _requiredCols = [
    'node_ac_id', 'domain', 'ip_access', 'model', 'port_access',
    'site_code', 'node_nw_id', 'ip_network', 'port_network',
  ];
  static const List<String> _allCols = [
    'node_ac_id', 'area_group', 'domain', 'ip_access', 'model', 'port_access',
    'site_code', 'node_nw_id', 'ip_network', 'port_network', 'cid', 'status',
  ];

  // ════════════════════════════════════════════
  //  FILE PICK & PARSE
  // ════════════════════════════════════════════

  Future<void> _pickFile() async {
    setState(() { _isParsing = true; _previewRows = []; _resultRows = []; _isDone = false; });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isParsing = false);
        return;
      }

      final file = result.files.first;
      _fileName = file.name;
      final content = utf8.decode(file.bytes!);
      final rows = const CsvToListConverter(eol: '\n').convert(content);

      if (rows.isEmpty) {
        _showSnack('ไฟล์ว่างเปล่า', Colors.orange);
        setState(() => _isParsing = false);
        return;
      }

      // header row
      final headers = rows.first.map((e) => e.toString().trim().toLowerCase()).toList();

      // เช็ค required columns
      final missing = _requiredCols.where((c) => !headers.contains(c)).toList();
      if (missing.isNotEmpty) {
        _showSnack('ขาด column: ${missing.join(', ')}', Colors.red);
        setState(() => _isParsing = false);
        return;
      }

      // parse data rows
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

      setState(() { _previewRows = parsed; _isParsing = false; });

    } catch (e) {
      _showSnack('Parse error: $e', Colors.red);
      setState(() => _isParsing = false);
    }
  }

  // ════════════════════════════════════════════
  //  IMPORT
  // ════════════════════════════════════════════

  Future<void> _confirmImport() async {
    setState(() => _isImporting = true);

    try {
      final payload = _previewRows.map((r) => {
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
        _successCount = result['success'] ?? 0;
        _failedCount  = result['failed']  ?? 0;
        _resultRows   = List<Map<String, dynamic>>.from(result['results'] ?? []);
        _isImporting  = false;
        _isDone       = true;
      });

    } catch (e) {
      _showSnack('Import error: $e', Colors.red);
      setState(() => _isImporting = false);
    }
  }

  void _reset() => setState(() {
    _previewRows = []; _resultRows = []; _isDone = false;
    _successCount = 0; _failedCount = 0; _fileName = null;
  });

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color));
  }

  // ════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ─── Upload Zone ───
        _buildUploadZone(),
        const SizedBox(height: 24),

        // ─── Column Guide ───
        if (_previewRows.isEmpty && !_isDone) _buildColumnGuide(),

        // ─── Preview Table ───
        if (_previewRows.isNotEmpty && !_isDone) ...[
          _buildSectionHeader('Preview — ${_previewRows.length} rows จากไฟล์ $_fileName'),
          const SizedBox(height: 12),
          _buildPreviewTable(),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            OutlinedButton(onPressed: _reset, child: const Text('Cancel')),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _isImporting ? null : _confirmImport,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF28A745), foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
              icon: _isImporting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.upload),
              label: Text(_isImporting ? 'กำลัง Import...' : 'Confirm Import',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ]),
        ],

        // ─── Result ───
        if (_isDone) ...[
          _buildResultSummary(),
          const SizedBox(height: 16),
          _buildResultTable(),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _reset,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056B3), foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
            icon: const Icon(Icons.refresh),
            label: const Text('Import ใหม่', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ]),
    );
  }

  // ════════════════════════════════════════════
  //  WIDGETS
  // ════════════════════════════════════════════

  Widget _buildUploadZone() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: Column(children: [
        Icon(Icons.upload_file_outlined, size: 56, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        const Text('อัพโหลดไฟล์ CSV', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('รองรับเฉพาะ .csv เท่านั้น', style: TextStyle(color: Colors.grey.shade500)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _isParsing ? null : _pickFile,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0056B3), foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14)),
          icon: _isParsing
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.folder_open),
          label: Text(_isParsing ? 'กำลังอ่านไฟล์...' : 'เลือกไฟล์',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ]),
    );
  }

  Widget _buildColumnGuide() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
          const SizedBox(width: 8),
          Text('Column ที่ต้องมีในไฟล์ CSV',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8,
          children: _allCols.map((col) {
            final isRequired = _requiredCols.contains(col);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isRequired ? Colors.blue.shade100 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: isRequired ? Colors.blue.shade300 : Colors.grey.shade300)),
              child: Text(col, style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold,
                color: isRequired ? Colors.blue.shade800 : Colors.grey.shade600)),
            );
          }).toList()),
        const SizedBox(height: 8),
        Text('สีน้ำเงิน = required, สีเทา = optional',
          style: TextStyle(fontSize: 12, color: Colors.blue.shade600)),
      ]),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)));
  }

  Widget _buildPreviewTable() {
    final displayCols = _allCols.where((c) =>
      _previewRows.any((r) => r[c]?.toString().isNotEmpty == true)).toList();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
          columnSpacing: 24,
          columns: [
            const DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
            ...displayCols.map((c) => DataColumn(
              label: Text(c, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
          ],
          rows: _previewRows.take(50).map((row) => DataRow(cells: [
            DataCell(Text(row['row'].toString(),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12))),
            ...displayCols.map((c) => DataCell(
              Text(row[c]?.toString() ?? '-',
                style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))),
          ])).toList(),
        ),
      ),
    );
  }

  Widget _buildResultSummary() {
    return Row(children: [
      _buildStatCard('Total', _previewRows.length, Colors.blue),
      const SizedBox(width: 16),
      _buildStatCard('Success', _successCount, Colors.green),
      const SizedBox(width: 16),
      _buildStatCard('Failed', _failedCount, Colors.red),
    ]);
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3))),
      child: Column(children: [
        Text(count.toString(), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 13, color: color)),
      ]),
    );
  }

  Widget _buildResultTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        // header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
          child: Row(children: [
            const SizedBox(width: 48, child: Text('ROW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            const SizedBox(width: 80, child: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            Expanded(child: Text('MESSAGE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade700))),
          ]),
        ),
        ..._resultRows.map((r) {
          final ok = r['success'] == true;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: ok ? Colors.green.shade50 : Colors.red.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade200))),
            child: Row(children: [
              SizedBox(width: 48, child: Text(r['row'].toString(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              SizedBox(width: 80, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ok ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4)),
                child: Text(ok ? 'OK' : 'FAIL',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                    color: ok ? Colors.green.shade800 : Colors.red.shade800)))),
              Expanded(child: Text(r['message']?.toString() ?? '',
                style: TextStyle(fontSize: 13, color: ok ? Colors.green.shade700 : Colors.red.shade700))),
            ]),
          );
        }),
      ]),
    );
  }
}