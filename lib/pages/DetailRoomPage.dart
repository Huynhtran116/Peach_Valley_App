import 'package:flutter/material.dart';
import '../models/loai_phong.dart';
import 'BookingDetail.dart';

class RoomDetailPage extends StatefulWidget {
  final LoaiPhong loaiPhong;

  const RoomDetailPage({super.key, required this.loaiPhong});

  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  int _currentImageIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Hàm hiển thị ảnh toàn màn hình
  void _showFullScreenImage(int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Ảnh toàn màn hình
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                widget.loaiPhong.hinhs[index].url,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.black,
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.white, size: 50),
                    ),
                  );
                },
              ),
            ),
            // Nút đóng
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
            // Chỉ báo trang
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${index + 1} / ${widget.loaiPhong.hinhs.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> imageUrls = widget.loaiPhong.hinhs.map((h) => h.url).toList();
    final bool hasMultipleImages = imageUrls.length > 1;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          widget.loaiPhong.tenLoaiPhong,
          style: const TextStyle(
            color: Color(0xFF49120F),
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔥 SLIDESHOW ẢNH CHÍNH
                    Stack(
                      children: [
                        // PageView để vuốt chuyển ảnh
                        SizedBox(
                          height: 250,
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemCount: imageUrls.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () => _showFullScreenImage(index),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.network(
                                    imageUrls[index],
                                    width: double.infinity,
                                    height: 250,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 250,
                                        color: const Color(0xFFE8BE97),
                                        child: const Center(
                                          child: Icon(Icons.hotel,
                                              size: 60, color: Color(0xFF49120F)),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Chỉ báo số ảnh (nếu có nhiều ảnh)
                        if (hasMultipleImages)
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_currentImageIndex + 1}/${imageUrls.length}',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ),

                        // Nút chuyển ảnh trái (nếu có nhiều ảnh)
                        if (hasMultipleImages)
                          Positioned(
                            left: 10,
                            top: 110,
                            child: GestureDetector(
                              onTap: () {
                                if (_currentImageIndex > 0) {
                                  _pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                              ),
                            ),
                          ),

                        // Nút chuyển ảnh phải (nếu có nhiều ảnh)
                        if (hasMultipleImages)
                          Positioned(
                            right: 10,
                            top: 110,
                            child: GestureDetector(
                              onTap: () {
                                if (_currentImageIndex < imageUrls.length - 1) {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                              ),
                            ),
                          ),

                        // Nút yêu thích (tim)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.favorite, color: Colors.red),
                          ),
                        ),

                        // Dấu chấm chỉ vị trí (nếu có nhiều ảnh)
                        if (hasMultipleImages)
                          Positioned(
                            bottom: 10,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                imageUrls.length,
                                    (index) => Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentImageIndex == index
                                        ? const Color(0xFFC97A3E)
                                        : Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    // 🔥 Tiện nghi
                    if (widget.loaiPhong.tienNghis.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.loaiPhong.tienNghis.map((tn) {
                          return _feature(_getIconForTienNghi(tn.tenTienNghi), tn.tenTienNghi);
                        }).toList(),
                      ),

                    const SizedBox(height: 20),

                    // 🔥 Tên + Giá
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.loaiPhong.tenLoaiPhong,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          "${_formatVND(widget.loaiPhong.giaThapNhat)} VND /đêm",
                          style: const TextStyle(
                            color: Color(0xFFC97A3E),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // 🔥 Số phòng trống
                    Text(
                      "${widget.loaiPhong.soPhongTrong} phòng trống",
                      style: const TextStyle(color: Colors.grey),
                    ),

                    // 🔥 Số người
                    Text(
                      "Tối đa: ${widget.loaiPhong.nguoiLon} người lớn${widget.loaiPhong.treEm > 0 ? ', ${widget.loaiPhong.treEm} trẻ em' : ''}",
                      style: const TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 15),

                    // 🔥 Mô tả
                    const Text(
                      "Mô tả",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.loaiPhong.mota,
                      style: const TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 15),

                    // 🔥 Gallery ảnh thu nhỏ (nếu có nhiều ảnh)
                    if (imageUrls.length > 1) ...[
                      const Text(
                        "Thư viện ảnh",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: imageUrls.length,
                          itemBuilder: (context, index) {
                            return _previewImg(imageUrls[index], index);
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          height: 55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFFC97A3E), Color(0xFF6F1D01)],
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BookingDetailPage(),
                ),
              );
            },
            child: const Center(
              child: Text(
                "Đặt phòng",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Format tiền
  String _formatVND(dynamic amount) {
    double t = double.tryParse(amount?.toString() ?? '0') ?? 0;
    return t.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
  }

  // Icon cho tiện nghi
  IconData _getIconForTienNghi(String ten) {
    switch (ten.toLowerCase()) {
      case 'wifi':
        return Icons.wifi;
      case 'tv':
        return Icons.tv;
      case 'may lanh':
        return Icons.ac_unit;
      case 'tu lanh':
        return Icons.kitchen;
      case 'ban lam viec':
        return Icons.desk;
      default:
        return Icons.check_circle;
    }
  }

  Widget _feature(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFC97A3E)),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _previewImg(String url, int index) {
    return GestureDetector(
      onTap: () {
        // Chuyển slideshow đến ảnh được chọn
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      onLongPress: () {
        // Nhấn giữ để xem toàn màn hình
        _showFullScreenImage(index);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _currentImageIndex == index
                ? const Color(0xFFC97A3E)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            url,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 80,
                height: 80,
                color: const Color(0xFFE8BE97),
                child: const Icon(Icons.broken_image, color: Color(0xFF49120F)),
              );
            },
          ),
        ),
      ),
    );
  }
}