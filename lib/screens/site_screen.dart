// ไฟล์: lib/screens/site_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../core/theme.dart';

class SiteScreen extends StatefulWidget {
  final bool canEdit;
  const SiteScreen({super.key, this.canEdit = true});

  @override
  State<SiteScreen> createState() => _SiteScreenState();
}

class _SiteScreenState extends State<SiteScreen> {
  final _api = ApiService();

  List<Map<String, dynamic>> _sites     = [];
  List<Map<String, dynamic>> _siteNodes = [];
  Map<String, dynamic>? _selectedSite;
  bool _loadingSites    = false;
  bool _loadingSiteData = false;
  String _searchSite = '';

  @override
  void initState() {
    super.initState();
    _fetchSites();
  }

  // ════════════════════════════════════════════
  //  DATA
  // ════════════════════════════════════════════

  Future<void> _fetchSites() async {
    setState(() => _loadingSites = true);
    final data = await _api.fetchSites();
    setState(() { _sites = data; _loadingSites = false; });
  }

  Future<void> _fetchSiteData(String siteCode) async {
    setState(() => _loadingSiteData = true);
    final data = await _api.fetchNetworkNodes(siteCode: siteCode);
    setState(() { _siteNodes = data; _loadingSiteData = false; });
  }

  void _selectSite(Map<String, dynamic> site) {
    setState(() { _selectedSite = site; _siteNodes = []; });
    _fetchSiteData(site['Site_code'].toString());
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    AppSnackbar.show(context, msg, color: color);
  }

  // ════════════════════════════════════════════
  //  SITE DIALOGS
  // ════════════════════════════════════════════

  void _showSiteDialog({Map<String, dynamic>? existing}) {
    final ctrl = TextEditingController(text: existing?['Site_code'] ?? '');
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(existing == null ? 'Add Site Code' : 'Edit Site Code',
        style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(width: 320, child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Site Code', style: AppTextStyles.label),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            autofocus: true,
            decoration: AppInputDecoration.standard(hint: 'e.g., BCH-5012-UR'),
          ),
        ],
      )),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: AppButtonStyles.primary(),
          onPressed: () async {
            final code = ctrl.text.trim();
            if (code.isEmpty) {
              _showSnack('กรอก Site Code ด้วย', Colors.orange);
              return;
            }
            Navigator.pop(ctx);
            if (existing == null) {
              final ok = await _api.createSite(code);
              ok ? _showSnack('เพิ่ม $code สำเร็จ', AppColors.success)
                 : _showSnack('เพิ่มไม่สำเร็จ (อาจซ้ำ)', Colors.red);
            } else {
              final ok = await _api.updateSite(existing['Location_ID'] as int, code);
              ok ? _showSnack('แก้ไขสำเร็จ', AppColors.success)
                 : _showSnack('แก้ไขไม่สำเร็จ', Colors.red);
            }
            _fetchSites();
          },
          child: Text(existing == null ? 'Add' : 'Save'),
        ),
      ],
    ));
  }

  void _confirmDeleteSite(Map<String, dynamic> site) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete Site Code', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text('ลบ "${site['Site_code']}" ออกไหม?\nต้องไม่มี Switch Network อยู่ใน Site นี้'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: AppButtonStyles.danger(),
          onPressed: () async {
            Navigator.pop(ctx);
            final ok = await _api.deleteSite(site['Location_ID'] as int);
            if (ok) {
              if (_selectedSite?['Location_ID'] == site['Location_ID']) {
                setState(() { _selectedSite = null; _siteNodes = []; });
              }
              _showSnack('ลบสำเร็จ', AppColors.success);
              _fetchSites();
            } else {
              _showSnack('ลบไม่ได้ — มี Switch Network อยู่ใน Site นี้', Colors.red);
            }
          },
          child: const Text('Delete'),
        ),
      ],
    ));
  }

  // ════════════════════════════════════════════
  //  ADD NODE DIALOG
  // ════════════════════════════════════════════


  // แสดง port summary เช่น "GE: 8/24" แต่ละตัวเป็น chip
  Widget _portSummaryWidget(String summary) {
    final parts = summary.split(', ');
    return Wrap(spacing: 4, runSpacing: 4, children: parts.map((p) {
      final split     = p.split(': ');
      final type      = split.first;
      final counts    = split.length > 1 ? split[1].split('/') : ['0', '0'];
      final available = int.tryParse(counts[0]) ?? 0;
      final total     = int.tryParse(counts.length > 1 ? counts[1] : '0') ?? 0;
      final hasAvail  = available > 0;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: hasAvail ? AppColors.success.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: hasAvail ? AppColors.success.withOpacity(0.4) : Colors.grey.shade300)),
        child: Text('$type: $available/$total',
          style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.bold,
            color: hasAvail ? AppColors.success : Colors.grey.shade500)),
      );
    }).toList());
  }

  InputDecoration _dropdownDecor() => InputDecoration(
    filled: true, fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.primary, width: 2)),
  );

  // ════════════════════════════════════════════
  //  CSV IMPORT
  // ════════════════════════════════════════════

  Future<void> _importSitesCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['csv'], withData: true);
    if (result == null || result.files.isEmpty) return;

    final bytes = result.files.first.bytes;
    if (bytes == null) return;

    final lines = String.fromCharCodes(bytes)
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) { AppSnackbar.error(context, 'ไฟล์ว่างเปล่า'); return; }

    // ข้าม header row ถ้ามี
    final dataLines = lines.first.toLowerCase() == 'site_code'
        ? lines.skip(1).toList()
        : lines;

    if (dataLines.isEmpty) { AppSnackbar.error(context, 'ไม่พบข้อมูลใน CSV'); return; }

    // preview ก่อน import
    _showCsvPreviewDialog(dataLines);
  }

  void _showCsvPreviewDialog(List<String> siteCodes) {
    final codes = siteCodes.where((s) => s.isNotEmpty).toList();

    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Preview Import Site Codes',
        style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(width: 360, height: 360, child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('พบ ${codes.length} Site Codes',
            style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border)),
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: codes.length,
              separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Row(children: [
                  const Icon(Icons.business_outlined, size: 14, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(codes[i], style: const TextStyle(fontSize: 13)),
                ]),
              ),
            ),
          )),
        ],
      )),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: AppButtonStyles.success(),
          onPressed: () async {
            Navigator.pop(ctx);
            int created = 0, skipped = 0;
            for (final code in codes) {
              final ok = await _api.createSite(code);
              ok ? created++ : skipped++;
            }
            AppSnackbar.success(context,
              'เพิ่ม $created Sites สำเร็จ (ข้าม $skipped ที่มีอยู่แล้ว)');
            _fetchSites();
          },
          child: const Text('Import'),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _sites.where((s) =>
      (s['Site_code']?.toString() ?? '').toLowerCase()
        .contains(_searchSite.toLowerCase())).toList();

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ─── Panel ซ้าย: Site Codes ───
        SizedBox(width: 300, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Site Codes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Row(children: [
              if (widget.canEdit) ...[
              OutlinedButton.icon(
                onPressed: _importSitesCsv,
                icon: const Icon(Icons.upload_file, size: 14),
                label: const Text('CSV', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(0, 32),
                  side: const BorderSide(color: AppColors.border)),
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                onPressed: _showSiteDialog,
                style: AppButtonStyles.primary(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              ]]),
          ]),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => _searchSite = v),
            decoration: AppInputDecoration.search(hint: 'Search site code...'),
          ),
          const SizedBox(height: 12),
          Expanded(child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _loadingSites
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                  ? Center(child: Text('ไม่พบข้อมูล',
                      style: TextStyle(color: Colors.grey.shade400)))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (_, i) {
                        final s = filtered[i];
                        final isSelected =
                          _selectedSite?['Location_ID'] == s['Location_ID'];
                        return InkWell(
                          onTap: () => _selectSite(s),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                            color: isSelected
                              ? AppColors.primary.withOpacity(0.08)
                              : Colors.transparent,
                            child: Row(children: [
                              Expanded(child: Text(
                                s['Site_code']?.toString() ?? '-',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14,
                                  color: isSelected
                                    ? AppColors.primary : AppColors.dark))),
                              if (widget.canEdit)
                              PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'edit')   _showSiteDialog(existing: s);
                                  if (v == 'delete') _confirmDeleteSite(s);
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(value: 'edit',
                                    child: Text('Edit')),
                                  const PopupMenuItem(value: 'delete',
                                    child: Text('Delete',
                                      style: TextStyle(color: Colors.red))),
                                ],
                                child: Icon(Icons.more_vert, size: 18,
                                  color: Colors.grey.shade400),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
            ),
          )),
        ])),

        const SizedBox(width: 24),

        // ─── Panel ขวา: Network Nodes ───
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text(
              _selectedSite == null
                ? 'เลือก Site Code เพื่อดูข้อมูล'
                : 'Network Nodes ใน ${_selectedSite!['Site_code']}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 12),

          Expanded(child: _selectedSite == null
            ? Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200)),
                child: Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.business_outlined, size: 56,
                      color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('กรุณาเลือก Site Code ด้านซ้าย',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
                  ])),
              )
            : _loadingSiteData
              ? const Center(child: CircularProgressIndicator())
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border)),
                  child: Column(children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8))),
                      child: Row(children: [
                        Expanded(flex: 3, child: Text('NODE NAME',
                          style: AppTextStyles.tableHeader.copyWith(color: Colors.grey.shade600))),
                        Expanded(flex: 1, child: Text('ID',
                          style: AppTextStyles.tableHeader.copyWith(color: Colors.grey.shade600))),
                        Expanded(flex: 2, child: Text('IP',
                          style: AppTextStyles.tableHeader.copyWith(color: Colors.grey.shade600))),
                        Expanded(flex: 2, child: Text('MODEL',
                          style: AppTextStyles.tableHeader.copyWith(color: Colors.grey.shade600))),
                        Expanded(flex: 3, child: Text('PORT ว่าง/ทั้งหมด',
                          style: AppTextStyles.tableHeader.copyWith(color: Colors.grey.shade600))),
                      ]),
                    ),
                    // Rows
                    Expanded(child: _siteNodes.isEmpty
                      ? Center(child: Text('ไม่พบ Network Node ใน Site นี้',
                          style: TextStyle(color: Colors.grey.shade400)))
                      : ListView.separated(
                          itemCount: _siteNodes.length,
                          separatorBuilder: (_, __) =>
                            Divider(height: 1, color: Colors.grey.shade100),
                          itemBuilder: (_, i) {
                            final node        = _siteNodes[i];
                            final portSummary = node['port_summary']?.toString();
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                              child: Row(children: [
                                Expanded(flex: 3, child: Text(
                                  node['NodeName']?.toString() ?? '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500, fontSize: 14))),
                                Expanded(flex: 1, child: Text(
                                  node['NodeNwID']?.toString() ?? '-',
                                  style: AppTextStyles.bodySmall)),
                                Expanded(flex: 2, child: Text(
                                  node['ip']?.toString() ?? '-',
                                  style: AppTextStyles.bodySmall)),
                                Expanded(flex: 2, child: Text(
                                  node['model_name']?.toString() ?? '-',
                                  style: AppTextStyles.bodySmall,
                                  overflow: TextOverflow.ellipsis)),
                                Expanded(flex: 3, child: portSummary != null
                                  ? _portSummaryWidget(portSummary)
                                  : Text('-', style: AppTextStyles.bodySmall)),
                              ]),
                            );
                          },
                        )),
                  ]),
                )),
        ])),
      ]),
    );
  }
}