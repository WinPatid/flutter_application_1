// ไฟล์: lib/screens/node_assist_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/search_field.dart';
import '../widgets/dropdown_field.dart';
import '../widgets/network_table.dart';
import '../widgets/topology_diagram.dart';
import 'login_screen.dart';
import 'bulk_import_screen.dart';
import 'domain_screen.dart';
import 'site_screen.dart'; // 🚨 เพิ่ม Import ตรงนี้นะครับ 🚨

class NodeAssistScreen extends StatefulWidget {
  const NodeAssistScreen({super.key});

  @override
  State<NodeAssistScreen> createState() => _NodeAssistScreenState();
}

class _NodeAssistScreenState extends State<NodeAssistScreen> {
  final _api = ApiService();

  // ─── Navigation ───
  int _selectedMenuIndex = 0;

  // ─── Phase & Keys ───
  int _currentPhase = 1;
  Key _keyNodeId      = UniqueKey();
  Key _keyNodeName    = UniqueKey();
  Key _keyDomain      = UniqueKey();
  Key _keyIpAccess    = UniqueKey();
  Key _keyModel       = UniqueKey();
  Key _keyPort        = UniqueKey();
  Key _autocompleteKey = UniqueKey();

  // ─── Phase 1: Access ───
  String? selectedNodeId;
  int?    selectedNodeAcID;
  String? selectedNodeName;
  String? selectedAreaGroup;
  String? selectedDomain;
  int?    selectedDomainId;
  String? selectedIpAddress;
  int?    selectedIpAccessId;
  String? selectedModel;
  int?    selectedModelId;
  String? selectedPort;
  int?    selectedPortAccessId;
  int?    selectedSwitchAcId;
  int?    selectedTemplateId;

  // ─── Phase 2: Network ───
  String? selectedSiteCode;
  String? selectedSiteName;
  String? selectedNodeNetworkId;
  int?    selectedNodeNwID;
  String? selectedIpNetwork;
  int?    selectedIpNetworkId;
  String? selectedPortNetwork;
  int?    selectedPortNetworkId;
  int?    selectedSwitchNwId;
  final Map<String, String?> _tempSelectedPorts = {};
  final Map<String, String?> _tempIpNetworks    = {};

  bool _isConnectionTested = false;

  // ─── Dashboard mock data ───
  String _searchTableId   = '';
  String _searchTableName = '';
  final List<Map<String, dynamic>> _mockTableData = [
    {'id': '88860', 'name': 'บุญรอดบริวเวอรี่ คลังบางบัวทอง',              'isAvailable': false},
    {'id': '88861', 'name': '-',                                             'isAvailable': true},
    {'id': '88872', 'name': 'NEC Corporation (Thailand) LCo., Ltd.',        'isAvailable': false},
    {'id': '88895', 'name': 'บ. เถ้าแก่น้อย ฟู้ดแอนด์มาร์เก็ตติ้ง จก.',  'isAvailable': false},
    {'id': '88920', 'name': '-',                                             'isAvailable': true},
    {'id': '88938', 'name': 'สำนักงานสรรพากรพื้นที่นนทบุรี',               'isAvailable': false},
    {'id': '98352', 'name': 'บ. อิทธิพรอิมปอร์ต จก.(หลักสี่)',            'isAvailable': false},
    {'id': '98424', 'name': '-',                                             'isAvailable': true},
    {'id': '98447', 'name': 'อาคารการไฟฟ้าส่วนภูมิภาค',                   'isAvailable': false},
    {'id': '880234','name': 'BCH_17FL / WHB',                               'isAvailable': false},
  ];

  // ─── API Data ───
  List<Map<String, dynamic>> accessNodesRaw   = [];
  List<String> nodeIds    = [];
  List<String> nodeNames  = [];
  List<Map<String, dynamic>> domainRaw        = [];
  List<String> domains    = [];
  List<Map<String, dynamic>> ipRaw            = [];
  List<String> ipList         = [];
  List<String> ipNetworkList  = [];
  List<Map<String, dynamic>> modelsRaw        = [];
  List<String> models         = [];
  List<String> filteredSwitchPorts            = [];
  List<Map<String, dynamic>> templatePortsRaw = [];
  List<Map<String, dynamic>> networkNodesRaw  = [];
  Map<String, List<Map<String, dynamic>>> networkPortsByNode = {};
  bool _isLoadingNodes = false;
  String? _loadingPortsForNode;

  // ─── Site data ───
  List<Map<String, dynamic>> sitesRaw = [];
  List<String> get siteCodes => sitesRaw.map((e) => e['Site_code'].toString()).toList();

  final List<String> areaGroups = ['BKK', 'UPC'];

  // ════════════════════════════════════════════
  //  INIT & DATA LOADING
  // ════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final results = await Future.wait([
      _api.fetchAccessNodes(),
      _api.fetchDomains(),
      _api.fetchModels(),
      _api.fetchSites(),
    ]);

    setState(() {
      final nodes      = results[0];
      final domainData = results[1];
      final modelData  = results[2];
      final siteData   = results[3];

      accessNodesRaw = List<Map<String, dynamic>>.from(nodes);
      nodeIds        = nodes.map((n) => n['NodeAcID'].toString()).toList();
      nodeNames      = nodes.map((n) => n['NodeName'].toString()).toList();
      domainRaw      = List<Map<String, dynamic>>.from(domainData);
      domains        = domainData.map((d) => d['Domain_Name'].toString()).toList();
      modelsRaw      = List<Map<String, dynamic>>.from(modelData);
      models         = modelData.map((m) => m['Model_Name'].toString()).toList();
      sitesRaw       = List<Map<String, dynamic>>.from(siteData);
    });
  }

  Future<void> _loadNetworkNodesBySite(String siteCode) async {
    setState(() { _isLoadingNodes = true; networkPortsByNode = {}; });
    final nodes = await _api.fetchNetworkNodes(siteCode: siteCode);
    setState(() {
      networkNodesRaw = List<Map<String, dynamic>>.from(nodes);
      _isLoadingNodes = false;
    });
  }

  Future<void> _loadPortsForNode(String nodeId) async {
    if (networkPortsByNode.containsKey(nodeId)) return;
    setState(() => _loadingPortsForNode = nodeId);
    final ports = await _api.fetchNetworkNodePorts(int.parse(nodeId));
    setState(() {
      networkPortsByNode[nodeId] = List<Map<String, dynamic>>.from(ports);
      _loadingPortsForNode = null;
    });
  }

  Future<void> _loadIpsByDomain(String domainName) async {
    final domain = domainRaw.firstWhere((d) => d['Domain_Name'] == domainName, orElse: () => {});
    if (domain.isEmpty) return;
    final id  = domain['Domain_id'] as int;
    final ips = await _api.fetchIpsByDomain(id);
    setState(() {
      selectedDomainId    = id;
      ipRaw               = List<Map<String, dynamic>>.from(ips);
      ipList              = ips.map((ip) => ip['IP'].toString()).toList();
      ipNetworkList       = List.from(ipList);
      selectedIpAddress   = null;
      selectedIpAccessId  = null;
      selectedIpNetworkId = null;
      _keyIpAccess        = UniqueKey();
    });
  }

  Future<void> _loadPortsByModel(int modelId) async {
    final ports = await _api.fetchModelInterfaces(modelId: modelId);
    setState(() {
      templatePortsRaw    = List<Map<String, dynamic>>.from(ports);
      filteredSwitchPorts = ports.map((p) => p['Interface_Name'].toString()).toList();
      selectedPort        = null;
      selectedTemplateId  = null;
      _keyPort            = UniqueKey();
    });
  }

  // ════════════════════════════════════════════
  //  ACTIONS
  // ════════════════════════════════════════════

  void _clearData() {
    setState(() {
      selectedNodeId = null;        selectedNodeAcID = null;
      selectedNodeName = null;      selectedAreaGroup = null;
      selectedDomain = null;        selectedDomainId = null;
      selectedIpAddress = null;     selectedIpAccessId = null;
      selectedModel = null;         selectedModelId = null;
      selectedPort = null;          selectedPortAccessId = null;
      selectedSwitchAcId = null;    selectedTemplateId = null;
      filteredSwitchPorts = [];     templatePortsRaw = [];
      selectedSiteCode = null;      selectedSiteName = null;
      selectedNodeNetworkId = null; selectedNodeNwID = null;
      selectedIpNetwork = null;     selectedIpNetworkId = null;
      selectedPortNetwork = null;   selectedPortNetworkId = null;
      selectedSwitchNwId = null;
      networkNodesRaw = [];         networkPortsByNode = {};
      ipList = [];    ipNetworkList = [];    ipRaw = [];
      _tempSelectedPorts.clear();   _tempIpNetworks.clear();
      _currentPhase = 1;
      _autocompleteKey = UniqueKey();
      _isConnectionTested = false;
      _keyNodeId = UniqueKey();     _keyNodeName = UniqueKey();
      _keyDomain = UniqueKey();     _keyIpAccess = UniqueKey();
      _keyModel  = UniqueKey();     _keyPort     = UniqueKey();
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Form cleared successfully'), backgroundColor: Colors.blue));
  }

  void _submitData() {
    _isConnectionTested = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: TopologyDiagram(
            selectedSiteCode: selectedSiteCode,
            selectedSiteName: selectedSiteCode,
            selectedNodeNetworkId: selectedNodeNetworkId,
            selectedIpNetwork: selectedIpNetwork,
            selectedPortNetwork: selectedPortNetwork,
            selectedDomain: selectedDomain,
            selectedAreaGroup: selectedAreaGroup,
            selectedNodeId: selectedNodeId,
            selectedNodeName: selectedNodeName,
            selectedIpAddress: selectedIpAddress,
            selectedPort: selectedPort,
            selectedModel: selectedModel,
            isConnectionTested: _isConnectionTested,
            selectedNodeAcID: selectedNodeAcID,
            selectedTemplateId: selectedTemplateId,
            selectedIpAccessId: selectedIpAccessId,
            selectedModelId: selectedModelId,
            selectedNodeNwID: selectedNodeNwID,
            selectedPortNetworkId: selectedPortNetworkId,
            selectedIpNetworkId: selectedIpNetworkId,
            selectedSwitchNwId: selectedSwitchNwId,
            api: _api,
            onTestConnection: () {},
            onBack: () => Navigator.pop(context),
            onSuccess: _clearData,
          ),
        ),
      ),
    );
  }

  void _handleLogout() {
    Navigator.pushReplacement(context, PageRouteBuilder(
      pageBuilder: (_, __, ___) => const LoginScreen(),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }

  void _showAdminPopup() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80, height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF0056B3), Color(0xFF4A88C7)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight)),
                child: const Icon(Icons.person, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 16),
              const Text('Admin User', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 4),
              Text('Network Engineer', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _buildInfoRow(Icons.badge_outlined,        'Role',         'Administrator'),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.business_outlined,     'Organization', 'IIH Core Network'),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.verified_user_outlined,'Access Level', 'Full Access'),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () { Navigator.pop(ctx); _handleLogout(); },
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 18, color: Colors.blueAccent),
      const SizedBox(width: 10),
      Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
      Expanded(child: Text(value, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
    ]);
  }

  // ════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Row(
        children: [
          // ─── Sidebar ───
          Container(
            width: 240,
            color: const Color(0xFF1A1D23),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: Row(children: [
                    const Icon(Icons.hub_outlined, color: Colors.blueAccent, size: 28),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                      Text('NODE ASSIST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1)),
                      Text('PRO', style: TextStyle(color: Colors.blueAccent, fontSize: 11, letterSpacing: 3)),
                    ]),
                  ]),
                ),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 8),
                _buildSidebarItem(Icons.dashboard_outlined,   'Dashboard',        0),
                _buildSidebarItem(Icons.add_circle_outline,   'Search & Reserve', 1),
                _buildSidebarItem(Icons.hub_outlined,         'Topology Map',     2),
                _buildSidebarItem(Icons.upload_file_outlined, 'Bulk Import',      3),
                _buildSidebarItem(Icons.dns_outlined,         'Domain & IP',      4),
                // 🚨 เมนูใหม่ที่เพิ่มเข้ามาครับ 🚨
                _buildSidebarItem(Icons.business_outlined,    'Site Code',        5), 
                const Spacer(),
                const Divider(color: Colors.white12, height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                  title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
                  onTap: _handleLogout,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // ─── Main Content ───
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedMenuIndex == 0 ? 'Dashboard'
                          : _selectedMenuIndex == 1 ? 'Search & Reserve'
                          : _selectedMenuIndex == 2 ? 'Topology Map'
                          : _selectedMenuIndex == 3 ? 'Bulk Import'
                          : _selectedMenuIndex == 4 ? 'Domain & IP'
                          : 'Site Code', // อัพเดตชื่อหัวข้อตามเมนูใหม่
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      // Admin User Button
                      InkWell(
                        onTap: _showAdminPopup,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(8)),
                          child: Row(children: [
                            Container(
                              width: 32, height: 32,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Color(0xFF0056B3), Color(0xFF4A88C7)],
                                  begin: Alignment.topLeft, end: Alignment.bottomRight)),
                              child: const Icon(Icons.person, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('Admin User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                              Text('Network Engineer', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            ]),
                            const SizedBox(width: 8),
                            Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade400, size: 18),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),

                // Page content (ส่วนนี้จัดการการแสดงผลหน้าจอต่างๆ)
                Expanded(
                  child: _selectedMenuIndex == 0
                    ? _buildDashboardPage()
                    : _selectedMenuIndex == 1
                      ? _buildSearchAndReservePage()
                      : _selectedMenuIndex == 2
                        ? _buildTopologyMockPage()
                        : _selectedMenuIndex == 3
                          ? const BulkImportScreen()
                          : _selectedMenuIndex == 4
                            ? const DomainScreen()
                            : const SiteScreen(), // 🚨 ผูกหน้าจอใหม่เข้ากับ Index ที่ 5
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════
  //  PAGE: Dashboard
  // ════════════════════════════════════════════

  Widget _buildDashboardPage() {
    final filtered = _mockTableData.where((row) {
      final matchId   = row['id'].toString().contains(_searchTableId);
      final matchName = row['name'].toString().toLowerCase().contains(_searchTableName.toLowerCase());
      return matchId && matchName;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(children: [
              Expanded(child: TextField(onChanged: (v) => setState(() => _searchTableId = v), decoration: _searchDecor('Search ID...', Icons.search))),
              const SizedBox(width: 16),
              Expanded(child: TextField(onChanged: (v) => setState(() => _searchTableName = v), decoration: _searchDecor('Search Name...', Icons.search))),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              child: SizedBox(
                width: double.infinity,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                  columns: const [
                    DataColumn(label: Text('Node ID',   style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Node Name', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Status',    style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Action',    style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: filtered.map((node) {
                    final isAvailable = node['isAvailable'] as bool;
                    return DataRow(cells: [
                      DataCell(Text(node['id'], style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(node['name'], overflow: TextOverflow.ellipsis)),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAvailable ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: isAvailable ? Colors.green.shade200 : Colors.red.shade200)),
                        child: Text(isAvailable ? 'Available' : 'In Use',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                            color: isAvailable ? Colors.green.shade700 : Colors.red.shade700)),
                      )),
                      DataCell(Row(children: [
                        if (isAvailable)
                          ElevatedButton.icon(
                            onPressed: () { _clearData(); setState(() { selectedNodeId = node['id']; _selectedMenuIndex = 1; _autocompleteKey = UniqueKey(); }); },
                            icon: const Icon(Icons.touch_app, size: 16),
                            label: const Text('เลือก', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0056B3), foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: const Size(0, 36),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                          ),
                      ])),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════
  //  PAGE: Search & Reserve
  // ════════════════════════════════════════════

  Widget _buildSearchAndReservePage() {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Row(children: [
          _buildPhaseIndicator(1, "ข้อมูล LSW Access", _currentPhase >= 1),
          Expanded(child: Divider(color: _currentPhase == 2 ? const Color(0xFF0056B3) : Colors.grey.shade300, thickness: 2)),
          _buildPhaseIndicator(2, "ข้อมูล LSW Network", _currentPhase == 2),
        ]),
      ),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Phase 1 ──
            if (_currentPhase == 1) ...[
              _buildStepHeader('1. ข้อมูล LSW Access'),
              Padding(padding: const EdgeInsets.all(24), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _buildNodeIdField()),
                const SizedBox(width: 20),
                Expanded(child: SearchField(label: 'Search Node Name', hint: 'Type to search name',
                  items: nodeNames, initialValue: selectedNodeName,
                  onSelected: (val) => setState(() => selectedNodeName = val), fieldKey: _keyNodeName)),
                const SizedBox(width: 20),
                Expanded(child: DropdownField(label: 'Select Area Group', items: areaGroups,
                  currentValue: selectedAreaGroup, onChanged: (val) => setState(() => selectedAreaGroup = val))),
              ])),
              Padding(padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24), child: Row(children: [
                Expanded(child: SearchField(label: 'Select Domain', hint: 'Type to search domain...',
                  items: domains, initialValue: selectedDomain,
                  onSelected: (val) {
                    setState(() { selectedDomain = val; selectedIpAddress = null; ipList = []; ipNetworkList = []; ipRaw = []; });
                    final d = domainRaw.firstWhere((d) => d['Domain_Name'] == val, orElse: () => {});
                    if (d.isNotEmpty) _loadIpsByDomain(val);
                  }, fieldKey: _keyDomain, showAllOnEmpty: true)),
                const SizedBox(width: 20),
                Expanded(child: SearchField(label: 'Search IP Assist', hint: 'e.g., 10.98.4.200...',
                  items: ipList, initialValue: selectedIpAddress,
                  onSelected: (val) {
                    final ip = ipRaw.firstWhere((i) => i['IP'].toString() == val, orElse: () => {});
                    setState(() { selectedIpAddress = val; selectedIpAccessId = ip.isNotEmpty ? ip['IP_id'] as int : null; });
                  }, isDisabled: selectedDomain == null, fieldKey: _keyIpAccess)),
              ])),
              Padding(padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24), child: Row(children: [
                Expanded(child: SearchField(label: 'Select Model (LAN Switch)', hint: 'Type to search model...',
                  items: models, initialValue: selectedModel,
                  onSelected: (val) {
                    final m = modelsRaw.firstWhere((m) => m['Model_Name'] == val, orElse: () => {});
                    final mid = m.isNotEmpty ? m['Model_Id'] as int : null;
                    setState(() { selectedModel = val; selectedModelId = mid; selectedPort = null; selectedTemplateId = null; filteredSwitchPorts = []; });
                    if (mid != null) _loadPortsByModel(mid);
                  }, fieldKey: _keyModel)),
                const SizedBox(width: 20),
                Expanded(child: SearchField(label: 'Select Switch Port', hint: 'Type to search port...',
                  items: filteredSwitchPorts, initialValue: selectedPort,
                  onSelected: (val) {
                    final t = templatePortsRaw.firstWhere((t) => t['Interface_Name'] == val, orElse: () => {});
                    setState(() { selectedPort = val; selectedTemplateId = t.isNotEmpty ? t['Template_ID'] as int : null; });
                  }, isDisabled: selectedModel == null, fieldKey: _keyPort, showAllOnEmpty: true)),
              ])),
            ],

            // ── Phase 2 ──
            if (_currentPhase == 2) ...[
              _buildStepHeader('2. ข้อมูล LSW Network'),
              Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Site Code + Site Name
                Row(children: [
                  Expanded(child: SearchField(label: 'Search Site Code LSW', hint: 'e.g., BCH-5012-UR',
                    items: siteCodes, initialValue: selectedSiteCode,
                    onSelected: (val) {
                      final site = sitesRaw.firstWhere((s) => s['Site_code'].toString() == val, orElse: () => {});
                      setState(() {
                        selectedSiteCode = val;
                        selectedSiteName = site.isNotEmpty ? site['Site_code'].toString() : null;
                        selectedNodeNetworkId = null; selectedNodeNwID = null;
                        selectedPortNetwork = null;   selectedPortNetworkId = null;
                        selectedSwitchNwId = null;    selectedIpNetwork = null;
                        selectedIpNetworkId = null;
                        networkNodesRaw = [];         networkPortsByNode = {};
                        _tempSelectedPorts.clear();   _tempIpNetworks.clear();
                      });
                      _loadNetworkNodesBySite(val);
                    })),
                  const SizedBox(width: 20),
                  // Site Name (read-only, auto-filled)
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Site Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF495057))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300)),
                      child: Row(children: [
                        Icon(Icons.location_on_outlined, size: 18, color: Colors.grey.shade400),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          selectedSiteName ?? 'Auto-filled from Site Code',
                          style: TextStyle(color: selectedSiteName != null ? const Color(0xFF0F172A) : Colors.grey.shade400, fontSize: 14),
                        )),
                      ]),
                    ),
                  ])),
                ]),

                // Loading / count badge
                if (selectedSiteCode?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    if (_isLoadingNodes)
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    else
                      const Icon(Icons.filter_list, size: 16, color: Colors.blueGrey),
                    const SizedBox(width: 6),
                    Text(
                      _isLoadingNodes
                        ? 'กำลังโหลด nodes ใน $selectedSiteCode...'
                        : 'แสดง ${networkNodesRaw.length} nodes ใน $selectedSiteCode'
                          '${networkNodesRaw.isEmpty ? " (ไม่พบ node ใน site นี้)" : ""}',
                      style: TextStyle(
                        fontSize: 13,
                        color: (!_isLoadingNodes && networkNodesRaw.isEmpty) ? Colors.orange.shade700 : Colors.blueGrey.shade700,
                        fontStyle: FontStyle.italic),
                    ),
                  ]),
                ],

                // Site info banner
                if (!_isLoadingNodes && (selectedSiteCode?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 30),
                  if (selectedSiteCode != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue.shade100)),
                      child: Row(children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text('Site Code: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue.shade700)),
                        Text(selectedSiteCode!, style: TextStyle(fontSize: 13, color: Colors.blue.shade700)),
                        if (selectedSiteName != null) ...[
                          Text('  |  Site Name: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue.shade700)),
                          Text(selectedSiteName!, style: TextStyle(fontSize: 13, color: Colors.blue.shade700)),
                        ],
                      ]),
                    ),

                  NetworkSelectionTable(
                    networkNodesRaw: networkNodesRaw,
                    networkPortsByNode: networkPortsByNode,
                    loadingPortsForNode: _loadingPortsForNode,
                    ipNetworkList: ipNetworkList,
                    ipRaw: ipRaw,
                    selectedNodeNetworkId: selectedNodeNetworkId,
                    siteCode: selectedSiteCode,
                    tempSelectedPorts: _tempSelectedPorts,
                    tempIpNetworks: _tempIpNetworks,
                    onNodeExpanded: (nodeId) => _loadPortsForNode(nodeId),
                    onShowDiagram: _submitData,
                    onPortChanged: (netId, val) => setState(() => _tempSelectedPorts[netId] = val),
                    onIpChanged: (netId, val) => setState(() => _tempIpNetworks[netId] = val),
                    onSelect: (netId, nodeNwID, port, portId, switchNwId, ip, ipId) {
                      setState(() {
                        selectedNodeNetworkId = netId;    selectedNodeNwID      = nodeNwID;
                        selectedPortNetwork   = port;     selectedPortNetworkId = portId;
                        selectedSwitchNwId    = switchNwId;
                        selectedIpNetwork     = ip;       selectedIpNetworkId   = ipId;
                      });
                    },
                  ),
                ],
              ])),
            ],

            // Bottom bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(color: const Color(0xFFF8F9FA), border: Border(top: BorderSide(color: Colors.grey.shade300))),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                if (_currentPhase == 2)
                  OutlinedButton.icon(onPressed: () => setState(() => _currentPhase = 1),
                    icon: const Icon(Icons.arrow_back), label: const Text('Back'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)))
                else
                  TextButton(onPressed: _clearData,
                    child: const Text('Clear Form Data', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
                if (_currentPhase == 1)
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _currentPhase = 2),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056B3), foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                    icon: const Icon(Icons.arrow_forward, size: 20),
                    label: const Text('Next Step', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))
                else
                  const SizedBox.shrink(),
              ]),
            ),
          ]),
        ),
      )),
      const SizedBox(height: 40),
    ]);
  }

  // ════════════════════════════════════════════
  //  PAGE: Topology Mock
  // ════════════════════════════════════════════

  Widget _buildTopologyMockPage() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.hub_outlined, size: 100, color: Colors.grey.shade300),
      const SizedBox(height: 20),
      Text('Interactive Topology Mapper', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
      const SizedBox(height: 10),
      Text('Live visualization module is currently under development.',
        textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
      const SizedBox(height: 30),
      ElevatedButton.icon(
        onPressed: () => setState(() => _selectedMenuIndex = 1),
        icon: const Icon(Icons.add), label: const Text('Create New Reservation'),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056B3), foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16))),
    ]));
  }

  // ════════════════════════════════════════════
  //  HELPER WIDGETS
  // ════════════════════════════════════════════

  Widget _buildSidebarItem(IconData icon, String label, int index) {
    final isSelected = _selectedMenuIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blueAccent : Colors.white54, size: 20),
      title: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white70,
        fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      tileColor: isSelected ? Colors.white.withOpacity(0.08) : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      onTap: () => setState(() => _selectedMenuIndex = index),
    );
  }

  Widget _buildPhaseIndicator(int phase, String label, bool isActive) {
    return Column(children: [
      Container(width: 32, height: 32,
        decoration: BoxDecoration(shape: BoxShape.circle,
          color: isActive ? const Color(0xFF0056B3) : Colors.grey.shade300),
        child: Center(child: Text('$phase', style: TextStyle(
          color: isActive ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold)))),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 12,
        color: isActive ? const Color(0xFF0056B3) : Colors.grey.shade500,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
    ]);
  }

  Widget _buildStepHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))));
  }

  InputDecoration _searchDecor(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint, prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade400),
      filled: true, fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5)));
  }

  Widget _buildNodeIdField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Search Node ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF495057))),
      const SizedBox(height: 8),
      LayoutBuilder(builder: (context, constraints) {
        return Autocomplete<String>(
          key: _autocompleteKey,
          initialValue: TextEditingValue(text: selectedNodeId ?? ''),
          optionsBuilder: (tv) {
            if (tv.text.isEmpty) return const Iterable<String>.empty();
            final base = int.tryParse(tv.text);
            if (base != null) return List.generate(5, (i) => (base + i).toString());
            return nodeIds.where((id) => id.contains(tv.text));
          },
          onSelected: (val) {
            final node = accessNodesRaw.firstWhere((n) => n['NodeAcID'].toString() == val, orElse: () => {});
            setState(() { selectedNodeId = val; selectedNodeAcID = node.isNotEmpty ? node['NodeAcID'] as int : null; });
          },
          fieldViewBuilder: (context, controller, focusNode, _) {
            return TextField(
              controller: controller, focusNode: focusNode,
              onChanged: (val) => setState(() => selectedNodeId = val),
              decoration: InputDecoration(
                hintText: 'e.g., 99012', hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true, fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Colors.blue, width: 2)),
                suffixIcon: const Icon(Icons.search, color: Colors.grey, size: 20)));
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(alignment: Alignment.topLeft,
              child: Material(elevation: 4, child: Container(
                width: constraints.maxWidth, constraints: const BoxConstraints(maxHeight: 250),
                child: ListView.builder(padding: EdgeInsets.zero, shrinkWrap: true, itemCount: options.length,
                  itemBuilder: (_, i) {
                    final option = options.elementAt(i);
                    final isAvail = int.parse(option) % 2 == 0;
                    return InkWell(onTap: () => onSelected(option),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(option, style: const TextStyle(fontWeight: FontWeight.w500)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isAvail ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: isAvail ? Colors.green.shade200 : Colors.red.shade200)),
                            child: Text(isAvail ? 'ว่าง' : 'ไม่ว่าง',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                                color: isAvail ? Colors.green.shade700 : Colors.red.shade700))),
                        ])));
                  }))));
          });
      }),
    ]);
  }
}