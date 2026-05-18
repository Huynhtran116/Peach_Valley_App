import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class PersonalDataPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const PersonalDataPage({super.key, this.userData});

  @override
  State<PersonalDataPage> createState() => _PersonalDataPageState();
}

class _PersonalDataPageState extends State<PersonalDataPage> {
  late TextEditingController _fullNameController;
  late TextEditingController _addressController;
  late TextEditingController _cccdController;
  late TextEditingController _phoneController;
  late TextEditingController _birthdayController;
  int _gender = 2;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _fullNameController = TextEditingController(text: widget.userData?['TenKH'] ?? '');
    _addressController = TextEditingController(text: widget.userData?['DiaChi'] ?? '');
    _cccdController = TextEditingController(text: widget.userData?['CCCD'] ?? '');
    _phoneController = TextEditingController(text: widget.userData?['SoDienThoai'] ?? '');
    _birthdayController = TextEditingController(text: _formatDateDisplay(widget.userData?['NgaySinh']));
    _gender = widget.userData?['GioiTinh'] ?? 2;
  }

  String _formatDateDisplay(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      DateTime d = DateTime.parse(dateStr);
      return "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
    } catch (e) {
      return dateStr;
    }
  }

  String _formatDateAPI(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      List<String> parts = dateStr.split('/');
      return "${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}";
    } catch (e) {
      return '';
    }
  }

  Future<void> _saveChanges() async {
    if (!_isEditing) {
      setState(() => _isEditing = true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      int? maKH = prefs.getInt('user_maKH');

      if (maKH == null || maKH == 0) {
        throw Exception('Không tìm thấy thông tin khách hàng');
      }

      Map<String, dynamic> updateData = {};

      if (_fullNameController.text.trim() != widget.userData?['TenKH']) {
        updateData['TenKH'] = _fullNameController.text.trim();
      }
      if (_addressController.text.trim() != widget.userData?['DiaChi']) {
        updateData['DiaChi'] = _addressController.text.trim();
      }
      if (_cccdController.text.trim() != widget.userData?['CCCD']) {
        updateData['CCCD'] = _cccdController.text.trim();
      }
      if (_phoneController.text.trim() != widget.userData?['SoDienThoai']) {
        updateData['SoDienThoai'] = _phoneController.text.trim();
      }
      if (_birthdayController.text.trim() != _formatDateDisplay(widget.userData?['NgaySinh'])) {
        updateData['NgaySinh'] = _formatDateAPI(_birthdayController.text.trim());
      }
      if (_gender != (widget.userData?['GioiTinh'] ?? 2)) {
        updateData['GioiTinh'] = _gender;
      }

      if (updateData.isNotEmpty) {
        var response = await ApiService.put('khach-hang/$maKH', updateData);
        print('📥 Response cập nhật: $response');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thông tin thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không có thay đổi nào'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('❌ Lỗi cập nhật: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString().replaceFirst("Exception: ", "")}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('vi'),
    );
    if (picked != null) {
      setState(() {
        _birthdayController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _addressController.dispose();
    _cccdController.dispose();
    _phoneController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = widget.userData?['Email'] ?? '';
    final userPhone = _phoneController.text;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Column(
          children: [
            /// APP BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  _iconBtn(Icons.arrow_back, () {
                    Navigator.pop(context, false);
                  }),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Thông tin cá nhân",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  _iconBtn(
                    _isEditing ? Icons.save : Icons.edit,
                    _saveChanges,
                  ),
                ],
              ),
            ),

            /// CONTENT
            Expanded(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFC97A3E)),
              )
                  : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// PERSONAL DATA
                    _sectionTitle("Thông tin cá nhân"),
                    _card(
                      child: Column(
                        children: [
                          _infoItem(
                            icon: Icons.person_outline,
                            title: "Họ và tên",
                            value: _fullNameController.text,
                            isEditing: _isEditing,
                            onChanged: (v) => _fullNameController.text = v,
                          ),
                          _divider(),
                          _infoItem(
                            icon: Icons.cake_outlined,
                            title: "Ngày sinh",
                            value: _birthdayController.text,
                            isEditing: _isEditing,
                            onTap: _selectDate,
                            isDate: true,
                          ),
                          _divider(),
                          _genderSelector(),
                          _divider(),
                          _infoItem(
                            icon: Icons.location_on_outlined,
                            title: "Địa chỉ",
                            value: _addressController.text,
                            isEditing: _isEditing,
                            onChanged: (v) => _addressController.text = v,
                          ),
                          _divider(),
                          _infoItem(
                            icon: Icons.credit_card_outlined,
                            title: "CCCD/CMND",
                            value: _cccdController.text,
                            isEditing: _isEditing,
                            onChanged: (v) => _cccdController.text = v,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// CONTACT
                    _sectionTitle("Liên hệ"),
                    _card(
                      child: Column(
                        children: [
                          /// Email - KHÔNG CHO CHỈNH SỬA
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Địa chỉ email",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black.withOpacity(0.5),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.email_outlined, size: 16, color: Colors.black54),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userEmail.isEmpty ? "Chưa cập nhật" : userEmail,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Email này dùng để đăng nhập và nhận xác nhận đặt phòng.",
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          _divider(),

                          /// Số điện thoại - CHO PHÉP CHỈNH SỬA
                          _infoItem(
                            icon: Icons.phone_outlined,
                            title: "Số điện thoại",
                            value: _phoneController.text,
                            isEditing: _isEditing,
                            onChanged: (v) => _phoneController.text = v,
                          ),
                          if (!_isEditing && userPhone.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 0),
                              child: Text(
                                "Khách sạn sẽ liên hệ qua số này nếu cần xác nhận đặt phòng.",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _genderSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Giới tính",
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          if (_isEditing)
            Row(
              children: [
                _genderOption("Nam", 1),
                const SizedBox(width: 16),
                _genderOption("Nữ", 0),
                const SizedBox(width: 16),
                _genderOption("Khác", 2),
              ],
            )
          else
            Row(
              children: [
                Icon(Icons.wc_outlined, size: 16, color: Colors.black54),
                const SizedBox(width: 8),
                Text(
                  _getGenderText(_gender),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _genderOption(String label, int value) {
    return Row(
      children: [
        Radio<int>(
          value: value,
          groupValue: _gender,
          onChanged: (v) => setState(() => _gender = v ?? 2),
          activeColor: const Color(0xFFC97A3E),
        ),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  String _getGenderText(int gender) {
    switch (gender) {
      case 0: return 'Nữ';
      case 1: return 'Nam';
      case 2: return 'Khác';
      default: return 'Không xác định';
    }
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black.withOpacity(0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _infoItem({
    required IconData icon,
    required String title,
    required String value,
    bool isEditing = false,
    Function(String)? onChanged,
    VoidCallback? onTap,
    bool isDate = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.black54),
              const SizedBox(width: 8),
              Expanded(
                child: isEditing
                    ? GestureDetector(
                  onTap: onTap,
                  child: TextField(
                    controller: TextEditingController(text: value),
                    onChanged: onChanged,
                    readOnly: isDate,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: "Nhập $title",
                      border: InputBorder.none,
                      isDense: true,
                      suffixIcon: isDate
                          ? const Icon(Icons.calendar_today, size: 16)
                          : null,
                    ),
                  ),
                )
                    : Text(
                  value.isEmpty ? "Chưa cập nhật" : value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 20,
      color: Colors.black.withOpacity(0.06),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: Colors.black87,
        ),
      ),
    );
  }
}