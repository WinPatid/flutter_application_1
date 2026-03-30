// ไฟล์: lib/screens/node_assist_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart'; 

class NodeAssistScreen extends StatefulWidget {
  const NodeAssistScreen({super.key});

  @override
  State<NodeAssistScreen> createState() => _NodeAssistScreenState();
}

class _NodeAssistScreenState extends State<NodeAssistScreen> {
  final _api = ApiService();

  // ─── การนำทาง (Navigation State) ───
  int _selectedMenuIndex = 0; 

  // ─── ตัวแปร Phase 1 & 2 ───
  int _currentPhase = 1;
  // แยก key สำหรับแต่ละ field เพื่อไม่ให้ reset พร้อมกัน
  Key _keyNodeId       = UniqueKey();
  Key _keyNodeName     = UniqueKey();
  Key _keyDomain       = UniqueKey();
  Key _keyIpAccess     = UniqueKey();
  Key _keyModel        = UniqueKey();
  Key _keyPort         = UniqueKey();
  Key _keyNetworkNode  = UniqueKey();
  Key _keyIpNetwork    = UniqueKey();
  Key _keyPortNetwork  = UniqueKey();

  String? selectedNodeId;
  int? selectedNodeAcID;        // FK → LSW_Access.NodeAcID
  String? selectedNodeName;
  String? selectedAreaGroup;
  String? selectedDomain;
  int? selectedDomainId;
  String? selectedIpAddress;
  int? selectedIpAccessId;      // FK → ip.IP_id (Access side)
  String? selectedModel;
  String? selectedPort;
  int? selectedPortAccessId;    // FK → InterfacesAc.Interface_ID (สร้างตอน confirm)
  int? selectedSwitchAcId;      // FK → SwitchAc.SwitchAc_ID (สร้างตอน confirm)
  int? selectedTemplateId;      // FK → ModelInterfaces.Template_ID
  int? selectedModelId;         // Model.Model_Id

  String? selectedNodeNetworkId;
  int? selectedNodeNwID;        // FK → LSW_Network.NodeNwID
  String? selectedIpNetwork;
  int? selectedIpNetworkId;     // FK → ip.IP_id (Network side)
  String? selectedPortNetwork;
  int? selectedPortNetworkId;   // FK → interfaces_nw.Interface_ID
  int? selectedSwitchNwId;      // FK → switch_nw.SwitchNw_ID
  String _autoFilledSite = 'Pending auto-detection...';

  // raw data สำหรับ lookup ID ทีหลัง
  List<Map<String, dynamic>> accessPortsRaw = [];
  List<Map<String, dynamic>> networkPortsRaw = [];
  List<Map<String, dynamic>> accessSwitchesRaw = [];
  List<Map<String, dynamic>> networkSwitchesRaw = [];
  List<Map<String, dynamic>> ipRaw = [];

  // ─── ตัวแปรควบคุมปุ่ม Confirm ───
  bool _isConnectionTested = false;
  List<Map<String, dynamic>> accessNodesRaw = [];
  List<String> nodeIds = [];
  List<String> nodeNames = [];
  List<String> domains = [];
  List<Map<String, dynamic>> domainRaw = [];
  List<String> ipList = [];        // IP list สำหรับ Access side
  List<String> ipNetworkList = []; // IP list สำหรับ Network side (แยกกัน)
  List<String> models = [];
  List<Map<String, dynamic>> modelsRaw = [];
  List<String> switchPorts = [];
  List<String> filteredSwitchPorts = []; // กรองตาม Model ที่เลือก
  List<Map<String, dynamic>> templatePortsRaw = []; // Port templates จาก ModelInterfaces
  List<Map<String, dynamic>> networkNodesRaw = [];
  List<String> networkNodeNames = [];
  List<String> networkPorts = [];

  final List<String> areaGroups = ['BKK', 'UPC'];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final nodes           = await _api.fetchAccessNodes();
    final domainData      = await _api.fetchDomains();
    final ports           = await _api.fetchAccessInterfaces();
    final networkNodes    = await _api.fetchNetworkNodes();
    final networkPortData = await _api.fetchNetworkInterfaces();
    final modelData       = await _api.fetchModels();

    setState(() {
      accessNodesRaw      = List<Map<String, dynamic>>.from(nodes);
      nodeIds             = nodes.map((n) => n['NodeAcID'].toString()).toList();
      nodeNames           = nodes.map((n) => n['NodeName'].toString()).toList();
      domainRaw           = List<Map<String, dynamic>>.from(domainData);
      domains             = domainData.map((d) => d['Domain_Name'].toString()).toList();
      accessPortsRaw      = List<Map<String, dynamic>>.from(ports);
      switchPorts         = ports.map((p) => p['Interface_Name'].toString()).toList();
      filteredSwitchPorts = List.from(switchPorts);
      modelsRaw           = List<Map<String, dynamic>>.from(modelData);
      models              = modelData.map((m) => m['Model_Name'].toString()).toList();
      networkNodesRaw     = List<Map<String, dynamic>>.from(networkNodes);
      networkNodeNames    = networkNodes.map((n) => n['NodeName'].toString()).toList();
      networkPortsRaw     = List<Map<String, dynamic>>.from(networkPortData);
      networkPorts        = networkPortData.map((p) => p['Interface_Name'].toString()).toList();
    });
  }

  Future<void> _loadPortsByModel(int modelId) async {
    final templates = await _api.fetchModelInterfaces(modelId: modelId);
    setState(() {
      templatePortsRaw    = List<Map<String, dynamic>>.from(templates);
      filteredSwitchPorts = templates.map((t) => t['Interface_Name'].toString()).toList();
      selectedPort        = null;
      selectedTemplateId  = null;
      _keyPort            = UniqueKey();
    });
  }

  Future<void> _loadIpsByDomain(String domainName) async {
    final domain = domainRaw.firstWhere(
      (d) => d['Domain_Name'] == domainName,
      orElse: () => {},
    );
    if (domain.isEmpty) return;
    final id  = domain['Domain_id'] as int;
    final ips = await _api.fetchIpsByDomain(id);
    setState(() {
      selectedDomainId    = id;
      ipRaw               = List<Map<String, dynamic>>.from(ips);
      ipList              = ips.map((ip) => ip['IP'].toString()).toList();
      ipNetworkList       = List.from(ipList); // Network ใช้ IP จาก domain เดียวกัน
      selectedIpAddress   = null;
      selectedIpAccessId  = null;
      selectedIpNetwork   = null;
      selectedIpNetworkId = null;
      _keyIpAccess  = UniqueKey();
      _keyIpNetwork = UniqueKey();
    });
  }

  Future<void> _loadSiteForNetwork(String nodeName) async {
    if (nodeName.length < 2) {
      setState(() => _autoFilledSite = 'Pending auto-detection...');
      return;
    }
    final matched = networkNodesRaw.where(
      (n) => n['NodeName'].toString().toLowerCase().contains(nodeName.toLowerCase())
    ).toList();

    if (matched.isEmpty) {
      setState(() => _autoFilledSite = 'Pending auto-detection...');
      return;
    }

    final nodeId = matched.first['NodeNwID'] as int;
    final site   = await _api.fetchSiteForNetworkNode(nodeId);
    setState(() => _autoFilledSite = site);
  }

  void _clearData() {
    setState(() {
      selectedNodeId        = null;
      selectedNodeAcID      = null;
      selectedNodeName      = null;
      selectedAreaGroup     = null;
      selectedDomain        = null;
      selectedDomainId      = null;
      selectedIpAddress     = null;
      selectedIpAccessId    = null;
      selectedModel         = null;
      selectedPort          = null;
      selectedPortAccessId  = null;
      selectedSwitchAcId    = null;
      selectedTemplateId    = null;
      selectedModelId       = null;
      templatePortsRaw      = [];
      filteredSwitchPorts   = List.from(switchPorts);
      selectedNodeNetworkId = null;
      selectedNodeNwID      = null;
      selectedIpNetwork     = null;
      selectedIpNetworkId   = null;
      selectedPortNetwork   = null;
      selectedPortNetworkId = null;
      selectedSwitchNwId    = null;
      ipRaw                 = [];
      ipList                = [];
      ipNetworkList         = [];
      _autoFilledSite       = 'Pending auto-detection...';
      _currentPhase         = 1;
      _isConnectionTested   = false;
      // reset ทุก key แยกกันเพื่อ clear เฉพาะ field
      _keyNodeId      = UniqueKey();
      _keyNodeName    = UniqueKey();
      _keyDomain      = UniqueKey();
      _keyIpAccess    = UniqueKey();
      _keyModel       = UniqueKey();
      _keyPort        = UniqueKey();
      _keyNetworkNode = UniqueKey();
      _keyIpNetwork   = UniqueKey();
      _keyPortNetwork = UniqueKey();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Form cleared successfully'), backgroundColor: Colors.blue),
    );
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
          content: _buildDiagramSummary(setStateDialog),
        ),
      ),
    );
  }

  // ─── ฟังก์ชัน Test Connection (ดึงเฉพาะข้อมูลที่กรอกมาโชว์) ───
  void _handleTestConnection(StateSetter setStateDialog) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
    );

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pop(context); 

      List<Widget> dynamicDetails = [];

      // ฟังก์ชันช่วยเช็ค ถ้าช่องไหนมีข้อมูลให้เอามาโชว์ (ถ้าเป็นค่าว่างจะไม่แสดง)
      void addDetail(String label, String? value) {
        if (value != null && value.trim().isNotEmpty && value != 'Pending auto-detection...') {
          dynamicDetails.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text('$label: $value', style: const TextStyle(color: Colors.white70, fontSize: 14)),
            )
          );
        }
      }

      // ดึงข้อมูลจากฟอร์มหน้า 1
      addDetail('Node ID', selectedNodeId);
      addDetail('Node Name', selectedNodeName);
      addDetail('Area Group', selectedAreaGroup);
      addDetail('Domain', selectedDomain);
      addDetail('IP Assist', selectedIpAddress);
      addDetail('Model (LAN Switch)', selectedModel);
      addDetail('Switch Port', selectedPort);

      // ดึงข้อมูลจากฟอร์มหน้า 2
      addDetail('Network ID', selectedNodeNetworkId);
      addDetail('IP Network', selectedIpNetwork);
      addDetail('Site Location', _autoFilledSite);
      addDetail('Port Network', selectedPortNetwork);

      // กรณีที่กดเข้ามาแต่ไม่ได้กรอกอะไรเลย
      if (dynamicDetails.isEmpty) {
        dynamicDetails.add(
          const Text('No configuration data provided.', style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic))
        );
      }

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF2B2B2B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white12)),
          title: const Text('Succeeded', style: TextStyle(color: Color(0xFFA5D63F), fontWeight: FontWeight.bold, fontSize: 24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            // เอา Ping และ Status ออกแล้ว ยัดแค่ข้อมูลที่เราเช็คไว้ลงไปตรงๆ
            children: dynamicDetails, 
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); 
                setStateDialog(() {
                  _isConnectionTested = true; 
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A88C7), foregroundColor: Colors.white),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    });
  }

  void _handleLogout() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child); 
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Row(
        children: [
          Container(
            width: 250,
            color: const Color(0xFF212529),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 60, width: double.infinity,
                  color: const Color(0xFF1A1D20),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: const Text('NODE ASSIST PRO',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 10),
                _buildSidebarItem(Icons.search, 'Search & Reserve', 0),
                _buildSidebarItem(Icons.settings_ethernet, 'Network Topology', 1),
                _buildSidebarItem(Icons.storage, 'Database Overview', 2),
                
                const Spacer(),
                const Divider(color: Colors.white24),
                Container(
                  padding: const EdgeInsets.all(20),
                  child: const Text('Version 1.0.0 (Beta)\nUIH Core Network', 
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                )
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 60, padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedMenuIndex == 0 
                          ? 'System  >  Node Assist  >  New Reservation'
                          : _selectedMenuIndex == 1
                            ? 'System  >  Visualization  >  Network Topology'
                            : 'System  >  Administration  >  Database Overview',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500)
                      ),
                      
                      PopupMenuButton<String>(
                        offset: const Offset(0, 45),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        onSelected: (value) {
                          if (value == 'logout') _handleLogout();
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'profile', child: ListTile(leading: Icon(Icons.person), title: Text('My Profile'), contentPadding: EdgeInsets.zero)),
                          const PopupMenuItem(value: 'settings', child: ListTile(leading: Icon(Icons.settings), title: Text('Settings'), contentPadding: EdgeInsets.zero)),
                          const PopupMenuDivider(),
                          const PopupMenuItem(value: 'logout', child: ListTile(leading: Icon(Icons.logout, color: Colors.red), title: Text('Sign Out', style: TextStyle(color: Colors.red)), contentPadding: EdgeInsets.zero)),
                        ],
                        child: Row(
                          children: [
                            const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Admin User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('Network Engineer', style: TextStyle(color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                            const SizedBox(width: 12),
                            const CircleAvatar(
                              radius: 18,
                              backgroundColor: Color(0xFFE8F0FE),
                              child: Icon(Icons.person, size: 20, color: Color(0xFF0056B3)),
                            ),
                            const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildMainContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedMenuIndex) {
      case 0: return _buildSearchAndReservePage(); 
      case 1: return _buildTopologyMockPage(); 
      case 2: return _buildDatabaseMockPage(); 
      default: return _buildSearchAndReservePage();
    }
  }

  Widget _buildSearchAndReservePage() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: Row(
            children: [
              _buildPhaseIndicator(1, "ข้อมูล LSW Access", _currentPhase >= 1),
              Expanded(child: Divider(
                color: _currentPhase == 2 ? const Color(0xFF0056B3) : Colors.grey.shade300,
                thickness: 2)),
              _buildPhaseIndicator(2, "ข้อมูล LSW Network", _currentPhase == 2),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentPhase == 1) ...[
                    _buildStepHeader('1. ข้อมูล LSW Access'),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildSearchField(
                            'Search Node ID', 'e.g., 99012',
                            nodeIds, selectedNodeId,
                            (val) {
                              final node = accessNodesRaw.firstWhere(
                                (n) => n['NodeAcID'].toString() == val, orElse: () => {});
                              setState(() {
                                selectedNodeId   = val;
                                selectedNodeAcID = node.isNotEmpty ? node['NodeAcID'] as int : null;
                              });
                            }, fieldKey: _keyNodeId)),
                          const SizedBox(width: 20),
                          Expanded(child: _buildSearchField(
                            'Search Node Name', 'Type to search name',
                            nodeNames, selectedNodeName,
                            (val) => setState(() => selectedNodeName = val),
                            fieldKey: _keyNodeName)),
                          const SizedBox(width: 20),
                          Expanded(child: _buildDropdownField(
                            'Select Area Group', areaGroups,
                            selectedAreaGroup,
                            (val) => setState(() => selectedAreaGroup = val))),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                      child: Row(
                        children: [
                          Expanded(child: _buildSearchField(
                            'Select Domain', 'Type to search domain...',
                            domains, selectedDomain,
                            (val) {
                              setState(() {
                                selectedDomain      = val;
                                selectedIpAddress   = null;
                                selectedIpAccessId  = null;
                                selectedIpNetwork   = null;
                                selectedIpNetworkId = null;
                                ipList              = [];
                                ipNetworkList       = [];
                                ipRaw               = [];
                              });
                              final matched = domainRaw.firstWhere(
                                (d) => d['Domain_Name'].toString() == val, orElse: () => {});
                              if (matched.isNotEmpty) _loadIpsByDomain(val);
                            }, fieldKey: _keyDomain, showAllOnEmpty: true)),
                          const SizedBox(width: 20),
                          Expanded(child: _buildSearchField(
                            'Search IP Assist', 'e.g., 10.98.4.200...',
                            ipList, selectedIpAddress,
                            (val) {
                              final ip = ipRaw.firstWhere(
                                (i) => i['IP'].toString() == val, orElse: () => {});
                              setState(() {
                                selectedIpAddress  = val;
                                selectedIpAccessId = ip.isNotEmpty ? ip['IP_id'] as int : null;
                              });
                            },
                            isDisabled: selectedDomain == null, fieldKey: _keyIpAccess)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                      child: Row(
                        children: [
                          Expanded(child: _buildSearchField(
                            'Select Model (LAN Switch)', 'Type to search model...',
                            models, selectedModel,
                            (val) {
                              final model = modelsRaw.firstWhere(
                                (m) => m['Model_Name'].toString() == val, orElse: () => {});
                              final modelId = model.isNotEmpty ? model['Model_Id'] as int : null;
                              setState(() {
                                selectedModel   = val;
                                selectedModelId = modelId;
                                selectedPort    = null;
                                selectedTemplateId  = null;
                                selectedPortAccessId = null;
                                selectedSwitchAcId   = null;
                                filteredSwitchPorts  = [];
                              });
                              if (modelId != null) _loadPortsByModel(modelId);
                            }, fieldKey: _keyModel)),
                          const SizedBox(width: 20),
                          Expanded(child: _buildSearchField(
                            'Select Switch Port', 'Type to search port...',
                            filteredSwitchPorts, selectedPort,
                            (val) {
                              // ดึงจาก templatePortsRaw แทน accessPortsRaw
                              final tmpl = templatePortsRaw.firstWhere(
                                (t) => t['Interface_Name'].toString() == val, orElse: () => {});
                              setState(() {
                                selectedPort       = val;
                                selectedTemplateId = tmpl.isNotEmpty ? tmpl['Template_ID'] as int : null;
                                // SwitchAc_ID และ Interface_ID จะสร้างตอน confirm
                                selectedPortAccessId = null;
                                selectedSwitchAcId   = null;
                              });
                            },
                            isDisabled: selectedModel == null, fieldKey: _keyPort, showAllOnEmpty: true)),
                        ],
                      ),
                    ),
                  ],

                  if (_currentPhase == 2) ...[
                    _buildStepHeader('2. ข้อมูล LSW Network'),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildSearchField(
                                'Search Network ID', 'e.g., 85001_BCH...',
                                networkNodeNames, selectedNodeNetworkId,
                                (val) {
                                  final node = networkNodesRaw.firstWhere(
                                    (n) => n['NodeName'].toString() == val, orElse: () => {});
                                  setState(() {
                                    selectedNodeNetworkId = val;
                                    selectedNodeNwID      = node.isNotEmpty ? node['NodeNwID'] as int : null;
                                  });
                                  _loadSiteForNetwork(val);
                                }, fieldKey: _keyNetworkNode)),
                              const SizedBox(width: 20),
                              Expanded(child: _buildSearchField(
                                'Search IP Network', 'e.g., 10.98.4.10...',
                                ipNetworkList, selectedIpNetwork,
                                (val) {
                                  final ip = ipRaw.firstWhere(
                                    (i) => i['IP'].toString() == val, orElse: () => {});
                                  setState(() {
                                    selectedIpNetwork   = val;
                                    selectedIpNetworkId = ip.isNotEmpty ? ip['IP_id'] as int : null;
                                  });
                                },
                                isDisabled: selectedDomain == null,
                                fieldKey: _keyIpNetwork)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: _buildReadOnlyField(
                                'Site Location (Auto-fill)', _autoFilledSite)),
                              const SizedBox(width: 20),
                              Expanded(child: _buildSearchField(
                                'Select Port Network', 'Type to search port...',
                                networkPorts, selectedPortNetwork,
                                (val) {
                                  final port = networkPortsRaw.firstWhere(
                                    (p) => p['Interface_Name'].toString() == val, orElse: () => {});
                                  setState(() {
                                    selectedPortNetwork   = val;
                                    selectedPortNetworkId = port.isNotEmpty ? port['Interface_ID'] as int : null;
                                    selectedSwitchNwId    = port.isNotEmpty ? port['SwitchNw_ID'] as int : null;
                                  });
                                }, fieldKey: _keyPortNetwork)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      border: Border(top: BorderSide(color: Colors.grey.shade300))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentPhase == 2)
                          OutlinedButton.icon(
                            onPressed: () => setState(() => _currentPhase = 1),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Back'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
                          )
                        else
                          TextButton(
                            onPressed: _clearData,
                            child: const Text('Clear Form Data',
                              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),

                        if (_currentPhase == 1)
                          ElevatedButton.icon(
                            onPressed: () => setState(() => _currentPhase = 2),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0056B3),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            icon: const Icon(Icons.arrow_forward, size: 20),
                            label: const Text('Next Step',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: _submitData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF28A745),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            icon: const Icon(Icons.auto_graph, size: 20),
                            label: const Text('View Topology Diagram',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildTopologyMockPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hub_outlined, size: 100, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text('Interactive Topology Mapper', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
          const SizedBox(height: 10),
          Text('Live visualization module is currently under development.\nWill be available in Phase 2 deployment.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => setState(() => _selectedMenuIndex = 0),
            icon: const Icon(Icons.add),
            label: const Text('Create New Reservation'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056B3), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
          )
        ],
      ),
    );
  }

  Widget _buildDatabaseMockPage() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Active Network Nodes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Icon(Icons.more_horiz, color: Colors.grey),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                  columns: const [
                    DataColumn(label: Text('NODE ID', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                    DataColumn(label: Text('NODE NAME', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                    DataColumn(label: Text('IP ADDRESS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                    DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                  ],
                  rows: [
                    _buildMockDataRow('85001', 'BCH_FL21', '10.98.4.10', true),
                    _buildMockDataRow('99012', 'PEA Chonburi', '10.98.4.200', true),
                    _buildMockDataRow('10452', 'Boot_Navamin', '10.100.1.0', false),
                    _buildMockDataRow('77410', 'Ring-Bkk-12', '192.168.1.0', true),
                    _buildMockDataRow('55021', 'CBI Facility - Bldg B', '10.99.200.10', true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildMockDataRow(String id, String name, String ip, bool isActive) {
    return DataRow(cells: [
      DataCell(Text(id, style: const TextStyle(fontWeight: FontWeight.bold))),
      DataCell(Text(name)),
      DataCell(Text(ip, style: const TextStyle(color: Colors.blue))),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isActive ? Colors.green.shade200 : Colors.red.shade200),
          ),
          child: Text(isActive ? 'ONLINE' : 'OFFLINE', style: TextStyle(color: isActive ? Colors.green.shade700 : Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
        )
      ),
    ]);
  }

  Widget _buildSidebarItem(IconData icon, String title, int index) {
    final isActive = _selectedMenuIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedMenuIndex = index),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0056B3).withOpacity(0.15) : Colors.transparent,
          border: Border(left: BorderSide(
            color: isActive ? const Color(0xFF0056B3) : Colors.transparent, width: 4)),
        ),
        child: ListTile(
          leading: Icon(icon, color: isActive ? Colors.white : Colors.grey.shade400, size: 22),
          title: Text(title, style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade400,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }

  Widget _buildPhaseIndicator(int stepNumber, String title, bool isActive) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0056B3) : Colors.grey.shade300,
            shape: BoxShape.circle),
          child: Center(child: Text(stepNumber.toString(),
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey.shade600,
              fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 12),
        Text(title, style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isActive ? const Color(0xFF0056B3) : Colors.grey.shade500,
          fontSize: 16)),
      ],
    );
  }

  Widget _buildStepHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        border: Border.symmetric(horizontal: BorderSide(color: Colors.grey.shade300))),
      child: Text(title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 8),
        TextFormField(
          key: ValueKey(value),
          initialValue: value,
          readOnly: true,
          style: TextStyle(
            color: value.contains('Pending') ? Colors.grey : const Color(0xFF0056B3),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            filled: true, fillColor: const Color(0xFFE8F0FE),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(String label, String hint, List<String> items,
      String? initialValue, Function(String) onSelected,
      {bool isDisabled = false, Key? fieldKey, bool showAllOnEmpty = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(
          fontWeight: FontWeight.bold, fontSize: 13,
          color: isDisabled ? Colors.grey : const Color(0xFF495057))),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, constraints) {
          return Autocomplete<String>(
            key: fieldKey,
            initialValue: TextEditingValue(text: initialValue ?? ''),
            displayStringForOption: (option) => option,
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (isDisabled) return const Iterable<String>.empty();
              if (textEditingValue.text.isEmpty) {
                return showAllOnEmpty ? items : const Iterable<String>.empty();
              }
              return items.where((item) =>
                item.toLowerCase().contains(textEditingValue.text.toLowerCase()));
            },
            onSelected: onSelected,
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              if (showAllOnEmpty) {
                focusNode.addListener(() {
                  if (focusNode.hasFocus) {
                    final text = controller.text;
                    controller.value = controller.value.copyWith(
                      text: text,
                      selection: TextSelection.collapsed(offset: text.length),
                    );
                  }
                });
              }
              return TextField(
                controller: controller,
                focusNode: focusNode,
                readOnly: isDisabled,
                decoration: InputDecoration(
                  hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true, fillColor: isDisabled ? Colors.grey.shade100 : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Colors.blue, width: 2)),
                  suffixIcon: isDisabled ? null : const Icon(Icons.search, color: Colors.grey, size: 20),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: constraints.maxWidth,
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (BuildContext context, int index) {
                        final String option = options.elementAt(index);
                        return InkWell(
                          onTap: () => onSelected(option),
                          hoverColor: const Color(0xFFE8F0FE),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Text(option, style: const TextStyle(fontSize: 14)),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> items,
      String? currentValue, Function(String?) onChanged) {
    final validValue = items.contains(currentValue) ? currentValue : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(
          fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF495057))),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: validValue,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
            filled: true, fillColor: Colors.white,
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
          items: items.toSet().toList().map((e) =>
            DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 15)))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDiagramSummary(StateSetter setStateDialog) {
    return Container(
      width: 800, 
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Network Topology Summary',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0056B3))),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(thickness: 1),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildDiagramNode(
                icon: Icons.dns,
                title: 'LSW Network',
                subTitle: _autoFilledSite,
                data: [
                  'ID: ${selectedNodeNetworkId ?? "-"}',
                  'IP: ${selectedIpNetwork ?? "-"}',
                  '', 
                  'Domain: ${selectedDomain?.split(' ').first ?? "-"}', 
                  'Area Group: ${selectedAreaGroup ?? "-"}',
                ],
              ),
              _buildDiagramLink(
                leftPort: selectedPortNetwork ?? 'GE-?',
                rightPort: selectedPort ?? 'GE-?'),
              _buildDiagramNode(
                icon: Icons.router,
                title: 'LSW Access',
                subTitle: selectedModel ?? 'Switch Model',
                data: [
                  'ID: ${selectedNodeId ?? "-"} - ${selectedNodeName ?? "-"}',
                  'IP: ${selectedIpAddress ?? "-"}',
                  '',
                  'Domain: ${selectedDomain?.split(' ').first ?? "-"}',
                  'Area Group: ${selectedAreaGroup ?? "-"}',
                ],
                isFinalNode: true,
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Divider(thickness: 1),
          const SizedBox(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: () => _handleTestConnection(setStateDialog),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF17A2B8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))
                ),
                icon: const Icon(Icons.wifi_protected_setup, size: 20),
                label: const Text('Test Connection', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),

              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      side: BorderSide(color: Colors.grey.shade400)
                    ),
                    child: const Text('Back to Edit', style: TextStyle(color: Colors.grey))
                  ),
                  const SizedBox(width: 15),
                  
                  ElevatedButton.icon(
                    onPressed: _isConnectionTested ? () async {
                      // ── Validate ──
                      if (selectedNodeAcID == null || selectedTemplateId == null ||
                          selectedIpAccessId == null || selectedModelId == null ||
                          selectedNodeNwID == null || selectedPortNetworkId == null ||
                          selectedIpNetworkId == null || selectedSwitchNwId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('❌ กรุณากรอกข้อมูลให้ครบก่อน Confirm'), backgroundColor: Colors.red));
                        return;
                      }

                      final payload = {
                        'access_node_id':     selectedNodeAcID,
                        'access_switch_id':   0,              // backend สร้างใหม่
                        'access_port_id':     0,              // backend สร้างจาก template
                        'access_ip_id':       selectedIpAccessId,
                        'access_template_id': selectedTemplateId,
                        'access_model_id':    selectedModelId,
                        'network_node_id':    selectedNodeNwID,
                        'network_switch_id':  selectedSwitchNwId,
                        'network_port_id':    selectedPortNetworkId,
                        'network_ip_id':      selectedIpNetworkId,
                        'status':             'planned',
                      };

                      final ok = await _api.submitReservation(payload);
                      if (!mounted) return;
                      Navigator.pop(context);
                      if (ok) {
                        _clearData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ Network Configured Successfully!'), backgroundColor: Colors.green));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('❌ บันทึกไม่สำเร็จ กรุณาตรวจสอบข้อมูล'), backgroundColor: Colors.red));
                      }
                    } : null, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isConnectionTested ? const Color(0xFF28A745) : Colors.grey.shade300, 
                      foregroundColor: _isConnectionTested ? Colors.white : Colors.grey.shade500,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade500,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))
                    ),
                    icon: const Icon(Icons.check_circle, size: 20),
                    label: const Text('Confirm Configuration',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiagramNode({required IconData icon, required String title,
      required String subTitle, required List<String> data, bool isFinalNode = false}) {
    return Container(
      width: 250, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isFinalNode ? const Color(0xFF0056B3) : Colors.teal.shade600, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: isFinalNode ? const Color(0xFF0056B3) : Colors.teal.shade600),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(
            fontWeight: FontWeight.bold, fontSize: 18,
            color: isFinalNode ? const Color(0xFF0056B3) : Colors.teal.shade700),
            textAlign: TextAlign.center),
          Text(subTitle, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 15),
          const Divider(thickness: 1),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.map((item) =>
              Text(item, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagramLink({required String leftPort, required String rightPort}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(leftPort, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
                Text(rightPort, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0056B3))),
              ],
            ),
            const SizedBox(height: 4),
            Container(height: 3, color: Colors.teal.shade300),
          ],
        ),
      ),
    );
  }
}