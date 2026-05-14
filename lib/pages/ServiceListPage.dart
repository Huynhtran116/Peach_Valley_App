import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/dich_vu.dart';
import 'ServiceGroupDetailPage.dart';

class ServiceListPage extends StatefulWidget {
  const ServiceListPage({super.key});

  @override
  State<ServiceListPage> createState() => _ServiceListPageState();
}

class _ServiceListPageState extends State<ServiceListPage> {
  // Danh sách đầy đủ
  List<DichVuModel> allServices = [];
  bool isLoading = true;

  // Các service ẩn (không hiển thị)
  final List<String> hiddenServices = [
    'Thêm giường phụ',
    'Đổi phòng',
    'Hủy phòng',
  ];

  @override
  void initState() {
    super.initState();
    fetchServices();
  }

  Future<void> fetchServices() async {
    try {
      var response = await ApiService.get('dich-vu');
      List data = response['data'] ?? [];
      setState(() {
        allServices = data
            .map((e) => DichVuModel.fromJson(e))
            .where((dv) => !hiddenServices.contains(dv.tenDV))
            .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // Lọc theo loại
  List<DichVuModel> getByLoai(int loaiDV) {
    return allServices.where((dv) => dv.loaiDV == loaiDV).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Dịch vụ",
          style: TextStyle(
            color: Color(0xFF49120F),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
          child: CircularProgressIndicator(color: Color(0xFFC97A3E)))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Nhóm Ăn uống
          _groupHeader(
            icon: Icons.restaurant,
            title: 'Dịch vụ ăn uống',
            color: Colors.orange,
            count: getByLoai(1).length,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServiceGroupDetailPage(
                    title: 'Dịch vụ ăn uống',
                    danhSach: getByLoai(1),
                    color: Colors.orange,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Nhóm Dịch vụ phòng
          _groupHeader(
            icon: Icons.room_service,
            title: 'Dịch vụ phòng',
            color: Colors.blue,
            count: getByLoai(2).length,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServiceGroupDetailPage(
                    title: 'Dịch vụ phòng',
                    danhSach: getByLoai(2),
                    color: Colors.blue,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Nhóm Giải trí
          _groupHeader(
            icon: Icons.sports_esports,
            title: 'Dịch vụ giải trí',
            color: Colors.green,
            count: getByLoai(3).length,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServiceGroupDetailPage(
                    title: 'Dịch vụ giải trí',
                    danhSach: getByLoai(3),
                    color: Colors.green,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _groupHeader({
    required IconData icon,
    required String title,
    required Color color,
    required int count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF49120F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count dịch vụ',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}