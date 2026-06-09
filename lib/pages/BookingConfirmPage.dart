import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'KhoKhuyenMaiPage.dart';
import 'PaymentPage.dart';

class BookingConfirmPage extends StatefulWidget {
  final DateTime checkIn;
  final DateTime checkOut;
  final int soNguoiLon;
  final int soTreEm;
  final List<Map<String, dynamic>> selectedRooms;

  const BookingConfirmPage({
    super.key,
    required this.checkIn,
    required this.checkOut,
    required this.soNguoiLon,
    required this.soTreEm,
    required this.selectedRooms,
  });

  @override
  State<BookingConfirmPage> createState() => _BookingConfirmPageState();
}

class _BookingConfirmPageState extends State<BookingConfirmPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final voucherController = TextEditingController();
  final noteController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isSubmitting = false;

  // Giá tính toán
  double tongGia = 0;
  double tienDatCoc = 0;
  bool isLoadingGia = true;

  int get soDem => widget.checkOut.difference(widget.checkIn).inDays;
  int get soPhong => widget.selectedRooms.length;
  int get tongNguoiLon => widget.selectedRooms.fold(0, (sum, r) => sum + ((r['nguoiLon'] ?? 0) as int));
  int get tongTreEm => widget.selectedRooms.fold(0, (sum, r) => sum + ((r['treEm'] ?? 0) as int));

  bool daDongYChinhSach = false;
  //
  Map<String, dynamic>? _selectedKhuyenMai;
  double tongGiaGoc = 0;

  @override
  void initState() {
    super.initState();
    loadUserInfo();
    tinhGia();
  }

  void loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    nameController.text = prefs.getString('user_name') ?? '';
    emailController.text = prefs.getString('user_email') ?? '';
  }

  Future<void> tinhGia() async {
    try {
      double total = 0;
      Map<int, int> loaiPhongCount = {};
      for (var room in widget.selectedRooms) {
        int maLoai = room['roomType']['MaLoaiPhong'];
        loaiPhongCount[maLoai] = (loaiPhongCount[maLoai] ?? 0) + 1;
      }

      for (var entry in loaiPhongCount.entries) {
        int maLoai = entry.key;
        int soLuong = entry.value;
        var response = await ApiService.post('tinh-gia', {
          'MaLoaiPhong': maLoai,
          'NgayNhanPhong': _formatDateAPI(widget.checkIn),
          'NgayTraPhong': _formatDateAPI(widget.checkOut),
          'SoLuong': soLuong,
        });
        total += (response['data']['tongTien'] ?? 0).toDouble();
      }

      setState(() {
        tongGiaGoc = total;  // 👈 THÊM
        _tinhTongSauGiam();   // 👈 THÊM
        isLoadingGia = false;
      });
    } catch (e) {
      print('❌ Lỗi tính giá: $e');
      double total = 0;
      for (var room in widget.selectedRooms) {
        var type = room['roomType'];
        double gia = double.tryParse(type['giaThapNhat']?.toString() ?? '0') ?? 0;
        total += gia * soDem;
      }
      setState(() {
        tongGiaGoc = total;  // 👈 THÊM
        _tinhTongSauGiam();   // 👈 THÊM
        isLoadingGia = false;
      });
    }
  }
  void _tinhTongSauGiam() {
    if (_selectedKhuyenMai != null) {
      double phanTramGiam = (_selectedKhuyenMai!['PhanTramGiamGia'] as num).toDouble();
      tongGia = tongGiaGoc * (1 - phanTramGiam / 100);
      tienDatCoc = tongGia;
    } else {
      tongGia = tongGiaGoc;
      tienDatCoc = tongGiaGoc;
    }
  }

  Future<void> xacNhanDatPhong() async {
    if (!formKey.currentState!.validate()) return;

    if (!daDongYChinhSach) {
      _showPopup("Chưa đồng ý", "Vui lòng đọc và đồng ý với Chính sách đặt phòng.", false);
      return;
    }

    // Chuyển sang trang thanh toán
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          checkIn: widget.checkIn,
          checkOut: widget.checkOut,
          soNguoiLon: widget.soNguoiLon,
          soTreEm: widget.soTreEm,
          selectedRooms: widget.selectedRooms,
          hoTen: nameController.text.trim(),
          email: emailController.text.trim(),
          soDienThoai: phoneController.text.trim(),
          ghiChu: noteController.text.trim(),
          tongTien: tongGia,
          tienDatCoc: tienDatCoc,
          selectedKhuyenMai: _selectedKhuyenMai,
        ),
      ),
    );
  }

  void _showPopup(String title, String message, bool isSuccess, {VoidCallback? onOk}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(isSuccess ? Icons.check_circle : Icons.error, color: isSuccess ? Color(0xFFC97A3E) : const Color(0xFFC97A3E), size: 28),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(color: Color(0xFF49120F), fontWeight: FontWeight.bold, fontSize: 17))),
        ]),
        content: Text(message, style: const TextStyle(fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (onOk != null) onOk();
            },
            child: const Text("OK", style: TextStyle(color: Color(0xFFC97A3E), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const thu = ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];
    return "${thu[date.weekday - 1]}, ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  String _formatDateAPI(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String _formatTien(double soTien) {
    return soTien.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    voucherController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Xác nhận đặt phòng",
          style: TextStyle(
            color: Color(0xFF49120F),
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF49120F)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========== HEADER HOTEL ==========
              Center(
                child: Column(
                  children: [
                    Image.asset('assets/logo.png', height: 60),
                    const SizedBox(height: 8),
                    const Text("Khách sạn Peach Valley",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF49120F))),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ========== THÔNG TIN ĐẶT PHÒNG ==========
              const Text("Yêu cầu đặt phòng của bạn",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF49120F))),
              const SizedBox(height: 12),

              // Ngày nhận/trả
              _buildDateCard(),
              const SizedBox(height: 12),

              // Thông tin phòng
              _buildRoomList(),
              const SizedBox(height: 16),

              // // Voucher
              // _buildVoucherInput(),
              const SizedBox(height: 16),

              // Tổng giá
              _buildPriceSummary(),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // ========== THÔNG TIN NGƯỜI ĐẶT ==========
              const Text("Thông tin người đặt phòng",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF49120F))),
              const SizedBox(height: 12),

              TextFormField(
                controller: nameController,
                decoration: _inputDeco("Họ tên *", Icons.person),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Vui lòng nhập họ tên" : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDeco("Email *", Icons.email),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Vui lòng nhập email";
                  if (!v.contains('@')) return "Email không hợp lệ";
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDeco("Số điện thoại *", Icons.phone),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Vui lòng nhập SĐT";
                  if (!RegExp(r'^0[0-9]{9}$').hasMatch(v)) return "SĐT phải 10 số, bắt đầu 0";
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: noteController,
                maxLines: 2,
                decoration: _inputDeco("Ghi chú (không bắt buộc)", Icons.note),
              ),
              const SizedBox(height: 30),

              // ========== NÚT XÁC NHẬN ==========
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : xacNhanDatPhong,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC97A3E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Xác nhận đặt phòng", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8BE97).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Check-in
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Nhận phòng", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(_formatDate(widget.checkIn), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF49120F))),
                const SizedBox(height: 2),
                const Text("Từ 14:00", style: TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          // Số đêm
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFC97A3E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text("$soDem đêm", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          // Check-out
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text("Trả phòng", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(_formatDate(widget.checkOut), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF49120F))),
                const SizedBox(height: 2),
                const Text("Trước 12:00", style: TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildRoomList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Thông tin phòng", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF49120F))),
        const SizedBox(height: 8),
        ...List.generate(widget.selectedRooms.length, (index) {
          var room = widget.selectedRooms[index];
          var type = room['roomType'];
          double giaPhong = double.tryParse(type['giaThapNhat']?.toString() ?? '0') ?? 0;
          // Giá 1 phòng = giá/đêm × số đêm
          double giaMoiPhong = giaPhong * soDem;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE8BE97)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text("Phòng ${index + 1}: ${type['TenLoaiPhong']}",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF49120F))),
                    ),
                    Text("${_formatTien(giaMoiPhong)} VND",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC97A3E))),
                  ],
                ),
                const SizedBox(height: 4),
                Text("${room['nguoiLon']} Người lớn - ${room['treEm']} Trẻ em \n${_formatTien(giaPhong)}đ/đêm × $soDem đêm",
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildVoucherInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedKhuyenMai != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFC97A3E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFC97A3E).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFFC97A3E), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedKhuyenMai!['TenKM'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF49120F)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Mã: ${_selectedKhuyenMai!['MaKM']} • Giảm ${(_selectedKhuyenMai!['PhanTramGiamGia'] as num).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 12, color: Color(0xFFC97A3E)),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedKhuyenMai = null;
                      _tinhTongSauGiam();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.close, color: Colors.red, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          InkWell(
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              int maKH = prefs.getInt('user_maKH') ?? 0;

              if (maKH == 0) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng đăng nhập để sử dụng mã khuyến mãi'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                return;
              }

              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KhoKhuyenMaiPage()),
              );

              if (result != null && result is Map) {
                setState(() {
                  _selectedKhuyenMai = Map<String, dynamic>.from(result);
                  _tinhTongSauGiam();
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã áp dụng mã ${result['TenKM']}'),
                      backgroundColor: Color(0xFFC97A3E),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFC97A3E)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline, color: Color(0xFFC97A3E), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Chọn mã khuyến mãi trong kho của bạn',
                    style: TextStyle(color: Color(0xFFC97A3E), fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF49120F).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8BE97)),
      ),
      child: Column(
        children: [
          // 🔥 Chọn mã KM (đã thêm)
          _buildVoucherInput(),
          const SizedBox(height: 12),

          if (isLoadingGia)
            const Center(child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Color(0xFFC97A3E), strokeWidth: 2),
            ))
          else ...[
            ..._buildGiaChiTiet(),
            const Divider(height: 20),
            _priceRow("Tổng giá phòng", tongGiaGoc, isTotal: false),

            // 🔥 Hiển thị giảm giá nếu có mã KM
            if (_selectedKhuyenMai != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Giảm ${(_selectedKhuyenMai!['PhanTramGiamGia'] as num).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 14, color: Color(0xFFC97A3E)),
                  ),
                  Text(
                    '-${_formatTien(tongGiaGoc - tongGia)} VND',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFFC97A3E),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 4),
            const Divider(height: 20),
            _priceRow("Tiền đặt cọc", tongGia, isTotal: true),
            const SizedBox(height: 12),

            // Checkbox + Link chính sách

            InkWell(
              onTap: () {
                setState(() => daDongYChinhSach = !daDongYChinhSach);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: daDongYChinhSach
                      ? const Color(0xFFC97A3E).withOpacity(0.05)
                      : Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: daDongYChinhSach
                        ? const Color(0xFFC97A3E).withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    // Checkbox custom đẹp hơn
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: daDongYChinhSach ? const Color(0xFFC97A3E) : Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: daDongYChinhSach ? const Color(0xFFC97A3E) : Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                      child: daDongYChinhSach
                          ? const Icon(Icons.check, color: Colors.white, size: 14)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    // Text
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 13, color: Color(0xFF49120F)),
                          children: [
                            const TextSpan(text: "Tôi đã đọc và đồng ý với "),
                            TextSpan(
                              text: "Chính sách đặt phòng",
                              style: const TextStyle(
                                color: Color(0xFFC97A3E),
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Icon info
                    GestureDetector(
                      onTap: () => _showChinhSachPopup(),
                      child: const Icon(Icons.info_outline, color: Color(0xFFC97A3E), size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  void _showChinhSachPopup() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.policy, color: Color(0xFFC97A3E), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text("Chính sách đặt phòng",
                  style: TextStyle(color: Color(0xFF49120F), fontWeight: FontWeight.bold, fontSize: 17)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon cảnh báo
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8BE97).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFFC97A3E), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text("Vui lòng đọc kỹ chính sách trước khi đặt phòng.",
                          style: TextStyle(fontSize: 13, color: Color(0xFF49120F))),
                    ),
                  ],
                ),
              ),

              // Chính sách chung
              _buildPolicySection(
                "Quy định chung",
                [
                  "Không thể chỉnh sửa sau khi đặt phòng.",
                  "Thanh toán đặt cọc trước.",
                  "Khách hàng có thể được yêu cầu thanh toán trước từ 30% đến 100% tổng giá trị đặt phòng, tùy theo hạng phòng, thời gian lưu trú, thời điểm đặt phòng và các chương trình ưu đãi/khuyến mãi đang áp dụng.",
                ],
              ),
              const SizedBox(height: 16),

              // Chính sách hủy
              _buildPolicySection(
                "Chính sách hủy phòng",
                [
                  "Hủy trước 10–15 ngày: Có thể được miễn phí hủy phòng.",
                  "Hủy trước 5–10 ngày: Có thể chịu 30%–70% phí đặt phòng.",
                  "Hủy trước 1–5 ngày: Có thể chịu 100% phí đặt phòng.",
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => daDongYChinhSach = true);
              Navigator.pop(ctx);
            },
            child: const Text("Tôi đồng ý",
                style: TextStyle(color: Color(0xFFC97A3E), fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Đóng", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFC97A3E),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF49120F))),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("• ", style: TextStyle(color: Color(0xFFC97A3E), fontSize: 14)),
              Expanded(
                child: Text(item, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
              ),
            ],
          ),
        )),
      ],
    );
  }

// Gom nhóm hiển thị giá theo loại phòng
  List<Widget> _buildGiaChiTiet() {
    // Gom nhóm
    Map<String, Map<String, dynamic>> grouped = {};
    for (var room in widget.selectedRooms) {
      var type = room['roomType'];
      String ten = type['TenLoaiPhong'] ?? 'Không xác định';
      double gia = double.tryParse(type['giaThapNhat']?.toString() ?? '0') ?? 0;

      if (grouped.containsKey(ten)) {
        grouped[ten]!['count'] = (grouped[ten]!['count'] as int) + 1;
      } else {
        grouped[ten] = {'gia': gia, 'count': 1};
      }
    }

    return grouped.entries.map((e) {
      double gia = e.value['gia'] as double;
      int count = e.value['count'] as int;
      double thanhTien = gia * soDem * count;
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text("${e.key} ×$count", style: const TextStyle(fontSize: 13, color: Colors.grey))),
            Text("${_formatTien(thanhTien)} VND", style: const TextStyle(fontSize: 13, color: Color(0xFF49120F))),
          ],
        ),
      );
    }).toList();
  }

  Widget _priceRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          fontSize: isTotal ? 16 : 14,
          color: Color(0xFF49120F),
        )),
        Text("${_formatTien(amount)} VND", style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: isTotal ? 20 : 14,
          color: const Color(0xFFC97A3E),
        )),
      ],
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFFC97A3E), size: 20),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFE8BE97).withOpacity(0.1),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: const Color(0xFFC97A3E).withOpacity(0.3))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFC97A3E))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}