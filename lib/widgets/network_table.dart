// ไฟล์: lib/widgets/network_table.dart
import 'package:flutter/material.dart';
import '../core/theme.dart';

class NetworkSelectionTable extends StatelessWidget {
  final List<Map<String, dynamic>> networkNodesRaw;
  final Map<String, List<Map<String, dynamic>>> networkPortsByNode;
  final String? loadingPortsForNode;
  final List<String> ipNetworkList;
  final List<Map<String, dynamic>> ipRaw;
  final String? selectedNodeNetworkId;
  final String? siteCode;
  final Map<String, String?> tempSelectedPorts;
  final Map<String, String?> tempIpNetworks;
  final Function(String nodeId) onNodeExpanded;
  final Function(String netId, int nodeNwID, String? port, int? portId, int? switchNwId, String? ip, int? ipId) onSelect;
  final Function(String netId, String? val) onPortChanged;
  final Function(String netId, String? val) onIpChanged;
  final VoidCallback? onShowDiagram;

  const NetworkSelectionTable({
    super.key,
    required this.networkNodesRaw,
    required this.networkPortsByNode,
    required this.loadingPortsForNode,
    required this.ipNetworkList,
    required this.ipRaw,
    required this.selectedNodeNetworkId,
    required this.tempSelectedPorts,
    required this.tempIpNetworks,
    required this.onNodeExpanded,
    required this.onSelect,
    required this.onPortChanged,
    required this.onIpChanged,
    this.siteCode,
    this.onShowDiagram,
  });

  // ── Test popup ──
  void _showTestPopup(BuildContext context, String netId, String nodeName) {
    final ipVal = tempIpNetworks[netId] ?? '-';
    final port  = tempSelectedPorts[netId] ?? '-';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2B2B2B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.white12)),
        title: const Text('Succeeded',
          style: TextStyle(color: Color(0xFFA5D63F), fontWeight: FontWeight.bold, fontSize: 24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _popupRow('Network ID',   netId),
            _popupRow('Node Name',    nodeName),
            if (siteCode != null) _popupRow('Site Code', siteCode!),
            _popupRow('IP Network',   ipVal),
            _popupRow('Port Network', port),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryLight, foregroundColor: Colors.white),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _popupRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text('$label: $value', style: const TextStyle(color: Colors.white70, fontSize: 14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Available Network Nodes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.dark)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              // ─── Header ───
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
                child: Row(children: [
                  Expanded(flex: 2, child: Text('NETWORK ID',         style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade700))),
                  Expanded(flex: 3, child: Text('NODE NAME',          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade700))),
                  Expanded(flex: 2, child: Text('SITE CODE',          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade700))),
                  Expanded(flex: 2, child: Text('SEARCH IP NETWORK',  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade700))),
                  Expanded(flex: 3, child: Text('SELECT PORT NETWORK',style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade700))),
                  Expanded(flex: 2, child: Text('TEST',               textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade700))),
                  Expanded(flex: 1, child: Text('ACTION',             textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade700))),
                ]),
              ),

              // ─── Rows ───
              networkNodesRaw.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('ไม่พบ Network Nodes', style: TextStyle(color: Colors.grey.shade400)))
                : Column(
                    children: networkNodesRaw.map((node) {
                      final netId      = node['NodeNwID'].toString();
                      final nodeName   = node['NodeName'].toString();
                      final isSelected = selectedNodeNetworkId == netId;
                      final ports      = networkPortsByNode[netId] ?? [];
                      final isLoadingPorts = loadingPortsForNode == netId;
                      final selectedPortName = tempSelectedPorts[netId];
                      final hasPort    = selectedPortName != null;

                      // โหลด ports ทันทีที่ row render
                      if (ports.isEmpty && loadingPortsForNode != netId) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          onNodeExpanded(netId);
                        });
                      }

                      final selectedPortData = ports.isNotEmpty && selectedPortName != null
                          ? ports.firstWhere((p) => p['Interface_Name'] == selectedPortName, orElse: () => {})
                          : <String, dynamic>{};

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue.shade50 : Colors.white,
                          border: Border(top: BorderSide(color: Colors.grey.shade200))),
                        child: Row(children: [

                          // Network ID
                          Expanded(flex: 2, child: Text(netId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),

                          // Node Name
                          Expanded(flex: 3, child: Text(nodeName, style: TextStyle(fontSize: 13, color: Colors.grey.shade700), overflow: TextOverflow.ellipsis)),

                          // Site Code badge
                          Expanded(
                            flex: 2,
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.blue.shade100)),
                              child: Text(siteCode ?? '-',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.blue.shade700),
                                overflow: TextOverflow.ellipsis),
                            ),
                          ),

                          // IP Search
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

                          // Port Dropdown (lazy load)
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: isLoadingPorts
                                ? const SizedBox(height: 36,
                                    child: Center(child: SizedBox(width: 18, height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2))))
                                : DropdownButtonFormField<String>(
                                    value: ports.any((p) => p['Interface_Name'] == selectedPortName)
                                        ? selectedPortName : null,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
                                      filled: true, fillColor: Colors.white, isDense: true,
                                    ),
                                    icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                                    hint: const Text('Select Port', style: TextStyle(fontSize: 13)),
                                    items: ports.map((p) {
                                      final portName = p['Interface_Name'].toString();
                                      final status   = p['status'].toString();
                                      final isAvail  = status == 'available';
                                      return DropdownMenuItem<String>(
                                        value: portName,
                                        enabled: isAvail,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(portName, style: TextStyle(color: isAvail ? Colors.black87 : Colors.grey.shade400, fontSize: 13)),
                                            _buildStatusBadge(status),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) => onPortChanged(netId, val),
                                  ),
                            ),
                          ),

                          // Test button
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ElevatedButton.icon(
                                onPressed: hasPort
                                  ? () => _showTestPopup(context, netId, nodeName)
                                  : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.info,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey.shade200,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                                icon: const Icon(Icons.wifi_protected_setup, size: 16),
                                label: const Text('Test', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                          ),

                          // Action button
                          Expanded(
                            flex: 1,
                            child: ElevatedButton(
                              onPressed: hasPort && selectedPortData['status'] == 'available'
                                ? () {
                                    final ipVal = tempIpNetworks[netId] ?? '';
                                    final ipObj = ipRaw.firstWhere((i) => i['IP'].toString() == ipVal, orElse: () => {});
                                    onSelect(
                                      netId,
                                      node['NodeNwID'] as int,
                                      selectedPortName,
                                      selectedPortData.isNotEmpty ? selectedPortData['Interface_ID'] as int? : null,
                                      selectedPortData.isNotEmpty ? selectedPortData['SwitchNw_ID'] as int? : null,
                                      ipVal.isNotEmpty ? ipVal : null,
                                      ipObj.isNotEmpty ? ipObj['IP_id'] as int : null,
                                    );
                                    if (onShowDiagram != null) {
                                      Future.microtask(() => onShowDiagram!());
                                    }
                                  }
                                : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected ? Colors.green : AppColors.primary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.shade200,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              child: Text(isSelected ? 'เลือกแล้ว' : 'เลือก',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        ]),
                      );
                    }).toList(),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final isAvail = status == 'available';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isAvail ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isAvail ? Colors.green.shade200 : Colors.red.shade200)),
      child: Text(isAvail ? 'ว่าง' : 'ไม่ว่าง',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
          color: isAvail ? Colors.green.shade700 : Colors.red.shade700)),
    );
  }
}