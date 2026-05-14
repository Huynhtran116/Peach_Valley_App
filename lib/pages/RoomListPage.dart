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
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
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
          child: CircularProgressIndicator(color: Color(0xFFC97A3E)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: danhSach.length,
        itemBuilder: (context, index) {
          final room = danhSach[index];
          return _roomListItem(room);
        },
      ),
    );
  }

  Widget _roomListItem(LoaiPhong room) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ảnh
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: room.anhDauTien != null
                ? Image.network(
              room.anhDauTien!,
              width: 130,
              height: 140,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 130,
                  height: 140,
                  color: const Color(0xFFE8BE97),
                  child: const Icon(Icons.hotel,
                      color: Color(0xFF49120F)),
                );
              },
            )
                : Container(
              width: 130,
              height: 140,
              color: const Color(0xFFE8BE97),
              child: const Icon(Icons.hotel,
                  color: Color(0xFF49120F)),
            ),
          ),
          // Thông tin
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.tenLoaiPhong,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    room.mota,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Giá + Trạng thái + Nút Chi tiết
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${room.giaThapNhat.toStringAsFixed(0)}đ/đêm',
                            style: const TextStyle(
                              color: Color(0xFFC97A3E),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: room.phongs.isNotEmpty
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              room.phongs.isNotEmpty
                                  ? '${room.phongs.length} phòng'
                                  : 'Hết phòng',
                              style: TextStyle(
                                color: room.phongs.isNotEmpty ? Colors.green : Colors.red,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RoomDetailPage(loaiPhong: room),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
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
                              fontSize: 12,
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
          ),
        ],
      ),
    );
  }
}