import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dich_vu.dart';
import '../services/api_service.dart';
import 'ServiceOrderDetailPage.dart';
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
  List<dynamic> currentBookings = [];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    if (isLoggedIn) {
      _fetchCurrentBookings();
    }
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

  // Lấy danh sách đặt phòng đang ở
  Future<void> _fetchCurrentBookings() async {
    final prefs = await SharedPreferences.getInstance();
    int maKH = prefs.getInt('user_maKH') ?? 0;
    if (maKH == 0) return;

    try {
      var response = await ApiService.get('khach-hang/$maKH/dat-phong');
      List allBookings = response['data'] ?? [];
      setState(() {
        currentBookings = allBookings.where((b) => b['TinhTrang'] == 2).toList();
      });
    } catch (e) {
      print('Lỗi load đặt phòng: $e');
    }
  }

  // Hiển thị loading dialog
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: Color(0xFFC97A3E),
                strokeWidth: 2,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Đang xử lý...',
              style: TextStyle(fontSize: 16, color: Color(0xFF49120F)),
            ),
            const SizedBox(height: 4),
            Text(
              'Vui lòng chờ trong giây lát',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  void _hideLoadingDialog() {
    if (mounted) {
      Navigator.of(context).pop();
    }
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
                await _fetchCurrentBookings();
                setState(() {});
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC97A3E),
            ),
            child: const Text('Đăng nhập', style: TextStyle(color: Color(0xFFFFFFFF))),
          ),
        ],
      ),
    );
  }


  // Hiển thị dialog chọn phòng
  void _showRoomSelectionDialog(DichVuModel dv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Chọn đặt phòng để đặt dịch vụ',
          style: TextStyle(color: Color(0xFF49120F), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: currentBookings.isEmpty
              ? const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Không có phòng đang ở'),
          )
              : ListView.builder(
            shrinkWrap: true,
            itemCount: currentBookings.length,
            itemBuilder: (context, index) {
              var booking = currentBookings[index];
              int maDatPhong = booking['MaDatPhong'];
              var phongs = booking['phongs'] ?? [];

              // 🔥 Tạo chuỗi số phòng (ví dụ: "104, 105" hoặc "104")
              String soPhongList = _getSoPhongList(phongs);

              // 🔥 Tạo tiêu đề hiển thị: #94 - 104, 105
              String title = '#$maDatPhong - $soPhongList';

              String ngayNhan = _formatDate(booking['NgayNhanPhong']);
              String ngayTra = _formatDate(booking['NgayTraPhong']);

              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC97A3E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long, color: Color(0xFFC97A3E), size: 20),
                ),
                title: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF49120F),
                  ),
                ),
                subtitle: Text(
                  '$ngayNhan → $ngayTra',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFC97A3E)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ServiceOrderDetailPage(
                        maDatPhong: maDatPhong,
                        soPhong: soPhongList,
                        preSelectedService: dv,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng', style: TextStyle(color: Color(0xFFC97A3E), fontSize: 14)),
          ),
        ],
      ),
    );
  }
  // 🔥 Thêm hàm này vào class
  String _getSoPhongList(List<dynamic> phongs) {
    if (phongs.isEmpty) return 'Chưa có phòng';

    List<String> soPhongs = phongs.map((p) => p['SoPhong'].toString()).toList();

    if (soPhongs.length == 1) {
      return soPhongs.first;
    }

    return soPhongs.join(', ');
  }
  // Xử lý đặt dịch vụ
  void _handleOrderService(DichVuModel dv) async {
    if (!isLoggedIn) {
      _showLoginRequiredDialog();
      return;
    }

    _showLoadingDialog(); // 🔥 HIỂN THỊ LOADING

    try {
      if (currentBookings.isEmpty) {
        await _fetchCurrentBookings();
      }

      _hideLoadingDialog(); // 🔥 ĐÓNG LOADING

      if (currentBookings.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bạn không có đặt phòng nào đang ở hiện tại'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (currentBookings.length == 1) {
        var booking = currentBookings.first;
        int maDatPhong = booking['MaDatPhong'];
        var phongs = booking['phongs'] ?? [];
        String soPhongText = _getSoPhongText(phongs);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceOrderDetailPage(
              maDatPhong: maDatPhong,
              soPhong: soPhongText,
              preSelectedService: dv,
            ),
          ),
        );
      } else {
        _showRoomSelectionDialog(dv);
      }
    } catch (e) {
      _hideLoadingDialog(); // 🔥 ĐÓNG LOADING KHI CÓ LỖI
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString().replaceFirst("Exception: ", "")}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getSoPhongText(List<dynamic> phongs) {
    if (phongs.isEmpty) return 'Chưa xác định';
    if (phongs.length == 1) return '#${phongs[0]['SoPhong']}';
    return '#${phongs[0]['SoPhong']} +${phongs.length - 1}';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      DateTime d = DateTime.parse(dateStr);
      return "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTien(double soTien) {
    return soTien.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF49120F)),
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
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Navigate to service detail
        },
        child: Container(
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
                          // NÚT ĐẶT DỊCH VỤ - Có hiệu ứng ripple
                          if (isLoggedIn)
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => _handleOrderService(dv),
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
                              ),
                            )
                          else
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
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
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}