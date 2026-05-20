import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'DanhGiaPage.dart';
import 'HomePage.dart';
import 'SearchPage.dart';

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> with WidgetsBindingObserver {
  List<dynamic> allBookings = []; // Lưu tất cả booking
  List<dynamic> filteredBookings = []; // Lưu booking đã lọc
  bool isLoading = true;
  bool isCancelling = false;

  // Biến lọc
  int selectedStatus = -1; // -1: Tất cả, 0: Chờ xác nhận, 1: Đã xác nhận, 2: Đang ở, 3: Đã trả phòng, 4: Đã hủy
  DateTime? _lastReload;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchBookings();
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reloadIfNeeded();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reloadIfNeeded();
  }

  Future<void> _reloadIfNeeded() async {
    final now = DateTime.now();
    if (_lastReload == null || now.difference(_lastReload!).inSeconds > 30) {
      _lastReload = now;
      fetchBookings();
    }
  }

  Future<void> fetchBookings() async {
    final prefs = await SharedPreferences.getInstance();
    int maKH = prefs.getInt('user_maKH') ?? 0;

    if (maKH == 0) {
      setState(() => isLoading = false);
      return;
    }

    try {
      var response = await ApiService.get('khach-hang/$maKH/dat-phong');
      setState(() {
        allBookings = response['data'] ?? [];
        _applyFilter(); // Áp dụng bộ lọc
        isLoading = false;
      });
    } catch (e) {
      print('❌ Lỗi load lịch sử: $e');
      setState(() => isLoading = false);
    }
  }

  // Áp dụng bộ lọc theo trạng thái
  void _applyFilter() {
    if (selectedStatus == -1) {
      // Tất cả
      filteredBookings = List.from(allBookings);
    } else {
      // Lọc theo trạng thái
      filteredBookings = allBookings.where((booking) {
        return booking['TinhTrang'] == selectedStatus;
      }).toList();
    }
    setState(() {});
  }

  // Lọc theo trạng thái
  void _filterByStatus(int status) {
    setState(() {
      selectedStatus = status;
      _applyFilter();
    });
  }

  // Lấy tên trạng thái
  String _getStatusName(int status) {
    switch (status) {
      case 0: return 'Chờ xác nhận';
      case 1: return 'Đã xác nhận';
      case 2: return 'Đang ở';
      case 3: return 'Đã trả phòng';
      case 4: return 'Đã hủy';
      default: return 'Tất cả';
    }
  }

  // Lấy màu cho chip filter
  Color _getFilterChipColor(int status) {
    if (selectedStatus == status) {
      switch (status) {
        case 0: return Colors.orange;
        case 1: return Colors.blue;
        case 2: return Colors.green;
        case 3: return Colors.grey;
        case 4: return Colors.red;
        default: return const Color(0xFFC97A3E);
      }
    }
    return Colors.grey.shade300;
  }

  // Lấy màu chữ cho chip filter
  Color _getFilterChipTextColor(int status) {
    if (selectedStatus == status) {
      return Colors.white;
    }
    return Colors.black87;
  }

  Future<void> cancelBooking(int maDatPhong) async {
    final booking = allBookings.firstWhere(
          (b) => b['MaDatPhong'] == maDatPhong,
      orElse: () => null,
    );

    final shouldCancel = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Xác nhận hủy phòng'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn có chắc chắn muốn hủy đặt phòng này?'),
            const SizedBox(height: 8),
            const Text(
              'Lưu ý: Sau khi hủy, đơn đặt phòng sẽ bị hủy và không thể khôi phục.',
              style: TextStyle(fontSize: 12, color: Color(0xFF854023)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFC97A3E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFC97A3E).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📋 Thông tin đặt phòng:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text('Mã đặt phòng: #$maDatPhong'),
                  if (booking != null) ...[
                    Text('Ngày nhận: ${_formatDate(booking['NgayNhanPhong'])}'),
                    Text('Ngày trả: ${_formatDate(booking['NgayTraPhong'])}'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Chính sách hủy phòng:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const Text(
              '• Hủy trước 10–15 ngày: Miễn phí hủy phòng',
              style: TextStyle(fontSize: 11, color: Color(0xFFC97A3E)),
            ),
            const Text(
              '• Hủy trước 5–10 ngày: Chịu 30%–70% phí đặt phòng',
              style: TextStyle(fontSize: 11, color: Color(0xFFC97A3E)),
            ),
            const Text(
              '• Hủy trước 1–5 ngày: Chịu 100% phí đặt phòng',
              style: TextStyle(fontSize: 11, color: Color(0xFFC97A3E)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Quay lại', style: TextStyle(color: Color(0xFF000000))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );

    if (shouldCancel != true) return;

    setState(() => isCancelling = true);

    try {
      final response = await ApiService.post('dat-phong/$maDatPhong/cancel', {});

      if (response['success'] == true) {
        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: const [
                    Icon(Icons.check_circle, color: Colors.green, size: 32),
                    SizedBox(width: 10),
                    Text(
                      'Thành công!',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.hotel,
                      color: Colors.green,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Hủy phòng thành công!',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.green, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              response['message'] ?? 'Đơn đặt phòng #$maDatPhong đã được hủy thành công',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Danh sách đặt phòng sẽ được cập nhật',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC97A3E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Đóng'),
                  ),
                ],
              );
            },
          );

          await fetchBookings();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã cập nhật danh sách đặt phòng'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        throw Exception(response['message'] ?? 'Không thể hủy phòng');
      }
    } catch (e) {
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: const [
                  Icon(Icons.error_outline, color: Colors.red, size: 32),
                  SizedBox(width: 10),
                  Text(
                    'Thất bại!',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cancel,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Hủy phòng thất bại!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            e.toString().replaceFirst('Exception: ', ''),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFC97A3E),
                  ),
                  child: const Text('Đóng'),
                ),
              ],
            );
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() => isCancelling = false);
      }
    }
  }

  bool _canCancelBooking(int? tinhTrang, DateTime ngayNhanPhong) {
    return (tinhTrang == 0 || tinhTrang == 1) && !DateTime.now().isAfter(ngayNhanPhong);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      DateTime d = DateTime.parse(dateStr);
      return "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTien(dynamic tien) {
    double t = double.tryParse(tien?.toString() ?? '0') ?? 0;
    return t.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
  }

  Color _tinhTrangColor(int? tinhTrang) {
    switch (tinhTrang) {
      case 0: return Colors.orange;
      case 1: return Colors.blue;
      case 2: return Colors.green;
      case 3: return Colors.grey;
      case 4: return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _tinhTrangIcon(int? tinhTrang) {
    switch (tinhTrang) {
      case 0: return Icons.hourglass_empty;
      case 1: return Icons.check_circle_outline;
      case 2: return Icons.hotel;
      case 3: return Icons.logout;
      case 4: return Icons.cancel;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text("Lịch sử đặt phòng",
            style: TextStyle(color: Color(0xFF49120F), fontWeight: FontWeight.bold , fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF49120F), size: 20),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
                  (route) => false,
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Color(0xFFC97A3E)),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔥 FILTER CHIPS
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Chip "Tất cả"
                  FilterChip(
                    label: Text('Tất cả', style: TextStyle(color: _getFilterChipTextColor(-1))),
                    selected: selectedStatus == -1,
                    onSelected: (_) => _filterByStatus(-1),
                    backgroundColor: Colors.grey.shade200,
                    selectedColor: _getFilterChipColor(-1),
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  const SizedBox(width: 8),
                  // Chip "Chờ xác nhận"
                  FilterChip(
                    label: Text('Chờ xác nhận', style: TextStyle(color: _getFilterChipTextColor(0))),
                    selected: selectedStatus == 0,
                    onSelected: (_) => _filterByStatus(0),
                    backgroundColor: Colors.grey.shade200,
                    selectedColor: _getFilterChipColor(0),
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  const SizedBox(width: 8),
                  // Chip "Đã xác nhận"
                  FilterChip(
                    label: Text('Đã xác nhận', style: TextStyle(color: _getFilterChipTextColor(1))),
                    selected: selectedStatus == 1,
                    onSelected: (_) => _filterByStatus(1),
                    backgroundColor: Colors.grey.shade200,
                    selectedColor: _getFilterChipColor(1),
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  const SizedBox(width: 8),
                  // Chip "Đang ở"
                  FilterChip(
                    label: Text('Đang ở', style: TextStyle(color: _getFilterChipTextColor(2))),
                    selected: selectedStatus == 2,
                    onSelected: (_) => _filterByStatus(2),
                    backgroundColor: Colors.grey.shade200,
                    selectedColor: _getFilterChipColor(2),
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  const SizedBox(width: 8),
                  // Chip "Đã trả phòng"
                  FilterChip(
                    label: Text('Đã trả phòng', style: TextStyle(color: _getFilterChipTextColor(3))),
                    selected: selectedStatus == 3,
                    onSelected: (_) => _filterByStatus(3),
                    backgroundColor: Colors.grey.shade200,
                    selectedColor: _getFilterChipColor(3),
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  const SizedBox(width: 8),
                  // Chip "Đã hủy"
                  FilterChip(
                    label: Text('Đã hủy', style: TextStyle(color: _getFilterChipTextColor(4))),
                    selected: selectedStatus == 4,
                    onSelected: (_) => _filterByStatus(4),
                    backgroundColor: Colors.grey.shade200,
                    selectedColor: _getFilterChipColor(4),
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ],
              ),
            ),
          ),
          // Hiển thị số lượng kết quả
          if (!isLoading && filteredBookings.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${filteredBookings.length} đơn đặt phòng',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Spacer(),
                  if (selectedStatus != -1)
                    TextButton(
                      onPressed: () => _filterByStatus(-1),
                      child: const Text(
                        'Xóa bộ lọc',
                        style: TextStyle(color: Color(0xFFC97A3E), fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          // Nội dung chính
          Expanded(
            child: isLoading || isCancelling
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFFC97A3E)),
                  if (isCancelling) ...[
                    const SizedBox(height: 16),
                    const Text('Đang xử lý hủy phòng...',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ],
              ),
            )
                : filteredBookings.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hotel_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    selectedStatus == -1
                        ? "Chưa có đơn đặt phòng nào"
                        : "Không có đơn đặt phòng nào ở trạng thái '${_getStatusName(selectedStatus)}'",
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // 🔥 Thay vì pop, chuyển trực tiếp đến SearchPage
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchPage()),
                            (route) => false, // Xóa tất cả các màn hình trước đó
                      );
                    },
                    icon: const Icon(Icons.search, color: Color(0xFFFFFFFF)),
                    label: const Text("Tìm phòng ngay", style: TextStyle(color: Color(0xFFFFFFFF)),),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC97A3E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: fetchBookings,
              color: const Color(0xFFC97A3E),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredBookings.length,
                itemBuilder: (context, index) {
                  var booking = filteredBookings[index];
                  return _buildBookingCard(booking);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(dynamic booking) {
    int tinhTrang = booking['TinhTrang'] ?? 4;
    String tinhTrangText = booking['TinhTrangText'] ?? 'Không xác định';
    var hoaDon = booking['hoa_don'];
    var phongs = booking['phongs'] ?? [];
    int soDem = booking['soDem'] ?? 1;
    int maDatPhong = booking['MaDatPhong'];
    DateTime ngayNhanPhong = DateTime.parse(booking['NgayNhanPhong']);
    bool canCancel = _canCancelBooking(tinhTrang, ngayNhanPhong);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Header
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _tinhTrangColor(tinhTrang).withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Bên trái: Mã ĐP + Ngày đặt
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC97A3E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.hotel, color: Color(0xFFC97A3E), size: 22),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Mã ĐP: #${booking['MaDatPhong']}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF49120F))),
                        Text(_formatDate(booking['NgayDat']),
                            style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),

                // Bên phải: Các nút hành động (THEO STYLE SHOPEE)
                Row(
                  children: [
                    // NÚT TRẠNG THÁI (giữ nguyên style cũ)
                    _buildTrangThaiBadge(tinhTrang, tinhTrangText),

                    // NÚT ĐÁNH GIÁ (nếu đã check-out)
                    if (tinhTrang == 3) ...[
                      const SizedBox(width: 8),
                      _buildDanhGiaButtonShopee(booking),
                    ],

                    // NÚT HỦY (nếu có thể hủy)
                    if (canCancel) ...[
                      const SizedBox(width: 8),
                      _buildHuyButtonShopee(maDatPhong),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Body (giữ nguyên phần còn lại)
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    _dateBox("Nhận phòng", _formatDate(booking['NgayNhanPhong'])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: [
                          Text("$soDem đêm",
                              style: const TextStyle(fontSize: 11, color: Color(0xFFC97A3E), fontWeight: FontWeight.bold)),
                          const Icon(Icons.arrow_forward, size: 16, color: Color(0xFFC97A3E)),
                        ],
                      ),
                    ),
                    _dateBox("Trả phòng", _formatDate(booking['NgayTraPhong'])),
                  ],
                ),
                const SizedBox(height: 14),
                if (phongs.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8BE97).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        ...phongs.take(3).map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.meeting_room, size: 14, color: Color(0xFFC97A3E)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  "${p['TenLoaiPhong']} (Phòng ${p['SoPhong']})",
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF49120F)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        )),
                        if (phongs.length > 3)
                          Text("+${phongs.length - 3} phòng khác",
                              style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                if (hoaDon != null && tinhTrang != 4 && hoaDon['TongTien'] > 0)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE8BE97)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        _moneyRow("Tổng tiền", hoaDon['TongTien']),
                        _moneyRow("Đã thanh toán", hoaDon['DaThanhToan'], color: Colors.green),
                        if ((hoaDon['ConLai'] ?? 0) > 0)
                          _moneyRow("Còn lại", hoaDon['ConLai'], color: Colors.red),
                      ],
                    ),
                  ),
                if (canCancel)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline, size: 14, color: Colors.orange),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Có thể hủy phòng trước ngày nhận phòng',
                              style: TextStyle(fontSize: 11, color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  //
  // 🔥 Badge trạng thái - Style cũ (giữ nguyên)
  Widget _buildTrangThaiBadge(int tinhTrang, String tinhTrangText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _tinhTrangColor(tinhTrang).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _tinhTrangColor(tinhTrang).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_tinhTrangIcon(tinhTrang), size: 13, color: _tinhTrangColor(tinhTrang)),
          const SizedBox(width: 4),
          Text(
            tinhTrangText,
            style: TextStyle(
              color: _tinhTrangColor(tinhTrang),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 Nút Đánh giá - Style Shopee
  Widget _buildDanhGiaButtonShopee(dynamic booking) {
    final daDanhGia = booking['da_danh_gia'] ?? false;
    final saoDanhGia = booking['SaoDanhGia'] ?? 0;

    if (daDanhGia) {
      // ✅ ĐÃ ĐÁNH GIÁ - Hiển thị sao + check xanh (đã khóa)
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.green.shade50, // Nền xanh nhạt
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.green.shade200), // Viền xanh
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 13, color: Colors.amber.shade600),
            const SizedBox(width: 3),
            Text(
              '$saoDanhGia',
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.check_circle, size: 12, color: Colors.green.shade600), // Thêm check xanh
          ],
        ),
      );
    }

    // ⭐ CHƯA ĐÁNH GIÁ - Nút viền cam (style Shopee)
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          String? tenLoaiPhong;
          final phongs = booking['phongs'] as List? ?? [];
          if (phongs.isNotEmpty) {
            tenLoaiPhong = phongs[0]['TenLoaiPhong']?.toString();
          }

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DanhGiaPage(
                maDatPhong: booking['MaDatPhong'],
                tenLoaiPhong: tenLoaiPhong,
                ngayTraPhong: DateTime.tryParse(booking['NgayTraPhong']?.toString() ?? ''),
              ),
            ),
          );

          if (result == true && mounted) {
            // 🔥 CẬP NHẬT NGAY TẠI CHỖ
            setState(() {
              booking['da_danh_gia'] = true;
              booking['SaoDanhGia'] = result['sao'] ?? 5; // Nếu DanhGiaPage trả về sao
            });

            // Vẫn fetch lại để đồng bộ với server
            await fetchBookings();
          }
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFC97A3E), width: 1),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_outline, size: 12, color: Color(0xFFC97A3E)),
              SizedBox(width: 3),
              Text(
                'Đánh giá',
                style: TextStyle(
                  color: Color(0xFFC97A3E),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // 🔥 Nút Hủy - Style Shopee
  Widget _buildHuyButtonShopee(int maDatPhong) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => cancelBooking(maDatPhong),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.red.shade300, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.close, size: 12, color: Colors.red.shade400),
              const SizedBox(width: 3),
              Text(
                'Hủy',
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateBox(String label, String date) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFE8BE97).withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(date,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF49120F))),
          ],
        ),
      ),
    );
  }

  Widget _moneyRow(String label, dynamic amount, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text("${_formatTien(amount)} VND",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color ?? const Color(0xFF49120F))),
        ],
      ),
    );
  }
}