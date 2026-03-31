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

  // ─── ตัวแปร Phase 1 & 2 (สำหรับหน้าฟอร์ม) ───
  int _currentPhase = 1;
  Key _autocompleteKey = UniqueKey();

  String? selectedNodeId;
  String? selectedNodeName;
  String? selectedAreaGroup;
  String? selectedDomain;
  int? selectedDomainId;
  String? selectedIpAddress;
  String? selectedModel;
  String? selectedPort;

  // ตัวแปร Phase 2 ที่ปรับปรุงใหม่
  String? selectedSiteCode; 
  String? selectedSiteName;
  String? selectedIpNetwork;
  String? selectedNodeNetworkId;
  String? selectedPortNetwork;
  
  // ตัวแปรเก็บค่าชั่วคราวในตาราง (แยกตาม Network ID)
  final Map<String, String?> _tempSelectedPorts = {};
  final Map<String, String?> _tempIpNetworks = {};

  bool _isConnectionTested = false;

  // ─── ตัวแปรสำหรับหน้าตาราง (Dashboard) ───
  String _searchTableId = '';
  String _searchTableName = '';

  final List<Map<String, dynamic>> _mockTableData = [
    {'id': '88860', 'name': 'บุญรอดบริวเวอรี่ คลังบางบัวทอง', 'isAvailable': false},
    {'id': '88861', 'name': '-', 'isAvailable': true},
    {'id': '88872', 'name': 'NEC Corporation (Thailand) LCo., Ltd.', 'isAvailable': false},
    {'id': '88895', 'name': 'บ. เถ้าแก่น้อย ฟู้ดแอนด์มาร์เก็ตติ้ง จก. - ปทุมธานี', 'isAvailable': false},
    {'id': '88920', 'name': '-', 'isAvailable': true},
    {'id': '88938', 'name': 'สำนักงานสรรพากรพื้นที่นนทบุรี', 'isAvailable': false},
    {'id': '98352', 'name': 'บ. อิทธิพรอิมปอร์ต จก.(หลักสี่)', 'isAvailable': false},
    {'id': '98424', 'name': '-', 'isAvailable': true},
    {'id': '98447', 'name': 'อาคารการไฟฟ้าส่วนภูมิภาค', 'isAvailable': false},
    {'id': '880234', 'name': 'BCH_17FL / WHB', 'isAvailable': false},
  ];

  // Data from API (สำหรับฟอร์ม)
  List<Map<String, dynamic>> accessNodesRaw = [];
  List<String> nodeIds = [];
  List<String> nodeNames = [];
  List<String> domains = [];
  List<Map<String, dynamic>> domainRaw = [];
  List<String> ipList = [];
  List<String> models = [];
  List<String> switchPorts = [];

  // ─── ข้อมูลจำลองสำหรับ Site Code & Name (จากรูป) ───
  final List<Map<String, String>> mockSites = [
    {'code': 'AYA-5024-UR', 'name': 'ประตูน้ำพระอินทร์ (UIH)'},
    {'code': 'BCH-5012-UR', 'name': 'True IDC เมืองทองธานี ชั้น 8 (Data Center) Rack 5G05A'},
    {'code': 'BCH-5013-UR', 'name': 'Jastel ชั้น 6 (Data Center)'},
    {'code': 'BCH-5018-UR', 'name': 'SBN แจ้งวัฒนะ (Data Center)'},
  ];

  List<String> get siteCodes => mockSites.map((e) => e['code']!).toList();
  List<String> get siteNames => mockSites.map((e) => e['name']!).toSet().toList(); // toSet ป้องกันชื่อซ้ำ

  final List<String> areaGroups = ['BKK', 'UPC'];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final nodes = await _api.fetchAccessNodes();
    final domainData = await _api.fetchDomains();
    final ports = await _api.fetchAccessInterfaces();

    setState(() {
      accessNodesRaw = List<Map<String, dynamic>>.from(nodes);
      nodeIds = nodes.map((n) => n['NodeAcID'].toString()).toList();
      nodeNames = nodes.map((n) => n['NodeName'].toString()).toList();
      domainRaw = List<Map<String, dynamic>>.from(domainData);
      domains = domainData.map((d) => d['Domain_Name'].toString()).toList();
      switchPorts = ports.map((p) => p['Interface_Name'].toString()).toList();
      models = ports.map((p) => p['Interface_Type'].toString()).toSet().toList();
    });
  }

  Future<void> _loadIpsByDomain(String domainName) async {
    final domain = domainRaw.firstWhere(
      (d) => d['Domain_Name'] == domainName,
      orElse: () => {},
    );
    if (domain.isEmpty) return;
    final id = domain['Domain_id'] as int;
    final ips = await _api.fetchIpsByDomain(id);
    setState(() {
      selectedDomainId = id;
      ipList = ips.map((ip) => ip['IP'].toString()).toList();
      selectedIpAddress = null;
    });
  }

  void _clearData() {
    setState(() {
      selectedNodeId = null;
      selectedNodeName = null;
      selectedAreaGroup = null;
      selectedDomain = null;
      selectedDomainId = null;
      selectedIpAddress = null;
      selectedModel = null;
      selectedPort = null;
      
      selectedSiteCode = null;
      selectedSiteName = null;
      selectedIpNetwork = null;
      selectedNodeNetworkId = null;
      selectedPortNetwork = null;
      _tempSelectedPorts.clear(); 
      _tempIpNetworks.clear();
      
      _currentPhase = 1;
      _autocompleteKey = UniqueKey();
      _isConnectionTested = false;
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

  void _handleTestConnection(StateSetter setStateDialog) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
    );

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pop(context);

      List<Widget> dynamicDetails = [];

      void addDetail(String label, String? value) {
        if (value != null && value.trim().isNotEmpty) {
          dynamicDetails.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text('$label: $value', style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ),
          );
        }
      }

      addDetail('Node ID', selectedNodeId);
      addDetail('Node Name', selectedNodeName);
      addDetail('Area Group', selectedAreaGroup);
      addDetail('Domain', selectedDomain);
      addDetail('IP Assist', selectedIpAddress);
      addDetail('Model (LAN Switch)', selectedModel);
      addDetail('Switch Port', selectedPort);
      
      addDetail('Site Code LSW', selectedSiteCode);
      addDetail('Site Name', selectedSiteName);
      addDetail('Network ID', selectedNodeNetworkId);
      addDetail('IP Network', selectedIpNetwork);
      addDetail('Port Network', selectedPortNetwork);

      if (dynamicDetails.isEmpty) {
        dynamicDetails.add(
          const Text('No configuration data provided.', style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
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
                _buildSidebarItem(Icons.dashboard, 'Node Availability', 0),
                _buildSidebarItem(Icons.post_add, 'Search & Reserve', 1),
                _buildSidebarItem(Icons.settings_ethernet, 'Network Topology', 2),
                
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
                            ? 'System  >  Dashboard  >  Node Availability'
                            : _selectedMenuIndex == 1
                                ? 'System  >  Node Assist  >  New Reservation'
                                : 'System  >  Visualization  >  Network Topology',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500),
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
      case 0: return _buildNodeAvailabilityPage(); 
      case 1: return _buildSearchAndReservePage(); 
      case 2: return _buildTopologyMockPage(); 
      default: return _buildNodeAvailabilityPage();
    }
  }

  // ─── หน้าแรก: ตารางเช็คสถานะ Node ───
  Widget _buildNodeAvailabilityPage() {
    final filteredList = _mockTableData.where((node) {
      final matchId = node['id'].toString().toLowerCase().contains(_searchTableId.toLowerCase());
      final matchName = node['name'].toString().toLowerCase().contains(_searchTableName.toLowerCase());
      return matchId && matchName;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Node Availability Status', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 8),
                  const Text('ตรวจสอบสถานะความพร้อมของ Node ก่อนทำการจอง', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => _searchTableId = val),
                          decoration: InputDecoration(
                            hintText: 'Search Node ID...',
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            filled: true, fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0056B3), width: 2)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => _searchTableName = val),
                          decoration: InputDecoration(
                            hintText: 'Search Node Name...',
                            prefixIcon: const Icon(Icons.business, color: Colors.grey),
                            filled: true, fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0056B3), width: 2)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          _clearData();
                          setState(() {
                            _selectedMenuIndex = 1;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0056B3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                        ),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('New Reservation', style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: filteredList.isEmpty 
              ? const Center(child: Text('No matching nodes found.', style: TextStyle(color: Colors.grey, fontSize: 16)))
              : SingleChildScrollView(
                  child: SizedBox(
                    width: double.infinity,
                    child: DataTable(
                      headingRowHeight: 56,
                      dataRowHeight: 64,
                      headingRowColor: MaterialStateProperty.all(Colors.white),
                      columns: const [
                        DataColumn(label: Text('NODE ID', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF495057), fontSize: 13))),
                        DataColumn(label: Text('NODE NAME / LOCATION', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF495057), fontSize: 13))),
                        DataColumn(label: Text('STATUS / ACTION', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF495057), fontSize: 13))),
                      ],
                      rows: filteredList.map((node) {
                        bool isAvailable = node['isAvailable'];
                        return DataRow(
                          color: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                            if (states.contains(MaterialState.hovered)) return Colors.grey.shade50;
                            return null;
                          }),
                          cells: [
                            DataCell(Text(node['id'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                            DataCell(Text(node['name'], style: TextStyle(color: isAvailable ? Colors.grey.shade400 : Colors.black87, fontSize: 14))),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isAvailable ? Colors.green.shade50 : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: isAvailable ? Colors.green.shade200 : Colors.red.shade200),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(isAvailable ? Icons.check_circle : Icons.cancel, size: 14, color: isAvailable ? Colors.green.shade700 : Colors.red.shade700),
                                        const SizedBox(width: 6),
                                        Text(isAvailable ? 'ว่าง (Available)' : 'ไม่ว่าง (Unavailable)', 
                                          style: TextStyle(color: isAvailable ? Colors.green.shade700 : Colors.red.shade700, fontSize: 13, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  if (isAvailable) ...[
                                    const SizedBox(width: 16),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        _clearData(); 
                                        setState(() {
                                          selectedNodeId = node['id'].toString(); 
                                          _selectedMenuIndex = 1; 
                                          _autocompleteKey = UniqueKey(); 
                                        });
                                      },
                                      icon: const Icon(Icons.touch_app, size: 16),
                                      label: const Text('เลือก', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0056B3),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        minimumSize: const Size(0, 36),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))
                                      ),
                                    )
                                  ]
                                ],
                              )
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── หน้าฟอร์ม (Search & Reserve) ───
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
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Search Node ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF495057))),
                              const SizedBox(height: 8),
                              LayoutBuilder(builder: (context, constraints) {
                                return Autocomplete<String>(
                                  key: _autocompleteKey,
                                  initialValue: TextEditingValue(text: selectedNodeId ?? ''),
                                  displayStringForOption: (option) => option,
                                  optionsBuilder: (TextEditingValue textEditingValue) {
                                    if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                                    String input = textEditingValue.text;
                                    int? baseNumber = int.tryParse(input);
                                    if (baseNumber != null) {
                                      return List.generate(5, (index) => (baseNumber + index).toString());
                                    }
                                    return nodeIds.where((item) => item.toLowerCase().contains(input.toLowerCase()));
                                  },
                                  onSelected: (val) => setState(() => selectedNodeId = val),
                                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
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
                                        suffixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                                      ),
                                    );
                                  },
                                  optionsViewBuilder: (context, onSelected, options) {
                                    return Align(
                                      alignment: Alignment.topLeft,
                                      child: Material(
                                        elevation: 4,
                                        child: Container(
                                          width: constraints.maxWidth,
                                          constraints: const BoxConstraints(maxHeight: 250),
                                          child: ListView.builder(
                                            padding: EdgeInsets.zero, shrinkWrap: true,
                                            itemCount: options.length,
                                            itemBuilder: (BuildContext context, int index) {
                                              final String option = options.elementAt(index);
                                              bool isAvailable = int.parse(option) % 2 == 0; 
                                              return InkWell(
                                                onTap: () => onSelected(option),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(option, style: const TextStyle(fontWeight: FontWeight.w500)),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: isAvailable ? Colors.green.shade50 : Colors.red.shade50,
                                                          borderRadius: BorderRadius.circular(4),
                                                          border: Border.all(color: isAvailable ? Colors.green.shade200 : Colors.red.shade200),
                                                        ),
                                                        child: Text(isAvailable ? 'ว่าง' : 'ไม่ว่าง', 
                                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isAvailable ? Colors.green.shade700 : Colors.red.shade700)),
                                                      )
                                                    ],
                                                  ),
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
                          )),
                          const SizedBox(width: 20),
                          Expanded(child: _buildSearchField(
                            'Search Node Name', 'Type to search name',
                            nodeNames, selectedNodeName,
                            (val) => setState(() => selectedNodeName = val))),
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
                          Expanded(child: _buildDropdownField(
                            'Select Domain', domains, selectedDomain,
                            (val) {
                              setState(() {
                                selectedDomain = val;
                                selectedIpAddress = null;
                              });
                              if (val != null) _loadIpsByDomain(val);
                            })),
                          const SizedBox(width: 20),
                          Expanded(child: _buildSearchField(
                            'Search IP Assist', 'e.g., 10.98.4.200...',
                            ipList, selectedIpAddress,
                            (val) => setState(() => selectedIpAddress = val),
                            isDisabled: selectedDomain == null)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                      child: Row(
                        children: [
                          Expanded(child: _buildDropdownField(
                            'Select Model (LAN Switch)', models,
                            selectedModel,
                            (val) => setState(() => selectedModel = val))),
                          const SizedBox(width: 20),
                          Expanded(child: _buildDropdownField(
                            'Select Switch Port', switchPorts,
                            selectedPort,
                            (val) => setState(() => selectedPort = val))),
                        ],
                      ),
                    ),
                  ],

                  if (_currentPhase == 2) ...[
                    _buildStepHeader('2. ข้อมูล LSW Network'),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─── แถว 1: Search Site Code LSW & Site Name ───
                          Row(
                            children: [
                              Expanded(child: _buildSearchField(
                                'Search Site Code LSW', 'e.g., BCH-5012-UR',
                                siteCodes, selectedSiteCode, 
                                (val) => setState(() {
                                  selectedSiteCode = val;
                                  // Auto-fill ชื่อ Site 
                                  final found = mockSites.firstWhere((s) => s['code'] == val, orElse: () => {});
                                  if (found.isNotEmpty) selectedSiteName = found['name'];
                                  
                                  _tempSelectedPorts.clear(); 
                                  _tempIpNetworks.clear();
                                }))),
                              const SizedBox(width: 20),
                              Expanded(child: _buildSearchField(
                                'Search Site Name', 'e.g., True IDC...',
                                siteNames, selectedSiteName,
                                (val) => setState(() {
                                  selectedSiteName = val;
                                  // Auto-fill โค้ด Site
                                  final found = mockSites.firstWhere((s) => s['name'] == val, orElse: () => {});
                                  if (found.isNotEmpty) selectedSiteCode = found['code'];
                                  
                                  _tempSelectedPorts.clear(); 
                                  _tempIpNetworks.clear();
                                }))),
                            ],
                          ),
                          
                          // ─── โชว์ตารางก็ต่อเมื่อเลือก Site Code หรือ Site Name แล้ว ───
                          if ((selectedSiteCode != null && selectedSiteCode!.isNotEmpty) || (selectedSiteName != null && selectedSiteName!.isNotEmpty)) ...[
                            const SizedBox(height: 30),
                            _buildNetworkSelectionTable(),
                          ]
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

  // ─── ตารางเลือก Network ID, IP และ Port (เวอร์ชันอัปเกรด) ───
  Widget _buildNetworkSelectionTable() {
    // เอาแค่เลขเน้นๆ ตามรีเควส
    List<String> mockNetIds = ['85001', '85002'];
    List<Map<String, dynamic>> mockPorts = List.generate(10, (i) => {
      'port': 'GE-0/0/${i+1}', 
      'isAvailable': i % 2 == 0 
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Available Network Nodes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              // Header ของตาราง
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text('SITE CODE LSW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade700))),
                    Expanded(flex: 1, child: Text('NETWORK ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade700))),
                    Expanded(flex: 2, child: Text('SEARCH IP NETWORK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade700))),
                    Expanded(flex: 3, child: Text('SELECT PORT NETWORK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade700))),
                    Expanded(flex: 1, child: Text('ACTION', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade700))),
                  ]
                )
              ),
              // แถวข้อมูล
              ...mockNetIds.map((netId) {
                bool isSelected = selectedNodeNetworkId == netId; 
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.shade50 : Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey.shade200))
                  ),
                  child: Row(
                    children: [
                      // 1. คอลัมน์ Site Code LSW (ย้ำข้อมูล)
                      Expanded(flex: 2, child: Text(selectedSiteCode ?? '-', style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
                      
                      // 2. คอลัมน์ Network ID (ตัวเลขล้วน)
                      Expanded(flex: 1, child: Text(netId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                      
                      // 3. คอลัมน์ Search IP Network (ย้ายมาไว้ตรงนี้)
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: Autocomplete<String>(
                            initialValue: TextEditingValue(text: _tempIpNetworks[netId] ?? ''),
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                              return ipList.where((ip) => ip.contains(textEditingValue.text));
                            },
                            onSelected: (val) {
                              setState(() {
                                _tempIpNetworks[netId] = val;
                                if (isSelected) selectedIpNetwork = val;
                              });
                            },
                            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                onChanged: (val) {
                                  setState(() {
                                    _tempIpNetworks[netId] = val;
                                    if (isSelected) selectedIpNetwork = val;
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: 'e.g., 10.98...', hintStyle: TextStyle(color: Colors.grey.shade400),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
                                  filled: true, fillColor: Colors.white,
                                  isDense: true,
                                  suffixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
                                ),
                                style: const TextStyle(fontSize: 13),
                              );
                            },
                          ),
                        ),
                      ),
                      
                      // 4. คอลัมน์ Dropdown เลือก Port
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: DropdownButtonFormField<String>(
                            value: _tempSelectedPorts[netId],
                            isExpanded: true,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
                              filled: true, fillColor: Colors.white,
                              isDense: true,
                            ),
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                            hint: const Text('Select Port', style: TextStyle(fontSize: 13)),
                            items: mockPorts.map((p) {
                              bool isAvail = p['isAvailable'];
                              return DropdownMenuItem<String>(
                                value: p['port'],
                                enabled: isAvail, 
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(p['port'], style: TextStyle(color: isAvail ? Colors.black87 : Colors.grey.shade400, fontSize: 13)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isAvail ? Colors.green.shade50 : Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: isAvail ? Colors.green.shade200 : Colors.red.shade200)
                                      ),
                                      child: Text(isAvail ? 'ว่าง' : 'ไม่ว่าง', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isAvail ? Colors.green.shade700 : Colors.red.shade700))
                                    )
                                  ]
                                )
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _tempSelectedPorts[netId] = val;
                                if (isSelected) selectedPortNetwork = val; 
                              });
                            }
                          ),
                        )
                      ),
                      
                      // 5. ปุ่ม Action (เลือก)
                      Expanded(
                        flex: 1,
                        child: ElevatedButton(
                          onPressed: _tempSelectedPorts[netId] != null ? () {
                            setState(() {
                              selectedNodeNetworkId = netId; 
                              selectedPortNetwork = _tempSelectedPorts[netId]; 
                              selectedIpNetwork = _tempIpNetworks[netId]; // บันทึก IP ประจำแถว
                            });
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected ? Colors.green : const Color(0xFF0056B3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))
                          ),
                          child: Text(isSelected ? 'เลือกแล้ว' : 'เลือก', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))
                        )
                      )
                    ]
                  )
                );
              }).toList()
            ]
          )
        )
      ]
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
            onPressed: () => setState(() => _selectedMenuIndex = 1), 
            icon: const Icon(Icons.add),
            label: const Text('Create New Reservation'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056B3), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
          )
        ],
      ),
    );
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

  Widget _buildSearchField(String label, String hint, List<String> items,
      String? initialValue, Function(String) onSelected, {bool isDisabled = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(
          fontWeight: FontWeight.bold, fontSize: 13,
          color: isDisabled ? Colors.grey : const Color(0xFF495057))),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, constraints) {
          return Autocomplete<String>(
            key: _autocompleteKey,
            initialValue: TextEditingValue(text: initialValue ?? ''),
            displayStringForOption: (option) => option,
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty || isDisabled) return const Iterable<String>.empty();
              return items.where((item) =>
                item.toLowerCase().contains(textEditingValue.text.toLowerCase()));
            },
            onSelected: onSelected,
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: (val) => onSelected(val),
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
                  elevation: 4,
                  child: Container(
                    width: constraints.maxWidth,
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final String option = options.elementAt(index);
                        return InkWell(
                          onTap: () => onSelected(option),
                          child: Padding(padding: const EdgeInsets.all(16.0), child: Text(option)),
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
                subTitle: '${selectedSiteCode ?? "-"} / ${selectedSiteName ?? "-"}',
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
                    onPressed: _isConnectionTested ? () {
                      Navigator.pop(context);
                      _clearData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Network Configured Successfully!'),
                          backgroundColor: Colors.green));
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