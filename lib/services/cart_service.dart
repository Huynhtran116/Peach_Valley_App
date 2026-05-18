// lib/services/cart_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CartService {
  static const String _cartKey = 'booking_cart';

  // Lưu giỏ hàng
  static Future<void> saveCart(Map<int, Map<String, dynamic>> gioPhong) async {
    final prefs = await SharedPreferences.getInstance();
    // Chuyển Map thành JSON để lưu
    Map<String, dynamic> cartData = {};
    gioPhong.forEach((key, value) {
      cartData[key.toString()] = value;
    });
    await prefs.setString(_cartKey, jsonEncode(cartData));
    print('✅ Đã lưu giỏ hàng: ${cartData.length} items');
  }

  // Đọc giỏ hàng
  static Future<Map<int, Map<String, dynamic>>> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    String? cartString = prefs.getString(_cartKey);
    if (cartString == null) return {};

    try {
      Map<String, dynamic> decoded = jsonDecode(cartString);
      Map<int, Map<String, dynamic>> result = {};
      decoded.forEach((key, value) {
        result[int.parse(key)] = Map<String, dynamic>.from(value);
      });
      print('✅ Đã đọc giỏ hàng: ${result.length} items');
      return result;
    } catch (e) {
      print('❌ Lỗi đọc giỏ hàng: $e');
      return {};
    }
  }

  // Xóa giỏ hàng
  static Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
    print('✅ Đã xóa giỏ hàng');
  }
}