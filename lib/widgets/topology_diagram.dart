// ไฟล์: lib/widgets/topology_diagram.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TopologyDiagram extends StatelessWidget {
  final String? selectedSiteCode;
  final String? selectedSiteName;
  final String? selectedNodeNetworkId;
  final String? selectedIpNetwork;
  final String? selectedPortNetwork;
  final String? selectedDomain;
  final String? selectedAreaGroup;
  final String? selectedNodeId;
  final String? selectedNodeName;
  final String? selectedIpAddress;
  final String? selectedPort;
  final String? selectedModel;
  final bool isConnectionTested;

  // IDs สำหรับ submit
  final int? selectedNodeAcID;
  final int? selectedTemplateId;
  final int? selectedIpAccessId;
  final int? selectedModelId;
  final int? selectedNodeNwID;
  final int? selectedPortNetworkId;
  final int? selectedIpNetworkId;
  final int? selectedSwitchNwId;

  final VoidCallback onTestConnection;
  final VoidCallback onBack;
  final VoidCallback onSuccess;
  final ApiService api;

  const TopologyDiagram({
    super.key,
    this.selectedSiteCode,
    this.selectedSiteName,
    this.selectedNodeNetworkId,
    this.selectedIpNetwork,
    this.selectedPortNetwork,
    this.selectedDomain,
    this.selectedAreaGroup,
    this.selectedNodeId,
    this.selectedNodeName,
    this.selectedIpAddress,
    this.selectedPort,
    this.selectedModel,
    required this.isConnectionTested,
    this.selectedNodeAcID,
    this.selectedTemplateId,
    this.selectedIpAccessId,
    this.selectedModelId,
    this.selectedNodeNwID,
    this.selectedPortNetworkId,
    this.selectedIpNetworkId,
    this.selectedSwitchNwId,
    required this.onTestConnection,
    required this.onBack,
    required this.onSuccess,
    required this.api,
  });

  @override
  Widget build(BuildContext context) {
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
              _buildNode(
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
              _buildLink(
                leftPort: selectedPortNetwork ?? 'GE-?',
                rightPort: selectedPort ?? 'GE-?'),
              _buildNode(
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
                onPressed: onTestConnection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF17A2B8), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Icon(Icons.wifi_protected_setup, size: 20),
                label: const Text('Test Connection', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: onBack,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    child: const Text('Back to Edit', style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 15),
                  ElevatedButton.icon(
                    onPressed: isConnectionTested ? () async {
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
                        'access_switch_id':   0,
                        'access_port_id':     0,
                        'access_ip_id':       selectedIpAccessId,
                        'access_template_id': selectedTemplateId,
                        'access_model_id':    selectedModelId,
                        'network_node_id':    selectedNodeNwID,
                        'network_switch_id':  selectedSwitchNwId,
                        'network_port_id':    selectedPortNetworkId,
                        'network_ip_id':      selectedIpNetworkId,
                        'status':             'planned',
                      };
                      final ok = await api.submitReservation(payload);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      if (ok) {
                        onSuccess();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ Network Configured Successfully!'), backgroundColor: Colors.green));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('❌ บันทึกไม่สำเร็จ กรุณาตรวจสอบข้อมูล'), backgroundColor: Colors.red));
                      }
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isConnectionTested ? const Color(0xFF28A745) : Colors.grey.shade300,
                      foregroundColor: isConnectionTested ? Colors.white : Colors.grey.shade500,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade500,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(Icons.check_circle, size: 20),
                    label: const Text('Confirm Configuration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNode({required IconData icon, required String title,
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
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18,
            color: isFinalNode ? const Color(0xFF0056B3) : Colors.teal.shade700), textAlign: TextAlign.center),
          Text(subTitle, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 15),
          const Divider(thickness: 1),
          const SizedBox(height: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: data.map((item) => Text(item, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))).toList()),
        ],
      ),
    );
  }

  Widget _buildLink({required String leftPort, required String rightPort}) {
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