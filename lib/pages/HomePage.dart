import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/loai_phong.dart';
import 'AllocationPage.dart';
import 'BookingPage.dart';
import 'DetailRoomPage.dart';
import 'AccountPage.dart';
import 'DetailSerVicePage.dart';
import 'PromotionPage.dart';
import 'RoomListPage.dart';
import 'SearchPage.dart';
import '../services/api_service.dart';
import '../models/dich_vu.dart';
import '../models/khuyen_mai.dart';
import 'ServiceListPage.dart';
import 'SignInPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

  @override
  void initState() {
    super.initState();
    _checkAndFixData(); // Thêm hàm kiểm tra dữ liệu lỗi
    loadUserInfo();
    fetchLoaiPhong();
    fetchDichVu();
    fetchKhuyenMai();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load lại mỗi khi quay lại (quan trọng!)
    loadUserInfo();
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
      List data = response['data'] ?? [];
      setState(() {
        danhSachPhong = data
            .map((e) => LoaiPhong.fromJson(e))
            .take(3)
            .toList();
        isLoadingRooms = false;
      });
    } catch (e) {
      print('Lỗi load phòng: $e');
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

      print('📥 Response khuyến mãi: $response');

      // Xử lý response linh hoạt
      List data = [];
      if (response is List) {
        data = response;
      } else if (response['data'] is List) {
        data = response['data'];
      } else {
        data = [];
      }

      print('📊 Số khuyến mãi nhận được: ${data.length}');

      // 🔥 Parse từng item
      List<KhuyenMaiModel> tempList = [];
      for (var item in data) {
        try {
          final km = KhuyenMaiModel.fromJson(item);
          // Chỉ hiển thị khuyến mãi còn hạn
          if (km.conHan) {
            tempList.add(km);
            print('✅ ${km.tenKM} - ${km.discountText} - ${km.expiryText}');
          } else {
            print('⏰ Bỏ qua khuyến mãi hết hạn: ${km.tenKM}');
          }
        } catch (e) {
          print('❌ Lỗi parse item: $e');
          print('Item: $item');
        }
      }

      setState(() {
        danhSachKhuyenMai = tempList;
        isLoadingPromos = false;
      });

      print('✅ Đã tải ${danhSachKhuyenMai.length} khuyến mãi đang diễn ra');

    } catch (e) {
      print('❌ Lỗi load khuyến mãi: $e');
      setState(() {
        danhSachKhuyenMai = [];
        isLoadingPromos = false;
      });
    }
  }

  // Logout
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_token');
    await prefs.remove('user_maKH');
    await prefs.remove('user_name');
    await prefs.remove('user_email');

    setState(() {
      isLoggedIn = false;
      userName = 'Khách';
      userEmail = '';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã đăng xuất thành công'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Các màn hình
  List<Widget> _pages() => [
    _homeContent(),
    const DatePickerPage(),
    _getMessagesPage(), // Màn hình Message (tùy theo login)
    _getAccountPage(), // Màn hình Account (tùy theo login)
  ];

  // Màn hình Message - yêu cầu login nếu chưa đăng nhập
  Widget _getMessagesPage() {
    if (!isLoggedIn) {
      return _buildLoginRequiredPage(
        icon: Icons.message,
        title: 'Tin nhắn',
        message: 'Đăng nhập để xem tin nhắn và thông báo từ khách sạn',
      );
    }
    return const Center(child: Text("Message Page - Đã đăng nhập"));
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
    double t = double.tryParse(amount?.toString() ?? '0') ?? 0;
    return t.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
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
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: "Booking",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: "Message",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Account",
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
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.notifications,
                                  color: Colors.white),
                            ),
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
                                "Bạn muốn tìm phòng",
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RoomDetailPage(
              loaiPhong: room,
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
                  Text(
                    '${room.soPhongTrong} phòng trống',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_formatVND(room.giaThapNhat)} VND /đêm',
                        style: const TextStyle(
                          color: Color(0xFFC97A3E),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RoomDetailPage(loaiPhong: room),
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
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
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
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _serviceCardAPI(DichVuModel dv) {
    return GestureDetector(
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
                      // 🔥 HIỂN THỊ NÚT KHÁC NHAU DỰA TRÊN TRẠNG THÁI ĐĂNG NHẬP
                      if (isLoggedIn)
                        GestureDetector(
                          onTap: () {
                            print('Đặt dịch vụ: ${dv.tenDV}');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã đặt dịch vụ thành công!'),
                                backgroundColor: Colors.green,
                              ),
                            );
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
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
              color: Color(0xFF000000),
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
    return Container(
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
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: CustomPaint(painter: DashedLinePainter()),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(km.tenKM,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(km.expiryText,
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        km.tag,
                        style: const TextStyle(color: Colors.red, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 🔥 HIỂN THỊ NÚT KHÁC NHAU DỰA TRÊN TRẠNG THÁI ĐĂNG NHẬP
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: isLoggedIn
                  ? GestureDetector(
                onTap: () {
                  // TODO: Xử lý lưu khuyến mãi
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã lưu khuyến mãi: ${km.tenKM}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  : GestureDetector(
                onTap: () {
                  _showLoginRequiredDialog();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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