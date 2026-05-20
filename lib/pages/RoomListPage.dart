import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/loai_phong.dart';
import 'DetailRoomPage.dart';

class RoomListPage extends StatefulWidget {
  const RoomListPage({super.key});

  @override
  State<RoomListPage> createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> {
  List<LoaiPhong> danhSach = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRooms();
  }

  Future<void> fetchRooms() async {
    try {
      var response = await ApiService.get('loai-phong');
      List data = response['data'] ?? [];
      setState(() {
        danhSach = data.map((e) => LoaiPhong.fromJson(e)).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Lỗi load phòng: $e');
      setState(() => isLoading = false);
    }
  }

  // Format tiền
  String _formatVND(dynamic amount) {
    double t = double.tryParse(amount?.toString() ?? '0') ?? 0;
    return t.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF49120F)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Tất cả loại phòng",
          style: TextStyle(
            color: Color(0xFF49120F),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFFC97A3E)),
      )
          : danhSach.isEmpty
          ? const Center(
        child: Text(
          "Không có dữ liệu phòng",
          style: TextStyle(color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: danhSach.length,
        itemBuilder: (context, index) {
          final room = danhSach[index];
          return _roomCard(room);
        },
      ),
    );
  }

  // 🔥 CARD GIỐNG HOMEPAGE - CÓ NÚT CHI TIẾT
  Widget _roomCard(LoaiPhong room) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ảnh phòng
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: room.anhDauTien != null
                ? Image.network(
              room.anhDauTien!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: const Color(0xFFE8BE97),
                  child: const Center(
                    child: Icon(Icons.hotel, size: 50, color: Color(0xFF49120F)),
                  ),
                );
              },
            )
                : Container(
              height: 200,
              color: const Color(0xFFE8BE97),
              child: const Center(
                child: Icon(Icons.hotel, size: 50, color: Color(0xFF49120F)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tên phòng
                Text(
                  room.tenLoaiPhong,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                // Mô tả
                Text(
                  room.mota,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                // Số phòng trống
                Row(
                  children: [
                    const Icon(Icons.account_circle_sharp, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Tối đa : ${room.nguoiLon} người lớn - ${room.treEm} trẻ em',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Giá + Nút chi tiết
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_formatVND(room.giaThapNhat)} VND /đêm',
                          style: const TextStyle(
                            color: Color(0xFFC97A3E),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    // 🔥 NÚT CHI TIẾT - CHUYỂN SANG RoomDetailPage VỚI fromHome = true
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RoomDetailPage(
                              loaiPhong: room,
                              fromHome: true, // 🔥 QUAN TRỌNG: Để biết là từ HomePage/RoomListPage
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF6F1D01),
                              Color(0xFFC97A3E),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Chi tiết',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}