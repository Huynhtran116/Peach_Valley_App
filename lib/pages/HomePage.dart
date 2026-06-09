import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/danh_gia.dart';
import '../models/loai_phong.dart';
import '../services/khuyen_mai_service.dart';
import '../utils/number_parser.dart';
import 'AllReviewsPage.dart';
import 'AllocationPage.dart';
import 'BookingHistoryPage.dart';
import 'DatePickerPage.dart';
import 'DetailRoomPage.dart';
import 'AccountPage.dart';
import 'DetailSerVicePage.dart';
import '../services/danh_gia_service.dart';
import 'PromotionPage.dart';
import 'RoomListPage.dart';
import 'SearchPage.dart';
import '../services/api_service.dart';
import '../models/dich_vu.dart';
import '../models/khuyen_mai.dart';
import 'ServiceListPage.dart';
import 'ServiceOrderDetailPage.dart';
import 'SignInPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver{
  int _currentIndex = 0;

  // Biến user
  String userName = 'Khách';
  String userEmail = '';
  bool isLoadingUser = true;
  bool isLoggedIn = false; // Thêm biến kiểm tra đăng nhập

  List<LoaiPhong> danhSachPhong = [];
  bool isLoadingRooms = true;

  List<DichVuModel> danhSachDichVu = [];
  bool isLoadingServices = true;

  List<KhuyenMaiModel> danhSachKhuyenMai = [];
  bool isLoadingPromos = true;

  // 🔥 THÊM: Biến cho đánh giá
  List<DanhGiaModel> danhSachDanhGia = [];
  double diemTrungBinh = 0.0;
  int tongDanhGia = 0;
  Map<int, int> soLuongTheoSao = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
  bool isLoadingDanhGia = true;
  DateTime? _lastDanhGiaReload;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 🔥 Theo dõi app lifecycle
    _checkAndFixData(); // Thêm hàm kiểm tra dữ liệu lỗi
    loadUserInfo();
    _loadAllData(); // 🔥 Load song song
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load lại mỗi khi quay lại (quan trọng!)
    loadUserInfo();
    _reloadDanhGiaIfNeeded();
  }
  // 🔥 Load tất cả song song
  Future<void> _loadAllData() async {
    await Future.wait([
      fetchLoaiPhong(),
      fetchDichVu(),
      fetchKhuyenMai(),
      fetchDanhGia(),
    ]);
  }
  // 🔥 Reload đánh giá nếu cần
  Future<void> _reloadDanhGiaIfNeeded() async {
    final now = DateTime.now();

    if (_lastDanhGiaReload == null ||
        now.difference(_lastDanhGiaReload!).inSeconds > 30) {
      _lastDanhGiaReload = now;
      fetchDanhGia(); // Không await để không block UI
    }
  }
// Hàm kiểm tra và fix dữ liệu lỗi
  Future<void> _checkAndFixData() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('user_token');
    int? maKH = prefs.getInt('user_maKH');

    // Nếu có token nhưng không có maKH -> dữ liệu lỗi, xóa token
    if ((token != null && token.isNotEmpty) && (maKH == null || maKH == 0)) {
      print('⚠️ Phát hiện dữ liệu lỗi: Có token nhưng không có maKH');
      await prefs.remove('user_token');
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      print('✅ Đã xóa dữ liệu không hợp lệ');
    }
  }

// Load user từ SharedPreferences
  Future<void> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();

    // Lấy dữ liệu hiện tại
    String? token = prefs.getString('user_token');
    int? maKH = prefs.getInt('user_maKH');
    String? storedName = prefs.getString('user_name');
    String? storedEmail = prefs.getString('user_email');

    print('📊 Dữ liệu thô trong SharedPreferences:');
    print('   - Token: ${token != null ? "Có (${token.length} chars)" : "KHÔNG"}');
    print('   - MaKH: $maKH');
    print('   - Name: $storedName');

    // 🔥 DỌN DẸP DỮ LIỆU LỖI
    bool needCleanup = false;

    // Trường hợp 1: Có maKH nhưng không có token
    if ((maKH != null && maKH > 0) && (token == null || token.isEmpty)) {
      print('⚠️ LỖI: Có maKH=$maKH nhưng KHÔNG có token');
      needCleanup = true;
    }

    // Trường hợp 2: Có token nhưng không có maKH
    if ((token != null && token.isNotEmpty) && (maKH == null || maKH == 0)) {
      print('⚠️ LỖI: Có token nhưng KHÔNG có maKH');
      needCleanup = true;
    }

    // Thực hiện dọn dẹp nếu cần
    if (needCleanup) {
      print('🧹 Đang dọn dẹp dữ liệu lỗi...');
      await prefs.remove('user_token');
      await prefs.remove('user_maKH');
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      await prefs.remove('user_diem');
      await prefs.remove('user_maTK');

      // Reset các biến
      token = null;
      maKH = null;
      storedName = null;
      storedEmail = null;
      print('✅ Đã dọn dẹp xong');
    }

    // Kiểm tra lại sau khi dọn dẹp
    final bool hasValidToken = (token != null && token.isNotEmpty);
    final bool hasValidMaKH = (maKH != null && maKH > 0);
    final bool loggedIn = hasValidToken && hasValidMaKH;

    print('🔍 Kết quả kiểm tra:');
    print('   - Token hợp lệ: $hasValidToken');
    print('   - MaKH hợp lệ: $hasValidMaKH');
    print('   - Đã đăng nhập: $loggedIn');

    setState(() {
      isLoggedIn = loggedIn;

      if (loggedIn) {
        // Đã đăng nhập hợp lệ
        userName = (storedName != null && storedName.isNotEmpty) ? storedName : 'Khách';
        userEmail = storedEmail ?? '';
        print('   ✅ Hiển thị: $userName (đã đăng nhập)');
      } else {
        // Chưa đăng nhập - LUÔN là "Khách"
        userName = 'Khách';
        userEmail = '';
        print('   ❌ Hiển thị: Khách (chưa đăng nhập)');
      }

      isLoadingUser = false;
    });
  }

  Future<void> fetchLoaiPhong() async {
    try {
      var response = await ApiService.get('loai-phong');

      // 🔥 THÊM DEBUG NÀY
      print('📦 API Response: $response');

      List data = response['data'] ?? [];

      // 🔥 THÊM DEBUG NÀY
      if (data.isNotEmpty) {
        print('📦 First item: ${data[0]}');
        print('📦 bang_gias: ${data[0]['bang_gias']}');
      }

      setState(() {
        danhSachPhong = data
            .map((e) => LoaiPhong.fromJson(e))
            .take(3)
            .toList();
        isLoadingRooms = false;
      });
    } catch (e) {
      print('❌ Lỗi load phòng: $e');
      setState(() => isLoadingRooms = false);
    }
  }

  Future<void> fetchDichVu() async {
    try {
      var response = await ApiService.get('dich-vu');
      List data = response['data'] ?? [];

      final List<String> hiddenServices = [
        'Thêm giường phụ',
        'Đổi phòng',
        'Hủy phòng',
      ];

      setState(() {
        danhSachDichVu = data
            .map((e) => DichVuModel.fromJson(e))
            .where((dv) => !hiddenServices.contains(dv.tenDV))
            .take(5)
            .toList();
        isLoadingServices = false;
      });
    } catch (e) {
      print('Lỗi load dịch vụ: $e');
      setState(() => isLoadingServices = false);
    }
  }

  Future<void> fetchKhuyenMai() async {
    try {
      var response = await ApiService.get('khuyen-mai');
      print('📥 Raw response: $response');

      // Xử lý response
      List data = [];
      if (response is List) {
        data = response;
      } else if (response['data'] is List) {
        data = response['data'];
      }

      print('📊 Data length: ${data.length}');

      List<KhuyenMaiModel> tempList = [];
      for (var item in data) {
        try {
          print('📦 Item: $item');
          final km = KhuyenMaiModel.fromJson(item);
          if (km.conHan) {
            tempList.add(km);
            print('✅ Added: ${km.tenKM}');
          }
        } catch (e) {
          print('❌ Parse error: $e');
          print('❌ Item causing error: $item');
        }
      }

      setState(() {
        danhSachKhuyenMai = tempList;
        isLoadingPromos = false;
      });

    } catch (e) {
      print('❌ Lỗi load khuyến mãi: $e');
      setState(() {
        danhSachKhuyenMai = [];
        isLoadingPromos = false;
      });
    }
  }
  Future<void> fetchDanhGia() async {
    final stopwatch = Stopwatch()..start();
    print('⏱️ [ĐÁNH GIÁ] Bắt đầu fetch...');

    try {
      final result = await DanhGiaService.layTatCaDanhGia();
      stopwatch.stop();
      print('⏱️ [ĐÁNH GIÁ] Fetch xong trong ${stopwatch.elapsedMilliseconds}ms');
      print('⏱️ [ĐÁNH GIÁ] Số lượng: ${result['tongDanhGia']}');

      if (!mounted) return;

      setState(() {
        danhSachDanhGia = (result['danhSach'] as List)
            .take(5)
            .cast<DanhGiaModel>()
            .toList();
        diemTrungBinh = result['diemTrungBinh'] ?? 0.0;
        tongDanhGia = result['tongDanhGia'] ?? 0;
        soLuongTheoSao = Map<int, int>.from(result['soLuongTheoSao'] ?? {});
        isLoadingDanhGia = false;
      });
    } catch (e) {
      stopwatch.stop();
      print('❌ Lỗi load đánh giá sau ${stopwatch.elapsedMilliseconds}ms: $e');
      if (!mounted) return;
      setState(() => isLoadingDanhGia = false);
    }
  }


  // Logout - Thêm dialog xác nhận
  Future<void> _logout() async {
    // 🔥 Hiển thị dialog xác nhận
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text(
              'Đăng xuất',
              style: TextStyle(
                color: Color(0xFF49120F),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất?',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    // Xóa dữ liệu trong SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_token');
    await prefs.remove('user_maKH');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_diem');
    await prefs.remove('user_maTK');

    // Cập nhật UI
    setState(() {
      isLoggedIn = false;
      userName = 'Khách';
      userEmail = '';
    });

    // Hiển thị thông báo
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã đăng xuất thành công'),
        backgroundColor: Color(0xFFC97A3E),
      ),
    );
  }

  // Các màn hình
  List<Widget> _pages() => [
    _homeContent(),
    const DatePickerPage(),
    _getHistoryPage(), // Màn hình Message (tùy theo login)
    _getAccountPage(), // Màn hình Account (tùy theo login)
  ];


  // Màn hình Lịch sử đặt phòng - yêu cầu login nếu chưa đăng nhập
  Widget _getHistoryPage() {
    if (!isLoggedIn) {
      return _buildLoginRequiredPage(
        icon: Icons.history,
        title: 'Lịch sử đặt phòng',
        message: 'Đăng nhập để xem lịch sử đặt phòng của bạn',
      );
    }
    return const BookingHistoryPage(); // 🔥 Trả về BookingHistoryPage thay vì Text
  }


  // Màn hình Account - hiển thị theo trạng thái login
  Widget _getAccountPage() {
    if (!isLoggedIn) {
      return _buildLoginRequiredPage(
        icon: Icons.person,
        title: 'Tài khoản',
        message: 'Đăng nhập để quản lý thông tin cá nhân và lịch sử đặt phòng',
      );
    }
    return AccountPage(
      onLogout: () {
        // Callback khi logout từ AccountPage
        setState(() {
          isLoggedIn = false;
          userName = 'Khách';
          userEmail = '';
        });
      },
    );
  }
  // Format tiền theo chuẩn VND
  String _formatVND(dynamic amount) {
    return NumberParser.formatVND(amount);
  }


  // Widget hiển thị khi chưa đăng nhập
  Widget _buildLoginRequiredPage({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF49120F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignInPage()),
                );
                if (result == true) {
                  await loadUserInfo(); // Refresh thông tin sau khi đăng nhập
                  setState(() {}); // Refresh lại UI
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC97A3E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: const Text('Đăng nhập ngay'),
            ),
          ],
        ),
      ),
    );
  }
  // 🔥 THÊM VÀO CLASS _HomePageState
  Widget _buildStarRating(double rating, {double size = 16, Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star, size: size, color: color ?? Colors.amber);
        } else if (index < rating && rating % 1 >= 0.5) {
          return Icon(Icons.star_half, size: size, color: color ?? Colors.amber);
        } else {
          return Icon(Icons.star_border, size: size, color: color ?? Colors.amber);
        }
      }),
    );
  }

  // 🔥 THÊM VÀO CLASS _HomePageState
  Widget _buildDanhGiaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Đánh giá từ khách hàng",
                style: TextStyle(
                  color: Color(0xFF6F1D01),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AllReviewsPage()),
                  );
                },
                child: const Text(
                  "Xem tất cả",
                  style: TextStyle(
                    color: Color(0xFFC97A3E),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),

        if (isLoadingDanhGia)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Color(0xFFC97A3E)),
            ),
          )
        else ...[
          // 🔥 Tổng quan đánh giá
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF49120F), Color(0xFFC97A3E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: tongDanhGia == 0
                ? const Center(
              child: Text(
                'Chưa có đánh giá nào',
                style: TextStyle(color: Colors.white70),
              ),
            )
                : Row(
              children: [
                // Điểm trung bình
                Column(
                  children: [
                    Text(
                      diemTrungBinh.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildStarRating(diemTrungBinh, size: 18, color: Colors.amber),
                    const SizedBox(height: 4),
                    Text(
                      '$tongDanhGia đánh giá',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                // Thanh tỉ lệ các sao
                Expanded(
                  child: Column(
                    children: List.generate(5, (index) {
                      int star = 5 - index;
                      int count = soLuongTheoSao[star] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 14,
                              child: Text(
                                '$star',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            const Icon(Icons.star, color: Colors.amber, size: 12),
                            const SizedBox(width: 4),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: tongDanhGia > 0 ? count / tongDanhGia : 0,
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            SizedBox(
                              width: 24,
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // 🔥 Danh sách đánh giá gần đây
          if (danhSachDanhGia.isNotEmpty)
            SizedBox(
              height: 200,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: danhSachDanhGia.length,
                itemBuilder: (context, index) {
                  final dg = danhSachDanhGia[index];
                  return _buildDanhGiaCard(dg);
                },
              ),
            ),
        ],
      ],
    );
  }
  // 🔥 THÊM VÀO CLASS _HomePageState
  Widget _buildDanhGiaCard(DanhGiaModel dg) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + Tên + Sao
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFC97A3E).withOpacity(0.1),
                child: Text(
                  dg.avatarChar,
                  style: const TextStyle(
                    color: Color(0xFFC97A3E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dg.tenKhachHang ?? 'Khách hàng',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _buildStarRating(dg.sao.toDouble(), size: 12),
                        const SizedBox(width: 4),
                        Text(
                          dg.ngayDanhGiaFormatted,
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Loại phòng đã đặt
          if (dg.tenLoaiPhong != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE8BE97).withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                dg.tenLoaiPhong!,
                style: const TextStyle(fontSize: 10, color: Color(0xFF49120F)),
              ),
            ),
          const SizedBox(height: 6),
          // Nội dung đánh giá
          Expanded(
            child: Text(
              dg.moTa ?? 'Không có nội dung',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: (dg.moTa == null || dg.moTa!.isEmpty)
                    ? Colors.grey
                    : Colors.black87,
                height: 1.4,
                fontStyle: (dg.moTa == null || dg.moTa!.isEmpty)
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFfffff),

      body: IndexedStack(
        index: _currentIndex,
        children: _pages(),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFC97A3E),
        unselectedItemColor: const Color(0xFF49120F),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Trang chủ",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: "Đặt phòng",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "Lịch sử đặt phòng",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Tài khoản",
          ),
        ],
      ),
    );
  }

  /// ================= HOME CONTENT =================
  Widget _homeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF49120F),
                      Color(0xFFC97A3E),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 80),

                    /// Top row với avatar và nút đăng nhập/đăng xuất
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            buildAvatar(userName, radius: 18),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isLoadingUser ? "Đang tải..." : userName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                                if (!isLoadingUser && userEmail.isNotEmpty)
                                  Text(
                                    userEmail,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Nút đăng xuất (chỉ hiển thị khi đã đăng nhập)
                            if (isLoggedIn) ...[
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: _logout,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.logout,
                                      color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    /// SEARCH
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SearchPage()),
                        );
                      },
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.search, color: Colors.black54),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Bạn muốn tìm phòng ...",
                                style: TextStyle(color: Color(0xFF49120F)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 25),

          /// ROOM
          _sectionTitle("Các loại phòng của khách sạn", type: "room"),
          const SizedBox(height: 15),

          SizedBox(
            height: 290,
            child: isLoadingRooms
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: danhSachPhong.length,
              itemBuilder: (context, index) {
                final room = danhSachPhong[index];
                return _roomCardAPI(room);
              },
            ),
          ),

          const SizedBox(height: 25),

          /// SERVICE
          _sectionTitle("Các loại dịch vụ", type: "service"),
          const SizedBox(height: 15),

          SizedBox(
            height: 250,
            child: isLoadingServices
                ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFC97A3E)))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: danhSachDichVu.length > 5 ? 5 : danhSachDichVu.length,
              itemBuilder: (context, index) {
                final dv = danhSachDichVu[index];
                return _serviceCardAPI(dv);
              },
            ),
          ),

          const SizedBox(height: 25),

          /// KHUYẾN MÃI
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Chương trình khuyến mãi",
                  style: TextStyle(
                    color: Color(0xFF6F1D01),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PromotionPage(),
                      ),
                    );
                  },
                  child: const Text(
                    "Xem tất cả",
                    style: TextStyle(color: Color(0xFFC97A3E)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),

          isLoadingPromos
              ? const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Color(0xFFC97A3E)),
            ),
          )
              : danhSachKhuyenMai.isEmpty
              ? const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              "Hiện chưa có khuyến mãi nào",
              style: TextStyle(color: Colors.grey),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: danhSachKhuyenMai.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final km = danhSachKhuyenMai[index];
              return _khuyenMaiCard(km);
            },
          ),
          const SizedBox(height: 15),
          // danh gia
          _buildDanhGiaSection(),
        ],
      ),
    );
  }

  /// ================= UI Components =================
  Widget _sectionTitle(String title, {String? type}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6F1D01),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: () {
              if (type == "room") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RoomListPage(),
                  ),
                );
              } else if (type == "service") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ServiceListPage(),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchPage()),
                );
              }
            },
            child: const Text(
              "Xem tất cả",
              style: TextStyle(color: Color(0xFFC97A3E)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roomCardAPI(LoaiPhong room) {
    // 🔥 KHAI BÁO BIẾN GIÁ
    double giaGoc = room.giaPhong;
    double giaGiam = room.giaHienThi;
    double gia = giaGiam; // Giá hiển thị chính

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RoomDetailPage(
                  loaiPhong: room,
                  fromHome: true
              ),
            ),
          );
        },
        child: Container(
          width: 300,
          margin: const EdgeInsets.only(right: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: room.anhDauTien != null
                    ? Image.network(
                  room.anhDauTien!,
                  height: 170,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 170,
                      color: const Color(0xFFE8BE97),
                      child: const Center(
                        child: Icon(Icons.hotel, size: 50, color: Color(0xFF49120F)),
                      ),
                    );
                  },
                )
                    : Container(
                  height: 170,
                  color: const Color(0xFFE8BE97),
                  child: const Center(
                    child: Icon(Icons.hotel, size: 50, color: Color(0xFF49120F)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.tenLoaiPhong,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.account_circle_sharp, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Tối đa : ${room.nguoiLon} người lớn - ${room.treEm} trẻ em',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 🔥 CỘT GIÁ KIỂU SHOPEE
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Giá gốc gạch ngang + badge (nếu có KM)
                            if (room.coKhuyenMai)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${_formatVND(giaGoc)} VND',
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
                                      '-${((1 - giaGiam / giaGoc) * 100).toStringAsFixed(0)}%',
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
                              '${_formatVND(gia)} VND/đêm',
                              style: const TextStyle(
                                color: Color(0xFFC97A3E),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        // Nút Chi tiết
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RoomDetailPage(
                                      loaiPhong: room,
                                      fromHome: true
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                                'Chi tiết',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _serviceCardAPI(DichVuModel dv) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: Navigate to service detail
        },
        child: Container(
          width: 300,
          margin: const EdgeInsets.only(right: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: dv.anhDauTien != null
                    ? Image.network(
                  dv.anhDauTien!,
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 130,
                      color: const Color(0xFFE8BE97),
                      child: const Center(
                        child: Icon(Icons.room_service,
                            size: 40, color: Color(0xFF49120F)),
                      ),
                    );
                  },
                )
                    : Container(
                  height: 130,
                  color: const Color(0xFFE8BE97),
                  child: const Center(
                    child: Icon(Icons.room_service,
                        size: 40, color: Color(0xFF49120F)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dv.tenDV,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getLoaiColor(dv.loaiDV).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        dv.loaiDVText,
                        style: TextStyle(
                          color: _getLoaiColor(dv.loaiDV),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dv.giaDVFormatted,
                          style: const TextStyle(
                            color: Color(0xFFC97A3E),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        // NÚT ĐẶT DỊCH VỤ
                        if (isLoggedIn)
                          Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                _navigateToServiceOrder(dv);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
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
                              onTap: () {
                                _showLoginRequiredDialog();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Đăng nhập để đặt',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
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
            ],
          ),
        ),
      ),
    );
  }

// 🔥 Thêm hàm điều hướng đến màn hình đăng ký dịch vụ
  void _navigateToServiceOrder(DichVuModel dv) async {
    _showLoadingDialog(); // 🔥 Hiển thị loading

    try {
      final prefs = await SharedPreferences.getInstance();
      int maKH = prefs.getInt('user_maKH') ?? 0;

      if (maKH == 0) {
        _hideLoadingDialog();
        _showLoginRequiredDialog();
        return;
      }

      var response = await ApiService.get('khach-hang/$maKH/dat-phong');
      List allBookings = response['data'] ?? [];
      List currentBookings = allBookings.where((b) => b['TinhTrang'] == 2).toList();

      _hideLoadingDialog(); // 🔥 Đóng loading

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
      }

    } catch (e) {
      _hideLoadingDialog();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString().replaceFirst("Exception: ", "")}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// 🔥 Hiển thị dialog chọn phòng khi có nhiều phòng đang ở
  void _showRoomSelectionDialog(List<dynamic> currentBookings, DichVuModel dv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.meeting_room, color: Color(0xFFC97A3E)),
            SizedBox(width: 8),
            Text(
              'Chọn phòng đặt dịch vụ',
              style: TextStyle(color: Color(0xFF49120F), fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            // 🔥 Đếm tổng số phòng thay vì số booking
            itemCount: currentBookings.fold(0, (sum, b) => sum! + ((b['phongs'] as List?)?.length ?? 0)),
            itemBuilder: (context, index) {
              // Tìm booking và phòng tương ứng với index
              int count = 0;
              dynamic targetBooking;
              dynamic targetPhong;

              for (var booking in currentBookings) {
                var phongs = booking['phongs'] as List? ?? [];
                if (index < count + phongs.length) {
                  targetBooking = booking;
                  targetPhong = phongs[index - count];
                  break;
                }
                count += phongs.length;
              }

              if (targetBooking == null || targetPhong == null) {
                return const SizedBox.shrink();
              }

              int maDatPhong = targetBooking['MaDatPhong'];
              String soPhong = targetPhong['SoPhong']?.toString() ?? '';
              String tenLoaiPhong = targetPhong['TenLoaiPhong']?.toString() ?? '';
              String ngayNhan = _formatDate(targetBooking['NgayNhanPhong']);
              String ngayTra = _formatDate(targetBooking['NgayTraPhong']);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC97A3E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.meeting_room, color: Color(0xFFC97A3E), size: 22),
                  ),
                  title: Row(
                    children: [
                      Text(
                        'Phòng $soPhong',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF49120F)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8BE97).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '#$maDatPhong',
                          style: const TextStyle(fontSize: 10, color: Color(0xFFC97A3E), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    '$tenLoaiPhong • $ngayNhan → $ngayTra',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFC97A3E)),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServiceOrderDetailPage(
                          maDatPhong: maDatPhong,
                          soPhong: soPhong,
                          preSelectedService: dv,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng', style: TextStyle(color: Color(0xFFC97A3E))),
          ),
        ],
      ),
    );
  }

// 🔥 Thêm hàm lấy danh sách số phòng
  String _getSoPhongList(List<dynamic> phongs) {
    if (phongs.isEmpty) return 'Chưa có phòng';

    List<String> soPhongs = phongs.map((p) => p['SoPhong'].toString()).toList();

    if (soPhongs.length == 1) {
      return soPhongs.first;
    }

    return soPhongs.join(', ');
  }

// 🔥 Helper lấy số phòng
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

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yêu cầu đăng nhập'),
        content: const Text('Vui lòng đăng nhập!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Để sau',style: TextStyle(
              color: Color(0xFFC97A3E),
            ),),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SignInPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC97A3E),
            ),
            child: const Text('Đăng nhập',style: TextStyle(color: Color(0xFFFFFFFF),),),
          ),
        ],
      ),
    );
  }

  Color _getLoaiColor(int loai) {
    switch (loai) {
      case 1:
        return Colors.orange;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.green;
      default:
        return Colors.grey;
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

// Đóng loading dialog
  void _hideLoadingDialog() {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
  Widget buildAvatar(String name, {double radius = 18}) {
    String firstChar = name.isNotEmpty ? name[0].toUpperCase() : '?';

    List<List<Color>> gradients = [
      [const Color(0xFF49120F), const Color(0xFFC97A3E)],
      [const Color(0xFF6F1D01), const Color(0xFFE8BE97)],
      [const Color(0xFF854023), const Color(0xFFC97A3E)],
      [const Color(0xFF49120F), const Color(0xFF854023)],
      [const Color(0xFF6F1D01), const Color(0xFFC97A3E)],
      [const Color(0xFF854023), const Color(0xFFE8BE97)],
      [const Color(0xFF49120F), const Color(0xFF6F1D01)],
    ];

    int index = firstChar.codeUnitAt(0) % gradients.length;
    List<Color> gradColors = gradients[index];

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: gradColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradColors[0].withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          firstChar,
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.8,
            fontWeight: FontWeight.bold,
            shadows: const [
              Shadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _khuyenMaiCard(KhuyenMaiModel km) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Xử lý khi bấm vào card
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Phần trăm giảm
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
                // Đường kẻ đứt
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  child: CustomPaint(painter: DashedLinePainter()),
                ),
                // Thông tin
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          km.tenKM,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC97A3E).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_offer, size: 10, color: Color(0xFFC97A3E)),
                              const SizedBox(width: 4),
                              Text(
                                'Mã: ${km.maKM}',
                                style: const TextStyle(fontSize: 10, color: Color(0xFFC97A3E), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          km.expiryText,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: km.diem > 0 ? Colors.orange : Colors.red),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            km.tag,
                            style: TextStyle(color: km.diem > 0 ? Colors.orange : Colors.red, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 🔥 NÚT HÀNH ĐỘNG (ĐÃ SỬA)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: isLoggedIn
                      ? _buildActionButton(km) // 👈 Gọi hàm riêng
                      : Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: _showLoginRequiredDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "Đăng nhập",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// 🔥 Hàm tạo nút hành động dựa vào loại khuyến mãi
  Widget _buildActionButton(KhuyenMaiModel km) {
    // Nếu mã cần điểm -> Hiển thị nút "Đổi bằng điểm"
    if (km.diem > 0) {
      return _buildDoiDiemButton(km);
    }

    // Nếu mã miễn phí -> Hiển thị nút "Sao chép mã"
    return _buildCopyButton(km);
  }

// 🔥 Nút "Đổi bằng điểm"
  Widget _buildDoiDiemButton(KhuyenMaiModel km) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _showDoiDiemDialog(km),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF49120F), Color(0xFFC97A3E)],
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars, color: Colors.amber, size: 14),
              const SizedBox(width: 4),
              Text(
                '${km.diem} điểm',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// 🔥 Nút "Sao chép mã"
  Widget _buildCopyButton(KhuyenMaiModel km) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _showCopyCodeDialog(km.maKM),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFC97A3E),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            "Sao chép mã",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

// 🔥 Dialog xác nhận đổi điểm
  void _showDoiDiemDialog(KhuyenMaiModel km) async {
    final prefs = await SharedPreferences.getInstance();
    int maKH = prefs.getInt('user_maKH') ?? 0;

    if (maKH == 0) {
      _showLoginRequiredDialog();
      return;
    }

    // 🔥 Hiển thị loading trước khi kiểm tra
    _showLoadingDialog();

    // Kiểm tra điểm
    final kiemTra = await KhuyenMaiService.kiemTraDiem(maKH, km.maKM);
    int diemHienTai = kiemTra['diemHienTai'] ?? 0;
    bool duDiem = kiemTra['duDiem'] ?? false;

    // 🔥 Đóng loading
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
                  Text('${diemHienTai - km.diem} điểm', style: const TextStyle(color: Color(0xFF49120F), fontWeight: FontWeight.bold)),
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
                    Text(
                      'Thiếu ${km.diem - diemHienTai} điểm',
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Để sau', style: TextStyle(color: Color(0xFFC97A3E),))
          ),
          if (duDiem)
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx); // Đóng dialog xác nhận

                // 🔥 Hiển thị loading
                _showLoadingDialog();

                // Gọi API đổi điểm
                final result = await KhuyenMaiService.doiBangDiem(maKH, km.maKM);
                print('🟢 [ĐỔI ĐIỂM] Kết quả API: $result');

                // 🔥 Đóng loading
                _hideLoadingDialog();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? ''),
                      backgroundColor: result['success'] == true ? Color(0xFFC97A3E) : Color(0xFF49120F),
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

// 🔥 Thêm hàm sao chép mã khuyến mãi
  void _showCopyCodeDialog(String? maKhuyenMai) {
    if (maKhuyenMai == null || maKhuyenMai.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không có mã khuyến mãi'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 🔥 Hiển thị loading ngắn
    _showLoadingDialog();

    // Giả lập delay nhỏ để thấy loading
    Future.delayed(const Duration(milliseconds: 300), () {
      _hideLoadingDialog();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFFC97A3E), size: 24),
              SizedBox(width: 8),
              Text('Mã khuyến mãi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_offer, size: 50, color: Color(0xFFC97A3E)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8BE97).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFC97A3E)),
                ),
                child: SelectableText(
                  maKhuyenMai,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF49120F),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sao chép mã và sử dụng khi thanh toán',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng', style: TextStyle(color: Color(0xFF000000))),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: maKhuyenMai));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã sao chép mã khuyến mãi'),
                    backgroundColor: Color(0xFFC97A3E),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Sao chép'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC97A3E),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    });
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