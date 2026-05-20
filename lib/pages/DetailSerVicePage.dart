import 'package:flutter/material.dart';

class ServiceDetailPage extends StatelessWidget {
  final String ten;
  final String loai;
  final String gia;
  final String image;

  const ServiceDetailPage({
    super.key,
    required this.ten,
    required this.loai,
    required this.gia,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        /// 🔥 BACK BUTTON
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF49120F)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        /// 🔥 TITLE CENTER
        centerTitle: true,
        title: const Text(
          "Chi tiết dịch vụ",
          style: TextStyle(
            color: Color(0xFF49120F),
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),


      ),
      /// 🔥 BODY
      body: SafeArea(
        child: Column(
          children: [

            /// CONTENT
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// 🔥 IMAGE
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            image,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),

                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.favorite,
                                color: Colors.red),
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 15),

                    /// 🔥 FEATURES (tuỳ chỉnh theo service)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _feature(Icons.category, loai),
                        _feature(Icons.star, "4.8"),
                        _feature(Icons.access_time, "30 phút"),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// 🔥 TITLE + PRICE
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            ten,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          gia,
                          style: const TextStyle(
                            color: Color(0xFFC97A3E),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    Text(
                      loai,
                      style: const TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 15),

                    /// 🔥 DESCRIPTION
                    const Text(
                      "Mô tả",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      "Dịch vụ chất lượng cao, giúp bạn thư giãn và tận hưởng trải nghiệm tốt nhất.",
                      style: TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 15),

                    /// 🔥 PREVIEW
                    const Text(
                      "Hình ảnh",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      height: 80,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _previewImg(image),
                          _previewImg(image),
                          _previewImg(image),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      /// 🔥 BUTTON
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          height: 55,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFC97A3E),
                Color(0xFF6F1D01),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // TODO: xử lý đặt dịch vụ
            },
            child: const Center(
              child: Text(
                "Đặt dịch vụ",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 🔥 feature
  Widget _feature(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Color(0xFFC97A3E)),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  /// 🔥 preview
  Widget _previewImg(String img) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          img,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}