// ไฟล์: lib/services/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api/v1';

  // ─── Dashboard ───
  Future<Map<String, dynamic>> fetchDashboardNodes() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/access-nodes/dashboard'));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      debugPrint('fetchDashboardNodes error: $e');
    }
    return {'nodes': [], 'available': [], 'recent': [], 'first_available_idx': null};
  }

  // ─── Access Nodes ───
  Future<List<Map<String, dynamic>>> fetchAccessNodes({String? search}) async {
    final uri = Uri.parse('$baseUrl/access-nodes')
        .replace(queryParameters: search != null ? {'search': search} : null);
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }
    return [];
  }

  Future<Map<String, dynamic>?> createNetworkNodeFull({
    required String nodeName,
    required int modelId,
    required int siteId,
    required int ipId,
    int? nodeId,
  }) async {
    final body = {
      'node_name': nodeName,
      'model_id':  modelId,
      'site_id':   siteId,
      'ip_id':     ipId,
      if (nodeId != null) 'node_id': nodeId,
    };
    final res = await http.post(Uri.parse('$baseUrl/network-nodes/full'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body));
    if (res.statusCode == 201) return jsonDecode(res.body);
    try {
      final err = jsonDecode(res.body);
      return {'error': err['detail'] ?? 'เกิดข้อผิดพลาด'};
    } catch (_) {
      return {'error': 'เกิดข้อผิดพลาด (${res.statusCode})'};
    }
  }

  // ─── Site CRUD ───
  Future<bool> createSite(String siteCode) async {
    final res = await http.post(Uri.parse('$baseUrl/sites'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Site_code': siteCode}));
    return res.statusCode == 201;
  }

  Future<bool> updateSite(int id, String siteCode) async {
    final res = await http.put(Uri.parse('$baseUrl/sites/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Site_code': siteCode}));
    return res.statusCode == 200;
  }

  Future<bool> deleteSite(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/sites/$id'));
    return res.statusCode == 204;
  }

  // ─── Roles ───
  Future<List<Map<String, dynamic>>> fetchRoles() async {
    final res = await http.get(Uri.parse('$baseUrl/roles'));
    if (res.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    return [];
  }

  Future<Map<String, dynamic>?> createRole(Map<String, dynamic> payload) async {
    final res = await http.post(Uri.parse('$baseUrl/roles'),
      headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload));
    if (res.statusCode == 201) return jsonDecode(res.body);
    try { return {'error': jsonDecode(res.body)['detail']}; } catch (_) { return {'error': 'Error'}; }
  }

  Future<Map<String, dynamic>?> updateRole(int id, Map<String, dynamic> payload) async {
    final res = await http.put(Uri.parse('$baseUrl/roles/$id'),
      headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload));
    if (res.statusCode == 200) return jsonDecode(res.body);
    try { return {'error': jsonDecode(res.body)['detail']}; } catch (_) { return {'error': 'Error'}; }
  }

  Future<Map<String, dynamic>?> deleteRole(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/roles/$id'));
    if (res.statusCode == 204) return {'ok': true};
    try { return {'error': jsonDecode(res.body)['detail']}; } catch (_) { return {'error': 'Error'}; }
  }

  // ─── Auth ───
  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}));
      if (res.statusCode == 200) return jsonDecode(res.body);
      final err = jsonDecode(res.body);
      return {'error': err['detail'] ?? 'Login ไม่สำเร็จ'};
    } catch (e) { return {'error': e.toString()}; }
  }

  // ─── Users ───
  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final res = await http.get(Uri.parse('$baseUrl/users'));
    if (res.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    return [];
  }

  Future<Map<String, dynamic>?> createUser(Map<String, dynamic> payload) async {
    final res = await http.post(Uri.parse('$baseUrl/users'),
      headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload));
    if (res.statusCode == 201) return jsonDecode(res.body);
    try { return {'error': jsonDecode(res.body)['detail']}; } catch (_) { return {'error': 'Error'}; }
  }

  Future<Map<String, dynamic>?> updateUser(int id, Map<String, dynamic> payload) async {
    final res = await http.put(Uri.parse('$baseUrl/users/$id'),
      headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload));
    if (res.statusCode == 200) return jsonDecode(res.body);
    try { return {'error': jsonDecode(res.body)['detail']}; } catch (_) { return {'error': 'Error'}; }
  }

  Future<bool> deleteUser(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/users/$id'));
    return res.statusCode == 204;
  }

  // ─── Subnet CSV ───
  Future<Map<String, dynamic>?> validateSubnetCsv(
      List<Map<String, dynamic>> rows) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/domains/validate-subnet-csv'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rows': rows}));
      if (res.statusCode == 200) return jsonDecode(res.body);
      return {'error': jsonDecode(res.body)['detail'] ?? 'Validate ไม่สำเร็จ'};
    } catch (e) { return {'error': e.toString()}; }
  }

  Future<Map<String, dynamic>?> importSubnetCsv(
      List<Map<String, dynamic>> rows) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/domains/import-subnet-csv'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rows': rows}));
      if (res.statusCode == 201) return jsonDecode(res.body);
      return {'error': jsonDecode(res.body)['detail'] ?? 'Import ไม่สำเร็จ'};
    } catch (e) { return {'error': e.toString()}; }
  }

  // ─── Network Node CSV ───
  Future<Map<String, dynamic>?> validateNetworkNodesCsv(
      List<Map<String, dynamic>> rows) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/network-nodes/validate-csv'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rows': rows}));
      if (res.statusCode == 200) return jsonDecode(res.body);
      final err = jsonDecode(res.body);
      return {'error': err['detail'] ?? 'Validate ไม่สำเร็จ'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> bulkImportNetworkNodes(
      List<Map<String, dynamic>> rows) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/network-nodes/bulk-import'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rows': rows}));
      if (res.statusCode == 201) return jsonDecode(res.body);
      final err = jsonDecode(res.body);
      return {'error': err['detail'] ?? 'Import ไม่สำเร็จ'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ─── Model CSV Import ───
  Future<Map<String, dynamic>?> importModelsCsv(List<Map<String, dynamic>> rows) async {
    final res = await http.post(Uri.parse('$baseUrl/models/import-csv'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'rows': rows}));
    if (res.statusCode == 201) return jsonDecode(res.body);
    try { return {'error': jsonDecode(res.body)['detail']}; } catch (_) { return {'error': 'Error'}; }
  }

  // ─── Model CRUD ───
  Future<bool> createModel(String name, String? type) async {
    final res = await http.post(Uri.parse('$baseUrl/models'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Model_Name': name, 'Model_type': type}));
    return res.statusCode == 201;
  }

  Future<bool> updateModel(int id, String name, String? type) async {
    final res = await http.put(Uri.parse('$baseUrl/models/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Model_Name': name, 'Model_type': type}));
    return res.statusCode == 200;
  }

  Future<bool> deleteModel(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/models/$id'));
    return res.statusCode == 204;
  }

  // ─── ModelInterface CRUD ───
  Future<bool> createModelInterface(int modelId, String name, String? type, String? speed, String? cable) async {
    final res = await http.post(Uri.parse('$baseUrl/model-interfaces'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Model_Id': modelId, 'Interface_Name': name, 'Interface_Type': type, 'speed': speed, 'cable_type': cable}));
    return res.statusCode == 201;
  }

  Future<bool> updateModelInterface(int templateId, String name, String? type, String? speed, String? cable) async {
    final res = await http.put(Uri.parse('$baseUrl/model-interfaces/$templateId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Interface_Name': name, 'Interface_Type': type, 'speed': speed, 'cable_type': cable}));
    return res.statusCode == 200;
  }

  Future<bool> deleteModelInterface(int templateId) async {
    final res = await http.delete(Uri.parse('$baseUrl/model-interfaces/$templateId'));
    return res.statusCode == 204;
  }

  // ─── Domain CRUD ───
  Future<bool> createDomain(String name, int? vlan) async {
    final res = await http.post(Uri.parse('$baseUrl/domains'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Domain_Name': name, 'Vlan': vlan}));
    return res.statusCode == 201;
  }

  Future<bool> updateDomain(int id, String name, int? vlan) async {
    final res = await http.put(Uri.parse('$baseUrl/domains/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Domain_Name': name, 'Vlan': vlan}));
    return res.statusCode == 200;
  }

  Future<bool> deleteDomain(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/domains/$id'));
    return res.statusCode == 204;
  }

  Future<Map<String, dynamic>?> deleteSubnet(int domainId, String subnet) async {
    final uri = Uri.parse('$baseUrl/domains/$domainId/ips/subnet').replace(
      queryParameters: {'subnet': subnet});
    final res = await http.delete(uri);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  Future<Map<String, dynamic>?> bulkCreateIps(int domainId, String subnet, int prefix) async {
    final res = await http.post(
      Uri.parse('$baseUrl/domains/$domainId/ips/bulk'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'subnet': subnet, 'prefix': prefix}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  // ─── IP CRUD ───
  Future<List<Map<String, dynamic>>> fetchIpsWithStatus(int domainId) async {
    final res = await http.get(Uri.parse('$baseUrl/domains/$domainId/ips-status'));
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }
    return [];
  }

  Future<bool> createIp(int domainId, String ip, int? prefix) async {
    final res = await http.post(Uri.parse('$baseUrl/domains/$domainId/ips'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'IP': ip, 'Prefix': prefix}));
    return res.statusCode == 201;
  }

  Future<bool> updateIp(int id, String ip, int? prefix) async {
    final res = await http.put(Uri.parse('$baseUrl/ips/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'IP': ip, 'Prefix': prefix}));
    return res.statusCode == 200;
  }

  Future<bool> deleteIp(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/ips/$id'));
    return res.statusCode == 204;
  }

  // ─── Bulk Import ───
  Future<List<Map<String, dynamic>>?> validateBulkImport(List<Map<String, dynamic>> rows) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/connections/validate-bulk'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(rows));
      if (res.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> bulkImport(List<Map<String, dynamic>> rows) async {
    final res = await http.post(
      Uri.parse('$baseUrl/connections/bulk-import'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(rows),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception('Bulk import failed: ${res.statusCode}');
  }

  // ─── Network Node Ports (template + status) ───
  Future<List<Map<String, dynamic>>> fetchNetworkNodePorts(int nodeId) async {
    final res = await http.get(Uri.parse('$baseUrl/network-nodes/$nodeId/ports'));
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }
    return [];
  }

  // ─── Network Nodes ───
  Future<List<Map<String, dynamic>>> fetchNetworkNodes({String? search, String? siteCode}) async {
    final params = <String, String>{};
    if (search != null) params['search'] = search;
    if (siteCode != null) params['site_code'] = siteCode;
    final uri = Uri.parse('$baseUrl/network-nodes').replace(queryParameters: params.isEmpty ? null : params);
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }
    return [];
  }

  // ─── Site auto-fill ───
  Future<String> fetchSiteForNetworkNode(int nodeId) async {
    final res = await http.get(Uri.parse('$baseUrl/network-nodes/$nodeId/site'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['site_location'] ?? '-';
    }
    return '-';
  }

  // ─── Sites ───
  Future<List<Map<String, dynamic>>> fetchSites() async {
    final res = await http.get(Uri.parse('$baseUrl/sites'));
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }
    return [];
  }

  // ─── Domains ───
  Future<List<Map<String, dynamic>>> fetchDomains() async {
    final res = await http.get(Uri.parse('$baseUrl/domains'));
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }
    return [];
  }

  // ─── IPs by Domain ───
  Future<List<Map<String, dynamic>>> fetchIpsByDomain(int domainId) async {
    final res = await http.get(Uri.parse('$baseUrl/domains/$domainId/ips'));
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }
    return [];
  }

  // ─── Access Interfaces ───
  Future<List<Map<String, dynamic>>> fetchAccessInterfaces({int? switchId}) async {
    final uri = Uri.parse('$baseUrl/access-interfaces').replace(
        queryParameters: switchId != null ? {'switch_id': '$switchId'} : null);
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }
    return [];
  }

  // ─── Network Interfaces ───
  Future<List<Map<String, dynamic>>> fetchNetworkInterfaces({int? switchId}) async {
    final uri = Uri.parse('$baseUrl/network-interfaces').replace(
        queryParameters: switchId != null ? {'switch_id': '$switchId'} : null);
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }
    return [];
  }

  // ─── Model Interfaces (Port Templates) ───
  Future<List<Map<String, dynamic>>> fetchModelInterfaces({int? modelId}) async {
    final uri = Uri.parse('$baseUrl/model-interfaces').replace(
        queryParameters: modelId != null ? {'model_id': '$modelId'} : null);
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }
    return [];
  }

  // ─── Models ───
  Future<List<Map<String, dynamic>>> fetchModels({String? modelType}) async {
    final uri = Uri.parse('$baseUrl/models').replace(
        queryParameters: modelType != null ? {'model_type': modelType} : null);
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }
    return [];
  }

  // ─── Submit Reservation ───
  Future<bool> submitReservation(Map<String, dynamic> payload) async {
    final res = await http.post(
      Uri.parse('$baseUrl/connections'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    return res.statusCode == 201;
  }

  // ─── Topology ───
  Future<Map<String, dynamic>?> fetchTopology(int connectionId) async {
    final res = await http.get(Uri.parse('$baseUrl/connections/$connectionId/topology'));
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }
}