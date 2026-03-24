// ไฟล์: lib/screens/node_assist_screen.dart
import 'package:flutter/material.dart';

class NodeAssistScreen extends StatefulWidget {
  const NodeAssistScreen({super.key});

  @override
  State<NodeAssistScreen> createState() => _NodeAssistScreenState();
}

class _NodeAssistScreenState extends State<NodeAssistScreen> {
  // --- Page State ---
  int _currentPhase = 1;
  Key _autocompleteKey = UniqueKey(); 

  // --- Form State (Phase 1: LSW Access) ---
  String? selectedNodeId;
  String? selectedNodeName;
  String? selectedAreaGroup;
  String? selectedDomain;
  String? selectedIpAddress;
  String? selectedModel;
  String? selectedPort;
  
  // --- Form State (Phase 2: LSW Network) ---
  String? selectedNodeNetworkId;
  String? selectedIpNetwork;
  String? selectedPortNetwork;

  // 📦 Mock Data 
  final List<String> mockNodeIds = ['88860', '88005', '99012', '99444', '85001'];
  final List<String> mockNodeNames = ['Boonrawd Brewery', 'CP All Chiang Mai', 'Boot_Navamin', 'PEA Chonburi', 'BCH_FL21'];
  List<String> get mockAreaGroups => ['BKK', 'UPC'];
  
  final Map<String, List<String>> domainIpMap = {
    'Domain-A (LSW-CBI-115)': ['10.98.4.113', '10.98.4.18', '10.98.4.82'],
    'Domain-B (LSW-RBT-100)': ['10.99.200.10', '10.98.4.200'],
  };

  List<String> get mockModels => ['S5700', 'S9700', 'S5200'];
  List<String> get mockSwitchPorts => ['GE-0/0/1', 'GE-0/0/6', 'GE-0/0/9'];

  // Mock Data for Phase 2
  List<String> get mockNodeNetworkIds => ['85001_BCH_FL21', 'Network-Core-A', 'Ring-Bkk-12'];
  List<String> get mockIpNetworks => ['10.98.4.10/24', '10.100.1.0/24', '192.168.1.0/24'];
  List<String> get mockPortNetworks => ['GE-0/0/6', 'Core-XG1', 'Uplink-9'];

  // 🧠 Logic Auto-fill Site Location
  String get autoFilledSite {
    if (selectedNodeNetworkId == '85001_BCH_FL21') return 'BCH Site - Floor 21';
    if (selectedNodeNetworkId == 'Network-Core-A') return 'BKK Office - Zone A';
    if (selectedNodeNetworkId == 'Ring-Bkk-12') return 'CBI Facility - Bldg B';
    return 'Pending auto-detection...'; 
  }

  // Clear Form
  void _clearData() {
    setState(() {
      selectedNodeId = null;
      selectedNodeName = null;
      selectedAreaGroup = null;
      selectedDomain = null;
      selectedIpAddress = null;
      selectedModel = null;
      selectedPort = null;
      selectedNodeNetworkId = null;
      selectedIpNetwork = null;
      selectedPortNetwork = null;
      _currentPhase = 1; 
      _autocompleteKey = UniqueKey(); 
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Form cleared successfully'), backgroundColor: Colors.blue),
    );
  }

  void _submitData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: _buildDiagramSummary(), // เรียกใช้ฟังก์ชัน Diagram 2 กล่อง
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: const Color(0xFF212529),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 60, width: double.infinity, color: const Color(0xFF1A1D20),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: const Text('NODE ASSIST PRO', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                ),
                _buildSidebarItem(Icons.search, 'Search & Reserve', isActive: true),
                _buildSidebarItem(Icons.settings_ethernet, 'Network Topology'),
                _buildSidebarItem(Icons.storage, 'Database Overview'),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top App Bar
                Container(
                  height: 60, padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('System  >  Node Assist  >  New Reservation', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                      const CircleAvatar(radius: 16, backgroundColor: Color(0xFFE8F0FE), child: Icon(Icons.person, size: 20, color: Color(0xFF0056B3))),
                    ],
                  ),
                ),

                // Form Area
                Expanded(
                  child: Column(
                    children: [
                      // --- Progress Indicator ---
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                        child: Row(
                          children: [
                            _buildPhaseIndicator(1, "ข้อมูล LSW Access", _currentPhase >= 1),
                            Expanded(child: Divider(color: _currentPhase == 2 ? const Color(0xFF0056B3) : Colors.grey.shade300, thickness: 2)),
                            _buildPhaseIndicator(2, "ข้อมูล LSW Network", _currentPhase == 2),
                          ],
                        ),
                      ),

                      // --- Content Area ---
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white, borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                
                                // ================= PHASE 1 =================
                                if (_currentPhase == 1) ...[
                                  _buildStepHeader('1. ข้อมูล LSW Access'),
                                  
                                  Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _buildSearchField('Search Node ID', 'e.g., 99012', mockNodeIds, selectedNodeId, (val) => setState(() => selectedNodeId = val)),
                                        ),
                                        const SizedBox(width: 20),
                                        Expanded(
                                          child: _buildSearchField('Search Node Name', 'Type to search name', mockNodeNames, selectedNodeName, (val) => setState(() => selectedNodeName = val)),
                                        ),
                                        const SizedBox(width: 20),
                                        Expanded(
                                          child: _buildDropdownField('Select Area Group', mockAreaGroups, selectedAreaGroup, (val) => setState(() => selectedAreaGroup = val)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  Padding(
                                    padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _buildDropdownField('Select Domain', domainIpMap.keys.toList(), selectedDomain, (val) {
                                              setState(() {
                                                selectedDomain = val;
                                                selectedIpAddress = null; 
                                              });
                                            }
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        Expanded(
                                          child: _buildSearchField(
                                            'Search IP Assist', 'e.g., 10.98.4.200...', 
                                            selectedDomain != null ? domainIpMap[selectedDomain!]! : [], 
                                            selectedIpAddress,
                                            (val) => setState(() => selectedIpAddress = val),
                                            isDisabled: selectedDomain == null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0),
                                    child: Row(
                                      children: [
                                        Expanded(child: _buildDropdownField('Select Model (LAN Switch)', mockModels, selectedModel, (val) => setState(() => selectedModel = val))),
                                        const SizedBox(width: 20),
                                        Expanded(child: _buildDropdownField('Select Switch Port', mockSwitchPorts, selectedPort, (val) => setState(() => selectedPort = val))),
                                      ],
                                    ),
                                  ),
                                ],

                                // ================= PHASE 2 =================
                                if (_currentPhase == 2) ...[
                                  _buildStepHeader('2. ข้อมูล LSW Network'),
                                  Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildSearchField('Search Network ID', 'e.g., 85001_BCH...', mockNodeNetworkIds, selectedNodeNetworkId, (val) => setState(() => selectedNodeNetworkId = val)),
                                            ),
                                            const SizedBox(width: 20),
                                            Expanded(
                                              child: _buildSearchField('Search IP Network', 'e.g., 10.98.4.10...', mockIpNetworks, selectedIpNetwork, (val) => setState(() => selectedIpNetwork = val)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildReadOnlyField('Site Location (Auto-fill)', autoFilledSite),
                                            ),
                                            const SizedBox(width: 20),
                                            Expanded(
                                              child: _buildDropdownField('Select Port Network', mockPortNetworks, selectedPortNetwork, (val) => setState(() => selectedPortNetwork = val)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                
                                // --- Action Buttons ---
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                  decoration: BoxDecoration(color: const Color(0xFFF8F9FA), border: Border(top: BorderSide(color: Colors.grey.shade300))),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (_currentPhase == 2)
                                        OutlinedButton.icon(
                                          onPressed: () => setState(() => _currentPhase = 1),
                                          icon: const Icon(Icons.arrow_back), label: const Text('Back'),
                                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
                                        )
                                      else
                                        TextButton(onPressed: _clearData, child: const Text('Clear Form Data', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
                                      
                                      if (_currentPhase == 1)
                                        ElevatedButton.icon(
                                          onPressed: () => setState(() => _currentPhase = 2),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF0056B3), foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                          ),
                                          icon: const Icon(Icons.arrow_forward, size: 20), label: const Text('Next Step', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        )
                                      else
                                        ElevatedButton.icon(
                                          onPressed: _submitData,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF28A745), foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                          ),
                                          icon: const Icon(Icons.auto_graph, size: 20), label: const Text('View Topology Diagram', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        ),
                                    ],
                                 ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget Builders ---
  Widget _buildPhaseIndicator(int stepNumber, String title, bool isActive) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: isActive ? const Color(0xFF0056B3) : Colors.grey.shade300, shape: BoxShape.circle),
          child: Center(child: Text(stepNumber.toString(), style: TextStyle(color: isActive ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 12),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? const Color(0xFF0056B3) : Colors.grey.shade500, fontSize: 16)),
      ],
    );
  }

  Widget _buildStepHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), border: Border.symmetric(horizontal: BorderSide(color: Colors.grey.shade300))),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, {bool isActive = false}) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF0056B3).withOpacity(0.15) : Colors.transparent,
        border: Border(left: BorderSide(color: isActive ? const Color(0xFF0056B3) : Colors.transparent, width: 4)),
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? Colors.white : Colors.grey.shade400, size: 22),
        title: Text(title, style: TextStyle(color: isActive ? Colors.white : Colors.grey.shade400, fontSize: 14, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        onTap: () {},
      ),
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
            fontSize: 15
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFE8F0FE), 
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(String label, String hint, List<String> items, String? initialValue, Function(String) onSelected, {bool isDisabled = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDisabled ? Colors.grey : const Color(0xFF495057))),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            return Autocomplete<String>(
              key: _autocompleteKey, 
              initialValue: TextEditingValue(text: initialValue ?? ''),
              displayStringForOption: (option) => option,
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty || isDisabled) return const Iterable<String>.empty();
                return items.where((item) => item.toLowerCase().contains(textEditingValue.text.toLowerCase()));
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
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(option),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            );
          }
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> items, String? currentValue, Function(String?) onChanged) {
    final validValue = items.contains(currentValue) ? currentValue : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF495057))),
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
          items: items.toSet().toList().map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 15)))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // ⭐️⭐️⭐️ ไฮไลท์: สร้าง Diagram 2 กล่องตามรูปบนกระดาน Whiteboard ⭐️⭐️⭐️
  Widget _buildDiagramSummary() {
    return Container(
      width: 750, // ปรับขนาดให้พอดีกับ 2 กล่อง
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, 
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Network Topology Summary', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0056B3))),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(thickness: 1),
          const SizedBox(height: 30),

          // Diagram Area
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 📦 กล่องซ้าย: LSW Network (ข้อมูลจาก Phase 2)
              _buildDiagramNode(
                icon: Icons.dns, // ไอคอน Server/Network
                title: 'LSW Network',
                subTitle: autoFilledSite, // ชื่อ Site
                data: [
                  'ID: ${selectedNodeNetworkId ?? "-"}',
                  'IP: ${selectedIpNetwork ?? "-"}',
                ],
              ),
              
              // 🔗 เส้นเชื่อมตรงกลาง พร้อมเลข Port หัวท้าย (สีเขียวคล้ายเมจิก)
              _buildDiagramLink(
                leftPort: selectedPortNetwork ?? 'GE-?', 
                rightPort: selectedPort ?? 'GE-?'
              ),

              // 📦 กล่องขวา: LSW Access (ข้อมูลจาก Phase 1)
              _buildDiagramNode(
                icon: Icons.router, // ไอคอน Switch
                title: 'LSW Access',
                subTitle: selectedModel ?? 'Switch Model', // รุ่น S5200
                data: [
                  'ID: ${selectedNodeId ?? "-"} - ${selectedNodeName ?? "-"}',
                  'IP: ${selectedIpAddress ?? "-"}',
                  '', // เว้นบรรทัด
                  'Domain: ${selectedDomain?.split(' ').first ?? "-"}', // โชว์แค่ชื่อ Domain หน้า
                  'Area Group: ${selectedAreaGroup ?? "-"}',
                ],
                isFinalNode: true,
              ),
            ],
          ),

          const SizedBox(height: 40),
          const Divider(thickness: 1),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Back to Edit', style: TextStyle(color: Colors.grey))),
              const SizedBox(width: 15),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _clearData();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Network Configured Successfully!'), backgroundColor: Colors.green));
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF28A745), foregroundColor: Colors.white),
                icon: const Icon(Icons.check_circle, size: 20),
                label: const Text('Confirm Configuration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          )
        ],
      ),
    );
  }

  // สร้างกล่อง (Node) บน Diagram
  Widget _buildDiagramNode({required IconData icon, required String title, required String subTitle, required List<String> data, bool isFinalNode = false}) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isFinalNode ? const Color(0xFF0056B3) : Colors.teal.shade600, width: 2), // สีขอบกล่องต่างกัน
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: isFinalNode ? const Color(0xFF0056B3) : Colors.teal.shade600),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isFinalNode ? const Color(0xFF0056B3) : Colors.teal.shade700), textAlign: TextAlign.center),
          Text(subTitle, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 15),
          const Divider(thickness: 1),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.map((item) => Text(item, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), textAlign: TextAlign.left)).toList(),
          ),
        ],
      ),
    );
  }

  // สร้างเส้นเชื่อมโยง (Link) ตรงกลาง พร้อมชื่อ Port
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
            Container(
              height: 3,
              color: Colors.teal.shade300, // สีเส้นเขียวอมฟ้าคล้ายปากกาไวท์บอร์ด
            ),
          ],
        ),
      ),
    );
  }
}