// models/diem_khach_hang.dart

class DiemKhachHangModel {
  final int diem;
  final int maKH;
  final String tenKH;

  DiemKhachHangModel({
    required this.diem,
    required this.maKH,
    required this.tenKH,
  });

  factory DiemKhachHangModel.fromJson(Map<String, dynamic> json) {
    return DiemKhachHangModel(
      diem: json['diem'] ?? json['DIEM'] ?? 0,
      maKH: json['maKH'] ?? json['MaKH'] ?? 0,
      tenKH: json['tenKH'] ?? json['TenKH'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'diem': diem,
      'maKH': maKH,
      'tenKH': tenKH,
    };
  }
}