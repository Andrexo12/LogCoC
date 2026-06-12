import 'package:flutter/material.dart';
import 'features/home/screens/dashboard_screen.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/admin/screens/admin_dashboard.dart';
import 'features/admin/screens/product_management_screen.dart';
import 'features/admin/screens/qr_generator_screen.dart';
import 'features/admin/screens/ar_settings_screen.dart';
import 'features/admin/screens/ai_training_screen.dart';
import 'features/catalog/screens/catalog_screen.dart';
import 'features/chatbot/screens/chat_screen.dart';
import 'features/qr/screens/qr_scanner_screen.dart';
import 'features/products/screens/product_detail_screen.dart';
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
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');
        
        // Handle dynamic product detail route: /product/:qrId
        if (uri.pathSegments.length == 2 && uri.pathSegments.first == 'product') {
          final qrId = uri.pathSegments[1];
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => ProductDetailScreen(qrId: qrId),
          );
        }

        switch (uri.path) {
          case '/':
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const DashboardScreen(),
            );
          case '/qr-scanner':
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const QrScannerScreen(),
            );
          case '/catalog':
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const CatalogScreen(),
            );
          case '/chatbot':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => ChatScreen(
                productContextId: args?['qrId'],
                productName: args?['name'],
              ),
            );
          case '/login':
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const LoginScreen(isFromAdmin: false),
            );
          case '/admin-login':
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const LoginScreen(isFromAdmin: true),
            );
          case '/admin':
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const AdminGuard(child: AdminDashboard()),
            );
          case '/admin/products':
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const AdminGuard(child: ProductManagementScreen()),
            );
          case '/admin/qr-generator':
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const AdminGuard(child: QrGeneratorScreen()),
            );
          case '/admin/ar-settings':
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const AdminGuard(child: ARSettingsScreen()),
            );
          case '/admin/ai-training':
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const AdminGuard(child: AITrainingScreen()),
            );
          default:
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const DashboardScreen(),
            );
        }
      },
    );
  }
}

class AdminGuard extends StatefulWidget {
  final Widget child;
  const AdminGuard({super.key, required this.child});

  @override
  State<AdminGuard> createState() => _AdminGuardState();
}

class _AdminGuardState extends State<AdminGuard> {
  bool _checking = true;
  bool _authorized = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authService = AuthService();
    final role = await authService.getRole();
    final token = await authService.getToken();

    if (token != null && role == 'admin') {
      if (mounted) {
        setState(() {
          _authorized = true;
          _checking = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _authorized = false;
          _checking = false;
        });
        Navigator.pushReplacementNamed(context, '/admin-login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.indigoAccent),
          ),
        ),
      );
    }
    return _authorized ? widget.child : const SizedBox.shrink();
  }
}

