import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:logw_front/features/admin/screens/admin_dashboard.dart';
import 'package:logw_front/features/catalog/screens/catalog_screen.dart';
import 'package:logw_front/features/chatbot/screens/chat_screen.dart';
import 'package:logw_front/features/qr/screens/qr_scanner_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _bg(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: 40),
                  _grid(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Innova Center',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 18,
            letterSpacing: 1.2,
          ),
        ),
        const Text(
          'LogCoC Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _grid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      children: [
        _card(
          context,
          'Escanear QR',
          Icons.qr_code_scanner,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QrScannerScreen()),
          ),
        ),
        _card(
          context,
          'Catálogo',
          Icons.inventory_2_outlined,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CatalogScreen()),
          ),
        ),
        _card(
          context,
          'Chatbot AI',
          Icons.assistant_outlined,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatScreen()),
          ),
        ),
        _card(
          context,
          'Panel Admin',
          Icons.admin_panel_settings_outlined,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          ),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 40,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bg() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B1222), Color(0xFF1A2A4D)],
          ),
        ),
      );
}
