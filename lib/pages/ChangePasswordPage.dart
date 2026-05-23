// pages/ChangePasswordPage.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _doiMatKhau() async {
    final oldPwd = _oldPasswordController.text.trim();
    final newPwd = _newPasswordController.text.trim();
    final confirmPwd = _confirmPasswordController.text.trim();

    if (oldPwd.isEmpty) {
      _showSnack('Vui lòng nhập mật khẩu cũ', true);
      return;
    }
    if (newPwd.isEmpty || newPwd.length < 8) {
      _showSnack('Mật khẩu mới phải có ít nhất 8 ký tự', true);
      return;
    }
    if (newPwd != confirmPwd) {
      _showSnack('Mật khẩu xác nhận không khớp', true);
      return;
    }
    if (oldPwd == newPwd) {
      _showSnack('Mật khẩu mới không được trùng mật khẩu cũ', true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.post('doi-mat-khau', {
        'old_password': oldPwd,
        'new_password': newPwd,
        'new_password_confirmation': confirmPwd,
      });

      if (mounted) {
        _showSnack(response['message'] ?? 'Đổi mật khẩu thành công!', false);
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context, true);
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnack(e.toString().replaceFirst('Exception: ', ''), true);
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnack(String msg, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Đổi mật khẩu',
            style: TextStyle(color: Color(0xFF49120F), fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFF49120F)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFC97A3E).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline, size: 40, color: Color(0xFFC97A3E)),
            ),
            const SizedBox(height: 24),
            const Text('Đổi mật khẩu',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF49120F))),
            const SizedBox(height: 8),
            const Text('Mật khẩu mới phải có ít nhất 8 ký tự',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 32),

            // Mật khẩu cũ
            _buildTextField(_oldPasswordController, 'Mật khẩu cũ', _obscureOld,
                    () => setState(() => _obscureOld = !_obscureOld)),
            const SizedBox(height: 16),
            // Mật khẩu mới
            _buildTextField(_newPasswordController, 'Mật khẩu mới', _obscureNew,
                    () => setState(() => _obscureNew = !_obscureNew)),
            const SizedBox(height: 16),
            // Xác nhận
            _buildTextField(_confirmPasswordController, 'Xác nhận mật khẩu', _obscureConfirm,
                    () => setState(() => _obscureConfirm = !_obscureConfirm)),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _doiMatKhau,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC97A3E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Đổi mật khẩu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, bool obscure, VoidCallback toggle) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFC97A3E)),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
            onPressed: toggle,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}