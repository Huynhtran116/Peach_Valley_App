import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'HomePage.dart';

class DatePickerPage extends StatefulWidget {
  const DatePickerPage({super.key});

  @override
  State<DatePickerPage> createState() => _DatePickerPageState();
}

class _DatePickerPageState extends State<DatePickerPage> {
  DateTime? startDate;
  DateTime? endDate;

  final List<DateTime> months = List.generate(
    12,
        (i) => DateTime(DateTime.now().year, DateTime.now().month + i),
  );

  void _onDayTap(DateTime date) {
    setState(() {
      if (startDate == null || (startDate != null && endDate != null)) {
        startDate = date;
        endDate = null;
      } else {
        if (date.isAfter(startDate!)) {
          endDate = date;
        } else {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),

      /// 🔥 APPBAR
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

          /// 🔥 RANGE DISPLAY
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
                  key: ValueKey(startDate.toString() + endDate.toString()), // 🔥 QUAN TRỌNG
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
                      const Icon(Icons.arrow_forward,
                          color: Color(0xFFC97A3E)),
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

          /// 🔥 CALENDAR
          Expanded(
            child: ListView.builder(
              itemCount: months.length,
              itemBuilder: (context, index) {
                return _buildMonth(months[index]);
              },
            ),
          ),

          /// 🔥 FOOTER
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [


                /// 🔥 BUTTON
                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFC97A3E),
                        Color(0xFF6F1D01),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC97A3E)
                            .withOpacity(0.3),
                        blurRadius: 15,
                      )
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "Đặt ngay hôm nay",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  /// 🔥 MONTH
  Widget _buildMonth(DateTime month) {
    final daysInMonth =
    DateUtils.getDaysInMonth(month.year, month.month);
    final firstDay =
        DateTime(month.year, month.month, 1).weekday;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// MONTH TITLE
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

          /// WEEK
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: const ["T2","T3","T4","T5","T6","T7","CN"]
                .map((e) => Expanded(
              child: Center(
                child: Text(
                  e,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ))
                .toList(),
          ),

          const SizedBox(height: 10),

          /// DAYS
          Wrap(
            children: List.generate(
                daysInMonth + firstDay - 1, (index) {
              if (index < firstDay - 1) {
                return const SizedBox(
                    width: 45, height: 45);
              }

              final day = index - (firstDay - 2);
              final date =
              DateTime(month.year, month.month, day);

              final isSelected = _isSelected(date);
              final isInRange = _isInRange(date);

              return GestureDetector(
                onTap: () => _onDayTap(date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 45,
                  height: 45,
                    margin: EdgeInsets.zero,

                  decoration: BoxDecoration(
                    color:  Colors.transparent,
                    borderRadius: BorderRadius.horizontal(
                      left: _isStart(date) ? const Radius.circular(30) : Radius.zero,
                      right: _isEnd(date) ? const Radius.circular(30) : Radius.zero,
                    ),
                  ),

                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      /// RANGE
                      if (endDate != null &&
                          (isInRange || _isStart(date) || _isEnd(date)))
                        Positioned.fill(
                          left: _isStart(date) ? 18 : 0,
                          right: _isEnd(date) ? 18 : 0,
                          child: Container(
                          color: const Color(0xFFC97A3E).withOpacity(0.1),
                          ),
                        ),

                      /// CIRCLE
                      if (_isStart(date) || _isEnd(date))
                        Container(
                          width: 40,
                          height: 40,
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

                      /// TEXT
                      Text(
                        "$day",
                        style: TextStyle(
                          color: (_isStart(date) || _isEnd(date))
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                )
              );
            }),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}