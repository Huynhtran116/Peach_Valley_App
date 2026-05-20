// pages/DanhGiaPage.dart
import 'package:flutter/material.dart';
import '../services/danh_gia_service.dart';

class DanhGiaPage extends StatefulWidget {
  final int maDatPhong;
  final String? tenLoaiPhong;
  final DateTime? ngayTraPhong;

  const DanhGiaPage({
    super.key,
    required this.maDatPhong,
    this.tenLoaiPhong,
    this.ngayTraPhong,
  });

  @override
  State<DanhGiaPage> createState() => _DanhGiaPageState();
}

class _DanhGiaPageState extends State<DanhGiaPage> {
  int _sao = 5;
  final TextEditingController _moTaController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _moTaController.dispose();
    super.dispose();
  }

  Future<void> _guiDanhGia() async {
    if (_sao == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn số sao'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await DanhGiaService.guiDanhGia(
      maDatPhong: widget.maDatPhong,
      sao: _sao,
      moTa: _moTaController.text.trim().isEmpty ? null : _moTaController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Cảm ơn bạn đã đánh giá!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // Trả về true để refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Lỗi gửi đánh giá'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Đánh giá khách sạn",
          style: TextStyle(
            color: Color(0xFF49120F),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFFFFFFFF),
        iconTheme: const IconThemeData(color: Color(0xFF49120F)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFC97A3E).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rate_review_outlined,
                size: 40,
                color: Color(0xFFC97A3E),
              ),
            ),
            const SizedBox(height: 16),

            // Tiêu đề
            const Text(
              'Đánh giá của bạn',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF49120F),
              ),
            ),
            const SizedBox(height: 8),

            // Thông tin đặt phòng
            if (widget.tenLoaiPhong != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8BE97).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.tenLoaiPhong!,
                  style: const TextStyle(
                    color: Color(0xFF49120F),
                    fontSize: 13,
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Chọn sao
            const Text(
              'Bạn thấy khách sạn thế nào?',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _sao = index + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      index < _sao ? Icons.star : Icons.star_border,
                      size: 48,
                      color: index < _sao ? Colors.amber : Colors.grey.shade300,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              _getSaoText(_sao),
              style: TextStyle(
                fontSize: 14,
                color: Colors.amber.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),

            // Nhập nội dung
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: TextField(
                controller: _moTaController,
                maxLines: 5,
                maxLength: 200,
                decoration: const InputDecoration(
                  hintText: 'Chia sẻ trải nghiệm của bạn về khách sạn...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Nút gửi
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _guiDanhGia,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC97A3E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Gửi đánh giá',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSaoText(int sao) {
    switch (sao) {
      case 5: return 'Tuyệt vời!';
      case 4: return 'Rất tốt';
      case 3: return 'Bình thường';
      case 2: return 'Tạm được';
      case 1: return 'Cần cải thiện';
      default: return '';
    }
  }
}