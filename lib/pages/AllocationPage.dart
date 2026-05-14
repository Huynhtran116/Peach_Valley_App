import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'BookingConfirmPage.dart';

class AllocationPage extends StatefulWidget {
  const AllocationPage({super.key});

  @override
  State<AllocationPage> createState() => _AllocationPageState();
}

class _AllocationPageState extends State<AllocationPage> {
  // ========== SEARCH PARAMS ==========
  DateTime selectedCheckIn = DateTime.now();
  DateTime selectedCheckOut = DateTime.now().add(const Duration(days: 1));
  int soNguoiLon = 2;
  int soTreEm = 0;
  int soPhong = 1;

  // ========== ALLOCATION ==========
  List<Map<String, dynamic>> selectedRooms = [];
  List<dynamic> availableRoomTypes = [];
  bool isLoading = true;

  int get totalGuests => soNguoiLon + soTreEm;
  int get assignedGuests {
    int total = 0;
    for (var room in selectedRooms) {
      total += (room['nguoiLon'] ?? 0) as int;
      total += (room['treEm'] ?? 0) as int;
    }
    return total;
  }
  int get remainingGuests => totalGuests - assignedGuests;
  int get remainingRooms => soPhong - selectedRooms.length;
  bool get isComplete => remainingRooms == 0;

  @override
  void initState() {
    super.initState();
    fetchRoomTypes();
  }

  Future<void> fetchRoomTypes() async {
    setState(() => isLoading = true);
    try {
      var response = await ApiService.post('available-room-types', {
        'checkIn': _formatDateAPI(selectedCheckIn),
        'checkOut': _formatDateAPI(selectedCheckOut),
      });
      setState(() {
        availableRoomTypes = response['data'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
    selectedRooms = [];
  }

  void addRoom(dynamic roomType) {
    if (remainingRooms <= 0) return;
    int maxAdult = roomType['NguoiLon'] ?? 2;
    int maxChild = roomType['TreEm'] ?? 1;
    int available = roomType['soPhongTrong'] ?? 0;

    // ✅ FIX: Tính maxCanAdd an toàn
    int maxCanAdd = remainingRooms < available ? remainingRooms : available;
    if (maxCanAdd <= 0) return;

    showDialog(
      context: context,
      builder: (ctx) {
        int soLuong = 1;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text("Thêm ${roomType['TenLoaiPhong']}", style: const TextStyle(color: Color(0xFF49120F))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Tối đa: $maxAdult NL + $maxChild TE / phòng", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 12),
                  Text("Còn trống: $available phòng", style: const TextStyle(color: Color(0xFFC97A3E), fontSize: 13)),
                  Text("Cần thêm: $remainingRooms phòng", style: const TextStyle(color: Colors.orange, fontSize: 13)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ✅ Nút giảm - bọc GestureDetector thay IconButton
                      GestureDetector(
                        onTap: () {
                          if (soLuong > 1) setDialogState(() => soLuong--);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFC97A3E)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.remove, color: Color(0xFFC97A3E), size: 24),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text("$soLuong", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF49120F))),
                      ),
                      // ✅ Nút tăng - bọc GestureDetector thay IconButton
                      GestureDetector(
                        onTap: () {
                          if (soLuong < maxCanAdd) setDialogState(() => soLuong++);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC97A3E),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("Tối đa có thể thêm: $maxCanAdd phòng",
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);

                    int currentRemainingNL = soNguoiLon - assignedAdults();
                    int currentRemainingTE = soTreEm - assignedChildren();
                    int currentRemainingRooms = soPhong - selectedRooms.length;

                    for (int i = 0; i < soLuong; i++) {
                      int roomsLeft = currentRemainingRooms - i;
                      int nlLeft = currentRemainingNL - (i * maxAdult);
                      int teLeft = currentRemainingTE - (i * maxChild);

                      int assignAdult = roomsLeft > 0
                          ? (nlLeft / roomsLeft).ceil().clamp(1, maxAdult)
                          : 1;
                      int assignChild = roomsLeft > 0
                          ? (teLeft / roomsLeft).ceil().clamp(0, maxChild)
                          : 0;

                      setState(() {
                        selectedRooms.add({
                          'roomType': roomType,
                          'nguoiLon': assignAdult,
                          'treEm': assignChild,
                        });
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC97A3E)),
                  child: const Text("Thêm", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

// ✅ THÊM: Đếm người lớn đã gán
  int assignedAdults() {
    int total = 0;
    for (var room in selectedRooms) {
      total += (room['nguoiLon'] ?? 0) as int;
    }
    return total;
  }

// Đếm trẻ em đã gán (giữ nguyên)
  int assignedChildren() {
    int total = 0;
    for (var room in selectedRooms) {
      total += (room['treEm'] ?? 0) as int;
    }
    return total;
  }

  void removeRoom(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_amber, color: Color(0xFFC97A3E), size: 28),
          SizedBox(width: 10),
          Text("Xác nhận", style: TextStyle(color: Color(0xFF49120F), fontWeight: FontWeight.bold)),
        ]),
        content: Text("Bạn muốn xóa phòng ${index + 1}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => selectedRooms.removeAt(index));
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> confirmBooking() async {
    // Kiểm tra đủ khách chưa
    if (assignedGuests < totalGuests) {
      int thieuNL = soNguoiLon - assignedAdults();
      int thieuTE = soTreEm - assignedChildren();

      String message = "Bạn chưa xếp đủ khách:\n";
      if (thieuNL > 0) message += "• Còn $thieuNL người lớn\n";
      if (thieuTE > 0) message += "• Còn $thieuTE trẻ em\n";
      message += "\nVẫn tiếp tục đặt phòng?";

      _showPopup(
        "Chưa đủ khách",
        message,
        false,
        onOk: () => _thucHienDatPhong(), // Vẫn cho đặt nếu muốn
      );
      return;
    }

    _thucHienDatPhong();
  }

// Tách riêng hàm đặt phòng
  void _thucHienDatPhong() {
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

  void _showSnackBar(String message, {bool isSuccess = false}) {
    if (!mounted) return;
    _showPopup(
      isSuccess ? "Thành công" : "Thông báo",
      message,
      isSuccess,
    );
  }

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
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          const Divider(height: 1),
          _buildProgress(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFC97A3E)))
                : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (selectedRooms.isNotEmpty) ...[
                    _buildSelectedRooms(),
                    const SizedBox(height: 16),
                  ],
                  _buildAvailableRooms(),
                ],
              ),
            ),
          ),
          _buildConfirmButton(),
        ],
      ),
    );
  }

  // ========== SEARCH BAR (POPUP) ==========
  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: _showSearchPopup,
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
                "${_formatDate(selectedCheckIn)} → ${_formatDate(selectedCheckOut)} • $soPhong phòng • $soNguoiLon NL, $soTreEm TE",
                style: const TextStyle(color: Color(0xFF49120F), fontWeight: FontWeight.w500),
              ),
            ),
            const Text("Sửa", style: TextStyle(color: Color(0xFFC97A3E), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showSearchPopup() {
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
                    _dateField(label: "Nhận phòng", date: tempCheckIn, onTap: () async {
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
                    _dateField(label: "Trả phòng", date: tempCheckOut, onTap: () async {
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
                    fetchRoomTypes();
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

  Widget _dateField({required String label, required DateTime date, required VoidCallback onTap}) {
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

  // ========== PROGRESS ==========
  Widget _buildProgress() {
    if (selectedRooms.isEmpty) return const SizedBox.shrink();
    double ratio = totalGuests > 0 ? assignedGuests / totalGuests : 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Đã xếp: $assignedGuests/$totalGuests khách",
                  style: TextStyle(fontSize: 13, color: ratio >= 1 ? Colors.green : const Color(0xFF49120F))),
              Text("Còn: $remainingRooms phòng", style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              color: ratio >= 1 ? Colors.green : const Color(0xFFC97A3E),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ========== SELECTED ROOMS ==========
  Widget _buildSelectedRooms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Đã chọn", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF49120F))),
        const SizedBox(height: 8),
        ...List.generate(selectedRooms.length, (index) {
          var room = selectedRooms[index];
          var type = room['roomType'];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6F1D01), Color(0xFFC97A3E)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text("${index + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(type['TenLoaiPhong'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Text("👤${room['nguoiLon']} 👶${room['treEm']}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                IconButton(onPressed: () => removeRoom(index), icon: const Icon(Icons.close, color: Colors.white70, size: 20)),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ========== AVAILABLE ROOMS ==========
  Widget _buildAvailableRooms() {
    var filtered = availableRoomTypes.where((r) => (r['soPhongTrong'] ?? 0) > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("🏨 Phòng có sẵn", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF49120F))),
            if (remainingRooms > 0)
              Text("Cần thêm $remainingRooms phòng", style: const TextStyle(fontSize: 13, color: Color(0xFFC97A3E))),
          ],
        ),
        const SizedBox(height: 8),
        ...filtered.map((room) => _buildRoomCard(room)),
      ],
    );
  }

  Widget _buildRoomCard(dynamic room) {
    List<dynamic> hinhs = room['hinhs'] ?? [];
    String anh = hinhs.isNotEmpty ? hinhs[0]['Url'] : '';
    int maxAdult = room['NguoiLon'] ?? 2;
    int maxChild = room['TreEm'] ?? 1;
    int available = room['soPhongTrong'] ?? 0;
    double gia = double.tryParse(room['giaThapNhat']?.toString() ?? '0') ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
            child: anh.isNotEmpty
                ? Image.network(anh, width: 100, height: 100, fit: BoxFit.cover, errorBuilder: (c, e, s) => _placeholder(100))
                : _placeholder(100),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(room['TenLoaiPhong'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text("Tối đa: $maxAdult NL + $maxChild TE", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text("$available phòng • ${gia.toStringAsFixed(0)}đ", style: const TextStyle(fontSize: 12, color: Color(0xFFC97A3E))),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ElevatedButton.icon(
              onPressed: remainingRooms > 0 ? () => addRoom(room) : null,
              icon: const Icon(Icons.add, size: 16),
              label: const Text("Thêm", style: TextStyle(color: Colors.white, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC97A3E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(double size) {
    return Container(
      width: size, height: size,
      color: const Color(0xFFE8BE97),
      child: const Center(child: Icon(Icons.hotel, color: Color(0xFF49120F))),
    );
  }

  // ========== CONFIRM BUTTON ==========
  Widget _buildConfirmButton() {
    if (selectedRooms.isEmpty) return const SizedBox.shrink();

    // Kiểm tra đủ khách chưa để đổi text
    bool duKhach = assignedGuests >= totalGuests;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: isComplete ? confirmBooking : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isComplete
                ? (duKhach ? const Color(0xFFC97A3E) : Colors.orange)
                : Colors.grey.shade300,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(
            !isComplete
                ? "Cần chọn thêm $remainingRooms phòng"
                : duKhach
                ? " Đặt phòng"
                : " Đặt phòng (chưa đủ khách)",
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
  void _showPopup(String title, String message, bool isSuccess, {VoidCallback? onOk}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.warning_amber,
              color: isSuccess ? Colors.green : const Color(0xFFC97A3E),
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(color: Color(0xFF49120F), fontWeight: FontWeight.bold, fontSize: 17))),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 15, color: Colors.black87)),
        actions: [
          if (!isSuccess)
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (onOk != null) onOk();
            },
            child: Text(
              isSuccess ? "OK" : "Tiếp tục đặt",
              style: const TextStyle(color: Color(0xFFC97A3E), fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }


}