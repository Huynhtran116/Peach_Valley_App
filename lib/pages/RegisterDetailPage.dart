import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'HomePage.dart';

class RegisterDetailPage extends StatefulWidget {
  final String email;
  final String password;

  const RegisterDetailPage({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  _RegisterDetailPageState createState() => _RegisterDetailPageState();
}

class _RegisterDetailPageState extends State<RegisterDetailPage> {
  final TextEditingController name = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController cccd = TextEditingController();
  final TextEditingController dob = TextEditingController();
  final TextEditingController address = TextEditingController();

  String? gender;
  String? selectedProvince;
  String? selectedDistrict;

  List<Map<String, String>> provinces = [];
  List<Map<String, String>> districts = [];
  bool isLoadingPage = true; // ← Loading full trang
  bool isLoadingDistricts = false;
  bool isSubmitting = false;

  Color primary = const Color(0xFF49120F);
  Color accent = const Color(0xFFC97A3E);
  Color bgInput = const Color(0xFF6F1D01).withOpacity(0.1);

  @override
  void initState() {
    super.initState();
    fetchProvinces();
  }

  // Lấy danh sách tỉnh
  Future<void> fetchProvinces() async {
    try {
      var response = await ApiService.get('mobile/provinces');
      List data = response['data'] ?? [];
      setState(() {
        provinces = data
            .map((e) => {
          'code': e['code'].toString(),
          'name': e['name'].toString(),
        })
            .toList();
        isLoadingPage = false; // ← Tắt loading
      });
    } catch (e) {
      setState(() => isLoadingPage = false);
      _showPopup(
        title: "Lỗi",
        message: 'Không thể tải danh sách tỉnh/thành phố',
        isSuccess: false,
      );
    }
  }

  // Lấy danh sách quận/huyện
  // Lấy danh sách quận/huyện
  Future<void> fetchDistricts(String provinceCode) async {
    setState(() {
      isLoadingDistricts = true;
      selectedDistrict = null;
    });

    try {
      var response = await ApiService.get('mobile/districts/$provinceCode');

      // ✅ SỬA: API trả về key "data"
      List data = response['data'] ?? [];

      print('📡 Số quận/huyện: ${data.length}');

      setState(() {
        districts = data
            .map((e) => {
          'code': e['code'].toString(),
          'name': e['name'].toString(),
        })
            .toList();
        isLoadingDistricts = false;
      });
    } catch (e) {
      setState(() => isLoadingDistricts = false);
      _showPopup(
        title: "Lỗi",
        message: 'Không thể tải danh sách quận/huyện',
        isSuccess: false,
      );
    }
  }


  // Gọi API Register Step 2
  // Gọi API Register Step 2
  Future<void> hoanTatDangKy() async {
    // Validate form
    if (name.text.trim().isEmpty) {
      _showPopup(title: "Lỗi", message: "Vui lòng nhập họ và tên", isSuccess: false);
      return;
    }
    if (phone.text.trim().isEmpty) {
      _showPopup(title: "Lỗi", message: "Vui lòng nhập số điện thoại", isSuccess: false);
      return;
    }
    if (cccd.text.trim().isEmpty) {
      _showPopup(title: "Lỗi", message: "Vui lòng nhập CCCD", isSuccess: false);
      return;
    }
    if (dob.text.trim().isEmpty) {
      _showPopup(title: "Lỗi", message: "Vui lòng chọn ngày sinh", isSuccess: false);
      return;
    }
    if (gender == null) {
      _showPopup(title: "Lỗi", message: "Vui lòng chọn giới tính", isSuccess: false);
      return;
    }

    setState(() => isSubmitting = true);

    try {
      List<String> dateParts = dob.text.split('/');
      String formattedDate =
          '${dateParts[2]}-${dateParts[1].padLeft(2, '0')}-${dateParts[0].padLeft(2, '0')}';

      String fullAddress = address.text.trim();
      if (selectedDistrict != null) {
        String districtName =
            districts.firstWhere((d) => d['code'] == selectedDistrict)['name'] ?? '';
        fullAddress += fullAddress.isEmpty ? districtName : ', $districtName';
      }
      if (selectedProvince != null) {
        String provinceName =
            provinces.firstWhere((p) => p['code'] == selectedProvince)['name'] ?? '';
        fullAddress += fullAddress.isEmpty ? provinceName : ', $provinceName';
      }

      // Xác định giá trị gender (0: Nam, 1: Nữ)
      int genderValue = gender == 'Nam' ? 0 : 1;

      var response = await ApiService.post('mobile/register/step2', {
        'email': widget.email,
        'password': widget.password,
        'full_name': name.text.trim(),
        'gender': genderValue,
        'phone': phone.text.trim(),
        'cccd': cccd.text.trim(),
        'birthday': formattedDate,
        'address': fullAddress,
      });

      print('📥 Response đăng ký bước 2: $response');

      // Kiểm tra response
      if (response['status'] != 'success') {
        throw Exception(response['message'] ?? 'Đăng ký thất bại');
      }

      // Lấy token
      String? token = response['token'];
      if (token == null || token.isEmpty) {
        throw Exception('Không nhận được token từ server');
      }

      // Lưu token
      await ApiService.setToken(token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_token', token);
      await prefs.setString('user_email', widget.email);
      await prefs.setString('user_name', name.text.trim());
      await prefs.setString('user_phone', phone.text.trim());

      // 🔥 GỌI API LẤY THÔNG TIN USER ĐỂ CÓ MaKH
      try {
        print('📥 Đang lấy thông tin user profile...');
        var userResponse = await ApiService.getUserProfile();
        print('📥 User profile response: $userResponse');

        if (userResponse['status'] == 'success' && userResponse['data'] != null) {
          var userData = userResponse['data'];
          await prefs.setInt('user_maKH', userData['MaKH'] ?? 0);
          await prefs.setInt('user_maTK', userData['MaTK'] ?? 0);
          await prefs.setInt('user_diem', userData['DiemTichLuy'] ?? 0);
          await prefs.setString('user_name', userData['Ten'] ?? name.text.trim());
          await prefs.setString('user_email', userData['Email'] ?? widget.email);

          print('✅ Đã lấy thông tin user:');
          print('   - MaKH: ${userData['MaKH']}');
          print('   - MaTK: ${userData['MaTK']}');
          print('   - Tên: ${userData['Ten']}');
          print('   - Điểm: ${userData['DiemTichLuy']}');
        } else {
          print('⚠️ Không lấy được thông tin user profile');
        }
      } catch (e) {
        print('⚠️ Lỗi khi lấy user profile: $e');
        // Vẫn tiếp tục dù lỗi
      }

      print('✅ Đã lưu thông tin đăng ký thành công');

      _showPopup(
        title: "Thành công",
        message: "Đăng ký tài khoản thành công!\nXin chào ${name.text.trim()}",
        isSuccess: true,
      );
    } catch (e) {
      print('❌ Lỗi đăng ký: $e');
      _showPopup(
        title: "Lỗi đăng ký",
        message: e.toString().replaceAll('Exception: ', ''),
        isSuccess: false,
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  void _showPopup({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Color(0xFFC97A3E) : Color(0xFF49120F),
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Đóng popup
              if (isSuccess) {
                // Chuyển trang Home
                Navigator.pushAndRemoveUntil(
                  this.context,
                  MaterialPageRoute(builder: (_) => HomePage()),
                      (route) => false,
                );
              }
            },
            child: Text(
              "OK",
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration inputStyle(String hint, {IconData? icon}) {
    return InputDecoration(
      prefixIcon: icon != null ? Icon(icon, color: primary) : null,
      hintText: hint,
      hintStyle: TextStyle(color: primary),
      filled: true,
      fillColor: bgInput,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: accent),
      ),
    );
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('vi'),
    );

    if (picked != null) {
      setState(() {
        // Hiển thị: dd/MM/yyyy
        dob.text =
        "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    cccd.dispose();
    dob.dispose();
    address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // NẾU ĐANG LOAD TRANG → HIỆN LOADING FULL MÀN HÌNH
    if (isLoadingPage) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFFC97A3E),
                strokeWidth: 3,
              ),
              SizedBox(height: 20),
              Text(
                "Đang tải dữ liệu...",
                style: TextStyle(
                  color: Color(0xFF49120F),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ĐÃ LOAD XONG → HIỆN FORM
    return Scaffold(
      backgroundColor: const Color(0xffffffff),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 15),
              Center(
                child: Image.asset(
                  'assets/logo.png',
                  height: 90,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "Hoàn tất thông tin đăng ký",
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF49120F),
                ),
              ),
              const SizedBox(height: 40),

              // Họ và tên
              TextField(
                controller: name,
                style: TextStyle(color: primary),
                decoration: inputStyle("Họ và tên", icon: Icons.person),
              ),
              const SizedBox(height: 16),

              // SĐT + Giới tính
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: primary),
                      decoration:
                      inputStyle("Số điện thoại", icon: Icons.phone),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: gender,
                      dropdownColor: Colors.white,
                      items: ["Nam", "Nữ"]
                          .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e,
                            style: TextStyle(color: primary)),
                      ))
                          .toList(),
                      onChanged: (v) => setState(() => gender = v),
                      decoration: inputStyle("Giới tính"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // CCCD
              TextField(
                controller: cccd,
                keyboardType: TextInputType.number,
                style: TextStyle(color: primary),
                decoration: inputStyle("CCCD", icon: Icons.credit_card),
              ),
              const SizedBox(height: 16),

              // Ngày sinh
              TextField(
                controller: dob,
                readOnly: true,
                onTap: pickDate,
                style: TextStyle(color: primary),
                decoration:
                inputStyle("Ngày sinh", icon: Icons.calendar_today),
              ),
              const SizedBox(height: 16),

              // Tỉnh/Thành phố
              DropdownButtonFormField<String>(
                value: selectedProvince,
                dropdownColor: Colors.white,
                items: provinces
                    .map((e) => DropdownMenuItem(
                  value: e['code'],
                  child: Text(e['name']!,
                      style: TextStyle(color: primary)),
                ))
                    .toList(),
                onChanged: (v) {
                  setState(() => selectedProvince = v);
                  if (v != null) fetchDistricts(v);
                },
                decoration: inputStyle("Tỉnh/Thành phố"),
              ),
              const SizedBox(height: 16),

              // Quận/Huyện
              isLoadingDistricts
                  ? Container(
                height: 55,
                decoration: BoxDecoration(
                  color: bgInput,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFC97A3E),
                    ),
                  ),
                ),
              )
                  : DropdownButtonFormField<String>(
                value: selectedDistrict,
                dropdownColor: Colors.white,
                items: districts
                    .map((e) => DropdownMenuItem(
                  value: e['code'],
                  child: Text(e['name']!,
                      style: TextStyle(color: primary)),
                ))
                    .toList(),
                onChanged: (v) => setState(() => selectedDistrict = v),
                decoration: inputStyle("Quận/Huyện"),
              ),
              const SizedBox(height: 16),

              // Địa chỉ
              TextField(
                controller: address,
                style: TextStyle(color: primary),
                decoration:
                inputStyle("Số nhà và tên đường", icon: Icons.home),
              ),
              const SizedBox(height: 30),

              // Nút Hoàn tất
              GestureDetector(
                onTap: isSubmitting ? null : hoanTatDangKy,
                child: Container(
                  height: 55,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6F1D01), Color(0xFFC97A3E)],
                    ),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black54,
                          blurRadius: 12,
                          offset: Offset(0, 5))
                    ],
                  ),
                  child: Center(
                    child: isSubmitting
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text(
                      "Hoàn tất đăng ký",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
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
}