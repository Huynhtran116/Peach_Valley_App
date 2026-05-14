class DichVuModel {
  final int maDV;
  final String tenDV;
  final double giaDV;
  final String giaDVFormatted;
  final int loaiDV;
  final String loaiDVText;
  final List<HinhAnhDV> hinhs;

  DichVuModel({
    required this.maDV,
    required this.tenDV,
    required this.giaDV,
    required this.giaDVFormatted,
    required this.loaiDV,
    required this.loaiDVText,
    required this.hinhs,
  });

  factory DichVuModel.fromJson(Map<String, dynamic> json) {
    return DichVuModel(
      maDV: json['MaDV'],
      tenDV: json['TenDV'],
      giaDV: double.parse(json['GiaDV'].toString()),
      giaDVFormatted: json['GiaDVFormatted'] ?? '',
      loaiDV: json['LoaiDV'],
      loaiDVText: json['LoaiDVText'] ?? '',
      hinhs: (json['hinhs'] as List? ?? [])
          .map((e) => HinhAnhDV.fromJson(e))
          .toList(),
    );
  }

  String? get anhDauTien => hinhs.isNotEmpty ? hinhs[0].url : null;
}

class HinhAnhDV {
  final int id;
  final String url;

  HinhAnhDV({required this.id, required this.url});

  factory HinhAnhDV.fromJson(Map<String, dynamic> json) {
    return HinhAnhDV(
      id: json['Id'],
      url: json['Url'],
    );
  }
}