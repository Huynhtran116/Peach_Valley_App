import 'package:flutter/material.dart';

import 'DatePage.dart';
import 'PersonalDataPage.dart';

class BookingDetailPage extends StatefulWidget {
  const BookingDetailPage({super.key});

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {

  DateTime? checkIn;
  DateTime? checkOut;
  String formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
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
                  _iconBtn(Icons.arrow_back, () {
                    Navigator.pop(context);
                  }),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Chi tiết đặt phòng",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            /// 🔥 CONTENT
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// 🔥 PERSONAL DATA
                    _title("Thông tin cá nhân"),
                    const SizedBox(height: 10),
                    _box(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PersonalDataPage(),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text("Kiểm tra"),
                          Icon(Icons.arrow_forward_ios, size: 14),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// 🔥 DATE
                    _titleRow("Ngày", "Chọn ngày"),
                    _box(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DatePage(),
                          ),
                        );

                        if (result != null) {
                          setState(() {
                            checkIn = result['checkIn'];
                            checkOut = result['checkOut'];
                          });
                        }
                      },
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                checkIn != null
                                    ? formatDate(checkIn!)
                                    : "Chọn ngày",
                              ),
                            ],
                          ),
                          Divider(color: Colors.black.withOpacity(0.06)),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                (checkIn != null && checkOut != null)
                                    ? "${checkOut!.difference(checkIn!).inDays} Đêm"
                                    : "0 Đêm",
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// 🔥 CHECK IN / OUT
                    _title("Nhận phòng & Trả phòng"),
                    const SizedBox(height: 10),
                    _box(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DatePage(),
                          ),
                        );

                        if (result != null) {
                          setState(() {
                            checkIn = result['checkIn'];
                            checkOut = result['checkOut'];
                          });
                        }
                      },
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.login, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                checkIn != null
                                    ? formatDate(checkIn!)
                                    : "Chọn ngày nhận phòng",
                              ),
                            ],
                          ),
                          Divider(color: Colors.black.withOpacity(0.06)),
                          Row(
                            children: [
                              const Icon(Icons.logout, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                checkOut != null
                                    ? formatDate(checkOut!)
                                    : "Chọn ngày trả phòng",
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// 🔥 ROOM
                    _titleRow("Thông tin phòng", ""),
                    const SizedBox(height: 10),
                    _box(
                      child: Column(
                        children: const [
                          Row(
                            children: [
                              Icon(Icons.bed, size: 16),
                              SizedBox(width: 6),
                              Text("Family Room"),
                            ],
                          ),
                          Divider(),
                          Row(
                            children: [
                              Icon(Icons.person, size: 16),
                              SizedBox(width: 6),
                              Text("2 Người lớn"),
                            ],
                          ),
                          Divider(),
                          Row(
                            children: [
                              Icon(Icons.child_care, size: 16),
                              SizedBox(width: 6),
                              Text("0 Trẻ em"),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// 🔥 PAYMENT
                    _titleRow("Thanh toán", ""),
                    const SizedBox(height: 10),
                    _box(
                      child: Row(
                        children: const [
                          Icon(Icons.credit_card),
                          SizedBox(width: 8),
                          Text("Master Card"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// 🔥 PRICE
                    _priceRow("Sub total", "\$280"),
                    _priceRow("Tax", "10%"),
                    const SizedBox(height: 5),
                    _priceRow("Total", "\$308", isTotal: true),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      /// 🔥 PAY BUTTON
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFC97A3E),
                Color(0xFF6F1D01),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFC97A3E).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              "Thanh toán",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        )
      ),
    );
  }

  /// 🔥 COMPONENTS

  Widget _title(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: Colors.black87,
      ),
    );
  }

  Widget _titleRow(String text, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _title(text),
        Text(
          action,
          style: const TextStyle(color: Color(0xFFC97A3E)),
        ),
      ],
    );
  }

  Widget _box({
    required Widget child,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.black.withOpacity(0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _priceRow(String title, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              color: isTotal ? Color(0xFFC97A3E) : Colors.black,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon),
      ),
    );
  }
}