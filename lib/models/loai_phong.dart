import '../utils/number_parser.dart';

class LoaiPhong {
  final int maLoaiPhong;
  final String tenLoaiPhong;
  final String mota;
  final int nguoiLon;
  final int treEm;
  final List<HinhAnh> hinhs;
  final List<Phong> phongs;
  final double giaPhong;      // 🔥 THÊM: Giá gốc từ API
  final double? giaGiam;      // 🔥 THÊM: Giá sau giảm (nullable)
  final List<TienNghi> tienNghis;
  final String? maKM;         // 🔥 THÊM: Mã khuyến mãi

  LoaiPhong({
    required this.maLoaiPhong,
    required this.tenLoaiPhong,
    required this.mota,
    required this.nguoiLon,
    required this.treEm,
    required this.hinhs,
    required this.phongs,
    required this.giaPhong,
    this.giaGiam,
    required this.tienNghis,
    this.maKM,
  });

  factory LoaiPhong.fromJson(Map<String, dynamic> json) {
    return LoaiPhong(
      maLoaiPhong: NumberParser.toInt(json['MaLoaiPhong']),
      tenLoaiPhong: json['TenLoaiPhong'] ?? '',
      mota: json['Mota'] ?? '',
      nguoiLon: NumberParser.toInt(json['NguoiLon'], defaultValue: 2),
      treEm: NumberParser.toInt(json['TreEm']),
      hinhs: (json['hinhs'] as List? ?? [])
          .map((e) => HinhAnh.fromJson(e))
          .toList(),
      phongs: (json['phongs'] as List? ?? [])
          .map((e) => Phong.fromJson(e))
          .toList(),

      // 🔥 Parse giá từ API
      giaPhong: NumberParser.toDouble(json['GiaPhong']),
      giaGiam: json['GiaGiam'] != null
          ? NumberParser.toDouble(json['GiaGiam'])
          : null,

      tienNghis: (json['tien_nghis'] as List? ?? [])
          .map((e) => TienNghi.fromJson(e))
          .toList(),

      maKM: json['MaKM'],
    );
  }

  // 🔥 Giá hiển thị (ưu tiên giá giảm, nếu không có thì dùng giá gốc)
  double get giaHienThi {
    return giaGiam ?? giaPhong;
  }

  // 🔥 Giá thấp nhất (nay chỉ là giá hiển thị)
  double get giaThapNhat {
    return giaHienThi;
  }

  // 🔥 Kiểm tra có khuyến mãi không
  bool get coKhuyenMai {
    return giaGiam != null && giaGiam! < giaPhong;
  }

  // Số phòng trống
  int get soPhongTrong {
    return phongs.where((p) => p.tinhTrang == 0).length;
  }

  // Ảnh đầu tiên
  String? get anhDauTien {
    return hinhs.isNotEmpty ? hinhs[0].url : null;
  }
}

class HinhAnh {
  final int id;
  final String url;

  HinhAnh({required this.id, required this.url});

  factory HinhAnh.fromJson(Map<String, dynamic> json) {
    return HinhAnh(
      id: NumberParser.toInt(json['Id']),
      url: json['Url'] ?? '',
    );
  }
}

class Phong {
  final int maPhong;
  final String soPhong;
  final int tinhTrang;

  Phong({
    required this.maPhong,
    required this.soPhong,
    required this.tinhTrang,
  });

  factory Phong.fromJson(Map<String, dynamic> json) {
    return Phong(
      maPhong: NumberParser.toInt(json['MaPhong']),
      soPhong: json['SoPhong'] ?? '',
      tinhTrang: NumberParser.toInt(json['TinhTrang']),
    );
  }
}

// 🔥 XÓA class BangGia vì API không trả về bang_gias

class TienNghi {
  final int maTienNghi;
  final String tenTienNghi;

  TienNghi({required this.maTienNghi, required this.tenTienNghi});

  factory TienNghi.fromJson(Map<String, dynamic> json) {
    return TienNghi(
      maTienNghi: NumberParser.toInt(json['MaTienNghi']),
      tenTienNghi: json['TenTienNghi'] ?? '',
    );
  }
}