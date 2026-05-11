import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/main_dashboard.dart';
import 'screens/login_screen.dart';
import 'config/firebase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 1. Khởi tạo app mặc định [DEFAULT] để làm hài lòng các plugin hệ thống
    await Firebase.initializeApp(
      options: FirebaseConfig.currentPlatform,
    );

    // 2. Khởi tạo app với tên riêng 'AdminApp' để cô lập hoàn toàn phiên đăng nhập,
    // tránh việc bị đồng bộ tài khoản với App chính trên cùng một thiết bị.
    await Firebase.initializeApp(
      name: 'AdminApp',
      options: FirebaseConfig.currentPlatform,
    );

    // Bắt buộc đăng xuất mỗi khi khởi động lại app Admin để tăng cường bảo mật
    await FirebaseAuth.instanceFor(app: Firebase.app('AdminApp')).signOut();
  } catch (e) {
    print("Firebase init error (possibly missing secrets): $e");
  }
  
  runApp(const ToeicAdminApp());
}

class ToeicAdminApp extends StatelessWidget {
  const ToeicAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TOEIC Tracker Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: FirebaseAuth.instanceFor(app: Firebase.app('AdminApp')).currentUser != null 
          ? const MainDashboard() 
          : const AdminLoginScreen(),
    );
  }
}
