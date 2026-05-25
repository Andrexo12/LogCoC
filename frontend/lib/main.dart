import 'package:flutter/material.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/admin/screens/admin_dashboard.dart';
import 'features/home/screens/dashboard_screen.dart';
import 'features/products/screens/product_detail_screen.dart';
import 'features/catalog/screens/catalog_screen.dart';
import 'features/chatbot/screens/chat_screen.dart';
import 'core/utils/file_picker_stub.dart'
    if (dart.library.html) 'core/utils/file_picker_web_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initFilePicker();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LogCoC Innova Center',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0B1222),
      ),
      home: const DashboardScreen(),
    );
  }
}
