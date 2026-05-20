import 'package:flutter/material.dart';

class DatePage extends StatefulWidget {
  const DatePage({super.key});

  @override
  State<DatePage> createState() => _DatePageState();
}

class _DatePageState extends State<DatePage> {
  DateTime? checkIn;
  DateTime? checkOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),

      body: SafeArea(
        child: Column(
          children: [

            /// 🔥 APP BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  _iconBtn(Icons.arrow_back_ios, () {
                    Navigator.pop(context);
                  }),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Chọn ngày",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF49120F),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            /// 🔥 CONTENT
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [

                    /// 🔥 CHECK IN / OUT BOX
                    Row(
                      children: [
                        Expanded(
                          child: _dateBox(
                            title: "Ngày nhận phòng",
                            date: checkIn,
                            isActive: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _dateBox(
                            title: "Ngày trả phòng",
                            date: checkOut,
                            isActive: false,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// 🔥 CALENDAR
                    Expanded(
                      child: CalendarDatePicker(
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        onDateChanged: (date) {
                          setState(() {
                            if (checkIn == null || (checkIn != null && checkOut != null)) {
                              checkIn = date;
                              checkOut = null;
                            } else {
                              if (date.isAfter(checkIn!)) {
                                checkOut = date;
                              } else {
                                checkIn = date;
                                checkOut = null;
                              }
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// 🔥 DONE BUTTON
            Padding(
              padding: const EdgeInsets.all(20),
              child: _doneButton(),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= UI =================

  Widget _dateBox({
    required String title,
    required DateTime? date,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? Colors.green
              : Colors.red,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16),
              const SizedBox(width: 6),
              Text(
                date != null
                    ? "${date.day}/${date.month}/${date.year}"
                    : "Chọn ngày",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _doneButton() {
    final isValid = checkIn != null && checkOut != null;

    return GestureDetector(
      onTap: isValid
          ? () {
        Navigator.pop(context, {
          'checkIn': checkIn,
          'checkOut': checkOut,
        });
      }
          : null,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: isValid
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
          borderRadius: BorderRadius.circular(18),
          boxShadow: isValid
              ? [
            BoxShadow(
              color: const Color(0xFFC97A3E).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ]
              : [],
        ),
        child: Center(
          child: Text(
            "Xác nhận",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon),
      ),
    );
  }
}