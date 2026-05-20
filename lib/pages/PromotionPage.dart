import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/khuyen_mai_service.dart';
import '../models/khuyen_mai.dart';
import 'HomePage.dart';
import 'SignInPage.dart';

class PromotionPage extends StatefulWidget {
  const PromotionPage({super.key});

  @override
  State<PromotionPage> createState() => _PromotionPageState();
}

class _PromotionPageState extends State<PromotionPage> with WidgetsBindingObserver {
  List<KhuyenMaiModel> danhSach = [];
  bool isLoading = true;
  bool isLoggedIn = false;
  DateTime? _lastReload;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLoginStatus();
    fetchKhuyenMai();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reloadIfNeeded();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reloadIfNeeded();
  }

  Future<void> _reloadIfNeeded() async {
    final now = DateTime.now();
    if (_lastReload == null || now.difference(_lastReload!).inSeconds > 30) {
      _lastReload = now;
      _checkLoginStatus();
      fetchKhuyenMai();
    }
  }

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

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Yêu cầu đăng nhập'),
        content: const Text('Vui lòng đăng nhập để sử dụng khuyến mãi này.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Để sau', style: TextStyle(color: Color(0xFFC97A3E))),
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
            child: const Text('Đăng nhập', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép mã khuyến mãi'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // 🔥 Dialog đổi điểm (giống HomePage)
  void _showDoiDiemDialog(KhuyenMaiModel km) async {
    final prefs = await SharedPreferences.getInstance();
    int maKH = prefs.getInt('user_maKH') ?? 0;

    if (maKH == 0) {
      _showLoginRequiredDialog();
      return;
    }

    _showLoadingDialog();

    final kiemTra = await KhuyenMaiService.kiemTraDiem(maKH, km.maKM);
    int diemHienTai = kiemTra['diemHienTai'] ?? 0;
    bool duDiem = kiemTra['duDiem'] ?? false;

    _hideLoadingDialog();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.card_giftcard, color: Color(0xFFC97A3E)),
            SizedBox(width: 10),
            Text('Đổi mã khuyến mãi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFC97A3E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(km.tenKM, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Giảm ${km.discountText}', style: const TextStyle(color: Color(0xFFC97A3E))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Điểm hiện tại:'),
                Text('$diemHienTai điểm', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Điểm cần đổi:'),
                Text('${km.diem} điểm', style: const TextStyle(color: Color(0xFFC97A3E), fontWeight: FontWeight.bold)),
              ],
            ),
            if (duDiem) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Điểm còn lại:'),
                  Text('${diemHienTai - km.diem} điểm', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ] else ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Text('Thiếu ${km.diem - diemHienTai} điểm', style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Để sau', style: TextStyle(color: Color(0xFFC97A3E))),
          ),
          if (duDiem)
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                _showLoadingDialog();
                final result = await KhuyenMaiService.doiBangDiem(maKH, km.maKM);
                _hideLoadingDialog();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? ''),
                      backgroundColor: result['success'] == true ? Colors.green : Colors.red,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Xác nhận đổi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC97A3E),
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: Color(0xFFC97A3E)),
            SizedBox(width: 20),
            Text('Đang xử lý...'),
          ],
        ),
      ),
    );
  }

  void _hideLoadingDialog() {
    if (mounted) Navigator.of(context).pop();
  }

  // 🔥 Hàm tạo nút hành động (giống HomePage)
  Widget _buildActionButton(KhuyenMaiModel km) {
    if (!isLoggedIn) {
      return GestureDetector(
        onTap: _showLoginRequiredDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text("Đăng nhập", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
        ),
      );
    }

    // Nếu mã cần điểm -> Nút "Đổi bằng điểm"
    if (km.diem > 0) {
      return GestureDetector(
        onTap: () => _showDoiDiemDialog(km),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF49120F), Color(0xFFC97A3E)]),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars, color: Colors.amber, size: 14),
              const SizedBox(width: 4),
              Text('${km.diem} điểm', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
        ),
      );
    }

    // Nếu mã miễn phí -> Nút "Sao chép mã"
    return GestureDetector(
      onTap: () => _copyCode(km.maKM),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFC97A3E),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text("Sao chép mã", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF49120F)),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
                  (route) => false,
            );
          },
        ),
        centerTitle: true,
        title: const Text("Khuyến mãi", style: TextStyle(color: Color(0xFF49120F), fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC97A3E)))
          : danhSach.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text("Hiện chưa có khuyến mãi nào", style: TextStyle(color: Colors.grey, fontSize: 16)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // LEFT - Phần trăm
            Container(
              width: 90,
              decoration: const BoxDecoration(
                color: Color(0xFFC97A3E),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
              ),
              child: Center(
                child: Text(km.discountText, textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ),
            // DASH
            Container(width: 1, margin: const EdgeInsets.symmetric(horizontal: 6), child: CustomPaint(painter: DashedLinePainter())),
            // CONTENT
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(km.tenKM, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => _copyCode(km.maKM),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC97A3E).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.local_offer, size: 12, color: Color(0xFFC97A3E)),
                                  const SizedBox(width: 4),
                                  Text('Mã: ${km.maKM}', style: const TextStyle(fontSize: 11, color: Color(0xFFC97A3E), fontWeight: FontWeight.w500)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.copy, size: 12, color: Color(0xFFC97A3E)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(km.expiryText, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              border: Border.all(color: km.diem > 0 ? Colors.orange : Colors.red),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(km.tag, style: TextStyle(color: km.diem > 0 ? Colors.orange : Colors.red, fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 🔥 NÚT HÀNH ĐỘNG
                    _buildActionButton(km),
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
    final paint = Paint()..color = Colors.grey..strokeWidth = 1;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}