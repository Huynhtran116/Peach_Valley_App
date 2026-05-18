import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'HomePage.dart';
import 'SearchPage.dart';

class DatePickerPage extends StatefulWidget {
  const DatePickerPage({super.key});

  @override
  State<DatePickerPage> createState() => _DatePickerPageState();
}

class _DatePickerPageState extends State<DatePickerPage> {
  DateTime? startDate;
  DateTime? endDate;

  // 🔥 THÊM BIẾN CHO DIALOG
  int tempSoPhong = 1;
  int tempNguoiLon = 2;
  int tempTreEm = 0;

  final List<DateTime> months = List.generate(
    12,
        (i) => DateTime(DateTime.now().year, DateTime.now().month + i),
  );

  int get soDem {
    if (startDate == null || endDate == null) return 0;
    return endDate!.difference(startDate!).inDays;
  }

  void _onDayTap(DateTime date) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (date.isBefore(today)) return;

    setState(() {
      if (startDate == null || (startDate != null && endDate != null)) {
        startDate = date;
        endDate = null;
      } else {
        if (date.isAfter(startDate!)) {
          endDate = date;
        } else if (date.isBefore(startDate!)) {
          startDate = date;
          endDate = null;
        }
      }
    });
  }

  bool _isInRange(DateTime day) {
    if (startDate == null || endDate == null) return false;
    return day.isAfter(startDate!) && day.isBefore(endDate!);
  }

  bool _isSelected(DateTime day) {
    return (startDate != null &&
        day.year == startDate!.year &&
        day.month == startDate!.month &&
        day.day == startDate!.day) ||
        (endDate != null &&
            day.year == endDate!.year &&
            day.month == endDate!.month &&
            day.day == endDate!.day);
  }

  bool _isStart(DateTime day) {
    return startDate != null &&
        day.year == startDate!.year &&
        day.month == startDate!.month &&
        day.day == startDate!.day;
  }

  bool _isEnd(DateTime day) {
    return endDate != null &&
        day.year == endDate!.year &&
        day.month == endDate!.month &&
        day.day == endDate!.day;
  }

  bool _isSelectable(DateTime date) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return !date.isBefore(today);
  }

  // 🔥 HIỂN THỊ DIALOG CHỌN SỐ PHÒNG, SỐ NGƯỜI
  void _showGuestRoomDialog() {
    // Reset giá trị tạm thời
    tempSoPhong = 1;
    tempNguoiLon = 2;
    tempTreEm = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.hotel, color: Color(0xFFC97A3E)),
                SizedBox(width: 10),
                Text(
                  'Thông tin tìm kiếm',
                  style: TextStyle(
                    color: Color(0xFF49120F),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔥 THÔNG TIN NGÀY NHẬN - TRẢ
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8BE97).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ngày nhận',
                                style: TextStyle(fontSize: 11, color: Color(0xFF000000)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd/MM/yyyy').format(startDate!),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF49120F),
                                ),
                              ),
                            ],
                          ),
                          const Icon(Icons.arrow_forward, color: Color(0xFFC97A3E), size: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ngày trả',
                                style: TextStyle(fontSize: 11, color: Color(0xFF000000)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd/MM/yyyy').format(endDate!),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF49120F),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC97A3E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.nightlife, size: 16, color: Color(0xFFC97A3E)),
                            const SizedBox(width: 6),
                            Text(
                              '$soDem đêm',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFC97A3E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Số phòng
                _buildDialogCounter(
                  title: 'Số phòng',
                  icon: Icons.meeting_room,
                  value: tempSoPhong,
                  minValue: 1,
                  maxValue: 10,
                  onChanged: (v) => setDialogState(() => tempSoPhong = v),
                ),
                const SizedBox(height: 16),

                // Số người lớn
                _buildDialogCounter(
                  title: 'Người lớn',
                  icon: Icons.person,
                  value: tempNguoiLon,
                  minValue: 1,
                  maxValue: 20,
                  onChanged: (v) => setDialogState(() => tempNguoiLon = v),
                ),
                const SizedBox(height: 16),

                // Số trẻ em
                _buildDialogCounter(
                  title: 'Trẻ em',
                  icon: Icons.child_care,
                  value: tempTreEm,
                  minValue: 0,
                  maxValue: 10,
                  onChanged: (v) => setDialogState(() => tempTreEm = v),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Hủy',
                  style: TextStyle(color: Color(0xFF000000)),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToSearchPage();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC97A3E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('Tìm phòng',style: TextStyle(color: Color(0xFFFFFFFF)),),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDialogCounter({
    required String title,
    required IconData icon,
    required int value,
    required int minValue,
    required int maxValue,
    required Function(int) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFC97A3E).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFC97A3E), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (value > minValue) onChanged(value - 1);
                },
                icon: const Icon(Icons.remove_circle_outline),
                color: const Color(0xFFC97A3E),
                iconSize: 24,
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  if (value < maxValue) onChanged(value + 1);
                },
                icon: const Icon(Icons.add_circle_outline),
                color: const Color(0xFFC97A3E),
                iconSize: 24,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🔥 CHUYỂN SANG SEARCHPAGE VỚI ĐẦY ĐỦ THÔNG TIN
  void _navigateToSearchPage() {
    if (startDate != null && endDate != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SearchPage(
            preSelectedCheckIn: startDate,
            preSelectedCheckOut: endDate,
            preSelectedSoPhong: tempSoPhong,
            preSelectedNguoiLon: tempNguoiLon,
            preSelectedTreEm: tempTreEm,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF49120F)),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
                  (route) => false,
            );
          },
        ),
        title: const Text(
          "Chọn ngày",
          style: TextStyle(
            color: Color(0xFF49120F),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          /// RANGE DISPLAY
          if (startDate != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  key: ValueKey(startDate.toString() + (endDate?.toString() ?? '')),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color(0xFFC97A3E).withOpacity(0.4),
                    ),
                    color: const Color(0xFFFDF6F2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat("EEE, dd MMM", "vi").format(startDate!),
                        style: const TextStyle(
                          color: Color(0xFF49120F),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Icon(Icons.arrow_forward, color: Color(0xFFC97A3E)),
                      Text(
                        endDate != null
                            ? DateFormat("EEE, dd MMM", "vi").format(endDate!)
                            : "...",
                        style: const TextStyle(
                          color: Color(0xFF49120F),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          /// CALENDAR
          Expanded(
            child: ListView.builder(
              itemCount: months.length,
              itemBuilder: (context, index) {
                return _buildMonth(months[index]);
              },
            ),
          ),

          /// FOOTER
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                /// HIỂN THỊ SỐ ĐÊM
                if (endDate != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8BE97).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.nightlife, size: 16, color: Color(0xFFC97A3E)),
                          const SizedBox(width: 6),
                          Text(
                            '$soDem đêm',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFC97A3E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                /// 🔥 BUTTON - MỞ DIALOG CHỌN SỐ PHÒNG, SỐ NGƯỜI
                GestureDetector(
                  onTap: () {
                    if (startDate != null && endDate != null) {
                      _showGuestRoomDialog();
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: (startDate != null && endDate != null)
                          ? const LinearGradient(
                        colors: [
                          Color(0xFFC97A3E),
                          Color(0xFF6F1D01),
                        ],
                      )
                          : LinearGradient(
                        colors: [
                          Colors.grey.shade400,
                          Colors.grey.shade500,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: (startDate != null && endDate != null)
                          ? [
                        BoxShadow(
                          color: const Color(0xFFC97A3E).withOpacity(0.3),
                          blurRadius: 15,
                        ),
                      ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        startDate != null && endDate != null
                            ? "Tiếp tục • $soDem đêm"
                            : "Chọn ngày nhận và trả phòng",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
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

  /// MONTH
  Widget _buildMonth(DateTime month) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstDay = DateTime(month.year, month.month, 1).weekday;
    final firstDayIndex = firstDay == 7 ? 0 : firstDay;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              DateFormat("MMMM yyyy", "vi").format(month),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF49120F),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]
                .map((e) => Expanded(
              child: Center(
                child: Text(
                  e,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ))
                .toList(),
          ),
          const SizedBox(height: 10),
          Wrap(
            children: List.generate(daysInMonth + firstDayIndex, (index) {
              if (index < firstDayIndex) {
                return const SizedBox(width: 45, height: 45);
              }
              final day = index - firstDayIndex + 1;
              final date = DateTime(month.year, month.month, day);
              final isSelectable = _isSelectable(date);
              final isInRange = _isInRange(date);
              final isStart = _isStart(date);
              final isEnd = _isEnd(date);

              return GestureDetector(
                onTap: isSelectable ? () => _onDayTap(date) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 45,
                  height: 45,
                  margin: EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.horizontal(
                      left: isStart ? const Radius.circular(30) : Radius.zero,
                      right: isEnd ? const Radius.circular(30) : Radius.zero,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (endDate != null && (isInRange || isStart || isEnd))
                        Positioned.fill(
                          left: isStart ? 18 : 0,
                          right: isEnd ? 18 : 0,
                          child: Container(
                            color: const Color(0xFFC97A3E).withOpacity(0.15),
                          ),
                        ),
                      if (isStart || isEnd)
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFC97A3E),
                                Color(0xFF6F1D01),
                              ],
                            ),
                          ),
                        ),
                      Text(
                        "$day",
                        style: TextStyle(
                          color: !isSelectable
                              ? Colors.grey.shade400
                              : (isStart || isEnd)
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: isStart || isEnd ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}