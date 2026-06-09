import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'ForgotPasswordPage.dart';
import 'HomePage.dart';
import 'SignUpPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> dangNhap() async {
    if (emailController.text.trim().isEmpty || passwordController.text.isEmpty) {
      _showPopup(
        title: "Lỗi",
        message: "Vui lòng nhập email và mật khẩu.",
        isSuccess: false,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      var response = await ApiService.post('mobile/login', {
        'email': emailController.text.trim(),
        'password': passwordController.text,
      });

      print('📥 Response đăng nhập: $response');

      // 🔥 Kiểm tra theo cấu trúc response từ backend
      if (response['status'] != 'success') {
        throw Exception(response['message'] ?? 'Đăng nhập thất bại');
      }

      // Lấy token và user data
      String token = response['token'];
      var user = response['user'];

      if (token.isEmpty) {
        throw Exception('Token không hợp lệ');
      }

      // Lưu token vào ApiService
      await ApiService.setToken(token);

      // Lưu thông tin user vào SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_token', token);
      await prefs.setInt('user_maKH', user['MaKH'] ?? 0);
      await prefs.setString('user_name', user['Ten'] ?? '');
      await prefs.setString('user_email', user['Email'] ?? '');
      await prefs.setInt('user_maTK', user['MaTK'] ?? 0);
      await prefs.setInt('user_loai', user['LoaiTaiKhoan'] ?? 0);
      await prefs.setInt('user_diem', user['DiemTichLuy'] ?? 0);

      print('✅ Đã lưu thông tin:');
      print('   - Token: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      print('   - MaKH: ${user['MaKH']}');
      print('   - Tên: ${user['Ten']}');
      print('   - Email: ${user['Email']}');

      // Hiển thị thông báo thành công
      _showPopup(
        title: "Thành công",
        message: "Đăng nhập thành công!\nXin chào ${user['Ten'] ?? ''}",
        isSuccess: true,
      );

    } catch (e) {
      print('❌ Lỗi đăng nhập: $e');
      _showPopup(
        title: "Lỗi đăng nhập",
        message: e.toString().replaceAll('Exception: ', ''),
        isSuccess: false,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
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
              color: isSuccess ? Color(0xFFC97A3E) : const Color(0xFFC97A3E),
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF49120F),
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
              Navigator.of(context).pop();
              if (isSuccess) {
                // 🔥 Chuyển về HomePage
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
                );
              }
            },
            child: const Text(
              "OK",
              style: TextStyle(
                color: Color(0xFFC97A3E),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  const Center(
                    child: Text(
                      "Xin chào",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF49120F),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildInput("Email", Icons.email, controller: emailController),
                  _buildInput("Password", Icons.lock, isPassword: true, controller: passwordController),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                        );
                      },
                      child: const Text(
                        "Quên mật khẩu?",
                        style: TextStyle(
                          color: Color(0xFFC97A3E), // 👈 Đổi màu cam cho nổi bật
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: isLoading ? null : dangNhap,
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
                            offset: Offset(0, 5),
                          )
                        ],
                      ),
                      child: Center(
                        child: isLoading
                            ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text(
                          "Đăng nhập",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: Color(0xFF49120F).withOpacity(0.2)),
                      ),
                      Expanded(
                        child: Divider(color: Color(0xFF49120F).withOpacity(0.2)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: RichText(
                      text: TextSpan(
                        text: "Bạn không có tài khoản ? ",
                        style: const TextStyle(color: Color(0xFF49120F)),
                        children: [
                          TextSpan(
                            text: "Đăng ký",
                            style: const TextStyle(
                              color: Color(0xFFC97A3E),
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SignUpPage(),
                                  ),
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
      String hint,
      IconData icon, {
        bool isPassword = false,
        TextEditingController? controller,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Color(0xFF49120F)),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF49120F)),
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF49120F)),
          filled: true,
          fillColor: const Color(0xFF6F1D01).withOpacity(0.1),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFC97A3E), width: 1),
          ),
        ),
      ),
    );
  }

  Widget _socialButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 55,
        width: 200,
        decoration: BoxDecoration(
          color: const Color(0xFF6F1D01).withOpacity(0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFC97A3E)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.g_mobiledata, color: Color(0xFF49120F), size: 28),
            SizedBox(width: 10),
            Text("Google", style: TextStyle(color: Color(0xFF49120F))),
          ],
        ),
      ),
    );
  }
}