// ไฟล์: lib/screens/domain_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DomainScreen extends StatefulWidget {
  const DomainScreen({super.key});

  @override
  State<DomainScreen> createState() => _DomainScreenState();
}

class _DomainScreenState extends State<DomainScreen> {
  final _api = ApiService();

  List<Map<String, dynamic>> _domains = [];
  List<Map<String, dynamic>> _ips     = [];
  Map<String, dynamic>? _selectedDomain;
  bool _loadingDomains = false;
  bool _loadingIps     = false;

  @override
  void initState() {
    super.initState();
    _fetchDomains();
  }

  // ════════════════════════════════════════════
  //  DATA LOADING
  // ════════════════════════════════════════════

  Future<void> _fetchDomains() async {
    setState(() => _loadingDomains = true);
    final data = await _api.fetchDomains();
    setState(() { _domains = data; _loadingDomains = false; });
  }

  Future<void> _fetchIps(int domainId) async {
    setState(() => _loadingIps = true);
    final data = await _api.fetchIpsByDomain(domainId);
    // เช็ค in_use ผ่าน ac_interfaces / nw_interfaces
    final ipsWithStatus = await _api.fetchIpsWithStatus(domainId);
    setState(() { _ips = ipsWithStatus; _loadingIps = false; });
  }

  void _selectDomain(Map<String, dynamic> domain) {
    setState(() { _selectedDomain = domain; _ips = []; });
    _fetchIps(domain['Domain_id'] as int);
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
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056B3), foregroundColor: Colors.white),
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
                setState(() { _selectedDomain = null; _ips = []; });
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
  //  IP DIALOGS
  // ════════════════════════════════════════════

  void _showIpDialog({Map<String, dynamic>? existing}) {
    final ipCtrl     = TextEditingController(text: existing?['IP'] ?? '');
    final prefixCtrl = TextEditingController(text: existing?['Prefix']?.toString() ?? '');

    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(existing == null ? 'Add IP' : 'Edit IP',
        style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(width: 360, child: Column(mainAxisSize: MainAxisSize.min, children: [
        _buildTextField(ipCtrl, 'IP Address', 'e.g., 10.98.4.200'),
        const SizedBox(height: 16),
        _buildTextField(prefixCtrl, 'Prefix (optional)', 'e.g., 24', isNumber: true),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056B3), foregroundColor: Colors.white),
          onPressed: () async {
            Navigator.pop(ctx);
            if (existing == null) {
              await _api.createIp(_selectedDomain!['Domain_id'] as int,
                ipCtrl.text.trim(), int.tryParse(prefixCtrl.text));
            } else {
              await _api.updateIp(existing['IP_id'] as int,
                ipCtrl.text.trim(), int.tryParse(prefixCtrl.text));
            }
            _fetchIps(_selectedDomain!['Domain_id'] as int);
          },
          child: Text(existing == null ? 'Add' : 'Save'),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // ════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ─── Domain List (left panel) ───
        SizedBox(
          width: 300,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Domains', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _showDomainDialog(),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056B3), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8)),
                child: _loadingDomains
                  ? const Center(child: CircularProgressIndicator())
                  : _domains.isEmpty
                    ? Center(child: Text('ยังไม่มี Domain', style: TextStyle(color: Colors.grey.shade400)))
                    : ListView.separated(
                        itemCount: _domains.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (_, i) {
                          final d = _domains[i];
                          final isSelected = _selectedDomain?['Domain_id'] == d['Domain_id'];
                          return InkWell(
                            onTap: () => _selectDomain(d),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              color: isSelected ? const Color(0xFF0056B3).withOpacity(0.08) : Colors.transparent,
                              child: Row(children: [
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(d['Domain_Name'].toString(),
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                                      color: isSelected ? const Color(0xFF0056B3) : Colors.black87)),
                                  if (d['Vlan'] != null)
                                    Text('VLAN ${d['Vlan']}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                ])),
                                PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') _showDomainDialog(existing: d);
                                    if (v == 'delete') _confirmDeleteDomain(d);
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(value: 'edit',   child: Text('Edit')),
                                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                                  ],
                                  child: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade400),
                                ),
                              ]),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ]),
        ),

        const SizedBox(width: 24),

        // ─── IP List (right panel) ───
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(
                _selectedDomain == null
                  ? 'เลือก Domain เพื่อดู IP'
                  : 'IPs ใน ${_selectedDomain!['Domain_Name']}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (_selectedDomain != null)
                ElevatedButton.icon(
                  onPressed: () => _showIpDialog(),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF28A745), foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add IP', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
            ]),
            const SizedBox(height: 12),

            if (_selectedDomain == null)
              Expanded(child: Container(
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200)),
                child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.dns_outlined, size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('เลือก Domain จากด้านซ้าย', style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
                ])),
              ))
            else if (_loadingIps)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300)),
                child: Column(children: [
                  // header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
                    child: Row(children: [
                      Expanded(flex: 3, child: Text('IP ADDRESS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade600))),
                      Expanded(flex: 1, child: Text('PREFIX', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade600))),
                      Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade600))),
                      const SizedBox(width: 80, child: Text('ACTION', textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    ]),
                  ),
                  Expanded(
                    child: _ips.isEmpty
                      ? Center(child: Text('ยังไม่มี IP ใน domain นี้', style: TextStyle(color: Colors.grey.shade400)))
                      : ListView.separated(
                          itemCount: _ips.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                          itemBuilder: (_, i) {
                            final ip = _ips[i];
                            final inUse = ip['in_use'] == true;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Row(children: [
                                Expanded(flex: 3, child: Text(ip['IP'].toString(),
                                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
                                Expanded(flex: 1, child: Text(
                                  ip['Prefix'] != null ? '/${ip['Prefix']}' : '-',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
                                Expanded(flex: 2, child: _buildIpStatusBadge(inUse)),
                                SizedBox(width: 80, child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18),
                                      color: Colors.blueGrey,
                                      tooltip: 'Edit',
                                      onPressed: inUse ? null : () => _showIpDialog(existing: ip),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18),
                                      color: inUse ? Colors.grey.shade300 : Colors.red.shade400,
                                      tooltip: inUse ? 'ใช้งานอยู่ ลบไม่ได้' : 'Delete',
                                      onPressed: inUse ? null : () => _confirmDeleteIp(ip),
                                    ),
                                  ],
                                )),
                              ]),
                            );
                          },
                        ),
                  ),
                ]),
              )),
          ]),
        ),
      ]),
    );
  }

  Widget _buildIpStatusBadge(bool inUse) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: inUse ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: inUse ? Colors.red.shade200 : Colors.green.shade200)),
      child: Text(inUse ? 'In Use' : 'Available',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
          color: inUse ? Colors.red.shade700 : Colors.green.shade700)),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, String hint, {bool isNumber = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF495057))),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade400),
          filled: true, fillColor: const Color(0xFFF8F9FA),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFF0056B3), width: 2)),
        ),
      ),
    ]);
  }
}