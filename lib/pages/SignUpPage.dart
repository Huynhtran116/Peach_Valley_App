import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart'; // ← Thêm import

import 'HomePage.dart';
import 'SignInPage.dart';
import 'RegisterDetailPage.dart';

class SignUpPage extends StatefulWidget { // ← Đổi StatefulWidget
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool isLoading = false;

  // Gọi API Register Step 1
  Future<void> dangKyBuoc1() async {
    // Kiểm tra rỗng
    if (emailController.text.trim().isEmpty) {
      _showError('Vui lòng nhập email.');
      return;
    }
    if (passwordController.text.isEmpty) {
      _showError('Vui lòng nhập mật khẩu.');
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      _showError('Mật khẩu xác nhận không khớp.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      var response = await ApiService.post('mobile/register/step1', {
        'email': emailController.text.trim(),
        'password': passwordController.text,
        'password_confirmation': confirmPasswordController.text,
      });

      print('✅ Bước 1 thành công: ${response['message']}');

      // Chuyển sang trang RegisterDetailPage
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RegisterDetailPage(
              email: emailController.text.trim(),
              password: passwordController.text,
            ),
          ),
        );
      }

    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffffffff),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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

                  const Center(
                    child: Text(
                      "Tạo tài khoản mới",
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF49120F),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Input Email
                  _buildInput("Email", Icons.email, controller: emailController),

                  // Input Mật khẩu
                  _buildInput("Mật khẩu", Icons.lock,
                      isPassword: true, controller: passwordController),

                  // Input Xác nhận mật khẩu
                  _buildInput("Xác nhận mật khẩu", Icons.lock,
                      isPassword: true, controller: confirmPasswordController),

                  const SizedBox(height: 30),

                  // Nút Đăng ký
                  GestureDetector(
                    onTap: isLoading ? null : dangKyBuoc1, // ← Gọi API
                    child: Container(
                      height: 55,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF6F1D01),
                            Color(0xFFC97A3E),
                          ],
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
                          "Đăng ký",
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
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          "hoặc đăng ký với",
                          style: TextStyle(color: Color(0xFF49120F)),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: Color(0xFF49120F).withOpacity(0.2)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child: _socialButton(() {
                      print("Google Sign up 🔥");
                    }),
                  ),

                  const SizedBox(height: 30),

                  Center(
                    child: RichText(
                      text: TextSpan(
                        text: "Bạn đã có tài khoản ",
                        style: const TextStyle(color: Color(0xFF49120F)),
                        children: [
                          TextSpan(
                            text: "Đăng nhập",
                            style: const TextStyle(
                              color: Color(0xFFC97A3E),
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SignInPage(),
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

  Widget _buildInput(String hint, IconData icon,
      {bool isPassword = false, TextEditingController? controller}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextField(
        controller: controller, // ← Thêm controller
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
            borderSide: const BorderSide(
              color: Color(0xFFC97A3E),
              width: 1,
            ),
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