import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/khuyen_mai.dart';
import 'HomePage.dart';
import 'SignInPage.dart';

class PromotionPage extends StatefulWidget {
  const PromotionPage({super.key});

  @override
  State<PromotionPage> createState() => _PromotionPageState();
}

class _PromotionPageState extends State<PromotionPage> {
  List<KhuyenMaiModel> danhSach = [];
  bool isLoading = true;
  bool isLoggedIn = false; // Thêm biến kiểm tra đăng nhập

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    fetchKhuyenMai();
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

  Future<void> fetchKhuyenMai() async {
    try {
      var response = await ApiService.get('khuyen-mai');

      // Kiểm tra mounted trước khi setState
      if (!mounted) return;

      List data = response is List ? response : response['data'] ?? [];

      setState(() {
        danhSach = data
            .map((e) => KhuyenMaiModel.fromJson(e))
            .where((km) => km.conHan)
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print('Lỗi load khuyến mãi: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // Hiển thị dialog yêu cầu đăng nhập
  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Yêu cầu đăng nhập'),
        content: const Text('Vui lòng đăng nhập để lưu khuyến mãi này.'),
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
            child: const Text(
              'Đăng nhập',
              style: TextStyle(
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Lưu khuyến mãi
  void _savePromotion(KhuyenMaiModel km) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã lưu khuyến mãi: ${km.tenKM}'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    // TODO: Gọi API lưu khuyến mãi vào tài khoản
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
                  (route) => false,
            );
          },
        ),
        centerTitle: true,
        title: const Text(
          "Khuyến mãi",
          style: TextStyle(
            color: Color(0xFF49120F),
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
      ),
      backgroundColor: const Color(0xFFFFFFFF),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFFC97A3E)),
      )
          : danhSach.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Hiện chưa có khuyến mãi nào",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: danhSach.length,
        itemBuilder: (context, index) {
          final km = danhSach[index];
          return _discountItem(km);
        },
      ),
    );
  }

  Widget _discountItem(KhuyenMaiModel km) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          )
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// LEFT - Phần trăm giảm
            Container(
              width: 90,
              decoration: const BoxDecoration(
                color: Color(0xFFC97A3E),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Text(
                  km.discountText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),

            /// DASH LINE
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: CustomPaint(
                painter: DashedLinePainter(),
              ),
            ),

            /// CONTENT + BUTTON
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    /// TEXT
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            km.tenKM,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            km.expiryText,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.red),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              km.tag,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 20),

                    /// 🔥 BUTTON - Chỉ hiển thị khi đã đăng nhập
                    if (isLoggedIn)
                      GestureDetector(
                        onTap: () => _savePromotion(km),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC97A3E),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "Lưu",
                            style: TextStyle(
                              color: Colors.white,
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
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "Đăng nhập để lưu",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 4, dashSpace = 3, startY = 0;
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}