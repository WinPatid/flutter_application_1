// ไฟล์: lib/services/api_service.dart
import 'dart:convert';
// import 'package:http/http.dart' as http; // (เดี๋ยวตอนเชื่อมจริงเราจะเปิดใช้ตัวนี้)

class ApiService {
  // สมมติ URL API ของบริษัท
  static const String baseUrl = 'https://api.yourcompany.com/v1';

  // ตัวอย่างฟังก์ชันดึงข้อมูลจำลอง
  Future<List<Map<String, dynamic>>> fetchNodes() async {
    try {
      await Future.delayed(const Duration(seconds: 1)); // จำลองการโหลด
      return [
        {"id": "88860", "name": "บุญรอดบริวเวอรี่ คลังบางบัวทอง", "area": "BKK"},
        {"id": "99102", "name": "CP All สาขาเชียงใหม่", "area": "UPC"},
      ];
    } catch (e) {
      print("Error fetching nodes: $e");
      return [];
    }
  }

  // ตัวอย่างฟังก์ชันส่งข้อมูลบันทึกลง Database
  Future<bool> submitReservation(Map<String, dynamic> payload) async {
    try {
      print("กำลังส่งข้อมูลเข้า Database: $payload");
      await Future.delayed(const Duration(seconds: 1));
      return true; 
    } catch (e) {
      print("Error submitting: $e");
      return false;
    }
  }
}