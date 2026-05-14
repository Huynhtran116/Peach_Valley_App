import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:hotel_app/pages/HomePage.dart';
import 'package:hotel_app/pages/SignUpPage.dart';
import 'package:hotel_app/pages/onboarding.dart';
import 'package:hotel_app/pages/BookingHistoryPage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi', null);
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _initDeepLink();
  }

  void _initDeepLink() {
    _appLinks = AppLinks();

    // Bắt link khi app mở lần đầu (từ VNPay redirect về)
    _appLinks.getInitialLink().then((Uri? uri) {
      if (uri != null) _handleDeepLink(uri);
    });

    // Bắt link khi app đang chạy
    _appLinks.uriLinkStream.listen((Uri uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    print('📱 Deep link: $uri');

    if (uri.scheme == 'peachvalley' && uri.host == 'vnpay-result') {
      String? status = uri.queryParameters['status'];

      // Đợi 1 chút để context sẵn sàng
      Future.delayed(const Duration(milliseconds: 500), () {
        if (status == 'success') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const BookingHistoryPage()),
                (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thanh toán thất bại! Vui lòng thử lại.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Peach Valley Hotel',
      theme: ThemeData(
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: Colors.white,
      ),
      locale: const Locale('vi'),
      supportedLocales: const [
        Locale('vi'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const OnboardingPage(),
    );
  }
}