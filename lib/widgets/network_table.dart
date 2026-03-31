// ไฟล์: lib/widgets/network_table.dart
import 'package:flutter/material.dart';

class NetworkSelectionTable extends StatelessWidget {
  final List<Map<String, dynamic>> networkNodesRaw;
  final List<Map<String, dynamic>> networkPortsRaw;
  final List<String> networkPorts;
  final List<String> ipNetworkList;
  final List<Map<String, dynamic>> ipRaw;
  final String? selectedNodeNetworkId;
  final Map<String, String?> tempSelectedPorts;
  final Map<String, String?> tempIpNetworks;
  final Function(String netId, int nodeNwID, String? port, int? portId, int? switchNwId, String? ip, int? ipId) onSelect;
  final Function(String netId, String? val) onPortChanged;
  final Function(String netId, String? val) onIpChanged;

  const NetworkSelectionTable({
    super.key,
    required this.networkNodesRaw,
    required this.networkPortsRaw,
    required this.networkPorts,
    required this.ipNetworkList,
    required this.ipRaw,
    required this.selectedNodeNetworkId,
    required this.tempSelectedPorts,
    required this.tempIpNetworks,
    required this.onSelect,
    required this.onPortChanged,
    required this.onIpChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Available Network Nodes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text('NETWORK ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade700))),
                    Expanded(flex: 3, child: Text('NODE NAME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade700))),
                    Expanded(flex: 2, child: Text('SEARCH IP NETWORK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade700))),
                    Expanded(flex: 3, child: Text('SELECT PORT NETWORK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade700))),
                    Expanded(flex: 1, child: Text('ACTION', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade700))),
                  ],
                ),
              ),

              // Rows
              networkNodesRaw.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('ไม่พบ Network Nodes', style: TextStyle(color: Colors.grey.shade400)))
                : Column(
                    children: networkNodesRaw.map((node) {
                      final netId    = node['NodeNwID'].toString();
                      final nodeName = node['NodeName'].toString();
                      final isSelected = selectedNodeNetworkId == netId;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue.shade50 : Colors.white,
                          border: Border(top: BorderSide(color: Colors.grey.shade200))),
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: Text(netId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                            Expanded(flex: 3, child: Text(nodeName, style: TextStyle(fontSize: 13, color: Colors.grey.shade700), overflow: TextOverflow.ellipsis)),

                            // IP search
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Autocomplete<String>(
                                  initialValue: TextEditingValue(text: tempIpNetworks[netId] ?? ''),
                                  optionsBuilder: (tv) {
                                    if (tv.text.isEmpty) return const Iterable<String>.empty();
                                    return ipNetworkList.where((ip) => ip.contains(tv.text));
                                  },
                                  onSelected: (val) => onIpChanged(netId, val),
                                  fieldViewBuilder: (context, controller, focusNode, _) {
                                    return TextField(
                                      controller: controller, focusNode: focusNode,
                                      onChanged: (val) => onIpChanged(netId, val),
                                      decoration: InputDecoration(
                                        hintText: 'e.g., 10.98...',
                                        hintStyle: TextStyle(color: Colors.grey.shade400),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
                                        filled: true, fillColor: Colors.white, isDense: true,
                                        suffixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
                                      ),
                                      style: const TextStyle(fontSize: 13),
                                    );
                                  },
                                ),
                              ),
                            ),

                            // Port dropdown
                            Expanded(
                              flex: 3,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: DropdownButtonFormField<String>(
                                  value: networkPorts.contains(tempSelectedPorts[netId]) ? tempSelectedPorts[netId] : null,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
                                    filled: true, fillColor: Colors.white, isDense: true,
                                  ),
                                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                                  hint: const Text('Select Port', style: TextStyle(fontSize: 13)),
                                  items: networkPortsRaw.map((p) {
                                    final portName = p['Interface_Name'].toString();
                                    final isAvail  = p['status'].toString() == 'available';
                                    return DropdownMenuItem<String>(
                                      value: portName,
                                      enabled: isAvail,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(portName, style: TextStyle(color: isAvail ? Colors.black87 : Colors.grey.shade400, fontSize: 13)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isAvail ? Colors.green.shade50 : Colors.red.shade50,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: isAvail ? Colors.green.shade200 : Colors.red.shade200)),
                                            child: Text(isAvail ? 'ว่าง' : 'ไม่ว่าง',
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                                                color: isAvail ? Colors.green.shade700 : Colors.red.shade700)),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) => onPortChanged(netId, val),
                                ),
                              ),
                            ),

                            // Action
                            Expanded(
                              flex: 1,
                              child: ElevatedButton(
                                onPressed: tempSelectedPorts[netId] != null ? () {
                                  final port = networkPortsRaw.firstWhere(
                                    (p) => p['Interface_Name'].toString() == tempSelectedPorts[netId], orElse: () => {});
                                  final ipVal = tempIpNetworks[netId] ?? '';
                                  final ipObj = ipRaw.firstWhere((i) => i['IP'].toString() == ipVal, orElse: () => {});
                                  onSelect(
                                    netId,
                                    node['NodeNwID'] as int,
                                    tempSelectedPorts[netId],
                                    port.isNotEmpty ? port['Interface_ID'] as int : null,
                                    port.isNotEmpty ? port['SwitchNw_ID'] as int : null,
                                    ipVal.isNotEmpty ? ipVal : null,
                                    ipObj.isNotEmpty ? ipObj['IP_id'] as int : null,
                                  );
                                } : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSelected ? Colors.green : const Color(0xFF0056B3),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                                child: Text(isSelected ? 'เลือกแล้ว' : 'เลือก',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}