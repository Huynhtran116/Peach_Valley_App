// pages/KhoKhuyenMaiPage.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../utils/number_parser.dart';
import 'PromotionPage.dart';

class KhoKhuyenMaiPage extends StatefulWidget {
  const KhoKhuyenMaiPage({super.key});

  @override
  State<KhoKhuyenMaiPage> createState() => _KhoKhuyenMaiPageState();
}

class _KhoKhuyenMaiPageState extends State<KhoKhuyenMaiPage>  with WidgetsBindingObserver{
  List<Map<String, dynamic>> _khoKhuyenMai = [];
  List<Map<String, dynamic>> _allKhoKhuyenMai = [];
  int _diemHienTai = 0;
  bool _isLoading = true;
  String? _errorMessage;
  int? _selectedFilter; // null = Tất cả
  DateTime? _lastReload;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedFilter = null;
    _loadData();

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
      _loadData();
    }
  }

  // ========== LOAD DATA ==========

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      int maKH = prefs.getInt('user_maKH') ?? 0;

      if (maKH == 0) {
        setState(() {
          _errorMessage = 'Vui lòng đăng nhập để xem kho khuyến mãi';
          _isLoading = false;
        });
        return;
      }

      // GỌI 2 API SONG SONG
      final results = await Future.wait([
        ApiService.get('kho-khuyen-mai/khach-hang/$maKH'),
        ApiService.get('khach-hang/$maKH'),
      ]);

      final response = results[0];
      final khResponse = results[1];

      // Parse kho khuyến mãi
      List<dynamic> rawData = [];
      if (response is List) {
        rawData = response;
      } else if (response['data'] is List) {
        rawData = response['data'];
      }

      List<Map<String, dynamic>> parsedData = rawData.map((item) {
        final km = item['khuyen_mai'] as Map<String, dynamic>? ?? {};

        String ngayHetHan = '';
        final ngayKetThuc = km['NgayKetThuc']?.toString();
        if (ngayKetThuc != null && ngayKetThuc.isNotEmpty) {
          try {
            final date = DateTime.parse(ngayKetThuc);
            ngayHetHan = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
          } catch (_) {
            ngayHetHan = ngayKetThuc;
          }
        }

        final trangThai = _parseInt(item['TrangThai']);

        return {
          'MaKM': km['MaKM']?.toString() ?? '',
          'MaKH': item['MaKH']?.toString() ?? '',
          'TenKM': km['TenKM']?.toString() ?? '',
          'MoTa': km['MoTa']?.toString() ?? '',
          'PhanTramGiamGia': _parseDouble(km['PhanTramGiamGia']),
          'Diem': _parseInt(km['Diem']),
          'NgayHetHan': ngayHetHan,
          'NgayHetHanRaw': km['NgayKetThuc']?.toString(),
          'TrangThai': trangThai,
          'TrangThaiText': _getTrangThaiText(trangThai),
          'LoaiKM': _parseInt(km['LoaiKM']),
        };
      }).toList();

      // Parse điểm
      int diem = 0;
      if (khResponse is Map) {
        diem = _parseInt(khResponse['data']?['DIEM'] ?? khResponse['DIEM'] ?? 0);
      }

      setState(() {
        _allKhoKhuyenMai = parsedData;
        _khoKhuyenMai = List.from(parsedData);
        _diemHienTai = diem;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      print('❌ Lỗi tải dữ liệu: $e');
      setState(() {
        _errorMessage = 'Lỗi tải dữ liệu';
        _isLoading = false;
      });
    }
  }

  // ========== HELPERS ==========

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _getTrangThaiText(int code) {
    switch (code) {
      case 0: return 'Chưa sử dụng';
      case 1: return 'Đã sử dụng';
      case 2: return 'Hết hạn';
      default: return 'Không xác định';
    }
  }

  Color _getTrangThaiColor(int trangThai) {
    switch (trangThai) {
      case 0: return Colors.green;
      case 1: return Colors.grey;
      case 2: return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getTrangThaiIcon(int trangThai) {
    switch (trangThai) {
      case 0: return Icons.check_circle_outline;
      case 1: return Icons.done_all;
      case 2: return Icons.timer_off;
      default: return Icons.help_outline;
    }
  }

  void _filterByTrangThai(int? trangThai) {
    setState(() {
      _selectedFilter = trangThai;
      if (trangThai == null) {
        _khoKhuyenMai = List.from(_allKhoKhuyenMai);
      } else {
        _khoKhuyenMai = _allKhoKhuyenMai.where((km) => km['TrangThai'] == trangThai).toList();
      }
    });
  }

  // ========== BUILD ==========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Kho khuyến mãi của tôi",
          style: TextStyle(
            color: Color(0xFF49120F),
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),

        foregroundColor: Color(0xFF49120F),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC97A3E)))
          : _errorMessage != null
          ? _buildErrorView()
          : RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildDiemHeader()),
            SliverToBoxAdapter(child: _buildFilterTabs()),
            _khoKhuyenMai.isEmpty
                ? SliverFillRemaining(child: _buildEmptyForFilter())
                : SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildKhuyenMaiCard(_khoKhuyenMai[index]),
                childCount: _khoKhuyenMai.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== HEADER ĐIỂM ==========

  Widget _buildDiemHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF49120F), Color(0xFFC97A3E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC97A3E).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.stars, color: Colors.amber, size: 28),
              SizedBox(width: 10),
              Text('Điểm của bạn', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$_diemHienTai',
                style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('điểm', style: TextStyle(color: Colors.white70, fontSize: 16)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_circle_outline, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text('Kiếm điểm', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_diemHienTai / 1000).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.centerRight,
            child: Text('1000 điểm để lên VIP', style: TextStyle(color: Colors.white54, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  // ========== FILTER TABS CÓ HIỆU ỨNG ==========

  Widget _buildFilterTabs() {
    final countAll = _allKhoKhuyenMai.length;
    final countChuaDung = _allKhoKhuyenMai.where((km) => km['TrangThai'] == 0).length;
    final countDaDung = _allKhoKhuyenMai.where((km) => km['TrangThai'] == 1).length;
    final countHetHan = _allKhoKhuyenMai.where((km) => km['TrangThai'] == 2).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Tất cả', null, countAll),
            const SizedBox(width: 8),
            _buildFilterChip('Chưa dùng', 0, countChuaDung),
            const SizedBox(width: 8),
            _buildFilterChip('Đã dùng', 1, countDaDung),
            const SizedBox(width: 8),
            _buildFilterChip('Hết hạn', 2, countHetHan),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int? trangThai, int count) {
    final isSelected = _selectedFilter == trangThai;

    return GestureDetector(
      onTap: () => _filterByTrangThai(trangThai),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC97A3E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFC97A3E) : const Color(0xFFE8BE97),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFFC97A3E).withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : const Color(0xFF49120F),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.3) : const Color(0xFFE8BE97).withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF49120F),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== CARD MÃ KM ==========

  Widget _buildKhuyenMaiCard(Map<String, dynamic> km) {
    final trangThai = km['TrangThai'] as int;
    final statusColor = _getTrangThaiColor(trangThai);
    final phanTramGiam = km['PhanTramGiamGia'] as double;
    final tenKM = km['TenKM'] as String;
    final maKM = km['MaKM'] as String;
    final ngayHetHan = km['NgayHetHan'] as String;
    final trangThaiText = km['TrangThaiText'] as String;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: trangThai == 0 ? const Color(0xFFC97A3E).withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${phanTramGiam.toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: trangThai == 0 ? const Color(0xFFC97A3E) : Colors.grey),
                ),
                const Text('GIẢM', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tenKM, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(_getTrangThaiIcon(trangThai), size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(trangThaiText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Mã: $maKM', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  if (ngayHetHan.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('HSD: $ngayHetHan', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ],
              ),
            ),
          ),
          if (trangThai == 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, {'MaKM': maKM, 'PhanTramGiamGia': phanTramGiam, 'TenKM': tenKM}),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC97A3E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: const Text('Dùng ngay', style: TextStyle(fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }

  // ========== EMPTY STATE THEO FILTER ==========

  Widget _buildEmptyForFilter() {
    IconData icon;
    String title;
    String subtitle;
    Color color;
    bool showButton;

    switch (_selectedFilter) {
      case 0:
        icon = Icons.check_circle_outline;
        title = 'Không có mã chưa sử dụng';
        subtitle = 'Đổi điểm để nhận mã khuyến mãi mới';
        color = Colors.green;
        showButton = true;
        break;
      case 1:
        icon = Icons.done_all;
        title = 'Không có mã đã sử dụng';
        subtitle = 'Mã đã sử dụng sẽ hiển thị ở đây';
        color = Colors.grey;
        showButton = false;
        break;
      case 2:
        icon = Icons.timer_off;
        title = 'Không có mã hết hạn';
        subtitle = 'Mã hết hạn sẽ tự động chuyển vào đây';
        color = Colors.red;
        showButton = false;
        break;
      default:
        icon = Icons.card_giftcard_outlined;
        title = 'Chưa có mã khuyến mãi nào';
        subtitle = 'Đổi điểm để nhận mã khuyến mãi hấp dẫn';
        color = const Color(0xFFC97A3E);
        showButton = true;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 60, color: color),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF49120F)), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey), textAlign: TextAlign.center),
            if (showButton) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PromotionPage()));
                },
                icon: const Icon(Icons.local_offer, size: 18),
                label: const Text('Xem khuyến mãi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC97A3E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ========== ERROR VIEW ==========

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _loadData, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}