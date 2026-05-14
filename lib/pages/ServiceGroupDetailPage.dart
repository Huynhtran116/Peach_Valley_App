import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dich_vu.dart';
import 'SignInPage.dart';

class ServiceGroupDetailPage extends StatefulWidget {
  final String title;
  final List<DichVuModel> danhSach;
  final Color color;

  const ServiceGroupDetailPage({
    super.key,
    required this.title,
    required this.danhSach,
    required this.color,
  });

  @override
  State<ServiceGroupDetailPage> createState() => _ServiceGroupDetailPageState();
}

class _ServiceGroupDetailPageState extends State<ServiceGroupDetailPage> {
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // Kiểm tra trạng thái đăng nhập
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('user_token');
    int? maKH = prefs.getInt('user_maKH');

    setState(() {
      isLoggedIn = (token != null && token.isNotEmpty) && (maKH != null && maKH > 0);
    });
  }

  // Hiển thị dialog yêu cầu đăng nhập
  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Yêu cầu đăng nhập'),
        content: const Text('Vui lòng đăng nhập để đặt dịch vụ này.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Để sau', style: TextStyle(color: Color(0xFF000000))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SignInPage()),
              );
              if (result == true && mounted) {
                await _checkLoginStatus();
                setState(() {});
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC97A3E),
            ),
            child: const Text('Đăng nhập',style: TextStyle(color: Color(0xFFFFFFFF))),
          ),
        ],
      ),
    );
  }

  // Đặt dịch vụ
  void _orderService(DichVuModel dv) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã đặt dịch vụ: ${dv.tenDV}'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    // TODO: Gọi API đặt dịch vụ
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
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Color(0xFF49120F),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: widget.danhSach.isEmpty
          ? const Center(
        child: Text(
          'Chưa có dịch vụ nào',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.danhSach.length,
        itemBuilder: (context, index) {
          final dv = widget.danhSach[index];
          return _serviceItem(dv);
        },
      ),
    );
  }

  Widget _serviceItem(DichVuModel dv) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ảnh
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: dv.anhDauTien != null
                ? Image.network(
              dv.anhDauTien!,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 120,
                  height: 120,
                  color: const Color(0xFFE8BE97),
                  child: const Icon(Icons.room_service,
                      color: Color(0xFF49120F)),
                );
              },
            )
                : Container(
              width: 120,
              height: 120,
              color: const Color(0xFFE8BE97),
              child: const Icon(Icons.room_service,
                  color: Color(0xFF49120F)),
            ),
          ),
          // Thông tin + Nút
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dv.tenDV,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      dv.loaiDVText,
                      style: TextStyle(
                        color: widget.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Giá + Nút Đặt dịch vụ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dv.giaDVFormatted,
                        style: const TextStyle(
                          color: Color(0xFFC97A3E),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      // 🔥 CHỈ HIỂN THỊ NÚT ĐẶT DỊCH VỤ KHI ĐÃ ĐĂNG NHẬP
                      if (isLoggedIn)
                        GestureDetector(
                          onTap: () => _orderService(dv),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF6F1D01),
                                  Color(0xFFC97A3E),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Đặt dịch vụ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: _showLoginRequiredDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Đăng nhập để đặt',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}