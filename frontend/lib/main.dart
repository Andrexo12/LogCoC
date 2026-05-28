import 'package:flutter/material.dart';
import 'features/home/screens/dashboard_screen.dart';
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
