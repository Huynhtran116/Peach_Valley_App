import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/loai_phong.dart';
import 'BookingConfirmPage.dart';
import 'DetailRoomPage.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // Filter
  DateTime selectedCheckIn = DateTime.now();
  DateTime selectedCheckOut = DateTime.now().add(const Duration(days: 1));
  int soNguoiLon = 2;
  int soTreEm = 0;
  int soPhong = 1;

  // 🔥 BỘ LỌC MỚI
  String searchKeyword = ''; // Tìm kiếm theo tên phòng
  String selectedSort = 'Mặc định'; // 'Mặc định', 'Giá tăng dần', 'Giá giảm dần'
  bool _isFilterExpanded = false; // 🔥 Trạng thái mở rộng bộ lọc

  // Kết quả
  List<dynamic> ketQua = [];
  List<dynamic> ketQuaGoc = []; // Lưu kết quả gốc để lọc
  bool isSearching = false;
  bool hasSearched = false;

  // ✅ Giỏ phòng dạng grouped: Map<MaLoaiPhong, {...}>
  Map<int, Map<String, dynamic>> gioPhong = {};

  int get soDem => selectedCheckOut.difference(selectedCheckIn).inDays;
  late TextEditingController _searchController;
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ========== GIỎ PHÒNG LOGIC ==========

  void _themPhong(dynamic room, double gia) {
    int maLoai = room['MaLoaiPhong'];
    int soPhongTrong = room['soPhongTrong'] ?? 99;
    int currentQty = (gioPhong[maLoai]?['quantity'] as int?) ?? 0;

    if (currentQty >= soPhongTrong) {
      _showSnackBar("Chỉ còn $soPhongTrong phòng trống", isError: true);
      return;
    }

    setState(() {
      if (gioPhong.containsKey(maLoai)) {
        gioPhong[maLoai]!['quantity'] = currentQty + 1;
      } else {
        gioPhong[maLoai] = {
          'MaLoaiPhong': maLoai,
          'TenLoaiPhong': room['TenLoaiPhong'],
          'gia': gia,
          'hinhs': room['hinhs'],
          'NguoiLon': room['NguoiLon'],
          'TreEm': room['TreEm'],
          'soPhongTrong': soPhongTrong,
          'quantity': 1,
        };
      }
    });

    _showSnackBar("Đã thêm ${room['TenLoaiPhong']}");
  }

  void _giamPhong(int maLoaiPhong) {
    if (!gioPhong.containsKey(maLoaiPhong)) return;

    setState(() {
      gioPhong[maLoaiPhong]!['quantity'] = (gioPhong[maLoaiPhong]!['quantity'] as int) - 1;
      if ((gioPhong[maLoaiPhong]!['quantity'] as int) <= 0) {
        gioPhong.remove(maLoaiPhong);
      }
    });

    _showSnackBar("Đã cập nhật giỏ phòng");
  }

  void _xoaPhong(int maLoaiPhong) {
    if (!gioPhong.containsKey(maLoaiPhong)) return;
    String ten = gioPhong[maLoaiPhong]!['TenLoaiPhong'] ?? '';

    setState(() {
      gioPhong.remove(maLoaiPhong);
    });

    _showSnackBar("Đã xóa $ten khỏi giỏ");
  }

  int get tongSoPhongTrongGio => gioPhong.values.fold(
    0,
        (sum, item) => sum + ((item['quantity'] as int?) ?? 0),
  );

  // ========== SNACKBAR ==========

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFFC97A3E),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ========== FORMAT ==========

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  String _formatDateAPI(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String _formatTien(double soTien) {
    return soTien.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
  }

  // ========== LỌC VÀ SẮP XẾP ==========

  void _filterAndSortResults() {
    if (ketQuaGoc.isEmpty) return;

    List<dynamic> filtered = List.from(ketQuaGoc);

    // 🔥 Lọc theo từ khóa (tên phòng, mô tả, tiện nghi)
    if (searchKeyword.isNotEmpty) {
      filtered = filtered.where((room) {
        String ten = room['TenLoaiPhong']?.toLowerCase() ?? '';
        String mota = room['Mota']?.toLowerCase() ?? '';

        List<dynamic> tienNghis = room['tien_nghis'] ?? [];
        bool hasAmenity = tienNghis.any((tn) {
          return tn['TenTienNghi']?.toString().toLowerCase().contains(searchKeyword.toLowerCase()) ?? false;
        });

        return ten.contains(searchKeyword.toLowerCase()) ||
            mota.contains(searchKeyword.toLowerCase()) ||
            hasAmenity;
      }).toList();
    }

    // 🔥 Sắp xếp theo giá
    if (selectedSort == 'Giá tăng dần') {
      filtered.sort((a, b) {
        double giaA = double.tryParse(a['giaThapNhat']?.toString() ?? '0') ?? 0;
        double giaB = double.tryParse(b['giaThapNhat']?.toString() ?? '0') ?? 0;
        return giaA.compareTo(giaB);
      });
    } else if (selectedSort == 'Giá giảm dần') {
      filtered.sort((a, b) {
        double giaA = double.tryParse(a['giaThapNhat']?.toString() ?? '0') ?? 0;
        double giaB = double.tryParse(b['giaThapNhat']?.toString() ?? '0') ?? 0;
        return giaB.compareTo(giaA);
      });
    }

    setState(() {
      ketQua = filtered;
    });
  }

  void _resetFilters() {
    setState(() {
      searchKeyword = '';
      selectedSort = 'Mặc định';
      ketQua = List.from(ketQuaGoc);
      _searchController.clear();
    });
    _showSnackBar("Đã xóa bộ lọc");
  }

  // ========== TÌM KIẾM ==========

  Future<void> timKiem() async {
    setState(() {
      gioPhong.clear();
      ketQua = [];
      ketQuaGoc = [];
      isSearching = true;
      hasSearched = true;
      _isFilterExpanded = false; // 🔥 Reset trạng thái filter khi tìm kiếm mới
    });

    try {
      var response = await ApiService.get(
        'phong/tim-kiem?checkIn=${_formatDateAPI(selectedCheckIn)}&checkOut=${_formatDateAPI(selectedCheckOut)}&NguoiLon=$soNguoiLon&TreEm=$soTreEm&SoPhong=$soPhong',
      );

      setState(() {
        ketQuaGoc = response['data'] ?? [];
        ketQua = List.from(ketQuaGoc);
        isSearching = false;
        _isFilterExpanded = ketQua.isNotEmpty; // 🔥 Chỉ mở filter nếu có kết quả
      });
    } catch (e) {
      setState(() => isSearching = false);
    }
  }

  // ========== FILTER POPUP ==========

  void _showFilterPopup() {
    int tempNguoiLon = soNguoiLon;
    int tempTreEm = soTreEm;
    int tempSoPhong = soPhong;
    DateTime tempCheckIn = selectedCheckIn;
    DateTime tempCheckOut = selectedCheckOut;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              title: const Row(
                children: [
                  Icon(Icons.search, color: Color(0xFFC97A3E)),
                  SizedBox(width: 10),
                  Text("Tìm phòng", style: TextStyle(color: Color(0xFF49120F), fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dateField("Nhận phòng", tempCheckIn, () async {
                      final picked = await showDatePicker(
                        context: context, initialDate: tempCheckIn,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        locale: const Locale('vi'),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          tempCheckIn = picked;
                          if (tempCheckOut.isBefore(tempCheckIn.add(const Duration(days: 1)))) {
                            tempCheckOut = tempCheckIn.add(const Duration(days: 1));
                          }
                        });
                      }
                    }),
                    const SizedBox(height: 12),
                    _dateField("Trả phòng", tempCheckOut, () async {
                      final picked = await showDatePicker(
                        context: context, initialDate: tempCheckOut,
                        firstDate: tempCheckIn.add(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        locale: const Locale('vi'),
                      );
                      if (picked != null) setDialogState(() => tempCheckOut = picked);
                    }),
                    const SizedBox(height: 20),
                    const Text("Số phòng", style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(onPressed: () { if (tempSoPhong > 1) setDialogState(() => tempSoPhong--); }, icon: const Icon(Icons.remove_circle, color: Color(0xFFC97A3E))),
                        Text("$tempSoPhong", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF49120F))),
                        IconButton(onPressed: () { if (tempSoPhong < 10) setDialogState(() => tempSoPhong++); }, icon: const Icon(Icons.add_circle, color: Color(0xFFC97A3E))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text("Người lớn"),
                      Row(children: [
                        IconButton(onPressed: () { if (tempNguoiLon > 1) setDialogState(() => tempNguoiLon--); }, icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFC97A3E))),
                        Text("$tempNguoiLon", style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(onPressed: () => setDialogState(() => tempNguoiLon++), icon: const Icon(Icons.add_circle_outline, color: Color(0xFFC97A3E))),
                      ]),
                    ]),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text("Trẻ em"),
                      Row(children: [
                        IconButton(onPressed: () { if (tempTreEm > 0) setDialogState(() => tempTreEm--); }, icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFC97A3E))),
                        Text("$tempTreEm", style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(onPressed: () => setDialogState(() => tempTreEm++), icon: const Icon(Icons.add_circle_outline, color: Color(0xFFC97A3E))),
                      ]),
                    ]),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Hủy")),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedCheckIn = tempCheckIn;
                      selectedCheckOut = tempCheckOut;
                      soNguoiLon = tempNguoiLon;
                      soTreEm = tempTreEm;
                      soPhong = tempSoPhong;
                    });
                    Navigator.pop(dialogContext);
                    timKiem();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC97A3E)),
                  child: const Text("Tìm phòng", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _dateField(String label, DateTime date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFC97A3E).withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: Color(0xFFC97A3E)),
            const SizedBox(width: 10),
            Text("$label: ${_formatDate(date)}", style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ========== BUILD ==========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Tìm phòng", style: TextStyle(color: Color(0xFF49120F))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF49120F)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFFC97A3E)),
            onPressed: _showFilterPopup,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          // 🔥 THANH TÌM KIẾM VÀ LỌC - CHỈ HIỆN SAU KHI CÓ KẾT QUẢ
          if (hasSearched && !isSearching)
            _buildSearchAndFilterBar(),
          Expanded(child: _buildBody()),
          _buildStickyBottom(),
        ],
      ),
    );
  }

  // 🔥 THANH TÌM KIẾM VÀ LỌC - ĐẸP HƠN, NẰM TRONG MỘT HÀNG
  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 🔥 Ô tìm kiếm (chiếm phần lớn)
          Expanded(
            flex: 3,
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: const Color(0xFFE8BE97).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    searchKeyword = value;
                    _filterAndSortResults();
                  });
                },
                decoration: InputDecoration(
                  hintText: "🔍 Tìm phòng , tiện nghi phòng ,..",
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  suffixIcon: searchKeyword.isNotEmpty
                      ? GestureDetector(
                    onTap: () {
                      setState(() {
                        searchKeyword = '';
                        _filterAndSortResults();
                      });
                    },
                    child: const Icon(Icons.clear, size: 18, color: Colors.grey),
                  )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 🔥 Dropdown sắp xếp
          Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8BE97).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              value: selectedSort,
              underline: const SizedBox(),
              icon: const Icon(Icons.sort, color: Color(0xFFC97A3E), size: 20),
              items: const [
                DropdownMenuItem(value: 'Mặc định', child: Text('Mặc định', style: TextStyle(fontSize: 13))),
                DropdownMenuItem(value: 'Giá tăng dần', child: Text('Giá tăng dần', style: TextStyle(fontSize: 13))),
                DropdownMenuItem(value: 'Giá giảm dần', child: Text('Giá giảm dần', style: TextStyle(fontSize: 13))),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedSort = value;
                    _filterAndSortResults();
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          // 🔥 Nút xóa lọc (chỉ hiện khi có filter đang áp dụng)
          if (searchKeyword.isNotEmpty || selectedSort != 'Mặc định')
            GestureDetector(
              onTap: _resetFilters,
              child: Container(
                height: 45,
                width: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFFC97A3E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.close, color: Color(0xFFC97A3E), size: 20),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStickyBottom() {
    double tongTien = gioPhong.values.fold(
      0,
          (sum, item) {
        double gia = (item['gia'] as num).toDouble();
        int qty = item['quantity'] as int;
        return sum + (gia * soDem * qty);
      },
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Đã chọn $tongSoPhongTrongGio phòng",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF49120F),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: _showGioPhongPopup,
                    child: const Row(
                      children: [
                        Text(
                          "Xem chi tiết",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFC97A3E),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFFC97A3E)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Tổng thanh toán",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      Text(
                        "${_formatTien(tongTien)} VND",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC97A3E),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 48,
                    width: 160,
                    child: ElevatedButton(
                      onPressed: () {
                        if (gioPhong.isEmpty) {
                          _showSnackBar(
                            "Vui lòng đặt ít nhất 1 phòng!",
                            isError: true,
                          );
                          return;
                        }
                        _showGioPhongPopup();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC97A3E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Đặt phòng",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: _showFilterPopup,
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE8BE97).withOpacity(0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFC97A3E).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFF49120F)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "${_formatDate(selectedCheckIn)} → ${_formatDate(selectedCheckOut)} • $soPhong phòng • $soNguoiLon Người lớn, $soTreEm Trẻ em",
                style: const TextStyle(color: Color(0xFF49120F), fontWeight: FontWeight.w500),
              ),
            ),
            const Text("Sửa", style: TextStyle(color: Color(0xFFC97A3E), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isSearching) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFC97A3E)));
    }
    if (!hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            const Text("Nhập thông tin để tìm phòng", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showFilterPopup,
              icon: const Icon(Icons.tune),
              label: const Text("Tìm kiếm"),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC97A3E)),
            ),
          ],
        ),
      );
    }
    if (ketQua.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            const Text("Không có phòng phù hợp", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 5),
            GestureDetector(
              onTap: _showFilterPopup,
              child: const Text("Thử thay đổi ngày hoặc số khách", style: TextStyle(color: Color(0xFFC97A3E))),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ketQua.length,
      itemBuilder: (context, index) => _buildRoomCard(ketQua[index]),
    );
  }

  // ========== ROOM CARD ==========

  Widget _buildRoomCard(dynamic room) {
    int maLoai = room['MaLoaiPhong'] ?? 0;
    String ten = room['TenLoaiPhong'] ?? '';
    String mota = room['Mota'] ?? '';
    int nguoiLon = room['NguoiLon'] ?? 2;
    int treEm = room['TreEm'] ?? 1;
    int soPhongTrong = room['soPhongTrong'] ?? 0;
    int tongKhach = nguoiLon + treEm;

    List<dynamic> hinhs = room['hinhs'] ?? [];
    String anh = hinhs.isNotEmpty ? (hinhs[0]['Url'] ?? '') : '';
    double gia = double.tryParse(room['giaThapNhat']?.toString() ?? '0') ?? 0;
    List<dynamic> tienNghis = room['tien_nghis'] ?? [];

    int soPhongDaChon = (gioPhong[maLoai]?['quantity'] as int?) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ảnh phòng
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: anh.isNotEmpty
                ? Image.network(anh, height: 200, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => _placeholder(200))
                : _placeholder(200),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(ten, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF49120F)))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFC97A3E).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text("$tongKhach khách", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC97A3E))),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (mota.isNotEmpty)
                  Text(mota, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4)),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _detailItem(Icons.people, "Người lớn:", "$nguoiLon"),
                    const SizedBox(width: 20),
                    _detailItem(Icons.child_care, "Trẻ em:", "$treEm"),
                    const SizedBox(width: 20),
                    _detailItem(Icons.meeting_room, "Còn trống:", "$soPhongTrong phòng", valueColor: soPhongTrong > 0 ? Colors.green : Colors.red),
                  ],
                ),
                const SizedBox(height: 12),
                if (tienNghis.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () => _showTienNghiPopup(tienNghis),
                    child: Row(
                      children: [
                        Wrap(spacing: 4, children: tienNghis.take(3).map((tn) => _miniChip(tn['TenTienNghi'] ?? '')).toList()),
                        if (tienNghis.length > 3) Text(" +${tienNghis.length - 3}", style: const TextStyle(color: Color(0xFFC97A3E), fontSize: 12)),
                        const SizedBox(width: 20),
                        const Text("Xem tất cả tiện nghi", style: TextStyle(color: Color(0xFFC97A3E), fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const Divider(height: 1),
                const SizedBox(height: 14),
                // 🔥 Hàng giá và nút thêm số lượng
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Giá
                    Text(
                      '${_formatTien(gia)} VND /đêm',
                      style: const TextStyle(
                        color: Color(0xFFC97A3E),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    // Nút thêm/bớt phòng (bên phải)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8BE97).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () { if (soPhongDaChon > 0) _giamPhong(maLoai); },
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFC97A3E)),
                              ),
                              child: const Icon(Icons.remove, color: Color(0xFFC97A3E), size: 16),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              "$soPhongDaChon",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF49120F)),
                            ),
                          ),
                          GestureDetector(
                            onTap: () { if (soPhongDaChon < soPhongTrong) _themPhong(room, gia); },
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFFC97A3E),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.add, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 🔥 Nút xem chi tiết (nằm dưới cùng, bên phải)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _navigateToRoomDetail(room);
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
                          'Xem chi tiết',
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

// 🔥 Thêm hàm điều hướng đến trang chi tiết phòng
  void _navigateToRoomDetail(dynamic room) {
    // Chuyển đổi dữ liệu từ API sang model LoaiPhong
    LoaiPhong loaiPhong = LoaiPhong(
      maLoaiPhong: room['MaLoaiPhong'] ?? 0,
      tenLoaiPhong: room['TenLoaiPhong'] ?? '',
      mota: room['Mota'] ?? '',
      nguoiLon: room['NguoiLon'] ?? 2,
      treEm: room['TreEm'] ?? 0,
      hinhs: (room['hinhs'] as List<dynamic>?)
          ?.map((e) => HinhAnh.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      phongs: (room['phongs'] as List<dynamic>?)
          ?.map((e) => Phong.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      bangGias: (room['bang_gias'] as List<dynamic>?)
          ?.map((e) => BangGia.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      tienNghis: (room['tien_nghis'] as List<dynamic>?)
          ?.map((e) => TienNghi.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoomDetailPage(
          loaiPhong: loaiPhong,
        ),
      ),
    );
  }


  void _chuyenDenXacNhanDatPhong() {
    List<Map<String, dynamic>> selectedRooms = [];

    gioPhong.forEach((maLoai, item) {
      int quantity = item['quantity'] as int;
      for (int i = 0; i < quantity; i++) {
        selectedRooms.add({
          'roomType': {
            'MaLoaiPhong': item['MaLoaiPhong'],
            'TenLoaiPhong': item['TenLoaiPhong'],
            'giaThapNhat': item['gia'],
            'hinhs': item['hinhs'],
            'NguoiLon': item['NguoiLon'],
            'TreEm': item['TreEm'],
          },
          'nguoiLon': item['NguoiLon'] ?? 2,
          'treEm': item['TreEm'] ?? 0,
        });
      }
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingConfirmPage(
          checkIn: selectedCheckIn,
          checkOut: selectedCheckOut,
          soNguoiLon: soNguoiLon,
          soTreEm: soTreEm,
          selectedRooms: selectedRooms,
        ),
      ),
    );
  }

  void _showGioPhongPopup() {
    if (gioPhong.isEmpty) {
      _showSnackBar("Vui lòng chọn ít nhất 1 phòng!", isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          double tongTien = gioPhong.values.fold(
            0,
                (sum, item) {
              double gia = (item['gia'] as num).toDouble();
              int qty = item['quantity'] as int;
              return sum + (gia * soDem * qty);
            },
          );

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.white,
            title: const Row(
              children: [
                Icon(Icons.receipt_long, color: Color(0xFFC97A3E)),
                SizedBox(width: 10),
                Text("Thông tin phòng", style: TextStyle(color: Color(0xFF49120F), fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFE8BE97).withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Color(0xFF49120F)),
                        const SizedBox(width: 8),
                        Text(
                          "${_formatDate(selectedCheckIn)} - ${_formatDate(selectedCheckOut)} (${soDem} đêm)",
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Color(0xFF49120F)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...gioPhong.entries.map((e) {
                    var g = e.value;
                    int count = g['quantity'] as int;
                    double gia = (g['gia'] as num).toDouble();
                    double thanhTien = gia * soDem * count;
                    List<dynamic> hinhs = g['hinhs'] ?? [];
                    String anh = hinhs.isNotEmpty ? (hinhs[0]['Url'] ?? '') : '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE8BE97)), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: anh.isNotEmpty
                                ? Image.network(anh, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c, e, s) => _placeholder(60))
                                : _placeholder(60),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${g['TenLoaiPhong']} ×$count phòng", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () { _giamPhong(g['MaLoaiPhong']); setDialogState(() {}); },
                                      child: const Icon(Icons.remove_circle_outline, color: Color(0xFFC97A3E), size: 22),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Text("$count", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ),
                                    GestureDetector(
                                      onTap: () { _themPhong(g, gia); setDialogState(() {}); },
                                      child: const Icon(Icons.add_circle_outline, color: Color(0xFFC97A3E), size: 22),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text("${_formatTien(gia)} VND / đêm", style: const TextStyle(fontSize: 12, color: Color(0xFFC97A3E))),
                                Text("${_formatTien(thanhTien)} VND", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF49120F))),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () { _xoaPhong(g['MaLoaiPhong']); setDialogState(() {}); },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                              child: const Text("Hủy", style: TextStyle(color: Colors.red, fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Tổng cộng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF49120F))),
                      Text("${_formatTien(tongTien)} VND", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFFC97A3E))),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Tiếp tục chọn", style: TextStyle(color: Color(0xFFC97A3E), fontWeight: FontWeight.bold)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (gioPhong.isEmpty) {
                    _showSnackBar(
                      "Vui lòng đặt ít nhất 1 phòng!",
                      isError: true,
                    );
                    return;
                  }
                  _chuyenDenXacNhanDatPhong();
                },
                label: const Text("Đặt phòng", style: TextStyle(fontWeight: FontWeight.bold,color: Color(0xFFFFFFFF))),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC97A3E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _detailItem(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: valueColor ?? const Color(0xFF49120F))),
      ],
    );
  }

  Widget _miniChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFE8BE97).withOpacity(0.5), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF49120F))),
    );
  }

  void _showTienNghiPopup(List<dynamic> tienNghis) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Tiện nghi phòng", style: TextStyle(color: Color(0xFF49120F), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: tienNghis.map((tn) => ListTile(
            leading: const Icon(Icons.check_circle, color: Color(0xFFC97A3E), size: 20),
            title: Text(tn['TenTienNghi'] ?? ''),
            dense: true,
          )).toList(),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Đóng"))],
      ),
    );
  }

  Widget _placeholder(double height) {
    return Container(height: height, color: const Color(0xFFE8BE97), child: const Center(child: Icon(Icons.hotel, size: 50, color: Color(0xFF49120F))));
  }
}