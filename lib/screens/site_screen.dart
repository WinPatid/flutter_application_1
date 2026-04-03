// ไฟล์: lib/screens/site_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/theme.dart';

class SiteScreen extends StatefulWidget {
  const SiteScreen({super.key});

  @override
  State<SiteScreen> createState() => _SiteScreenState();
}

class _SiteScreenState extends State<SiteScreen> {
  final _api = ApiService();

  // ข้อมูลฝั่ง Site 
  List<Map<String, dynamic>> _sites = [];
  List<Map<String, dynamic>> _siteNodes = []; 
  Map<String, dynamic>? _selectedSite;
  bool _loadingSites = false;
  bool _loadingSiteData = false;

  String _searchSite = '';

  @override
  void initState() {
    super.initState();
    _fetchSites();
  }

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
    setState(() { 
      _selectedSite = site; 
      _siteNodes = []; 
    });
    _fetchSiteData(site['Site_code'].toString());
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final filteredSites = _sites.where((s) => 
      (s['Site_code']?.toString() ?? '').toLowerCase().contains(_searchSite.toLowerCase()) ||
      (s['Site_name']?.toString() ?? '').toLowerCase().contains(_searchSite.toLowerCase())
    ).toList();

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ─── Left Panel (Site Codes) ───
        SizedBox(
          width: 320,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Site Codes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              ElevatedButton.icon(
                onPressed: () => _showSnack('ฟังก์ชัน Add Site รอ Backend จัดการ', Colors.blue),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 12),
            
            // ช่องค้นหา Site
            SizedBox(
              height: 38,
              child: TextField(
                onChanged: (val) => setState(() => _searchSite = val),
                decoration: InputDecoration(
                  hintText: 'Search site code or name...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade400),
                  filled: true, fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                child: _loadingSites
                  ? const Center(child: CircularProgressIndicator())
                  : filteredSites.isEmpty
                    ? Center(child: Text('ไม่พบข้อมูล', style: TextStyle(color: Colors.grey.shade400)))
                    : ListView.separated(
                        itemCount: filteredSites.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (_, i) {
                          final s = filteredSites[i];
                          final isSelected = _selectedSite?['Site_code'] == s['Site_code'];
                          return InkWell(
                            onTap: () => _selectSite(s),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
                              child: Row(children: [
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(s['Site_code']?.toString() ?? 'Unknown Code',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                                      color: isSelected ? AppColors.primary : Colors.black87)),
                                  Text('Site name: ${s['Site_name']?.toString() ?? '-'}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                ])),
                                PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') _showSnack('ฟังก์ชัน Edit Site รอ Backend จัดการ', Colors.orange);
                                    if (v == 'delete') _showSnack('ฟังก์ชัน Delete Site รอ Backend จัดการ', Colors.orange);
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

        const SizedBox(width: 32),

        // ─── Right Panel (Network Nodes) ───
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(
                _selectedSite == null 
                  ? 'เลือก Site Code เพื่อดูข้อมูล' 
                  : 'Network Nodes ใน Site: ${_selectedSite!['Site_code']}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (_selectedSite != null)
                ElevatedButton.icon(
                  onPressed: () => _showSnack('ฟังก์ชัน Add Node รอ Backend จัดการ', Colors.green),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Node', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
            ]),
            const SizedBox(height: 12),
            
            if (_selectedSite == null)
              Expanded(child: Container(
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.business_outlined, size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('กรุณาเลือกเมนูด้านซ้ายเพื่อดูข้อมูล', style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
                ])),
              ))
            else if (_loadingSiteData)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
                    child: Row(children: [
                      Expanded(flex: 3, child: Text('NODE NAME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade600))),
                      Expanded(flex: 1, child: Text('NETWORK ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade600))),
                      Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade600))),
                      const SizedBox(width: 80, child: Text('ACTION', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    ]),
                  ),
                  Expanded(
                    child: _siteNodes.isEmpty
                      ? Center(child: Text('ไม่พบ Network Node ใน Site นี้', style: TextStyle(color: Colors.grey.shade400)))
                      : ListView.separated(
                          itemCount: _siteNodes.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                          itemBuilder: (_, i) {
                            final node = _siteNodes[i];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Row(children: [
                                Expanded(flex: 3, child: Text(node['NodeName'].toString(), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
                                Expanded(flex: 1, child: Text(node['NodeNwID'].toString(), style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
                                Expanded(flex: 2, child: _buildStatusBadge(false)),
                                SizedBox(width: 80, child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18), color: Colors.blueGrey, tooltip: 'Edit', 
                                      onPressed: () => _showSnack('รอ Backend เขียนระบบแก้ Node', Colors.orange),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18), color: Colors.red.shade400, tooltip: 'Delete', 
                                      onPressed: () => _showSnack('รอ Backend เขียนระบบลบ Node', Colors.orange),
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

  Widget _buildStatusBadge(bool isOffline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOffline ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isOffline ? Colors.red.shade200 : Colors.green.shade200)),
      child: Text(isOffline ? 'Offline' : 'Available',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
          color: isOffline ? Colors.red.shade700 : Colors.green.shade700)),
    );
  }
}