import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
   //static const String baseUrl = 'http://192.168.100.15:8000/api/';
  static const String baseUrl = 'https://peach-valley-hotel.up.railway.app/api/';
  static String? _token;
  static bool _initialized = false;

  static Future<void> _init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _initialized = true;
  }

  static Future<String?> getToken() async {
    await _init();
    return _token;
  }

  static Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> removeToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = await getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // ==================== GET ====================
  static Future<dynamic> get(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final body = json.decode(response.body);
      throw Exception(body['message'] ?? 'Lỗi: ${response.statusCode}');
    }
  }

  // ==================== POST ====================
  static Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: json.encode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      final body = json.decode(response.body);
      throw Exception(body['message'] ?? 'Lỗi: ${response.statusCode}');
    }
  }

  // ==================== PUT ====================
  static Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final body = json.decode(response.body);
      throw Exception(body['message'] ?? 'Lỗi: ${response.statusCode}');
    }
  }

  // ==================== DELETE (THÊM MỚI) ====================
  static Future<dynamic> delete(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      // 204 No Content - không có body
      if (response.body.isEmpty) {
        return {'success': true, 'message': 'Xóa thành công'};
      }
      return json.decode(response.body);
    } else {
      final body = json.decode(response.body);
      throw Exception(body['message'] ?? 'Lỗi: ${response.statusCode}');
    }
  }

  // ==================== PATCH (THÊM NẾU CẦN) ====================
  static Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final body = json.decode(response.body);
      throw Exception(body['message'] ?? 'Lỗi: ${response.statusCode}');
    }
  }

  // ==================== GET USER PROFILE ====================
  static Future<Map<String, dynamic>> getUserProfile() async {
    return await get('mobile/user-profile');
  }
}