import 'package:flutter/material.dart';
import '../models/loai_phong.dart';
import '../services/cart_service.dart';
import '../utils/number_parser.dart';
import 'BookingDetail.dart';
import 'SearchPage.dart';

class RoomDetailPage extends StatefulWidget {
  final LoaiPhong loaiPhong;
  final int? soPhongTrongTheoNgay; // 🔥 Từ SearchPage (số phòng trống theo ngày)
  final bool fromHome;

  const RoomDetailPage({
    super.key,
    required this.loaiPhong,
    this.soPhongTrongTheoNgay,
    this.fromHome = false,
  });

  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  int _currentImageIndex = 0;
  late PageController _pageController;

  late int soLuongDat;
  late int soPhongTrong;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    // 🔥 Lấy số phòng trống phù hợp
    if (widget.soPhongTrongTheoNgay != null) {
      // Từ SearchPage - số phòng trống theo ngày
      soPhongTrong = widget.soPhongTrongTheoNgay!;
    } else {
      // Từ HomePage - tổng số phòng trống
      soPhongTrong = widget.loaiPhong.soPhongTrong;
    }

    await _loadCurrentQuantity();
    setState(() {
      isLoading = false;
    });
  }

  // Load số lượng hiện tại từ giỏ hàng
  Future<void> _loadCurrentQuantity() async {
    final cart = await CartService.loadCart();
    final maLoai = widget.loaiPhong.maLoaiPhong;
    setState(() {
      soLuongDat = cart[maLoai]?['quantity'] ?? 0;
    });
  }

  // Cập nhật giỏ hàng
  Future<void> _updateCart(int newQuantity) async {
    final cart = await CartService.loadCart();
    final maLoai = widget.loaiPhong.maLoaiPhong;

    if (newQuantity > 0) {
      cart[maLoai] = {
        'MaLoaiPhong': maLoai,
        'TenLoaiPhong': widget.loaiPhong.tenLoaiPhong,
        'gia': widget.loaiPhong.giaHienThi,
        'hinhs': widget.loaiPhong.hinhs.map((e) => {'Url': e.url}).toList(),
        'NguoiLon': widget.loaiPhong.nguoiLon,
        'TreEm': widget.loaiPhong.treEm,
        'soPhongTrong': soPhongTrong,
        'quantity': newQuantity,
      };
    } else {
      cart.remove(maLoai);
    }

    await CartService.saveCart(cart);
  }

  // Thêm phòng
  Future<void> _themPhong() async {
    if (soLuongDat < soPhongTrong) {
      setState(() {
        soLuongDat++;
      });
      await _updateCart(soLuongDat);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chỉ còn $soPhongTrong phòng trống'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Giảm phòng
  Future<void> _giamPhong() async {
    if (soLuongDat > 0) {
      setState(() {
        soLuongDat--;
      });
      await _updateCart(soLuongDat);
    }
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

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFC97A3E))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context, true),
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
                    // Slideshow ảnh chính
                    Stack(
                      children: [
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

                    // Tiện nghi
                    if (widget.loaiPhong.tienNghis.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.loaiPhong.tienNghis.map((tn) {
                          return _feature(_getIconForTienNghi(tn.tenTienNghi), tn.tenTienNghi);
                        }).toList(),
                      ),

                    const SizedBox(height: 20),

                    // Tên + Giá
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.loaiPhong.tenLoaiPhong,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // 🔥 CỘT GIÁ KIỂU SHOPEE
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Giá gốc gạch ngang + badge (nếu có KM)
                            if (widget.loaiPhong.coKhuyenMai)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "${_formatVND(widget.loaiPhong.giaPhong)} VND",
                                    style: const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFC97A3E),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '-${((1 - widget.loaiPhong.giaHienThi / widget.loaiPhong.giaPhong) * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 2),
                            // Giá chính (to, đậm)
                            Text(
                              "${_formatVND(widget.loaiPhong.giaHienThi)} VND/đêm",
                              style: const TextStyle(
                                color: Color(0xFFC97A3E),
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // Sửa lại phần hiển thị số phòng trống trong build method

                    // 🔥 SỐ PHÒNG TRỐNG - HIỂN THỊ THEO NGUỒN
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.meeting_room,
                            size: 14,
                            color: soPhongTrong > 0 ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          // 🔥 CHỈ HIỂN THỊ KHI TỪ SEARCHPAGE
                          if (widget.soPhongTrongTheoNgay != null)
                            Text(
                              "$soPhongTrong phòng trống ",
                              style: TextStyle(
                                color: soPhongTrong > 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          // 🔥 TỪ HOMEPAGE: HIỂN THỊ THÔNG BÁO KHÁC HOẶC KHÔNG HIỂN THỊ
                          if (widget.soPhongTrongTheoNgay == null && !widget.fromHome)
                            Text(
                              "$soPhongTrong phòng trống",
                              style: TextStyle(
                                color: soPhongTrong > 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Số người
                    Text(
                      "Tối đa: ${widget.loaiPhong.nguoiLon} người lớn${widget.loaiPhong.treEm > 0 ? ', ${widget.loaiPhong.treEm} trẻ em' : ''}",
                      style: const TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 15),

                    // Mô tả
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

                    // Gallery ảnh thu nhỏ
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
      // Bottom bar với nút thêm/bớt số lượng
      // Tìm bottomNavigationBar và sửa onPressed
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Nút thêm/bớt số lượng
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFC97A3E)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _giamPhong,
                      icon: const Icon(Icons.remove, color: Color(0xFFC97A3E)),
                    ),
                    Text(
                      '$soLuongDat',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      onPressed: _themPhong,
                      icon: const Icon(Icons.add, color: Color(0xFFC97A3E)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Nút đặt phòng
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (soLuongDat > 0) {
                      if (widget.fromHome) {
                        // 🔥 Từ HomePage: Chuyển sang SearchPage
                        _navigateToSearchPage();
                      } else {
                        // Từ SearchPage: Quay lại và cập nhật giỏ
                        Navigator.pop(context, true);
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng chọn số lượng phòng'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC97A3E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Đặt phòng',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _navigateToSearchPage() {
    // Chuyển sang SearchPage, kèm thông tin phòng đã chọn
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchPage(
          preSelectedRoom: widget.loaiPhong,
          preSelectedQuantity: soLuongDat,
        ),
      ),
    );
  }

  // Format tiền
  String _formatVND(dynamic amount) {
    return NumberParser.formatVND(amount);
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
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      onLongPress: () {
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