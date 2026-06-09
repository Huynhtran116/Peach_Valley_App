import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import 'BookingHistoryPage.dart';
import 'HomePage.dart';
import 'SignInPage.dart';
import 'dart:async';
import '../services/khuyen_mai_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';

class PaymentPage extends StatefulWidget {
  final DateTime checkIn;
  final DateTime checkOut;
  final int soNguoiLon;
  final int soTreEm;
  final List<Map<String, dynamic>> selectedRooms;
  final String hoTen;
  final String email;
  final String soDienThoai;
  final String ghiChu;
  final double tongTien;
  final double tienDatCoc;
  final Map<String, dynamic>? selectedKhuyenMai;
  const PaymentPage({
    super.key,
    required this.checkIn,
    required this.checkOut,
    required this.soNguoiLon,
    required this.soTreEm,
    required this.selectedRooms,
    required this.hoTen,
    required this.email,
    required this.soDienThoai,
    required this.ghiChu,
    required this.tongTien,
    required this.tienDatCoc,
    this.selectedKhuyenMai,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  int selectedMethod = 1; // 1: VNPay, 2: QR
  bool isProcessing = false;
  bool isWaitingPayment = false;
  int? maDatPhongDangCho;
  Timer? pollingTimer;
  bool isLoggedIn = false;
  int maKH = 0;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 🔥 Kiểm tra lại mỗi khi quay lại màn hình này
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('user_token');
    int? userId = prefs.getInt('user_maKH');

    final bool loggedIn = token != null && token.isNotEmpty && userId != null && userId > 0;

    print('🔍 PaymentPage - Đã đăng nhập: $loggedIn, Token: ${token != null ? "Có" : "Không"}, MaKH: $userId');

    if (mounted) {
      setState(() {
        isLoggedIn = loggedIn;
        maKH = userId ?? 0;
      });
    }
  }

  String _formatTien(double soTien) {
    return soTien.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
  }

  String _formatDateAPI(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  int get soDem => widget.checkOut.difference(widget.checkIn).inDays;

  Future<void> tienHanhThanhToan() async {
    setState(() => isProcessing = true);

    try {
      await _checkLoginStatus();

      // Gom loại phòng
      Map<int, int> loaiPhongCount = {};
      for (var room in widget.selectedRooms) {
        int maLoai = room['roomType']['MaLoaiPhong'];
        loaiPhongCount[maLoai] = (loaiPhongCount[maLoai] ?? 0) + 1;
      }
      List<Map<String, dynamic>> loaiPhongs = loaiPhongCount.entries.map((e) {
        return {'MaLoaiPhong': e.key, 'SoLuong': e.value};
      }).toList();

      Map<String, dynamic> requestData = {
        'NgayNhanPhong': _formatDateAPI(widget.checkIn),
        'NgayTraPhong': _formatDateAPI(widget.checkOut),
        'LoaiPhongs': loaiPhongs,
        'TenKH': widget.hoTen,
        'SoDienThoai': widget.soDienThoai,
      };

      if (widget.email.isNotEmpty) requestData['Email'] = widget.email;
      if (widget.ghiChu.isNotEmpty) requestData['GhiChu'] = widget.ghiChu;
      if (isLoggedIn && maKH > 0) requestData['MaKH'] = maKH;
      if (widget.selectedKhuyenMai != null) {
        requestData['MaKM'] = widget.selectedKhuyenMai!['MaKM'];
      }

      print('📝 Request đặt phòng: $requestData');

      // BƯỚC 1: Tạo đặt phòng
      var bookingResponse = await ApiService.post('dat-phong', requestData);
      print('✅ Response đặt phòng: $bookingResponse');

      int maDatPhong = bookingResponse['data']['datPhong']['MaDatPhong'];
      double soTienThanhToan = widget.tienDatCoc;

      // BƯỚC 2: Xử lý theo phương thức thanh toán
      if (selectedMethod == 1) {
        // Thanh toán VNPay - Thẻ nội địa
        await _processVNPayPayment(maDatPhong, soTienThanhToan);
      } else if (selectedMethod == 2) {
        // Thanh toán ZaloPay - Mã QR
        await _processZaloPayPayment(maDatPhong, soTienThanhToan);
      }

    } catch (e) {
      print('❌ Lỗi đặt phòng: $e');
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }
  Future<void> _processVNPayPayment(int maDatPhong, double soTienThanhToan) async {
    var paymentResponse = await ApiService.post('vnpay-payment', {
      'amount': soTienThanhToan.toInt(),
      'dat_phong_ids': [maDatPhong],
      'bank_code': 'VNBANK',
      'description': "Thanh toan dat phong Peach Valley",
    });

    String? paymentUrl = paymentResponse['payment_url'];
    String? txnRef = paymentResponse['txn_ref'];

    if (paymentUrl != null && mounted) {
      final Uri uri = Uri.parse(paymentUrl);
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
      setState(() {
        isWaitingPayment = true;
        maDatPhongDangCho = maDatPhong;
      });
      _startPollingPaymentStatus(txnRef, maDatPhong);
    }
  }
  Future<void> _processZaloPayPayment(int maDatPhong, double soTienThanhToan) async {
    try {
      var paymentResponse = await ApiService.post('zalopay-payment', {
        'amount': soTienThanhToan.toInt(),
        'dat_phong_ids': [maDatPhong],
        'app_user': widget.soDienThoai,
        'description': "Thanh toan dat phong Peach Valley",
        'payment_type': 'deposit',
      });

      print('📱 ZaloPay Response: $paymentResponse'); // Log để debug

      // ZaloPay trả về 2 dạng:
      // - order_url: URL để mở app/web
      // - qr_code: Chuỗi mã QR (dạng text)
      String? orderUrl = paymentResponse['order_url'];
      String? qrCode = paymentResponse['qr_code'];
      String? appTransId = paymentResponse['app_trans_id'];

      if (mounted) {
        if (qrCode != null && qrCode.isNotEmpty) {
          // Hiển thị QR code ngay trong app
          _showZaloPayQRDialog(orderUrl ?? '', qrCode, appTransId, maDatPhong);
        } else if (orderUrl != null && orderUrl.isNotEmpty) {
          // Nếu có URL thì mở trình duyệt
          final Uri uri = Uri.parse(orderUrl);
          await launchUrl(uri, mode: LaunchMode.inAppWebView);
          setState(() {
            isWaitingPayment = true;
            maDatPhongDangCho = maDatPhong;
          });
          _startPollingZaloPayStatus(appTransId, maDatPhong);
        } else {
          throw Exception('Không nhận được thông tin thanh toán từ ZaloPay');
        }
      }
    } catch (e) {
      print('❌ ZaloPay Error: $e');
      throw Exception('Lỗi thanh toán ZaloPay: $e');
    }
  }
  void _showZaloPayQRDialog(String orderUrl, String? qrCode, String? appTransId, int maDatPhong) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner, color: Color(0xFFC97A3E), size: 28),
            SizedBox(width: 10),
            Text("Quét mã QR để thanh toán",
                style: TextStyle(color: Color(0xFF49120F), fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,  // ✅ Quan trọng: Column co giãn theo nội dung
          children: [
            // ✅ Kiểm tra dữ liệu trước khi tạo QR
            if (qrCode != null && qrCode.isNotEmpty)
              SizedBox(
                width: 220,  // ✅ Fix cứng chiều rộng
                height: 220, // ✅ Fix cứng chiều cao
                child: QrImageView(
                  data: qrCode,
                  version: QrVersions.auto,
                  size: 200.0,
                  eyeStyle: const QrEyeStyle(
                    color: Color(0xFFC97A3E),
                    eyeShape: QrEyeShape.square,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    color: Color(0xFF49120F),
                    dataModuleShape: QrDataModuleShape.square,
                  ),
                ),
              )
            else
            // ✅ Fallback khi không có QR code
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code, size: 80, color: Colors.grey),
                      SizedBox(height: 8),
                      Text("Không có mã QR", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Số tiền
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFC97A3E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "${_formatTien(widget.tienDatCoc)} VND",
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC97A3E)
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Hướng dẫn
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Mở ZaloPay → Chọn \"Quét mã\" → Quét mã QR trên màn hình",
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showError("Hủy thanh toán");
            },
            child: const Text("Hủy", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  void _startPollingZaloPayStatus(String? appTransId, int maDatPhong) {
    int attempts = 0;
    const maxAttempts = 180; // 6 phút

    pollingTimer?.cancel();
    pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      attempts++;

      if (attempts > maxAttempts) {
        timer.cancel();
        if (mounted) {
          setState(() => isWaitingPayment = false);
          _showError("Quá thời gian chờ thanh toán. Vui lòng kiểm tra lại.");
        }
        return;
      }

      try {
        var response = await ApiService.get('zalopay/check-status/$appTransId');
        bool isPaid = response['data']?['paid'] ?? false;

        if (isPaid) {
          timer.cancel();
          if (mounted) {
            setState(() => isWaitingPayment = false);
            Navigator.of(context).popUntil((route) => route.isFirst);
            _showPaymentSuccess(maDatPhong, appTransId);
          }
        }
      } catch (e) {
        // Bỏ qua lỗi, thử lại
      }
    });
  }

  void _startPollingPaymentStatus(String? txnRef, int maDatPhong) {
    int attempts = 0;
    const maxAttempts = 450;

    pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      attempts++;

      if (attempts > maxAttempts) {
        timer.cancel();
        if (mounted) {
          setState(() => isWaitingPayment = false);
          _showError("Quá thời gian chờ thanh toán. Vui lòng kiểm tra lại.");
        }
        return;
      }

      try {
        var response = await ApiService.get('vnpay/check-status/$txnRef');
        bool isPaid = response['data']?['paid'] ?? false;

        if (isPaid) {
          timer.cancel();
          if (mounted) {
            setState(() => isWaitingPayment = false);
            Navigator.of(context).popUntil((route) => route.isFirst);
            _showPaymentSuccess(maDatPhong, txnRef);
          }
        }
      } catch (e) {
        // Bỏ qua lỗi, thử lại
      }
    });
  }

  void _showPaymentSuccess(int maDatPhong, String? txnRef) {
    // 🔥 Nếu có mã KM, đánh dấu đã sử dụng
    if (widget.selectedKhuyenMai != null) {
      _suDungKhuyenMai();
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.check_circle, color: Color(0xFFC97A3E), size: 28),
          SizedBox(width: 10),
          Text("Thanh toán thành công!", style: TextStyle(color: Color(0xFF49120F), fontWeight: FontWeight.bold, fontSize: 17)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _infoRow("Mã đặt phòng", "#$maDatPhong"),
            if (txnRef != null) _infoRow("Mã GD", txnRef),
            _infoRow("Tổng tiền", "${_formatTien(widget.tienDatCoc)} VND"),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  if (isLoggedIn) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const BookingHistoryPage()),
                          (route) => false,
                    );
                  } else {
                    _showLoginPrompt();
                  }
                },
                icon: const Icon(Icons.receipt_long, size: 18),
                label: Text(isLoggedIn ? "Xem lịch sử đặt phòng" : "Đăng nhập để xem lịch sử" , style: TextStyle(color: Color(0xFFFFFFFF)),),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC97A3E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
                    (route) => false,
              );
            },
            child: const Text("Về trang chủ", style: TextStyle(color: Color(0xFFC97A3E), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLoginPrompt() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Đăng nhập để quản lý đặt phòng"),
        content: const Text("Bạn có muốn đăng nhập để xem chi tiết lịch sử đặt phòng?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Để sau"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC97A3E),
            ),
            child: const Text("Đăng nhập"),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final loginResult = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SignInPage()),
      );

      // 🔥 Sau khi đăng nhập thành công, cập nhật lại trạng thái
      if (loginResult == true && mounted) {
        await _checkLoginStatus();
        setState(() {});

        // Tự động chuyển đến lịch sử đặt phòng
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const BookingHistoryPage()),
          );
        }
      }
    }
  }

  void _showSuccessDialog(int maDatPhong) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.check_circle, color: Color(0xFFC97A3E), size: 28),
          SizedBox(width: 10),
          Text("Đặt phòng thành công!", style: TextStyle(color: Color(0xFF49120F), fontWeight: FontWeight.bold, fontSize: 17)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow("Mã đặt phòng", "#$maDatPhong"),
            _infoRow("Phương thức", selectedMethod == 1 ? "VNPay" : "Thanh toán sau"),
            _infoRow("Tổng tiền", "${_formatTien(widget.tongTien)} VND"),
            if (selectedMethod != 1) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(children: [
                  Icon(Icons.access_time, size: 16, color: Colors.orange),
                  SizedBox(width: 6),
                  Expanded(child: Text("Vui lòng thanh toán trong 15 phút", style: TextStyle(fontSize: 12, color: Colors.orange))),
                ]),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  if (isLoggedIn) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const BookingHistoryPage()),
                          (route) => false,
                    );
                  } else {
                    _showLoginPrompt();
                  }
                },
                icon: const Icon(Icons.receipt_long, size: 18),
                label: Text(isLoggedIn ? "Xem lịch sử đặt phòng" : "Đăng nhập để xem lịch sử"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFC97A3E),
                  side: const BorderSide(color: Color(0xFFC97A3E)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
                    (route) => false,
              );
            },
            child: const Text("Về trang chủ", style: TextStyle(color: Color(0xFFC97A3E), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  //
  Future<void> _suDungKhuyenMai() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int maKH = prefs.getInt('user_maKH') ?? 0;

      print('🔍 _suDungKhuyenMai: maKH=$maKH, maKM=${widget.selectedKhuyenMai!['MaKM']}');

      if (maKH > 0 && widget.selectedKhuyenMai != null) {
        final result = await KhuyenMaiService.suDungKhuyenMai(
          maKH,
          widget.selectedKhuyenMai!['MaKM'] ?? '',
        );
        print('🔍 Kết quả suDungKhuyenMai: $result');  // 👈 XEM LOG NÀY
      }
    } catch (e) {
      print('❌ Lỗi đánh dấu mã KM: $e');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.error, color: Colors.red, size: 28),
          SizedBox(width: 10),
          Text("Lỗi", style: TextStyle(color: Color(0xFF49120F), fontWeight: FontWeight.bold)),
        ]),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF49120F))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    pollingTimer?.cancel();
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
          "Thanh toán",
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thông báo nếu chưa đăng nhập
                if (!isLoggedIn)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Bạn đang đặt phòng với tư cách khách. "
                                "${widget.hoTen} - ${widget.soDienThoai}",
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Tổng quan đơn hàng
                _buildOrderSummary(),
                const SizedBox(height: 24),

                // Chọn phương thức
                const Text("Chọn phương thức thanh toán",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF49120F))),
                const SizedBox(height: 12),
                // ZaloPay - Thanh toán QR
                _buildPaymentCard(
                  icon: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0066FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text("Z", style: TextStyle(color: Color(0xFF0066FF), fontWeight: FontWeight.bold, fontSize: 24)),
                    ),
                  ),
                  title: "Thanh toán bằng mã QR",
                  subtitle: "Quét mã QR qua ZaloPay",
                  value: 2,
                ),


                // VNPay
                _buildPaymentCard(
                  icon: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text("V", style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold, fontSize: 24)),
                    ),
                  ),
                  title: "Thanh toán qua thẻ nội địa ",
                  subtitle: "Thẻ ATM nội địa / Ví VNPay",
                  value: 1,
                ),
                const SizedBox(height: 10),

                // Thanh toán sau
                // _buildPaymentCard(
                //   icon: Container(
                //     width: 48, height: 48,
                //     decoration: BoxDecoration(
                //       color: const Color(0xFFC97A3E).withOpacity(0.1),
                //       borderRadius: BorderRadius.circular(12),
                //     ),
                //     child: const Center(
                //       child: Icon(Icons.credit_card, color: Color(0xFFC97A3E), size: 28),
                //     ),
                //   ),
                //   title: "Thanh toán qua thẻ quốc tế",
                //   subtitle: "Visa / Mastercard / JCB",
                //   value: 2,
                // ),
                // const SizedBox(height: 30),

                // Nút thanh toán
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isProcessing ? null : tienHanhThanhToan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC97A3E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: isProcessing
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text("Đặt phòng ${_formatTien(widget.tienDatCoc)}đ",
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.security, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text("Thanh toán an toàn & bảo mật",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isWaitingPayment)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFFC97A3E)),
                      SizedBox(height: 20),
                      Text("Đang chờ thanh toán...", style: TextStyle(color: Color(0xFF49120F), fontSize: 16)),
                      SizedBox(height: 8),
                      Text("Vui lòng hoàn tất thanh toán ", style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8BE97).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8BE97)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Đơn hàng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF49120F))),
          const SizedBox(height: 8),
          _infoRow("Khách hàng", widget.hoTen),
          _infoRow("Số điện thoại", widget.soDienThoai),
          if (widget.email.isNotEmpty) _infoRow("Email", widget.email),
          _infoRow("Số phòng", "${widget.selectedRooms.length} phòng • $soDem đêm"),

          //  THÊM: Hiển thị mã KM nếu có
          if (widget.selectedKhuyenMai != null) ...[
            const Divider(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_offer, color: Color(0xFFC97A3E), size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Đã áp dụng: ${widget.selectedKhuyenMai!['TenKM']} (-${(widget.selectedKhuyenMai!['PhanTramGiamGia'] as num).toStringAsFixed(0)}%)',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFC97A3E), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Tổng thanh toán", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF49120F))),
              Text("${_formatTien(widget.tienDatCoc)} VND",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFFC97A3E))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard({
    required Widget icon,
    required String title,
    required String subtitle,
    required int value,
    bool isDisabled = false,
  }) {
    bool isSelected = selectedMethod == value;

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: isDisabled
            ? () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tính năng đang bảo trì, vui lòng thử lại sau'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
            : () => setState(() => selectedMethod = value),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected && !isDisabled ? const Color(0xFFC97A3E).withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected && !isDisabled ? const Color(0xFFC97A3E) : Colors.grey.shade200,
              width: isSelected && !isDisabled ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              icon,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDisabled ? Colors.grey : const Color(0xFF49120F),
                            ),
                          ),
                        ),
                        if (isDisabled)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Bảo trì',
                              style: TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: isDisabled ? Colors.orange : Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDisabled
                      ? Colors.grey.shade300
                      : (isSelected ? const Color(0xFFC97A3E) : Colors.transparent),
                  border: Border.all(
                    color: isDisabled
                        ? Colors.grey
                        : (isSelected ? const Color(0xFFC97A3E) : Colors.grey.shade300),
                    width: 2,
                  ),
                ),
                child: isSelected && !isDisabled
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}