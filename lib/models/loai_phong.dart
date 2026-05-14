class LoaiPhong {
  final int maLoaiPhong;
  final String tenLoaiPhong;
  final String mota;
  final int nguoiLon;
  final int treEm;
  final List<HinhAnh> hinhs;
  final List<Phong> phongs;
  final List<BangGia> bangGias;
  final List<TienNghi> tienNghis;

  LoaiPhong({
    required this.maLoaiPhong,
    required this.tenLoaiPhong,
    required this.mota,
    required this.nguoiLon,
    required this.treEm,
    required this.hinhs,
    required this.phongs,
    required this.bangGias,
    required this.tienNghis,
  });

  factory LoaiPhong.fromJson(Map<String, dynamic> json) {
    return LoaiPhong(
      maLoaiPhong: json['MaLoaiPhong'],
      tenLoaiPhong: json['TenLoaiPhong'],
      mota: json['Mota'] ?? '',
      nguoiLon: json['NguoiLon'] ?? 2,
      treEm: json['TreEm'] ?? 0,
      hinhs: (json['hinhs'] as List? ?? [])
          .map((e) => HinhAnh.fromJson(e))
          .toList(),
      phongs: (json['phongs'] as List? ?? [])
          .map((e) => Phong.fromJson(e))
          .toList(),
      bangGias: (json['bang_gias'] as List? ?? [])
          .map((e) => BangGia.fromJson(e))
          .toList(),
      tienNghis: (json['tien_nghis'] as List? ?? [])
          .map((e) => TienNghi.fromJson(e))
          .toList(),
    );
  }

  // Giá thấp nhất
  double get giaThapNhat {
    if (bangGias.isEmpty) return 0;
    return bangGias.map((e) => e.giaPhong).reduce(
            (a, b) => a < b ? a : b);
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
      id: json['Id'],
      url: json['Url'],
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
      maPhong: json['MaPhong'],
      soPhong: json['SoPhong'],
      tinhTrang: json['TinhTrang'],
    );
  }
}

class BangGia {
  final int mua;
  final double giaPhong;

  BangGia({required this.mua, required this.giaPhong});

  factory BangGia.fromJson(Map<String, dynamic> json) {
    return BangGia(
      mua: json['Mua'],
      giaPhong: double.parse(json['GiaPhong']),
    );
  }
}

class TienNghi {
  final int maTienNghi;
  final String tenTienNghi;

  TienNghi({required this.maTienNghi, required this.tenTienNghi});

  factory TienNghi.fromJson(Map<String, dynamic> json) {
    return TienNghi(
      maTienNghi: json['MaTienNghi'],
      tenTienNghi: json['TenTienNghi'],
    );
  }
}