// models/kho_khuyen_mai.dart

class KhoKhuyenMaiModel {
  final String maKM;
  final String tenKM;
  final String? moTa;
  final double phanTramGiamGia;
  final int diem;
  final int trangThai; // 0: Chưa sử dụng, 1: Đã sử dụng, 2: Hết hạn
  final String? ngayHetHan;
  final String trangThaiText;

  KhoKhuyenMaiModel({
    required this.maKM,
    required this.tenKM,
    this.moTa,
    required this.phanTramGiamGia,
    required this.diem,
    required this.trangThai,
    this.ngayHetHan,
    required this.trangThaiText,
  });

  factory KhoKhuyenMaiModel.fromJson(Map<String, dynamic> json) {
    // Parse MaKM
    String maKM = '';
    if (json['MaKM'] is String) {
      maKM = json['MaKM'] as String;
    } else if (json['MaKM'] is int) {
      maKM = (json['MaKM'] as int).toString();
    }

    // Parse PhanTramGiamGia
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

    // Parse Diem
    int diem = 0;
    if (json['Diem'] is int) {
      diem = json['Diem'] as int;
    } else if (json['Diem'] is String) {
      diem = int.tryParse(json['Diem'] as String) ?? 0;
    }

    // Parse TrangThai
    int trangThai = 0;
    if (json['TrangThai'] is int) {
      trangThai = json['TrangThai'] as int;
    } else if (json['TrangThai'] is String) {
      trangThai = int.tryParse(json['TrangThai'] as String) ?? 0;
    }

    // Trạng thái text
    String trangThaiText = json['TrangThaiText'] ?? '';
    if (trangThaiText.isEmpty) {
      trangThaiText = _getTrangThaiText(trangThai);
    }

    return KhoKhuyenMaiModel(
      maKM: maKM,
      tenKM: json['TenKM'] ?? '',
      moTa: json['MoTa'],
      phanTramGiamGia: phanTram,
      diem: diem,
      trangThai: trangThai,
      ngayHetHan: json['NgayHetHan']?.toString(),
      trangThaiText: trangThaiText,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'MaKM': maKM,
      'TenKM': tenKM,
      'MoTa': moTa,
      'PhanTramGiamGia': phanTramGiamGia,
      'Diem': diem,
      'TrangThai': trangThai,
      'NgayHetHan': ngayHetHan,
      'TrangThaiText': trangThaiText,
    };
  }

  static String _getTrangThaiText(int trangThai) {
    switch (trangThai) {
      case 0:
        return 'Chưa sử dụng';
      case 1:
        return 'Đã sử dụng';
      case 2:
        return 'Hết hạn';
      default:
        return 'Không xác định';
    }
  }

  // 🔥 Getter tiện ích
  bool get chuaSuDung => trangThai == 0;
  bool get daSuDung => trangThai == 1;
  bool get hetHan => trangThai == 2;
  bool get coTheSuDung => trangThai == 0;

  String get discountText {
    if (phanTramGiamGia == phanTramGiamGia.roundToDouble()) {
      return '${phanTramGiamGia.toInt()}%';
    }
    return '${phanTramGiamGia.toStringAsFixed(1)}%';
  }

  String get diemText {
    if (diem > 0) return '$diem điểm';
    return 'Miễn phí';
  }

  String get expiryText {
    if (ngayHetHan == null) return '';
    try {
      final date = DateTime.parse(ngayHetHan!);
      return 'HSD: ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return '';
    }
  }
}