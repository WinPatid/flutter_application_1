// ไฟล์: lib/models/node_model.dart

class NodeModel {
  final String nodeId;
  final String nodeName;
  final String areaGroup;

  NodeModel({
    required this.nodeId, 
    required this.nodeName, 
    required this.areaGroup
  });

  // ฟังก์ชันแปลงข้อมูล JSON จาก Database ให้ใช้งานใน Flutter ได้ง่ายๆ
  factory NodeModel.fromJson(Map<String, dynamic> json) {
    return NodeModel(
      nodeId: json['node_id'] ?? '', 
      nodeName: json['node_name'] ?? '',
      areaGroup: json['area_group'] ?? '',
    );
  }
}