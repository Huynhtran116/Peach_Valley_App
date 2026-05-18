// services/khuyen_mai_service.dart
import 'dart:convert';
import 'api_service.dart';

class KhuyenMaiService {
  // 🔥 Lấy kho khuyến mãi của khách hàng
  static Future<List<Map<String, dynamic>>> getKhoKhuyenMai(int maKH) async {
    try {
      final response = await ApiService.get('kho-khuyen-mai/khach-hang/$maKH');

      List<dynamic> data = [];
      if (response is List) {
        data = response;
      } else if (response['data'] is List) {
        data = response['data'];
      }

      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('❌ Lỗi lấy kho KM: $e');
      return [];
    }
  }

  // 🔥 Đổi mã bằng điểm
  static Future<Map<String, dynamic>> doiBangDiem(int maKH, String maKM) async {
    try {
      final response = await ApiService.post('kho-khuyen-mai/doi-bang-diem', {
        'MaKM': maKM,
        'MaKH': maKH,
      });
      return Map<String, dynamic>.from(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  // 🔥 Sử dụng mã khi thanh toán
  static Future<Map<String, dynamic>> suDungKhuyenMai(int maKH, String maKM) async {
    try {
      final response = await ApiService.post('kho-khuyen-mai/su-dung', {
        'MaKM': maKM,
        'MaKH': maKH,
      });
      return Map<String, dynamic>.from(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  // 🔥 Kiểm tra điểm trước khi đổi
  static Future<Map<String, dynamic>> kiemTraDiem(int maKH, String maKM) async {
    try {
      final response = await ApiService.get('kho-khuyen-mai/kiem-tra-diem/$maKH/$maKM');

      if (response['data'] != null) {
        return Map<String, dynamic>.from(response['data']);
      }

      // Fallback: Lấy thông tin khách hàng
      final khResponse = await ApiService.get('khach-hang/$maKH');
      int diemHienTai = 0;

      if (khResponse['data'] != null) {
        diemHienTai = khResponse['data']['DIEM'] ?? 0;
      }

      // Lấy điểm cần từ khuyến mãi
      final kmResponse = await ApiService.get('khuyen-mai/$maKM');
      int diemCan = 0;

      if (kmResponse['data'] != null) {
        diemCan = kmResponse['data']['Diem'] ?? 0;
      }

      return {
        'diemHienTai': diemHienTai,
        'diemCan': diemCan,
        'duDiem': diemHienTai >= diemCan,
        'diemThieu': (diemCan - diemHienTai) > 0 ? (diemCan - diemHienTai) : 0,
      };
    } catch (e) {
      print('❌ Lỗi kiểm tra điểm: $e');
      return {
        'diemHienTai': 0,
        'diemCan': 0,
        'duDiem': false,
        'diemThieu': 0,
      };
    }
  }
}