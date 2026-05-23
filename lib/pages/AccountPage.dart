import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'BookingHistoryPage.dart';
import 'ChangePasswordPage.dart';
import 'HomePage.dart';
import 'KhoKhuyenMaiPage.dart';
import 'PersonalDataPage.dart';
import 'SignInPage.dart';

class AccountPage extends StatefulWidget {
  final VoidCallback? onLogout;

  const AccountPage({super.key, this.onLogout});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String userName = 'Khách';
  String userEmail = '';
  int userDiem = 0;
  String userPhone = '';
  String userAddress = '';
  String userCCCD = '';
  String userBirthday = '';
  int userGender = 2;
  bool isLoading = true;
  bool isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    loadUserInfo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadUserInfo();
  }

  // Trong AccountPage, sửa lại hàm loadUserInfo để log dữ liệu nhận được
  Future<void> loadUserInfo() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('user_token');
    int? maKH = prefs.getInt('user_maKH');

    bool isLoggedIn = token != null && token.isNotEmpty && maKH != null && maKH > 0;

    print('🔍 AccountPage - Đã đăng nhập: $isLoggedIn, MaKH: $maKH');

    if (isLoggedIn) {
      try {
        var userResponse = await ApiService.get('mobile/user-profile');
        print('📥 Response user profile: $userResponse');

        if (userResponse['status'] == 'success' && userResponse['data'] != null) {
          var userData = userResponse['data'];
          print('📥 Dữ liệu chi tiết:');
          print('   - Ten: ${userData['Ten']}');
          print('   - Email: ${userData['Email']}');
          print('   - SoDienThoai: ${userData['SoDienThoai']}');
          print('   - DiaChi: ${userData['DiaChi']}');
          print('   - CCCD: ${userData['CCCD']}');
          print('   - NgaySinh: ${userData['NgaySinh']}');
          print('   - GioiTinh: ${userData['GioiTinh']}');
          print('   - DiemTichLuy: ${userData['DiemTichLuy']}');

          setState(() {
            userName = userData['Ten'] ?? 'Khách';
            userEmail = userData['Email'] ?? '';
            userDiem = userData['DiemTichLuy'] ?? 0;
            userPhone = userData['SoDienThoai'] ?? '';
            userAddress = userData['DiaChi'] ?? '';
            userCCCD = userData['CCCD'] ?? '';
            userBirthday = userData['NgaySinh'] ?? '';
            userGender = userData['GioiTinh'] ?? 2;
          });
        } else {
          throw Exception('Không thể lấy thông tin user');
        }
      } catch (e) {
        print('❌ Lỗi lấy thông tin user: $e');
        // Fallback: lấy từ SharedPreferences nếu API lỗi
        setState(() {
          userName = prefs.getString('user_name') ?? 'Khách';
          userEmail = prefs.getString('user_email') ?? '';
          userDiem = prefs.getInt('user_diem') ?? 0;
        });
      }
    } else {
      setState(() {
        userName = 'Khách';
        userEmail = '';
        userPhone = '';
        userAddress = '';
        userCCCD = '';
        userBirthday = '';
        userGender = 2;
        userDiem = 0;
      });
    }

    setState(() => isLoading = false);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      DateTime d = DateTime.parse(dateStr);
      return "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
    } catch (e) {
      return dateStr;
    }
  }

  String _getGenderText(int gender) {
    switch (gender) {
      case 0: return 'Nữ';
      case 1: return 'Nam';
      case 2: return 'Khác';
      default: return 'Không xác định';
    }
  }

  Future<void> dangXuat() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 40,
                width: 40,
                child: CircularProgressIndicator(
                  color: Color(0xFFC97A3E),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Đang đăng xuất...",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF49120F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Vui lòng chờ trong giây lát",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    setState(() => isLoggingOut = true);

    try {
      await ApiService.post('mobile/logout', {});
    } catch (e) {
      print('Lỗi logout API: $e');
    }

    await ApiService.removeToken();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_maTK');
    await prefs.remove('user_maKH');
    await prefs.remove('user_loai');
    await prefs.remove('user_diem');
    await prefs.remove('user_token');
    await prefs.remove('user_phone');

    if (mounted) {
      Navigator.of(context).pop();
    }

    if (widget.onLogout != null && mounted) {
      widget.onLogout!();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đã đăng xuất thành công"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: RefreshIndicator(
        onRefresh: loadUserInfo,
        color: const Color(0xFFC97A3E),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              /// HEADER
              Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF49120F),
                        Color(0xFFC97A3E),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: isLoading
                      ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  )
                      : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      buildAvatar(userName, radius: 30),
                      const SizedBox(height: 15),
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (userEmail.isNotEmpty)
                        Text(
                          userEmail,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.star, color: Colors.white, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  "Điểm tích lũy",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                            Text(
                              "$userDiem Điểm",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// MENU
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _menuItem(
                      icon: Icons.account_circle_outlined,
                      title: "Thông tin cá nhân",
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PersonalDataPage(
                              userData: {
                                'TenKH': userName,
                                'Email': userEmail,
                                'SoDienThoai': userPhone,
                                'DiaChi': userAddress,
                                'CCCD': userCCCD,
                                'NgaySinh': userBirthday,
                                'GioiTinh': userGender,
                              },
                            ),
                          ),
                        );
                        if (result == true) {
                          loadUserInfo();
                        }
                      },
                    ),
                    _menuItem(
                      icon: Icons.history,
                      title: "Lịch sử đặt phòng",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BookingHistoryPage(),
                          ),
                        );
                      },
                    ),
                    _menuItem(
                      icon: Icons.home_filled,
                      title: "Kho khuyến mãi",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const KhoKhuyenMaiPage()),
                        );
                      },
                    ),
                    _menuItem(
                      icon: Icons.settings,
                      title: "Cài đặt",
                      onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordPage())

                        );
                      },
                    ),
                    const Divider(height: 30),
                    _menuItem(
                      icon: Icons.logout,
                      title: "Đăng xuất",
                      color: Colors.red,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text("Đăng xuất"),
                            content: const Text("Bạn có chắc muốn đăng xuất?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  "Hủy",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  dangXuat();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text("Đăng xuất"),
                              ),
                            ],
                          ),
                        );
                      },
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

  Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.black.withOpacity(0.04),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color ?? const Color(0xFFC97A3E)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 14, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildAvatar(String name, {double radius = 30}) {
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
            color: gradColors[0].withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Center(
        child: Text(
          firstChar,
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.85,
            fontWeight: FontWeight.bold,
            shadows: const [
              Shadow(
                color: Colors.black38,
                blurRadius: 6,
                offset: Offset(1, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}