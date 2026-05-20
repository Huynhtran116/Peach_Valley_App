// services/danh_gia_service.dart
import 'api_service.dart';
import '../models/danh_gia.dart';

class DanhGiaService {
  // 1. Lấy tất cả đánh giá (GET /api/danh-gia)
  static Future<Map<String, dynamic>> layTatCaDanhGia() async {
    try {
      final response = await ApiService.get('danh-gia');

      List<DanhGiaModel> danhSach = [];
      if (response is List) {
        danhSach = (response as List)
            .map((e) => DanhGiaModel.fromJson(Map<String, dynamic>.from(e))) // 🔥 SỬA
            .toList();
      } else if (response is Map && response['data'] is List) { // 🔥 SỬA
        danhSach = (response['data'] as List)
            .map((e) => DanhGiaModel.fromJson(Map<String, dynamic>.from(e))) // 🔥 SỬA
            .toList();
      }

      // Tính điểm trung bình
      double diemTB = 0.0;
      if (danhSach.isNotEmpty) {
        diemTB = danhSach.map((e) => e.sao).reduce((a, b) => a + b) / danhSach.length;
      }

      // Đếm số lượng theo sao
      Map<int, int> soLuongTheoSao = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      for (var dg in danhSach) {
        if (soLuongTheoSao.containsKey(dg.sao)) {
          soLuongTheoSao[dg.sao] = (soLuongTheoSao[dg.sao] ?? 0) + 1;
        }
      }

      return {
        'danhSach': danhSach,
        'tongDanhGia': danhSach.length,
        'diemTrungBinh': double.parse(diemTB.toStringAsFixed(1)),
        'soLuongTheoSao': soLuongTheoSao,
      };
    } catch (e) {
      print('❌ Lỗi load đánh giá: $e');
      return {
        'danhSach': [],
        'tongDanhGia': 0,
        'diemTrungBinh': 0.0,
        'soLuongTheoSao': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
      };
    }
  }

  // 2. Lấy đánh giá theo loại phòng (GET /api/danh-gia/loai-phong/{id})
  static Future<List<DanhGiaModel>> layDanhGiaTheoLoaiPhong(int maLoaiPhong) async {
    try {
      final response = await ApiService.get('danh-gia/loai-phong/$maLoaiPhong');

      List<DanhGiaModel> danhSach = [];
      if (response is List) {
        danhSach = (response as List)
            .map((e) => DanhGiaModel.fromJson(Map<String, dynamic>.from(e))) // 🔥 SỬA
            .toList();
      } else if (response is Map && response['data'] is List) { // 🔥 SỬA
        danhSach = (response['data'] as List)
            .map((e) => DanhGiaModel.fromJson(Map<String, dynamic>.from(e))) // 🔥 SỬA
            .toList();
      }

      return danhSach;
    } catch (e) {
      print('❌ Lỗi load đánh giá theo loại phòng: $e');
      return [];
    }
  }

  // 3. Gửi đánh giá mới (POST /api/danh-gia)
  static Future<Map<String, dynamic>> guiDanhGia({
    required int maDatPhong,
    required int sao,
    String? moTa,
  }) async {
    try {
      final response = await ApiService.post('danh-gia', {
        'MaDatPhong': maDatPhong,
        'Sao': sao,
        'MoTa': moTa ?? '',
        'NgayDanhGia': DateTime.now().toIso8601String().split('T')[0],
      });

      // 🔥 SỬA: Parse response thành Map<String, dynamic>
      final Map<String, dynamic> responseMap = Map<String, dynamic>.from(response);

      return {
        'success': true,
        'message': responseMap['message'] ?? 'Cảm ơn bạn đã đánh giá!',
        'data': responseMap['data'] != null
            ? DanhGiaModel.fromJson(Map<String, dynamic>.from(responseMap['data']))
            : null,
      };
    } catch (e) {
      print('❌ Lỗi gửi đánh giá: $e');
      return {
        'success': false,
        'message': 'Lỗi gửi đánh giá: ${e.toString().replaceFirst("Exception: ", "")}',
      };
    }
  }

  // 4. Cập nhật đánh giá (PUT /api/danh-gia/{id})
  static Future<Map<String, dynamic>> capNhatDanhGia({
    required int maDG,
    int? sao,
    String? moTa,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (sao != null) body['Sao'] = sao;
      if (moTa != null) body['MoTa'] = moTa;

      final response = await ApiService.put('danh-gia/$maDG', body);

      // 🔥 SỬA: Parse response thành Map<String, dynamic>
      final Map<String, dynamic> responseMap = Map<String, dynamic>.from(response);

      return {
        'success': true,
        'message': responseMap['message'] ?? 'Cập nhật đánh giá thành công',
        'data': responseMap['data'] != null
            ? DanhGiaModel.fromJson(Map<String, dynamic>.from(responseMap['data']))
            : null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi cập nhật: ${e.toString().replaceFirst("Exception: ", "")}',
      };
    }
  }

  // 5. Xóa đánh giá (DELETE /api/danh-gia/{id})
  static Future<bool> xoaDanhGia(int maDG) async {
    try {
      await ApiService.delete('danh-gia/$maDG');
      return true;
    } catch (e) {
      print('❌ Lỗi xóa đánh giá: $e');
      return false;
    }
  }

  // 6. Xem chi tiết đánh giá (GET /api/danh-gia/{id})
  static Future<DanhGiaModel?> layChiTietDanhGia(int maDG) async {
    try {
      final response = await ApiService.get('danh-gia/$maDG');
      if (response is Map) {
        final Map<String, dynamic> responseMap = Map<String, dynamic>.from(response); // 🔥 SỬA
        if (responseMap['MaDG'] != null) {
          return DanhGiaModel.fromJson(responseMap);
        }
      }
      return null;
    } catch (e) {
      print('❌ Lỗi xem chi tiết đánh giá: $e');
      return null;
    }
  }
}