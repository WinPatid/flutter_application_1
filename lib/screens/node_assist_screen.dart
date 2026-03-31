// ไฟล์: lib/screens/node_assist_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/search_field.dart';
import '../widgets/dropdown_field.dart';
import '../widgets/network_table.dart';
import '../widgets/topology_diagram.dart';
import 'login_screen.dart';

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
  List<Map<String, dynamic>> networkPortsRaw  = [];
  List<String> networkPorts   = [];

  // ─── Site mock data ───
  final List<Map<String, String>> mockSites = [
    {'code': 'AYA-5024-UR', 'name': 'ประตูน้ำพระอินทร์ (UIH)'},
    {'code': 'BCH-5012-UR', 'name': 'True IDC เมืองทองธานี ชั้น 8 (Data Center) Rack 5G05A'},
    {'code': 'BCH-5013-UR', 'name': 'Jastel ชั้น 6 (Data Center)'},
    {'code': 'BCH-5018-UR', 'name': 'SBN แจ้งวัฒนะ (Data Center)'},
  ];
  List<String> get siteCodes => mockSites.map((e) => e['code']!).toList();
  List<String> get siteNames => mockSites.map((e) => e['name']!).toSet().toList();

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
    final nodes           = await _api.fetchAccessNodes();
    final domainData      = await _api.fetchDomains();
    final modelData       = await _api.fetchModels();
    final networkNodes    = await _api.fetchNetworkNodes();
    final networkPortData = await _api.fetchNetworkInterfaces();

    setState(() {
      accessNodesRaw   = List<Map<String, dynamic>>.from(nodes);
      nodeIds          = nodes.map((n) => n['NodeAcID'].toString()).toList();
      nodeNames        = nodes.map((n) => n['NodeName'].toString()).toList();
      domainRaw        = List<Map<String, dynamic>>.from(domainData);
      domains          = domainData.map((d) => d['Domain_Name'].toString()).toList();
      modelsRaw        = List<Map<String, dynamic>>.from(modelData);
      models           = modelData.map((m) => m['Model_Name'].toString()).toList();
      networkNodesRaw  = List<Map<String, dynamic>>.from(networkNodes);
      networkPortsRaw  = List<Map<String, dynamic>>.from(networkPortData);
      networkPorts     = networkPortData.map((p) => p['Interface_Name'].toString()).toList();
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
            selectedSiteName: selectedSiteName,
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
            onTestConnection: () => _handleTestConnection(setStateDialog),
            onBack: () => Navigator.pop(context),
            onSuccess: _clearData,
          ),
        ),
      ),
    );
  }

  void _handleTestConnection(StateSetter setStateDialog) {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
    );
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pop(context);
      final details = <Widget>[];
      void add(String label, String? val) {
        if (val != null && val.trim().isNotEmpty) {
          details.add(Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('$label: $val', style: const TextStyle(color: Colors.white70, fontSize: 14))));
        }
      }
      add('Node ID', selectedNodeId);       add('Node Name', selectedNodeName);
      add('Area Group', selectedAreaGroup); add('Domain', selectedDomain);
      add('IP Assist', selectedIpAddress);  add('Model', selectedModel);
      add('Switch Port', selectedPort);     add('Site Code', selectedSiteCode);
      add('Network ID', selectedNodeNetworkId); add('IP Network', selectedIpNetwork);
      add('Port Network', selectedPortNetwork);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF2B2B2B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white12)),
          title: const Text('Succeeded', style: TextStyle(color: Color(0xFFA5D63F), fontWeight: FontWeight.bold, fontSize: 24)),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: details.isEmpty
              ? [const Text('No configuration data.', style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic))]
              : details),
          actions: [
            ElevatedButton(
              onPressed: () { Navigator.pop(ctx); setStateDialog(() => _isConnectionTested = true); },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A88C7), foregroundColor: Colors.white),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    });
  }

  void _handleLogout() {
    Navigator.pushReplacement(context, PageRouteBuilder(
      pageBuilder: (_, __, ___) => const LoginScreen(),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 400),
    ));
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
          // Sidebar
          Container(
            width: 250, color: const Color(0xFF212529),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 60, width: double.infinity, color: const Color(0xFF1A1D20),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: const Text('NODE ASSIST PRO',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 10),
                _buildSidebarItem(Icons.dashboard,          'Node Availability',  0),
                _buildSidebarItem(Icons.search,             'Search & Reserve',   1),
                _buildSidebarItem(Icons.settings_ethernet,  'Network Topology',   2),
                const Spacer(),
                const Divider(color: Colors.white24),
                Container(
                  padding: const EdgeInsets.all(20),
                  child: const Text('Version 1.0.0 (Beta)\nUIH Core Network',
                    style: TextStyle(color: Colors.grey, fontSize: 12))),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  height: 60, padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ['System > Node Availability', 'System > Search & Reserve', 'System > Network Topology'][_selectedMenuIndex.clamp(0,2)],
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500)),
                      PopupMenuButton<String>(
                        offset: const Offset(0, 45),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        onSelected: (v) { if (v == 'logout') _handleLogout(); },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'profile', child: ListTile(leading: Icon(Icons.person), title: Text('My Profile'), contentPadding: EdgeInsets.zero)),
                          const PopupMenuDivider(),
                          const PopupMenuItem(value: 'logout', child: ListTile(leading: Icon(Icons.logout, color: Colors.red), title: Text('Sign Out', style: TextStyle(color: Colors.red)), contentPadding: EdgeInsets.zero)),
                        ],
                        child: Row(children: [
                          const Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('Admin User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('Network Engineer', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          ]),
                          const SizedBox(width: 12),
                          const CircleAvatar(radius: 18, backgroundColor: Color(0xFFE8F0FE),
                            child: Icon(Icons.person, size: 20, color: Color(0xFF0056B3))),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ]),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildMainContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedMenuIndex) {
      case 0:  return _buildNodeAvailabilityPage();
      case 1:  return _buildSearchAndReservePage();
      case 2:  return _buildTopologyMockPage();
      default: return _buildNodeAvailabilityPage();
    }
  }

  // ════════════════════════════════════════════
  //  PAGE: Node Availability
  // ════════════════════════════════════════════

  Widget _buildNodeAvailabilityPage() {
    final filtered = _mockTableData.where((n) =>
      n['id'].toString().toLowerCase().contains(_searchTableId.toLowerCase()) &&
      n['name'].toString().toLowerCase().contains(_searchTableName.toLowerCase())).toList();

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Node Availability Status', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                const Text('ตรวจสอบสถานะความพร้อมของ Node ก่อนทำการจอง', style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(child: TextField(
                    onChanged: (v) => setState(() => _searchTableId = v),
                    decoration: _searchDecor('Search Node ID...', Icons.search))),
                  const SizedBox(width: 16),
                  Expanded(child: TextField(
                    onChanged: (v) => setState(() => _searchTableName = v),
                    decoration: _searchDecor('Search Node Name...', Icons.business))),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () { _clearData(); setState(() => _selectedMenuIndex = 1); },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056B3), foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('New Reservation', style: TextStyle(fontWeight: FontWeight.bold))),
                ]),
              ]),
            ),
            SingleChildScrollView(
              child: filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: Text('No matching nodes found.', style: TextStyle(color: Colors.grey, fontSize: 16))))
                : SizedBox(width: double.infinity,
                    child: DataTable(
                      headingRowHeight: 56, dataRowHeight: 64,
                      headingRowColor: MaterialStateProperty.all(Colors.white),
                      columns: const [
                        DataColumn(label: Text('NODE ID', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF495057), fontSize: 13))),
                        DataColumn(label: Text('NODE NAME / LOCATION', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF495057), fontSize: 13))),
                        DataColumn(label: Text('STATUS / ACTION', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF495057), fontSize: 13))),
                      ],
                      rows: filtered.map((node) {
                        final isAvail = node['isAvailable'] as bool;
                        return DataRow(cells: [
                          DataCell(Text(node['id'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                          DataCell(Text(node['name'], style: TextStyle(color: isAvail ? Colors.grey.shade400 : Colors.black87, fontSize: 14))),
                          DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: isAvail ? Colors.green.shade50 : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isAvail ? Colors.green.shade200 : Colors.red.shade200)),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(isAvail ? Icons.check_circle : Icons.cancel, size: 14, color: isAvail ? Colors.green.shade700 : Colors.red.shade700),
                                const SizedBox(width: 6),
                                Text(isAvail ? 'ว่าง (Available)' : 'ไม่ว่าง (Unavailable)',
                                  style: TextStyle(color: isAvail ? Colors.green.shade700 : Colors.red.shade700, fontSize: 13, fontWeight: FontWeight.bold)),
                              ])),
                            if (isAvail) ...[
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: () { _clearData(); setState(() { selectedNodeId = node['id']; _selectedMenuIndex = 1; _autocompleteKey = UniqueKey(); }); },
                                icon: const Icon(Icons.touch_app, size: 16),
                                label: const Text('เลือก', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056B3), foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: const Size(0, 36),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)))),
                            ]
                          ])),
                        ]);
                      }).toList(),
                    ),          // DataTable
                  ),            // SizedBox
            ),                  // SingleChildScrollView
          ],                    // Column children
        ),                      // Column
      ),                        // Container
    );                          // Padding
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
            if (_currentPhase == 1) ...[
              _buildStepHeader('1. ข้อมูล LSW Access'),
              Padding(padding: const EdgeInsets.all(24), child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Node ID autocomplete (custom — แสดง available badge)
                  Expanded(child: _buildNodeIdField()),
                  const SizedBox(width: 20),
                  Expanded(child: SearchField(label: 'Search Node Name', hint: 'Type to search name',
                    items: nodeNames, initialValue: selectedNodeName,
                    onSelected: (val) => setState(() => selectedNodeName = val), fieldKey: _keyNodeName)),
                  const SizedBox(width: 20),
                  Expanded(child: DropdownField(label: 'Select Area Group', items: areaGroups,
                    currentValue: selectedAreaGroup, onChanged: (val) => setState(() => selectedAreaGroup = val))),
                ],
              )),
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

            if (_currentPhase == 2) ...[
              _buildStepHeader('2. ข้อมูล LSW Network'),
              Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: SearchField(label: 'Search Site Code LSW', hint: 'e.g., BCH-5012-UR',
                    items: siteCodes, initialValue: selectedSiteCode,
                    onSelected: (val) {
                      final s = mockSites.firstWhere((s) => s['code'] == val, orElse: () => {});
                      setState(() { selectedSiteCode = val; if (s.isNotEmpty) selectedSiteName = s['name']; _tempSelectedPorts.clear(); _tempIpNetworks.clear(); });
                    })),
                  const SizedBox(width: 20),
                  Expanded(child: SearchField(label: 'Search Site Name', hint: 'e.g., True IDC...',
                    items: siteNames, initialValue: selectedSiteName,
                    onSelected: (val) {
                      final s = mockSites.firstWhere((s) => s['name'] == val, orElse: () => {});
                      setState(() { selectedSiteName = val; if (s.isNotEmpty) selectedSiteCode = s['code']; _tempSelectedPorts.clear(); _tempIpNetworks.clear(); });
                    })),
                ]),
                if ((selectedSiteCode?.isNotEmpty ?? false) || (selectedSiteName?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 30),
                  NetworkSelectionTable(
                    networkNodesRaw: networkNodesRaw,
                    networkPortsRaw: networkPortsRaw,
                    networkPorts: networkPorts,
                    ipNetworkList: ipNetworkList,
                    ipRaw: ipRaw,
                    selectedNodeNetworkId: selectedNodeNetworkId,
                    tempSelectedPorts: _tempSelectedPorts,
                    tempIpNetworks: _tempIpNetworks,
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
                  ElevatedButton.icon(
                    onPressed: _submitData,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF28A745), foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                    icon: const Icon(Icons.auto_graph, size: 20),
                    label: const Text('View Topology Diagram', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
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

  Widget _buildSidebarItem(IconData icon, String title, int index) {
    final isActive = _selectedMenuIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedMenuIndex = index),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0056B3).withOpacity(0.15) : Colors.transparent,
          border: Border(left: BorderSide(color: isActive ? const Color(0xFF0056B3) : Colors.transparent, width: 4))),
        child: ListTile(
          leading: Icon(icon, color: isActive ? Colors.white : Colors.grey.shade400, size: 22),
          title: Text(title, style: TextStyle(color: isActive ? Colors.white : Colors.grey.shade400,
            fontSize: 14, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)))));
  }

  Widget _buildPhaseIndicator(int step, String title, bool isActive) {
    return Row(children: [
      Container(width: 32, height: 32,
        decoration: BoxDecoration(color: isActive ? const Color(0xFF0056B3) : Colors.grey.shade300, shape: BoxShape.circle),
        child: Center(child: Text(step.toString(), style: TextStyle(color: isActive ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold)))),
      const SizedBox(width: 12),
      Text(title, style: TextStyle(fontWeight: FontWeight.bold,
        color: isActive ? const Color(0xFF0056B3) : Colors.grey.shade500, fontSize: 16)),
    ]);
  }

  Widget _buildStepHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9),
        border: Border.symmetric(horizontal: BorderSide(color: Colors.grey.shade300))),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))));
  }

  InputDecoration _searchDecor(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint, prefixIcon: Icon(icon, color: Colors.grey),
      filled: true, fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0056B3), width: 2)));
  }
}