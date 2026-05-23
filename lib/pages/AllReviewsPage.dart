// pages/AllReviewsPage.dart
import 'package:flutter/material.dart';
import '../models/danh_gia.dart';
import '../services/danh_gia_service.dart';

class AllReviewsPage extends StatefulWidget {
  const AllReviewsPage({super.key});

  @override
  State<AllReviewsPage> createState() => _AllReviewsPageState();
}

class _AllReviewsPageState extends State<AllReviewsPage> {
  List<DanhGiaModel> _tatCaDanhGia = [];
  double _diemTrungBinh = 0.0;
  int _tongDanhGia = 0;
  Map<int, int> _soLuongTheoSao = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
  bool _isLoading = true;
  int? _filterStar;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final result = await DanhGiaService.layTatCaDanhGia();

    if (!mounted) return;

    setState(() {
      _tatCaDanhGia = (result['danhSach'] as List).cast<DanhGiaModel>();
      _diemTrungBinh = result['diemTrungBinh'] ?? 0.0;
      _tongDanhGia = result['tongDanhGia'] ?? 0;
      _soLuongTheoSao = Map<int, int>.from(result['soLuongTheoSao'] ?? {});
      _isLoading = false;
    });
  }

  List<DanhGiaModel> get _filteredReviews {
    if (_filterStar == null) return _tatCaDanhGia;
    return _tatCaDanhGia.where((dg) => dg.sao == _filterStar).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Tất cả đánh giá',
          style: TextStyle(color: Color(0xFF49120F), fontWeight: FontWeight.bold , fontSize: 18), // 👈 Màu nâu đỏ
        ),
        iconTheme: const IconThemeData(color: Color(0xFF49120F)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC97A3E))) // 👈 Màu cam
          : RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFFC97A3E),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildOverviewHeader()),
            SliverToBoxAdapter(child: _buildStarFilter()),
            _filteredReviews.isEmpty
                ? SliverFillRemaining(child: _buildEmptyView())
                : SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildReviewCard(_filteredReviews[index]),
                childCount: _filteredReviews.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 Header tổng quan - Style HomePage
  Widget _buildOverviewHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient( // 👈 Gradient giống HomePage
          colors: [Color(0xFF49120F), Color(0xFFC97A3E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _tongDanhGia == 0
          ? const Center(
        child: Text('Chưa có đánh giá nào', style: TextStyle(color: Colors.white70)),
      )
          : Row(
        children: [
          Column(
            children: [
              Text(
                _diemTrungBinh.toStringAsFixed(1),
                style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold),
              ),
              _buildStarRow(_diemTrungBinh, size: 18, color: Colors.amber),
              const SizedBox(height: 4),
              Text('$_tongDanhGia đánh giá', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: List.generate(5, (index) {
                int star = 5 - index;
                int count = _soLuongTheoSao[star] ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        child: Text('$star', style: const TextStyle(color: Colors.white70, fontSize: 11), textAlign: TextAlign.right),
                      ),
                      const Icon(Icons.star, color: Colors.amber, size: 12),
                      const SizedBox(width: 4),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _tongDanhGia > 0 ? count / _tongDanhGia : 0,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(width: 24, child: Text('$count', style: const TextStyle(color: Colors.white70, fontSize: 10))),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 Filter sao
  Widget _buildStarFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('Tất cả', null),
          const SizedBox(width: 8),
          _buildFilterChip('5 ★', 5),
          const SizedBox(width: 8),
          _buildFilterChip('4 ★', 4),
          const SizedBox(width: 8),
          _buildFilterChip('3 ★', 3),
          const SizedBox(width: 8),
          _buildFilterChip('2 ★', 2),
          const SizedBox(width: 8),
          _buildFilterChip('1 ★', 1),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int? star) {
    final isSelected = _filterStar == star;
    return GestureDetector(
      onTap: () => setState(() => _filterStar = star),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC97A3E) : Colors.white, // 👈 Màu cam
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFFC97A3E) : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF49120F), // 👈 Màu nâu đỏ
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // 🔥 Card đánh giá - Style giống HomePage
  Widget _buildReviewCard(DanhGiaModel dg) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, // 👈 Nền trắng
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)), // 👈 Viền xám nhạt
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), // 👈 Bóng nhẹ
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFC97A3E).withOpacity(0.1), // 👈 Nền cam nhạt
                child: Text(
                  dg.avatarChar,
                  style: const TextStyle(color: Color(0xFFC97A3E), fontWeight: FontWeight.bold), // 👈 Chữ cam
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dg.tenKhachHang ?? 'Khách hàng',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF49120F)), // 👈 Nâu đỏ
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _buildStarRow(dg.sao.toDouble(), size: 12),
                        const SizedBox(width: 4),
                        Text(dg.ngayDanhGiaFormatted, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (dg.moTa != null && dg.moTa!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              dg.moTa!,
              style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4), // 👈 Đen
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStarRow(double rating, {double size = 16, Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star, size: size, color: color ?? Colors.amber);
        } else if (index < rating && rating % 1 >= 0.5) {
          return Icon(Icons.star_half, size: size, color: color ?? Colors.amber);
        } else {
          return Icon(Icons.star_border, size: size, color: color ?? Colors.amber);
        }
      }),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _filterStar != null ? 'Không có đánh giá $_filterStar ★' : 'Chưa có đánh giá nào',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}