// ไฟล์: lib/screens/network_node_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import 'network_node_csv_preview_screen.dart';

class NetworkNodeScreen extends StatefulWidget {
  final bool canEdit;
  const NetworkNodeScreen({super.key, this.canEdit = true});

  @override
  State<NetworkNodeScreen> createState() => _NetworkNodeScreenState();
}

class _NetworkNodeScreenState extends State<NetworkNodeScreen> {
  final _api = ApiService();

  List<Map<String, dynamic>> _nodes   = [];
  List<Map<String, dynamic>> _sites   = [];
  String? _selectedSiteCode;
  bool _loading = false;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetchSites();
  }

  Future<void> _fetchSites() async {
    final data = await _api.fetchSites();
    setState(() => _sites = data);
  }

  Future<void> _fetchNodes(String? siteCode) async {
    setState(() { _loading = true; _nodes = []; });
    final data = await _api.fetchNetworkNodes(siteCode: siteCode);
    setState(() { _nodes = data; _loading = false; });
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _nodes;
    return _nodes.where((n) =>
      n['NodeName']?.toString().toLowerCase().contains(_search.toLowerCase()) == true ||
      n['NodeNwID']?.toString().contains(_search) == true ||
      n['ip']?.toString().contains(_search) == true
    ).toList();
  }

  Future<void> _showAddNodeDialog() async {
    showDialog(context: context, barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()));

    List<Map<String, dynamic>> models  = [];
    List<Map<String, dynamic>> domains = [];
    try {
      models  = await _api.fetchModels();
      domains = await _api.fetchDomains();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      AppSnackbar.error(context, 'โหลดข้อมูลไม่สำเร็จ: $e');
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);

    final nameCtrl    = TextEditingController();
    final nodeIdCtrl  = TextEditingController();
    int?    selModel;
    int?    selSite;
    int?    selDomain;
    int?    selIp;
    List<Map<String, dynamic>> ips = [];
    bool loadingIps = false;

    final dec = InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      filled: true, fillColor: Colors.white,
    );

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        title: const Text('Add Network Node', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(width: 440, child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min, children: [

          // Node ID
          _dialogField('Node ID *', TextField(
            controller: nodeIdCtrl,
            keyboardType: TextInputType.number,
            decoration: dec.copyWith(hintText: 'e.g., 88860'),
          )),
          const SizedBox(height: 12),

          // Node Name
          _dialogField('Node Name *', TextField(
            controller: nameCtrl,
            decoration: dec.copyWith(hintText: 'e.g., LSW-BCH-NW-01'),
          )),
          const SizedBox(height: 12),

          // Site
          _dialogField('Site *', DropdownButtonFormField<int>(
            value: selSite,
            hint: const Text('เลือก Site'),
            decoration: dec,
            items: _sites.map<DropdownMenuItem<int>>((s) => DropdownMenuItem(
              value: s['Location_ID'] as int,
              child: Text(s['Site_code'].toString()))).toList(),
            onChanged: (v) => setD(() => selSite = v),
          )),
          const SizedBox(height: 12),

          // Model
          _dialogField('Model *', DropdownButtonFormField<int>(
            value: selModel,
            hint: const Text('เลือก Model'),
            decoration: dec,
            items: models.map<DropdownMenuItem<int>>((m) => DropdownMenuItem(
              value: m['Model_Id'] as int,
              child: Text(m['Model_Name'].toString(),
                overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) => setD(() => selModel = v),
          )),
          const SizedBox(height: 12),

          // Domain
          _dialogField('Domain *', DropdownButtonFormField<int>(
            value: selDomain,
            hint: const Text('เลือก Domain'),
            decoration: dec,
            items: domains.map<DropdownMenuItem<int>>((d) => DropdownMenuItem(
              value: d['Domain_id'] as int,
              child: Text(d['Domain_Name'].toString()))).toList(),
            onChanged: (v) async {
              setD(() { selDomain = v; selIp = null; ips = []; loadingIps = true; });
              final ipData = await _api.fetchIpsWithStatus(v!);
              setD(() {
                ips = ipData.where((ip) => ip['in_use'] == false).toList();
                loadingIps = false;
              });
            },
          )),
          const SizedBox(height: 12),

          // IP
          _dialogField('IP Address *', loadingIps
            ? const Padding(padding: EdgeInsets.symmetric(vertical: 14),
                child: LinearProgressIndicator())
            : DropdownButtonFormField<int>(
                value: selIp,
                hint: Text(selDomain == null ? 'เลือก Domain ก่อน' : 'เลือก IP'),
                decoration: dec,
                items: ips.map<DropdownMenuItem<int>>((ip) => DropdownMenuItem(
                  value: ip['IP_id'] as int,
                  child: Text('${ip['IP']}/${ip['Prefix'] ?? ''}'))).toList(),
                onChanged: selDomain == null ? null : (v) => setD(() => selIp = v),
              )),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: AppButtonStyles.success(),
            onPressed: () async {
              if (nodeIdCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty ||
                  selModel == null || selSite == null || selIp == null) {
                AppSnackbar.warning(context, 'กรอกข้อมูลให้ครบ');
                return;
              }
              final nodeId = int.tryParse(nodeIdCtrl.text.trim());
              if (nodeId == null) {
                AppSnackbar.warning(context, 'Node ID ต้องเป็นตัวเลข');
                return;
              }
              Navigator.pop(ctx);
              final result = await _api.createNetworkNodeFull(
                nodeName: nameCtrl.text.trim(),
                modelId:  selModel!,
                siteId:   selSite!,
                ipId:     selIp!,
                nodeId:   nodeId,
              );
              if (result != null && result['error'] == null) {
                AppSnackbar.success(context, 'เพิ่ม Node สำเร็จ');
                _fetchNodes(_selectedSiteCode);
              } else {
                AppSnackbar.error(context, result?['error'] ?? 'เพิ่มไม่สำเร็จ');
              }
            },
            child: const Text('Add Node'),
          ),
        ],
      ),
    ));
  }

  Widget _dialogField(String label, Widget field) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold,
        fontSize: 13, color: AppColors.textSecondary)),
      const SizedBox(height: 6),
      field,
    ]);

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['csv'], withData: true);
    if (result == null || result.files.isEmpty) return;

    final bytes = result.files.first.bytes;
    if (bytes == null) return;

    final lines = String.fromCharCodes(bytes)
        .split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    if (lines.isEmpty) { AppSnackbar.error(context, 'ไฟล์ว่างเปล่า'); return; }

    final header = lines.first.split(',').map((h) => h.trim().toLowerCase()).toList();
    final required = ['node_id', 'node_name', 'ip', 'model_name', 'site_code'];
    for (final col in required) {
      if (!header.contains(col)) {
        AppSnackbar.error(context, 'CSV ต้องมี column: $col');
        return;
      }
    }

    final rows = <Map<String, dynamic>>[];
    for (int i = 1; i < lines.length; i++) {
      final cols = lines[i].split(',').map((c) => c.trim()).toList();
      if (cols.length < header.length) continue;
      final row = <String, dynamic>{};
      for (int j = 0; j < header.length; j++) {
        row[header[j]] = cols[j];
      }
      rows.add(row);
    }

    if (rows.isEmpty) { AppSnackbar.error(context, 'ไม่พบข้อมูลใน CSV'); return; }

    final imported = await Navigator.push<bool>(context,
      MaterialPageRoute(builder: (_) =>
        NetworkNodeCsvPreviewScreen(rawRows: rows)));
    if (imported == true) _fetchNodes(_selectedSiteCode);
  }

  @override
  Widget build(BuildContext context) {
    final nodes = _filtered;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ─── Filters ───
        Row(children: [
          // Site filter
          SizedBox(width: 220, child: DropdownButtonFormField<String>(
            value: _selectedSiteCode,
            hint: const Text('All Sites'),
            decoration: AppInputDecoration.standard(hint: 'All Sites'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Sites')),
              ..._sites.map((s) => DropdownMenuItem(
                value: s['Site_code'].toString(),
                child: Text(s['Site_code'].toString()))),
            ],
            onChanged: (v) {
              setState(() => _selectedSiteCode = v);
              _fetchNodes(v);
            },
          )),
          const SizedBox(width: 16),
          // Search
          Expanded(child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: AppInputDecoration.search(hint: 'Search ID, Name, IP...'),
          )),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.refresh),
            color: AppColors.primary,
            onPressed: () => _fetchNodes(_selectedSiteCode),
          ),
          const SizedBox(width: 4),
          if (widget.canEdit) ...[
          OutlinedButton.icon(
            onPressed: _importCsv,
            icon: const Icon(Icons.upload_file, size: 16),
            label: const Text('Import CSV'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _sites.isEmpty ? null : _showAddNodeDialog,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Node'),
            style: AppButtonStyles.success(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
          ),
          ],
        ]),
        const SizedBox(height: 16),

        // ─── Table header ───
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: AppColors.border)),
          child: Row(children: [
            Expanded(flex: 1, child: Text('NODE ID',  style: AppTextStyles.tableHeader.copyWith(color: Colors.grey.shade600))),
            Expanded(flex: 3, child: Text('NODE NAME',style: AppTextStyles.tableHeader.copyWith(color: Colors.grey.shade600))),
            Expanded(flex: 2, child: Text('IP',       style: AppTextStyles.tableHeader.copyWith(color: Colors.grey.shade600))),
            Expanded(flex: 2, child: Text('MODEL',    style: AppTextStyles.tableHeader.copyWith(color: Colors.grey.shade600))),
            Expanded(flex: 2, child: Text('SITE',     style: AppTextStyles.tableHeader.copyWith(color: Colors.grey.shade600))),
            Expanded(flex: 3, child: Text('PORTS',    style: AppTextStyles.tableHeader.copyWith(color: Colors.grey.shade600))),
            const SizedBox(width: 40),
          ]),
        ),

        // ─── Rows ───
        Expanded(child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              left:   BorderSide(color: AppColors.border),
              right:  BorderSide(color: AppColors.border),
              bottom: BorderSide(color: AppColors.border)),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8))),
          child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _selectedSiteCode == null && _nodes.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.hub_outlined, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('เลือก Site เพื่อดู Network Nodes',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                ]))
              : nodes.isEmpty
                ? Center(child: Text('ไม่พบข้อมูล',
                    style: TextStyle(color: Colors.grey.shade400)))
                : ListView.separated(
                    itemCount: nodes.length,
                    separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (_, i) => _buildRow(nodes[i]),
                  ),
        )),
      ]),
    );
  }

  Widget _buildRow(Map<String, dynamic> node) {
    final portSummary = node['port_summary']?.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [

        // Node ID
        Expanded(flex: 1, child: Text(
          node['NodeNwID']?.toString() ?? '-',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),

        // Node Name
        Expanded(flex: 3, child: Text(
          node['NodeName']?.toString() ?? '-',
          style: AppTextStyles.bodySmall,
          overflow: TextOverflow.ellipsis)),

        // IP
        Expanded(flex: 2, child: Text(
          node['ip']?.toString() ?? '-',
          style: AppTextStyles.bodySmall)),

        // Model
        Expanded(flex: 2, child: Text(
          node['model_name']?.toString() ?? '-',
          style: AppTextStyles.bodySmall,
          overflow: TextOverflow.ellipsis)),

        // Site
        Expanded(flex: 2, child: node['site_code'] != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(4)),
              child: Text(node['site_code'].toString(),
                style: const TextStyle(fontSize: 11,
                  color: AppColors.primary, fontWeight: FontWeight.bold)))
          : const Text('-', style: AppTextStyles.bodySmall)),

        // Port summary
        Expanded(flex: 3, child: portSummary != null
          ? _portSummaryWidget(portSummary)
          : const Text('-', style: AppTextStyles.bodySmall)),

        // Details button
        SizedBox(width: 40, child: IconButton(
          icon: const Icon(Icons.more_vert, size: 18),
          color: Colors.grey.shade400,
          onPressed: () => _showDetails(node),
        )),
      ]),
    );
  }

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
          color: hasAvail
            ? AppColors.success.withOpacity(0.1)
            : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: hasAvail
              ? AppColors.success.withOpacity(0.4)
              : Colors.grey.shade300)),
        child: Text('$type: $available/$total',
          style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.bold,
            color: hasAvail ? AppColors.success : Colors.grey.shade500)),
      );
    }).toList());
  }

  // ════════════════════════════════════════════
  //  DETAILS POPUP
  // ════════════════════════════════════════════

  void _showDetails(Map<String, dynamic> node) async {
    // โหลด ports + connections
    showDialog(context: context, builder: (ctx) => _DetailsDialog(
      node: node, api: _api));
  }
}

// ─── Details Dialog ───
class _DetailsDialog extends StatefulWidget {
  final Map<String, dynamic> node;
  final ApiService api;

  const _DetailsDialog({required this.node, required this.api});

  @override
  State<_DetailsDialog> createState() => _DetailsDialogState();
}

class _DetailsDialogState extends State<_DetailsDialog> {
  List<Map<String, dynamic>> _ports       = [];
  List<Map<String, dynamic>> _connections = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final nodeId = widget.node['NodeNwID'] as int;
    final ports  = await widget.api.fetchNetworkNodePorts(nodeId);
    // ดึง connections ผ่าน node ports
    setState(() {
      _ports      = ports;
      _loading    = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    return AlertDialog(
      title: Row(children: [
        const Icon(Icons.hub_outlined, color: AppColors.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(node['NodeName']?.toString() ?? '-',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text('ID: ${node['NodeNwID']}  |  ${node['ip'] ?? '-'}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted,
              fontWeight: FontWeight.normal)),
        ])),
      ]),
      content: SizedBox(width: 560, height: 420, child: _loading
        ? const Center(child: CircularProgressIndicator())
        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Info row
          Wrap(spacing: 12, runSpacing: 8, children: [
            _infoChip(Icons.memory_outlined,    node['model_name']?.toString() ?? '-', AppColors.primary),
            _infoChip(Icons.business_outlined,  node['site_code']?.toString()  ?? '-', AppColors.info),
            _infoChip(Icons.lan_outlined,       node['ip']?.toString()         ?? '-', AppColors.success),
          ]),
          const SizedBox(height: 16),

          // Port list
          Row(children: [
            const Text('Ports', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(width: 8),
            AppWidgets.miniChip('${_ports.length}', Colors.grey),
          ]),
          const SizedBox(height: 8),
          Expanded(child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(6)),
            child: Column(children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: AppColors.surface,
                child: Row(children: [
                  Expanded(flex: 3, child: Text('PORT NAME', style: AppTextStyles.tableHeader.copyWith(color: Colors.grey.shade600))),
                  Expanded(flex: 2, child: Text('TYPE',      style: AppTextStyles.tableHeader.copyWith(color: Colors.grey.shade600))),
                  Expanded(flex: 2, child: Text('SPEED',     style: AppTextStyles.tableHeader.copyWith(color: Colors.grey.shade600))),
                  Expanded(flex: 2, child: Text('STATUS',    style: AppTextStyles.tableHeader.copyWith(color: Colors.grey.shade600))),
                  Expanded(flex: 2, child: Text('CONNECTION',style: AppTextStyles.tableHeader.copyWith(color: Colors.grey.shade600))),
                ]),
              ),
              Expanded(child: _ports.isEmpty
                ? Center(child: Text('ไม่พบ Port', style: TextStyle(color: Colors.grey.shade400)))
                : ListView.separated(
                    itemCount: _ports.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (_, i) {
                      final p      = _ports[i];
                      final inUse  = p['status'] == 'in_use';
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(children: [
                          Expanded(flex: 3, child: Text(
                            p['Interface_Name']?.toString() ?? '-',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                          Expanded(flex: 2, child: Text(
                            p['Interface_Type']?.toString() ?? '-',
                            style: AppTextStyles.bodySmall)),
                          Expanded(flex: 2, child: Text(
                            p['speed']?.toString() ?? '-',
                            style: AppTextStyles.bodySmall)),
                          Expanded(flex: 2, child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: inUse ? AppColors.inUseBg : AppColors.availableBg,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: inUse ? AppColors.inUseBorder : AppColors.availableBorder)),
                            child: Text(inUse ? 'In Use' : 'Available',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                                color: inUse ? AppColors.inUseText : AppColors.availableText)))),
                          Expanded(flex: 2, child: inUse
                            ? TextButton(
                                onPressed: () => _showConnectionInfo(p),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  foregroundColor: AppColors.primary),
                                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.info_outline, size: 14),
                                  SizedBox(width: 4),
                                  Text('ดูข้อมูล', style: TextStyle(fontSize: 11)),
                                ]))
                            : const SizedBox.shrink()),
                        ]),
                      );
                    },
                  )),
            ]),
          )),
        ])),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close')),
      ],
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: color,
          fontWeight: FontWeight.w600)),
      ]),
    );
  }

  void _showConnectionInfo(Map<String, dynamic> port) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('Connection — ${port['Interface_Name']}',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      content: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow('Port',   port['Interface_Name']?.toString() ?? '-'),
          _detailRow('Type',   port['Interface_Type']?.toString() ?? '-'),
          _detailRow('Speed',  port['speed']?.toString() ?? '-'),
          _detailRow('Cable',  port['cable_type']?.toString() ?? '-'),
          _detailRow('Status', port['status']?.toString() ?? '-'),
        ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
          child: const Text('Close')),
      ],
    ));
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 80, child: Text(label,
          style: AppTextStyles.label)),
        Expanded(child: Text(value,
          style: AppTextStyles.body)),
      ]),
    );
  }
}