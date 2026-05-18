class KhuyenMaiModel {
  final String maKM;
  final String tenKM;
  final String? moTa;
  final int diem;
  final DateTime ngayBatDau;
  final DateTime ngayKetThuc;
  final double phanTramGiamGia;

  KhuyenMaiModel({
    required this.maKM,
    required this.tenKM,
    this.moTa,
    required this.diem,
    required this.ngayBatDau,
    required this.ngayKetThuc,
    required this.phanTramGiamGia,
  });

  bool get conHan {
    final now = DateTime.now();
    return ngayBatDau.isBefore(now) && ngayKetThuc.isAfter(now);
  }

  factory KhuyenMaiModel.fromJson(Map<String, dynamic> json) {
    // Xử lý ngày tháng
    DateTime ngayBatDau = DateTime.now();
    DateTime ngayKetThuc = DateTime.now();

    try {
      if (json['NgayBatDau'] != null) {
        ngayBatDau = DateTime.parse(json['NgayBatDau'].toString());
      }
    } catch (e) {
      print('⚠️ Lỗi parse NgayBatDau: $e');
    }

    try {
      if (json['NgayKetThuc'] != null) {
        ngayKetThuc = DateTime.parse(json['NgayKetThuc'].toString());
      }
    } catch (e) {
      print('⚠️ Lỗi parse NgayKetThuc: $e');
    }

    // Xử lý phần trăm giảm giá
    double phanTram = 0;
    if (json['PhanTramGiamGia'] != null) {
      if (json['PhanTramGiamGia'] is int) {
        phanTram = (json['PhanTramGiamGia'] as int).toDouble();
      } else if (json['PhanTramGiamGia'] is double) {
        phanTram = json['PhanTramGiamGia'] as double;
      } else if (json['PhanTramGiamGia'] is String) {
        phanTram = double.tryParse(json['PhanTramGiamGia'] as String) ?? 0;
      }
    }

    // Xử lý MaKM
    String maKM = '';
    if (json['MaKM'] is String) {
      maKM = json['MaKM'] as String;
    } else if (json['MaKM'] is int) {
      maKM = (json['MaKM'] as int).toString();
    }

    // Xử lý Diem
    int diem = 0;
    if (json['Diem'] is int) {
      diem = json['Diem'] as int;
    } else if (json['Diem'] is String) {
      diem = int.tryParse(json['Diem'] as String) ?? 0;
    }

    return KhuyenMaiModel(
      maKM: maKM,
      tenKM: json['TenKM'] as String? ?? '',
      moTa: json['MoTa'] as String?,
      diem: diem,
      ngayBatDau: ngayBatDau,
      ngayKetThuc: ngayKetThuc,
      phanTramGiamGia: phanTram,
    );
  }

  // 🔥 Thêm toJson để có thể truyền lên server nếu cần
  Map<String, dynamic> toJson() {
    return {
      'MaKM': maKM,
      'TenKM': tenKM,
      'MoTa': moTa,
      'Diem': diem,
      'NgayBatDau': ngayBatDau.toIso8601String(),
      'NgayKetThuc': ngayKetThuc.toIso8601String(),
      'PhanTramGiamGia': phanTramGiamGia,
    };
  }

  String get discountText {
    if (phanTramGiamGia == phanTramGiamGia.roundToDouble()) {
      return '${phanTramGiamGia.toInt()}%';
    }
    return '${phanTramGiamGia.toStringAsFixed(1)}%';
  }

  String get expiryText {
    try {
      return 'Còn đến ${ngayKetThuc.day.toString().padLeft(2, '0')}/${ngayKetThuc.month.toString().padLeft(2, '0')}/${ngayKetThuc.year}';
    } catch (e) {
      return '';
    }
  }

  String get tag {
    if (diem > 0) return 'Đổi $diem điểm';
    return 'Ưu đãi đặc biệt';
  }
}