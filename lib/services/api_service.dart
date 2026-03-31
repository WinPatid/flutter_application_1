// ไฟล์: lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api/v1';

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

  // ─── Network Nodes ───
  Future<List<Map<String, dynamic>>> fetchNetworkNodes({String? search}) async {
    final uri = Uri.parse('$baseUrl/network-nodes')
        .replace(queryParameters: search != null ? {'search': search} : null);
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