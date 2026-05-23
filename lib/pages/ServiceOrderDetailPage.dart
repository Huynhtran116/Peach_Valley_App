import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/dich_vu.dart';

class ServiceOrderDetailPage extends StatefulWidget {
  final int maDatPhong;
  final String soPhong;
  final DichVuModel? preSelectedService;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;

  const ServiceOrderDetailPage({
    super.key,
    required this.maDatPhong,
    required this.soPhong,
    this.preSelectedService,
    this.checkInDate,
    this.checkOutDate,
  });

  @override
  State<ServiceOrderDetailPage> createState() => _ServiceOrderDetailPageState();
}

class _ServiceOrderDetailPageState extends State<ServiceOrderDetailPage> {
  List<DichVuModel> danhSachDichVu = [];
  List<DichVuModel> danhSachTheoLoai = [];
  List<Map<String, dynamic>> gioHang = [];

  int? selectedLoaiDV;
  DichVuModel? selectedDichVu;
  int soLuong = 1;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  bool isLoading = true;
  bool isOrdering = false;
  bool isAutoSelecting = false;

  final List<Map<String, dynamic>> loaiDichVu = [
    {'MaDV': 1, 'TenDV': 'Dịch vụ ăn uống', 'Icon': Icons.restaurant, 'Unit': 'món', 'Multiple': true},
    {'MaDV': 2, 'TenDV': 'Dịch vụ phòng', 'Icon': Icons.meeting_room, 'Unit': 'dịch vụ', 'Multiple': false},
    {'MaDV': 3, 'TenDV': 'Dịch vụ giải trí', 'Icon': Icons.sports_esports, 'Unit': 'người', 'Multiple': false},
  ];

  DateTime minDate = DateTime.now();
  DateTime maxDate = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    fetchDichVu();
    _loadBookingDates();
  }

  Future<void> _loadBookingDates() async {
    try {
      var response = await ApiService.get('dat-phong/${widget.maDatPhong}');
      if (response['success'] == true && response['data'] != null) {
        var data = response['data'];
        DateTime checkIn = DateTime.parse(data['NgayNhanPhong']);
        DateTime checkOut = DateTime.parse(data['NgayTraPhong']);

        setState(() {
          minDate = checkIn;
          maxDate = checkOut;
          if (selectedDate.isBefore(checkIn)) {
            selectedDate = checkIn;
          }
          if (selectedDate.isAfter(checkOut)) {
            selectedDate = checkOut;
          }
        });
      }
    } catch (e) {
      print('Lỗi load ngày đặt phòng: $e');
    }
  }

  // 🔥 Kiểm tra xem có phải ngày check-out không
  bool _isCheckoutDate() {
    return selectedDate == maxDate;
  }

  // 🔥 Lấy giới hạn giờ tối đa (12:00 cho ngày check-out, 23:59 cho ngày thường)
  int _getMaxHour() {
    if (_isCheckoutDate()) {
      return 12; // Ngày check-out: chỉ đến 12:00
    }
    return 23; // Ngày thường: đến 23:59
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: minDate,
      lastDate: maxDate,
      locale: const Locale('vi'),
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
        // Nếu chọn ngày check-out, kiểm tra lại giờ
        if (_isCheckoutDate() && selectedTime.hour > 12) {
          selectedTime = const TimeOfDay(hour: 12, minute: 0);
        }
      });
    }
  }

  Future<void> _selectTime() async {
    final maxHour = _getMaxHour();

    // Hiển thị thông báo nếu là ngày check-out
    if (_isCheckoutDate()) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Lưu ý', style: TextStyle(color: Color(0xFF49120F))),
          content: const Text('Ngày này là ngày trả phòng. Vui lòng chọn giờ trước 12:00.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đã hiểu', style: TextStyle(color: Color(0xFFC97A3E))),
            ),
          ],
        ),
      );
    }

    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (time != null) {
      // Kiểm tra nếu là ngày check-out và giờ > 12
      if (_isCheckoutDate() && time.hour > 12) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ngày trả phòng chỉ có thể đặt dịch vụ trước 12:00'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      setState(() {
        selectedTime = time;
      });
    }
  }

  Future<void> fetchDichVu() async {
    try {
      var response = await ApiService.get('dich-vu');
      List data = response['data'] ?? [];
      setState(() {
        danhSachDichVu = data.map((e) => DichVuModel.fromJson(e)).toList();
        isLoading = false;
      });

      if (widget.preSelectedService != null && !isAutoSelecting) {
        _autoSelectService(widget.preSelectedService!);
      }
    } catch (e) {
      print('Lỗi load dịch vụ: $e');
      setState(() => isLoading = false);
    }
  }

  void _autoSelectService(DichVuModel service) async {
    if (isAutoSelecting) return;
    isAutoSelecting = true;

    int loaiDV = service.loaiDV;
    setState(() {
      selectedLoaiDV = loaiDV;
      danhSachTheoLoai = danhSachDichVu.where((dv) => dv.loaiDV == loaiDV).toList();
    });

    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      final foundService = danhSachTheoLoai.firstWhere(
            (item) => item.maDV == service.maDV,
        orElse: () => service,
      );
      setState(() {
        selectedDichVu = foundService;
      });
      await Future.delayed(const Duration(milliseconds: 50));
      _themVaoGio();
    }
    isAutoSelecting = false;
  }

  void _filterByLoai(int? maLoaiDV) {
    if (maLoaiDV == null) {
      danhSachTheoLoai = [];
    } else {
      danhSachTheoLoai = danhSachDichVu.where((dv) => dv.loaiDV == maLoaiDV).toList();
    }
    setState(() {
      selectedDichVu = null;
    });
  }

  void _onChangeLoaiDV(int? newLoai) {
    setState(() {
      selectedLoaiDV = newLoai;
      _filterByLoai(newLoai);
      gioHang.clear();
      selectedDichVu = null;
      soLuong = 1;
    });
  }

  bool _canAddMultiple() {
    final loai = loaiDichVu.firstWhere(
          (l) => l['MaDV'] == selectedLoaiDV,
      orElse: () => {'Multiple': false},
    );
    return loai['Multiple'];
  }

  String _getUnit() {
    final loai = loaiDichVu.firstWhere(
          (l) => l['MaDV'] == selectedLoaiDV,
      orElse: () => {'Unit': 'món'},
    );
    return loai['Unit'];
  }

  String _getLabel() {
    switch (selectedLoaiDV) {
      case 1:
        return 'Món ăn';
      case 2:
        return 'Dịch vụ';
      case 3:
        return 'Dịch vụ';
      default:
        return 'Dịch vụ';
    }
  }

  void _themVaoGio() {
    if (selectedDichVu == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn dịch vụ'), backgroundColor: Colors.orange),
      );
      return;
    }

    final canAddMultiple = _canAddMultiple();

    if (!canAddMultiple && gioHang.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chỉ được chọn 1 dịch vụ cho loại này'), backgroundColor: Colors.orange),
      );
      return;
    }

    final existingIndex = gioHang.indexWhere(
            (item) => (item['dichVu'] as DichVuModel).maDV == selectedDichVu!.maDV
    );

    if (existingIndex != -1) {
      setState(() {
        int newSoLuong = (gioHang[existingIndex]['soLuong'] as int) + soLuong;
        gioHang[existingIndex]['soLuong'] = newSoLuong;
        gioHang[existingIndex]['thanhTien'] = selectedDichVu!.giaDV * newSoLuong;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật số lượng ${selectedDichVu!.tenDV}'), backgroundColor: Colors.green),
      );
    } else {
      double thanhTien = selectedDichVu!.giaDV * soLuong;
      setState(() {
        gioHang.add({
          'dichVu': selectedDichVu,
          'soLuong': soLuong,
          'thanhTien': thanhTien,
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm ${selectedDichVu!.tenDV} vào giỏ'), backgroundColor: Colors.green),
      );
    }

    setState(() {
      selectedDichVu = null;
      soLuong = 1;
    });
  }

  void _xoaKhoiGio(int index) {
    final dichVu = gioHang[index]['dichVu'] as DichVuModel;
    setState(() {
      gioHang.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã xóa ${dichVu.tenDV} khỏi giỏ'), backgroundColor: Colors.orange),
    );
  }

  double get tongTien {
    return gioHang.fold(0, (sum, item) => sum + (item['thanhTien'] as double));
  }

  Future<void> _datDichVu() async {
    if (gioHang.isEmpty) {
      print('🔴 [ĐẶT DV] Giỏ hàng trống');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 dịch vụ'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => isOrdering = true);

    try {
      // 🔥 BƯỚC 1: Lấy MaCTDP từ API
      print('🟢 [ĐẶT DV] Lấy thông tin đặt phòng...');
      var bookingResponse = await ApiService.get('dat-phong/${widget.maDatPhong}');
      print('🟢 [ĐẶT DV] Booking response: $bookingResponse');

      int maCTDP = 0;
      if (bookingResponse['success'] == true && bookingResponse['data'] != null) {
        var data = bookingResponse['data'];
        var chiTiet = data['chi_tiet_dat_phong'] as List? ?? [];
        if (chiTiet.isNotEmpty) {
          // Tìm MaCTDP theo số phòng
          for (var ct in chiTiet) {
            if (ct['phong'] != null && ct['phong']['SoPhong']?.toString() == widget.soPhong) {
              maCTDP = ct['MaCTDP'] ?? 0;
              break;
            }
          }
          // Nếu không tìm thấy, lấy cái đầu tiên
          if (maCTDP == 0) {
            maCTDP = chiTiet.first['MaCTDP'] ?? 0;
          }
        }
      }

      print('🟢 [ĐẶT DV] MaCTDP: $maCTDP');

      if (maCTDP == 0) {
        throw Exception('Không tìm thấy mã chi tiết đặt phòng');
      }

      // 🔥 BƯỚC 2: Tạo items
      List<Map<String, dynamic>> items = [];
      for (var item in gioHang) {
        DichVuModel dichVu = item['dichVu'];
        items.add({
          'MaDV': dichVu.maDV,
          'SoLuong': item['soLuong'],
        });
      }

      String thoiGian = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')} "
          "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00";

      // 🔥 BƯỚC 3: Gửi request
      print('🟢 [ĐẶT DV] Gửi: MaCTDP=$maCTDP, Items=$items');

      var response = await ApiService.post('su-dung-dich-vu', {
        'MaCTDP': maCTDP,  // 👈 DÙNG MaCTDP
        'ThoiGian': thoiGian,
        'items': items,
      });

      print('🟢 [ĐẶT DV] Response: $response');

      if (response['success'] == true) {
        print('✅ [ĐẶT DV] Thành công!');
        _showSuccessDialog();
      } else {
        throw Exception(response['message']);
      }
    } catch (e) {
      print('🔴 [ĐẶT DV] LỖI: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isOrdering = false);
    }
  }

  void _showSuccessDialog() {
    // Tạo danh sách dịch vụ để hiển thị
    List<Map<String, dynamic>> serviceList = [];
    for (var item in gioHang) {
      DichVuModel dv = item['dichVu'];
      serviceList.add({
        'ten': dv.tenDV,
        'soLuong': item['soLuong'],
        'thanhTien': item['thanhTien'],
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 10),
            Text('Đặt dịch vụ thành công!'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Yêu cầu dịch vụ của quý khách đã được ghi nhận.'),
              const SizedBox(height: 16),

              // 🔥 THÔNG TIN ĐẶT PHÒNG
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8BE97).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.meeting_room, size: 16, color: Color(0xFF49120F)),
                        const SizedBox(width: 8),
                        Text(
                          '#${widget.maDatPhong} - Phòng ${widget.soPhong}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Color(0xFF49120F)),
                        const SizedBox(width: 8),
                        Text(
                          'Ngày: ${_formatDate(selectedDate)} ${_formatTime(selectedTime)}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 🔥 DANH SÁCH DỊCH VỤ ĐÃ ĐẶT
              const Text(
                'Chi tiết dịch vụ:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF49120F),
                ),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: serviceList.map((service) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service['ten'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'x${service['soLuong']}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${_formatTien(service['thanhTien'])} VND',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFFC97A3E),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),

              // 🔥 TỔNG TIỀN
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFC97A3E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng cộng:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF49120F),
                      ),
                    ),
                    Text(
                      '${_formatTien(tongTien)} VND',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFFC97A3E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true);
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFC97A3E),
            ),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  String _formatTien(double soTien) {
    return soTien.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final unit = _getUnit();
    final label = _getLabel();
    final canAddMultiple = _canAddMultiple();
    final isCheckout = _isCheckoutDate();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Đăng ký dịch vụ",
          style: TextStyle(
            color: Color(0xFF49120F),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF49120F)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF49120F), Color(0xFFC97A3E)]),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Yêu cầu dịch vụ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Hãy để chúng tôi chuẩn bị đúng dịch vụ quý khách cần trong thời gian lưu trú.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '#${widget.maDatPhong} - Phòng ${widget.soPhong}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (minDate != maxDate)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Lưu trú: ${_formatDate(minDate)} → ${_formatDate(maxDate)}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Loại dịch vụ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF49120F))),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: loaiDichVu.map((loai) {
                        bool isSelected = selectedLoaiDV == loai['MaDV'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(loai['TenDV']),
                            selected: isSelected,
                            onSelected: (selected) {
                              _onChangeLoaiDV(selected ? loai['MaDV'] : null);
                            },
                            avatar: Icon(loai['Icon'], size: 16),
                            backgroundColor: Colors.grey.shade200,
                            selectedColor: const Color(0xFFC97A3E),
                            labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (selectedLoaiDV != null) ...[
                    const Text('Dịch vụ đã chọn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF49120F))),
                    const SizedBox(height: 8),
                    if (gioHang.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                        child: const Center(child: Text('Chưa có dịch vụ nào được chọn')),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: gioHang.length,
                        itemBuilder: (context, index) {
                          final item = gioHang[index];
                          final dv = item['dichVu'] as DichVuModel;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(dv.tenDV, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text('${_formatTien(dv.giaDV)} VND x ${item['soLuong']} $unit', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                Text('${_formatTien(item['thanhTien'])} VND', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC97A3E))),
                                const SizedBox(width: 8),
                                GestureDetector(onTap: () => _xoaKhoiGio(index), child: const Icon(Icons.close, color: Colors.red)),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 16),

                    Text('Thêm $label', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF49120F))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFC97A3E)), borderRadius: BorderRadius.circular(8)),
                      child: DropdownButton<DichVuModel>(
                        value: selectedDichVu,
                        hint: Text('Chọn $label'),
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: danhSachTheoLoai.map((dv) {
                          return DropdownMenuItem(value: dv, child: Text('${dv.tenDV} - ${_formatTien(dv.giaDV)} VND'));
                        }).toList(),
                        onChanged: (value) => setState(() => selectedDichVu = value),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Text('Số lượng $unit: '),
                        IconButton(onPressed: () { if (soLuong > 1) setState(() => soLuong--); }, icon: const Icon(Icons.remove_circle), color: const Color(0xFFC97A3E)),
                        Text('$soLuong', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(onPressed: () => setState(() => soLuong++), icon: const Icon(Icons.add_circle), color: const Color(0xFFC97A3E)),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: _themVaoGio,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC97A3E)),
                          child: const Text('Thêm', style: TextStyle(color: Color(0xFFFFFFFF))),
                        ),
                      ],
                    ),

                    if (!canAddMultiple && gioHang.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, size: 14, color: Colors.orange),
                              SizedBox(width: 6),
                              Expanded(child: Text('Chỉ được chọn 1 dịch vụ cho loại này', style: TextStyle(fontSize: 12, color: Colors.orange))),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],

                  const Text('Thời gian sử dụng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF49120F))),
                  const SizedBox(height: 8),

                  // 🔥 Thông báo nếu là ngày check-out
                  if (isCheckout)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber, size: 14, color: Colors.red),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Ngày này là ngày trả phòng. Chỉ được đặt dịch vụ trước 12:00',
                              style: TextStyle(fontSize: 12, color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _selectDate,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFC97A3E)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Color(0xFFC97A3E)),
                                const SizedBox(width: 8),
                                Text(_formatDate(selectedDate)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _selectTime,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFC97A3E)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, color: Color(0xFFC97A3E)),
                                const SizedBox(width: 8),
                                Text(_formatTime(selectedTime)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFE8BE97).withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tổng tiền dịch vụ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('${_formatTien(tongTien)} VND', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFFC97A3E))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isOrdering ? null : _datDichVu,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC97A3E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: isOrdering
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Hoàn tất đăng ký', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}