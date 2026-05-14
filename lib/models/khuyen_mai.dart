class KhuyenMaiModel {
  final int maKM;
  final String tenKM;
  final String? moTa;
  final int diem;
  final DateTime ngayBatDau;  // 🔥 Đổi từ String sang DateTime
  final DateTime ngayKetThuc; // 🔥 Đổi từ String sang DateTime
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
    // 🔥 Xử lý ngày tháng an toàn
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

    // 🔥 Xử lý phần trăm giảm giá
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

    return KhuyenMaiModel(
      maKM: json['MaKM'] as int? ?? 0,
      tenKM: json['TenKM'] as String? ?? '',
      moTa: json['MoTa'] as String?,
      diem: json['Diem'] as int? ?? 0,
      ngayBatDau: ngayBatDau,
      ngayKetThuc: ngayKetThuc,
      phanTramGiamGia: phanTram,
    );
  }

  // Format giảm giá hiển thị
  String get discountText {
    if (phanTramGiamGia == phanTramGiamGia.roundToDouble()) {
      return '${phanTramGiamGia.toInt()}%';
    }
    return '${phanTramGiamGia.toStringAsFixed(1)}%';
  }

  // Format ngày hết hạn
  String get expiryText {
    try {
      return 'Còn đến ${ngayKetThuc.day.toString().padLeft(2, '0')}/${ngayKetThuc.month.toString().padLeft(2, '0')}/${ngayKetThuc.year}';
    } catch (e) {
      return '';
    }
  }

  // Format ngày bắt đầu
  String get startText {
    try {
      return 'Từ ${ngayBatDau.day.toString().padLeft(2, '0')}/${ngayBatDau.month.toString().padLeft(2, '0')}/${ngayBatDau.year}';
    } catch (e) {
      return '';
    }
  }

  // Tag cho khuyến mãi
  String get tag {
    if (maKM <= 2) return 'Dành cho đơn đầu tiên';
    if (diem > 0) return 'Đổi ${diem} điểm';
    return 'Ưu đãi đặc biệt';
  }

  // Số ngày còn lại
  int get daysLeft {
    return ngayKetThuc.difference(DateTime.now()).inDays;
  }

  // Kiểm tra sắp hết hạn
  bool get isExpiringSoon {
    return daysLeft <= 3 && daysLeft >= 0;
  }
}