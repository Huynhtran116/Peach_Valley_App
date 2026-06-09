// pages/ForgotPasswordPage.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  int _step = 1;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ========== STEP 1: GỬI OTP ==========
  Future<void> _sendOTP() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      _showSnack('Vui lòng nhập số điện thoại hợp lệ', true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.post('quen-mat-khau/gui-otp', {'phone': phone});
      if (mounted) {
        setState(() { _step = 2; _isLoading = false; });
        _showSnack('Mã OTP đã gửi đến $phone', false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack(e.toString().replaceFirst('Exception: ', ''), true);
    }
  }

  // ========== STEP 2: XÁC NHẬN OTP ==========
  Future<void> _verifyOTP() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length != 6) {
      _showSnack('Vui lòng nhập mã OTP 6 số', true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.post('quen-mat-khau/xac-nhan-otp', {
        'phone': _phoneController.text.trim(),
        'otp': otp,
      });
      if (mounted) {
        setState(() { _step = 3; _isLoading = false; });
        _showSnack('Xác nhận thành công', false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack(e.toString().replaceFirst('Exception: ', ''), true);
    }
  }

  // ========== STEP 3: ĐẶT LẠI MẬT KHẨU ==========
  Future<void> _resetPassword() async {
    final newPwd = _newPasswordController.text.trim();
    final confirmPwd = _confirmPasswordController.text.trim();

    if (newPwd.isEmpty) { _showSnack('Vui lòng nhập mật khẩu mới', true); return; }
    if (newPwd.length < 8) { _showSnack('Mật khẩu phải có ít nhất 8 ký tự', true); return; }
    if (newPwd != confirmPwd) { _showSnack('Mật khẩu xác nhận không khớp', true); return; }

    setState(() => _isLoading = true);
    try {
      await ApiService.post('quen-mat-khau/dat-lai-mat-khau', {
        'phone': _phoneController.text.trim(),
        'otp': _otpController.text.trim(),
        'password': newPwd,
        'password_confirmation': confirmPwd,
      });
      if (mounted) {
        _showSnack('Đổi mật khẩu thành công!', false);
        Future.delayed(const Duration(seconds: 2), () => Navigator.pop(context, true));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack(e.toString().replaceFirst('Exception: ', ''), true);
    }
  }

  void _showSnack(String msg, bool isError) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Color(0xFF49120F) : Color(0xFFC97A3E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ========== UI ==========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Quên mật khẩu', style: TextStyle(color: Color(0xFF49120F), fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFF49120F)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildStepIndicator(),
            const SizedBox(height: 32),
            _buildIcon(),
            const SizedBox(height: 24),
            _buildTitle(),
            const SizedBox(height: 32),
            if (_step == 1) _buildStep1(),
            if (_step == 2) _buildStep2(),
            if (_step == 3) _buildStep3(),
          ],
        ),
      ),
    );
  }

  // ========== STEP INDICATOR ==========
  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _dot(1),
        _line(_step >= 2),
        _dot(2),
        _line(_step >= 3),
        _dot(3),
      ],
    );
  }

  Widget _dot(int step) {
    final active = _step >= step;
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFC97A3E) : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: active
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : Text('$step', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _line(bool active) {
    return Container(
      width: 30, height: 2,
      color: active ? const Color(0xFFC97A3E) : Colors.grey.shade300,
    );
  }

  // ========== ICON ==========
  Widget _buildIcon() {
    return Container(
      width: 80, height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFC97A3E).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _step == 1 ? Icons.phone_android : _step == 2 ? Icons.sms : Icons.lock_open,
        size: 40, color: const Color(0xFFC97A3E),
      ),
    );
  }

  // ========== TITLE ==========
  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          _step == 1 ? 'Nhập số điện thoại' : _step == 2 ? 'Nhập mã xác nhận' : 'Đặt mật khẩu mới',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF49120F)),
        ),
        const SizedBox(height: 8),
        Text(
          _step == 1 ? 'Nhập SĐT đã đăng ký tài khoản' : _step == 2 ? 'Mã OTP đã gửi đến ${_phoneController.text}' : 'Mật khẩu ít nhất 8 ký tự',
          style: const TextStyle(fontSize: 13, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ========== STEP 1: SĐT ==========
  Widget _buildStep1() {
    return Column(
      children: [
        _field(
          _phoneController,
          'Số điện thoại',
          Icons.phone_android,
          type: TextInputType.phone,
        ),
        const SizedBox(height: 24),
        _btn('Gửi mã OTP', _sendOTP),
      ],
    );
  }

  // ========== STEP 2: OTP ==========
  Widget _buildStep2() {
    return Column(
      children: [
        _field(
          _otpController,
          'Nhập mã OTP 6 số',
          Icons.pin,
          type: TextInputType.number,
          maxLength: 6,
        ),
        const SizedBox(height: 24),
        _btn('Xác nhận', _verifyOTP),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Không nhận được mã? ', style: TextStyle(color: Colors.grey, fontSize: 13)),
            GestureDetector(
              onTap: _sendOTP,
              child: const Text('Gửi lại', style: TextStyle(color: Color(0xFFC97A3E), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  // ========== STEP 3: MẬT KHẨU MỚI ==========
  Widget _buildStep3() {
    return Column(
      children: [
        _field(
          _newPasswordController,
          'Mật khẩu mới',
          Icons.lock_outline,
          obscure: _obscureNew,
          suffix: IconButton(
            icon: Icon(
              _obscureNew ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: () =>
                setState(() => _obscureNew = !_obscureNew),
          ),
        ),
        const SizedBox(height: 16),
        _field(
          _confirmPasswordController,
          'Xác nhận mật khẩu',
          Icons.lock_outline,
          obscure: _obscureConfirm,
          suffix: IconButton(
            icon: Icon(
              _obscureConfirm
                  ? Icons.visibility_off
                  : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: () => setState(
                  () => _obscureConfirm = !_obscureConfirm,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _btn('Đổi mật khẩu', _resetPassword),
      ],
    );
  }

  Widget _field(
      TextEditingController ctrl,
      String hint,
      IconData icon, {
        TextInputType? type,
        bool obscure = false,
        Widget? suffix,
        int? maxLength,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        obscureText: obscure,
        maxLength: maxLength,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFFC97A3E),
          ),
          suffixIcon: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          counterText: '',
        ),
      ),
    );
  }

  Widget _btn(String text, VoidCallback onTap) {
  return SizedBox(
  width: double.infinity,
  height: 50,
  child: ElevatedButton(
  onPressed: _isLoading ? null : onTap,
  style: ElevatedButton.styleFrom(
  backgroundColor: const Color(0xFFC97A3E),
  foregroundColor: Colors.white,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  disabledBackgroundColor: Colors.grey,
  ),
  child: _isLoading
  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
      : Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  ),
  );
  }
}