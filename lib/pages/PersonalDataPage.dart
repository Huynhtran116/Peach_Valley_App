import 'package:flutter/material.dart';

class PersonalDataPage extends StatelessWidget {
  const PersonalDataPage({super.key});

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
                        "Personal data",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// 🔥 PERSONAL DATA
                    _sectionTitle("Personal data"),
                    _card(
                      child: Column(
                        children: [
                          _infoItem(
                            icon: Icons.person_outline,
                            title: "Full name",
                            value: "Fin McMissile",
                          ),
                          _divider(),

                          _infoItem(
                            icon: Icons.location_on_outlined,
                            title: "Address",
                            value: "Oklahoma city 311, Oklahoma, USA",
                          ),
                          _divider(),

                          _infoItem(
                            icon: Icons.credit_card_outlined,
                            title: "ID number",
                            value: "15987615791",
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// 🔥 CONTACT
                    _sectionTitle("Contact"),
                    _card(
                      child: Column(
                        children: [
                          _infoItem(
                            icon: Icons.email_outlined,
                            title: "Email",
                            value: "abc***@gmail.com",
                          ),
                          _divider(),

                          _infoItem(
                            icon: Icons.phone_outlined,
                            title: "Phone number",
                            value: "0824-***-7890",
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= COMPONENTS =================

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black.withOpacity(0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _infoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.black54),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 20,
      color: Colors.black.withOpacity(0.06),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: Colors.black87,
        ),
      ),
    );
  }
}