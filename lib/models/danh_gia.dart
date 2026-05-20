// models/danh_gia.dart
import '../utils/number_parser.dart';

class DanhGiaModel {
  final int maDG;
  final int maDatPhong;
  final int sao;
  final String? moTa;
  final DateTime? ngayDanhGia;

  // Thông tin từ relationships (có thể null nếu API không include)
  final String? tenKhachHang;
  final String? tenLoaiPhong;
  final int? maLoaiPhong;

  DanhGiaModel({
    required this.maDG,
    required this.maDatPhong,
    required this.sao,
    this.moTa,
    this.ngayDanhGia,
    this.tenKhachHang,
    this.tenLoaiPhong,
    this.maLoaiPhong,
  });

  factory DanhGiaModel.fromJson(Map<String, dynamic> json) {
    // Parse nested relationships từ Laravel
    String? tenKhachHang;
    String? tenLoaiPhong;
    int? maLoaiPhong;

    // Laravel trả về: dat_phong { khach_hang { TenKH } }
    if (json['dat_phong'] != null) {
      final datPhong = json['dat_phong'] as Map<String, dynamic>;

      if (datPhong['khach_hang'] != null) {
        tenKhachHang = datPhong['khach_hang']['TenKH']?.toString();
      }

      // Lấy thông tin phòng đầu tiên
      if (datPhong['chi_tiet_dat_phong'] is List &&
          (datPhong['chi_tiet_dat_phong'] as List).isNotEmpty) {
        final chiTiet = (datPhong['chi_tiet_dat_phong'] as List).first;
        if (chiTiet['phong'] != null && chiTiet['phong']['loai_phong'] != null) {
          tenLoaiPhong = chiTiet['phong']['loai_phong']['TenLoaiPhong']?.toString();
          maLoaiPhong = chiTiet['phong']['loai_phong']['MaLoaiPhong'];
        }
      }
    }

    return DanhGiaModel(
      maDG: NumberParser.toInt(json['MaDG']),
      maDatPhong: NumberParser.toInt(json['MaDatPhong']),
      sao: NumberParser.toInt(json['Sao'], defaultValue: 5),
      moTa: json['MoTa'],
      ngayDanhGia: json['NgayDanhGia'] != null
          ? DateTime.tryParse(json['NgayDanhGia'].toString())
          : null,
      tenKhachHang: tenKhachHang ?? json['TenKhachHang']?.toString(),
      tenLoaiPhong: tenLoaiPhong ?? json['TenLoaiPhong']?.toString(),
      maLoaiPhong: maLoaiPhong ?? json['MaLoaiPhong'],
    );
  }

  // Format ngày đánh giá
  String get ngayDanhGiaFormatted {
    if (ngayDanhGia == null) return '';
    return "${ngayDanhGia!.day.toString().padLeft(2, '0')}/${ngayDanhGia!.month.toString().padLeft(2, '0')}/${ngayDanhGia!.year}";
  }

  // Lấy chữ cái đầu cho avatar
  String get avatarChar {
    if (tenKhachHang != null && tenKhachHang!.isNotEmpty) {
      return tenKhachHang![0].toUpperCase();
    }
    return 'K';
  }
}