// ไฟล์: lib/screens/domain_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../core/theme.dart';
import 'subnet_csv_preview_screen.dart';

class DomainScreen extends StatefulWidget {
  final bool canEdit;
  const DomainScreen({super.key, this.canEdit = true});

  @override
  State<DomainScreen> createState() => _DomainScreenState();
}

class _DomainScreenState extends State<DomainScreen> {
  final _api = ApiService();

  // ─── State ───
  List<Map<String, dynamic>> _domains  = [];
  List<Map<String, dynamic>> _ips      = [];
  Map<String, dynamic>? _selectedDomain;
  String? _selectedSubnet;   // เช่น "10.98.4"
  bool _loadingDomains = false;
  bool _loadingIps     = false;

  @override
  void initState() {
    super.initState();
    _fetchDomains();
  }

  // ════════════════════════════════════════════
  //  DATA
  // ════════════════════════════════════════════

  Future<void> _fetchDomains() async {
    setState(() => _loadingDomains = true);
    final data = await _api.fetchDomains();
    setState(() { _domains = data; _loadingDomains = false; });
  }

  Future<void> _fetchIps(int domainId) async {
    setState(() => _loadingIps = true);
    final data = await _api.fetchIpsWithStatus(domainId);
    setState(() { _ips = data; _loadingIps = false; });
  }

  void _selectDomain(Map<String, dynamic> domain) {
    setState(() { _selectedDomain = domain; _selectedSubnet = null; _ips = []; });
    _fetchIps(domain['Domain_id'] as int);
  }

  // ─── Group IPs by subnet/prefix เช่น "10.98.4.0/24" ───
  Map<String, List<Map<String, dynamic>>> get _subnetMap {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final ip in _ips) {
      final parts  = ip['IP'].toString().split('.');
      final prefix = ip['Prefix'];
      if (parts.length == 4 && prefix != null) {
        final key = '${parts[0]}.${parts[1]}.${parts[2]}.0/$prefix';
        map.putIfAbsent(key, () => []).add(ip);
      } else if (parts.length == 4) {
        // ถ้าไม่มี prefix → group ด้วย 3 octet แรก
        final key = '${parts[0]}.${parts[1]}.${parts[2]}.0';
        map.putIfAbsent(key, () => []).add(ip);
      }
    }
    return Map.fromEntries(map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  // ─── subnet key → 3 octet prefix สำหรับ filter ─── 
  String _subnetToPattern(String key) {
    // "10.98.4.0/24" → "10.98.4"
    final noPrefix = key.split('/').first;           // "10.98.4.0"
    final parts    = noPrefix.split('.');
    return '${parts[0]}.${parts[1]}.${parts[2]}';
  }

  List<Map<String, dynamic>> get _filteredIps {
    if (_selectedSubnet == null) return [];
    return _subnetMap[_selectedSubnet] ?? [];
  }

  // ════════════════════════════════════════════
  //  DOMAIN DIALOGS
  // ════════════════════════════════════════════

  void _showDomainDialog({Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['Domain_Name'] ?? '');
    final vlanCtrl = TextEditingController(text: existing?['Vlan']?.toString() ?? '');
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(existing == null ? 'Add Domain' : 'Edit Domain',
        style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(width: 360, child: Column(mainAxisSize: MainAxisSize.min, children: [
        _buildTextField(nameCtrl, 'Domain Name', 'e.g., BKK-MPLS'),
        const SizedBox(height: 16),
        _buildTextField(vlanCtrl, 'VLAN (optional)', 'e.g., 100', isNumber: true),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          onPressed: () async {
            Navigator.pop(ctx);
            if (existing == null) {
              await _api.createDomain(nameCtrl.text.trim(), int.tryParse(vlanCtrl.text));
            } else {
              await _api.updateDomain(existing['Domain_id'] as int, nameCtrl.text.trim(), int.tryParse(vlanCtrl.text));
            }
            _fetchDomains();
          },
          child: Text(existing == null ? 'Add' : 'Save'),
        ),
      ],
    ));
  }

  void _confirmDeleteDomain(Map<String, dynamic> domain) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete Domain', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text('ลบ "${domain['Domain_Name']}" ออกไหม?\nต้องไม่มี IP อยู่ใน domain นี้'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () async {
            Navigator.pop(ctx);
            final ok = await _api.deleteDomain(domain['Domain_id'] as int);
            if (ok) {
              if (_selectedDomain?['Domain_id'] == domain['Domain_id']) {
                setState(() { _selectedDomain = null; _selectedSubnet = null; _ips = []; });
              }
              _fetchDomains();
            } else {
              _showSnack('ลบไม่ได้ — มี IP อยู่ใน domain นี้', Colors.red);
            }
          },
          child: const Text('Delete'),
        ),
      ],
    ));
  }

  // ════════════════════════════════════════════
  //  ADD IP BLOCK DIALOG
  // ════════════════════════════════════════════

  void _showAddIpBlockDialog() {
    final oct1 = TextEditingController();
    final oct2 = TextEditingController();
    final oct3 = TextEditingController();
    final prefixCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // pre-fill ถ้ามี subnet เลือกอยู่
    if (_selectedSubnet != null) {
      final parts = _selectedSubnet!.split('.');
      if (parts.length == 3) {
        oct1.text = parts[0];
        oct2.text = parts[1];
        oct3.text = parts[2];
      }
    }

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setStateDialog) => AlertDialog(
        title: const Text('Add IP Block', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Subnet input
              const Align(alignment: Alignment.centerLeft,
                child: Text('Subnet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary))),
              const SizedBox(height: 8),
              Row(children: [
                _buildOctetField(oct1),
                _dot(), _buildOctetField(oct2),
                _dot(), _buildOctetField(oct3),
                _dot(),
                Container(
                  width: 40, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300)),
                  child: const Center(child: Text('x', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 16))),
                ),
                const SizedBox(width: 12),
                const Text('/', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey)),
                const SizedBox(width: 8),
                // Prefix field
                SizedBox(
                  width: 64,
                  child: TextFormField(
                    controller: prefixCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '24',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                    ),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 1 || n > 32) return '!';
                      return null;
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 16),

              // Preview
              if (prefixCtrl.text.isNotEmpty) ...[
                Builder(builder: (_) {
                  final prefix = int.tryParse(prefixCtrl.text);
                  if (prefix == null || prefix < 1 || prefix > 32) return const SizedBox.shrink();
                  final count = prefix >= 31 ? (32 - prefix) : (1 << (32 - prefix)) - 2;
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                    child: Row(children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text('จะ gen $count IP addresses',
                        style: TextStyle(fontSize: 13, color: Colors.blue.shade700)),
                    ]),
                  );
                }),
              ],
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              if (oct1.text.isEmpty || oct2.text.isEmpty || oct3.text.isEmpty) {
                _showSnack('กรอก subnet ให้ครบ', Colors.orange);
                return;
              }
              final subnet = '${oct1.text}.${oct2.text}.${oct3.text}';
              final prefix = int.parse(prefixCtrl.text);
              Navigator.pop(ctx);

              final result = await _api.bulkCreateIps(
                _selectedDomain!['Domain_id'] as int, subnet, prefix);

              if (result != null) {
                _showSnack(
                  'เพิ่ม ${result['inserted']} IPs (ข้าม ${result['skipped']} ที่มีอยู่แล้ว)',
                  Colors.green);
                _fetchIps(_selectedDomain!['Domain_id'] as int);
                setState(() => _selectedSubnet = subnet);
              } else {
                _showSnack('เกิดข้อผิดพลาด', Colors.red);
              }
            },
            child: const Text('Generate & Insert'),
          ),
        ],
      ),
    ));
  }

  // ════════════════════════════════════════════
  //  SUBNET DELETE
  // ════════════════════════════════════════════

  void _confirmDeleteSubnet(String subnetKey) {
    final ips   = _subnetMap[subnetKey] ?? [];
    final inUse = ips.where((ip) => ip['in_use'] == true).length;

    if (inUse > 0) {
      _showSnack('ลบไม่ได้ — มี $inUse IP ที่ใช้งานอยู่ใน $subnetKey', Colors.red);
      return;
    }

    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete Subnet', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text('ลบ IP ทั้งหมด ${ips.length} รายการใน $subnetKey ออกไหม?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () async {
            Navigator.pop(ctx);
            final pattern = _subnetToPattern(subnetKey);
            final result  = await _api.deleteSubnet(_selectedDomain!['Domain_id'] as int, pattern);
            if (result != null) {
              _showSnack('ลบ ${result['deleted']} IPs สำเร็จ', Colors.green);
              if (_selectedSubnet == subnetKey) setState(() => _selectedSubnet = null);
              _fetchIps(_selectedDomain!['Domain_id'] as int);
            } else {
              _showSnack('เกิดข้อผิดพลาด', Colors.red);
            }
          },
          child: const Text('Delete Subnet'),
        ),
      ],
    ));
  }

  // ════════════════════════════════════════════
  //  IP EDIT (ไม่มีลบ IP เดี่ยวแล้ว)
  // ════════════════════════════════════════════

  void _showIpDialog(Map<String, dynamic> existing) {
    final ipCtrl     = TextEditingController(text: existing['IP']);
    final prefixCtrl = TextEditingController(text: existing['Prefix']?.toString() ?? '');
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Edit IP', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(width: 360, child: Column(mainAxisSize: MainAxisSize.min, children: [
        _buildTextField(ipCtrl, 'IP Address', 'e.g., 10.98.4.200'),
        const SizedBox(height: 16),
        _buildTextField(prefixCtrl, 'Prefix', 'e.g., 24', isNumber: true),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          onPressed: () async {
            Navigator.pop(ctx);
            await _api.updateIp(existing['IP_id'] as int, ipCtrl.text.trim(), int.tryParse(prefixCtrl.text));
            _fetchIps(_selectedDomain!['Domain_id'] as int);
          },
          child: const Text('Save'),
        ),
      ],
    ));
  }

  void _confirmDeleteIp(Map<String, dynamic> ip) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete IP', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text('ลบ "${ip['IP']}" ออกไหม?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () async {
            Navigator.pop(ctx);
            final ok = await _api.deleteIp(ip['IP_id'] as int);
            if (ok) {
              _fetchIps(_selectedDomain!['Domain_id'] as int);
            } else {
              _showSnack('ลบไม่ได้ — IP นี้ถูกใช้งานอยู่', Colors.red);
            }
          },
          child: const Text('Delete'),
        ),
      ],
    ));
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    AppSnackbar.show(context, msg, color: color);
  }

  // ════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════

  Future<void> _importSubnetCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['csv'], withData: true);
    if (result == null || result.files.isEmpty) return;

    final bytes = result.files.first.bytes;
    if (bytes == null) return;

    final lines = String.fromCharCodes(bytes)
        .split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    if (lines.isEmpty) { AppSnackbar.error(context, 'ไฟล์ว่างเปล่า'); return; }

    final header = lines.first.split(',').map((h) => h.trim().toLowerCase()).toList();
    final required = ['domain_name', 'subnet', 'prefix'];
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
      MaterialPageRoute(builder: (_) => SubnetCsvPreviewScreen(rawRows: rows)));
    if (imported == true && _selectedDomain != null) {
      _fetchIps(_selectedDomain!['Domain_id'] as int);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subnetMap = _subnetMap;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ─── Top bar ───
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          OutlinedButton.icon(
            onPressed: widget.canEdit ? _importSubnetCsv : null,
            icon: const Icon(Icons.upload_file, size: 16),
            label: const Text('Import Subnet CSV',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6))),
          ),
        ]),
        const SizedBox(height: 16),

        // ─── Panels ───
        Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ─── Panel 1: Domain ───
        SizedBox(width: 220, child: _buildPanel(
          title: 'Domains',
          onAdd: widget.canEdit ? () => _showDomainDialog() : null,
          addLabel: 'Add',
          addColor: AppColors.primary,
          child: _loadingDomains
            ? const Center(child: CircularProgressIndicator())
            : _domains.isEmpty
              ? _emptyHint('ยังไม่มี Domain')
              : ListView.separated(
                  itemCount: _domains.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (_, i) {
                    final d = _domains[i];
                    final isSelected = _selectedDomain?['Domain_id'] == d['Domain_id'];
                    return InkWell(
                      onTap: () => _selectDomain(d),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
                        child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(d['Domain_Name'].toString(),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                                color: isSelected ? AppColors.primary : Colors.black87)),
                            if (d['Vlan'] != null)
                              Text('VLAN ${d['Vlan']}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          ])),
                          PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit')   _showDomainDialog(existing: d);
                              if (v == 'delete') _confirmDeleteDomain(d);
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'edit',   child: Text('Edit')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                            ],
                            child: Icon(Icons.more_vert, size: 16, color: Colors.grey.shade400),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
        )),

        const SizedBox(width: 12),

        // ─── Panel 2: Subnet ───
        SizedBox(width: 220, child: _buildPanel(
          title: 'Subnets',
          onAdd: (widget.canEdit && _selectedDomain != null) ? () => _showAddIpBlockDialog() : null,
          addLabel: '+ Block',
          addColor: AppColors.success,
          child: _selectedDomain == null
            ? _emptyHint('เลือก Domain')
            : _loadingIps
              ? const Center(child: CircularProgressIndicator())
              : subnetMap.isEmpty
                ? _emptyHint('ยังไม่มี IP')
                : ListView.separated(
                    itemCount: subnetMap.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (_, i) {
                      final subnet     = subnetMap.keys.elementAt(i);
                      final ips        = subnetMap[subnet]!;
                      final inUse      = ips.where((ip) => ip['in_use'] == true).length;
                      final isSelected = _selectedSubnet == subnet;
                      return InkWell(
                        onTap: () => setState(() => _selectedSubnet = subnet),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
                          child: Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(subnet, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                                color: isSelected ? AppColors.primary : Colors.black87)),
                              const SizedBox(height: 4),
                              Row(children: [
                                _miniChip('${ips.length} IPs', Colors.grey),
                                const SizedBox(width: 4),
                                if (inUse > 0) _miniChip('$inUse used', Colors.red),
                                if (ips.length - inUse > 0) _miniChip('${ips.length - inUse} free', Colors.green),
                              ]),
                            ])),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 16),
                              color: inUse > 0 ? Colors.grey.shade300 : Colors.red.shade300,
                              tooltip: inUse > 0 ? 'มี IP ที่ใช้งานอยู่' : 'Delete Subnet',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _confirmDeleteSubnet(subnet),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
        )),

        const SizedBox(width: 12),

        // ─── Panel 3: IP list ───
        Expanded(child: _buildPanel(
          title: _selectedSubnet != null ? 'IPs ใน $_selectedSubnet' : 'IP Addresses',
          onAdd: null,
          child: _selectedSubnet == null
            ? _emptyHint('เลือก Subnet')
            : _loadingIps
              ? const Center(child: CircularProgressIndicator())
              : _filteredIps.isEmpty
                ? _emptyHint('ไม่มี IP ใน subnet นี้')
                : Column(children: [
                    // header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
                      child: Row(children: [
                        Expanded(flex: 3, child: Text('IP ADDRESS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade600))),
                        Expanded(flex: 1, child: Text('PREFIX',    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade600))),
                        Expanded(flex: 2, child: Text('STATUS',    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade600))),
                        const SizedBox(width: 72),
                      ]),
                    ),
                    Expanded(child: ListView.separated(
                      itemCount: _filteredIps.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (_, i) {
                        final ip    = _filteredIps[i];
                        final inUse = ip['in_use'] == true;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(children: [
                            Expanded(flex: 3, child: Text(ip['IP'].toString(),
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
                            Expanded(flex: 1, child: Text(ip['Prefix'] != null ? '/${ip['Prefix']}' : '-',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
                            Expanded(flex: 2, child: _statusBadge(inUse)),
                            SizedBox(width: 40, child: IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 16), color: Colors.blueGrey,
                              tooltip: 'Edit', onPressed: inUse ? null : () => _showIpDialog(ip))),
                          ]),
                        );
                      },
                    )),
                  ]),
        )),
        ])),  // ปิด Row(panels) + Expanded + Column(page)
      ]),
    );
  }

  // ════════════════════════════════════════════
  //  HELPER WIDGETS
  // ════════════════════════════════════════════

  Widget _buildPanel({required String title, VoidCallback? onAdd, String addLabel = 'Add',
      Color addColor = AppColors.primary, Widget? extraAction, required Widget child}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        Row(mainAxisSize: MainAxisSize.min, children: [
          if (extraAction != null) ...[extraAction, const SizedBox(width: 6)],
          if (onAdd != null)
            ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(backgroundColor: addColor, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(0, 32),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              child: Text(addLabel),
            ),
        ]),
      ]),
      const SizedBox(height: 8),
      Expanded(child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8)),
        child: ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
      )),
    ]);
  }

  Widget _emptyHint(String text) {
    return Center(child: Text(text, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)));
  }

  Widget _statusBadge(bool inUse) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: inUse ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: inUse ? Colors.red.shade200 : Colors.green.shade200)),
      child: Text(inUse ? 'In Use' : 'Available',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
          color: inUse ? Colors.red.shade700 : Colors.green.shade700)),
    );
  }

  Widget _miniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildOctetField(TextEditingController ctrl) {
    return SizedBox(
      width: 52,
      child: TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: '0',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        ),
        validator: (v) {
          final n = int.tryParse(v ?? '');
          if (n == null || n < 0 || n > 255) return '!';
          return null;
        },
      ),
    );
  }

  Widget _dot() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 4),
    child: Text('.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.grey)),
  );

  Widget _buildTextField(TextEditingController ctrl, String label, String hint, {bool isNumber = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade400),
          filled: true, fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        ),
      ),
    ]);
  }
}