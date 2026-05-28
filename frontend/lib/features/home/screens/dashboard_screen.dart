import '../../../widgets/glass_effect.dart';
import 'package:flutter/material.dart';
import 'package:logw_front/features/catalog/screens/catalog_screen.dart';
import 'package:logw_front/features/chatbot/screens/chat_screen.dart';
import 'package:logw_front/features/qr/screens/qr_scanner_screen.dart';
import 'package:logw_front/features/auth/screens/login_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _handleAdminPanelTap(BuildContext context) async {
    // Siempre llevamos al LoginScreen para que el usuario se autentique como admin
    // La pantalla de Login ya tiene la lógica para redirigir al AdminDashboard si el rol es admin
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen(isFromAdmin: true)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 768;

    return Scaffold(
      body: Stack(
        children: [
          _bg(),
          // Glowing top elements
          Positioned(left: -50, top: -50, child: _glowCircle(200, Colors.indigoAccent.withOpacity(0.12))),
          Positioned(right: -60, top: 120, child: _glowCircle(150, Colors.cyanAccent.withOpacity(0.08))),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: 40),
                  _grid(context, isDesktop),
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
          'INNOVA CENTER',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 3.0,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'LogCoC Experience',
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 80,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.indigoAccent,
            borderRadius: BorderRadius.circular(2),
          ),
        )
      ],
    );
  }

  Widget _grid(BuildContext context, bool isDesktop) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isDesktop ? 4 : 2,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: 1.0,
      children: [
        _card(
          context,
          'Escanear QR',
          'Consulta detalles del producto instantáneamente',
          Icons.qr_code_scanner_rounded,
          Colors.cyanAccent,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QrScannerScreen()),
          ),
        ),
        _card(
          context,
          'Catálogo',
          'Explora productos por categoría y marca',
          Icons.inventory_2_outlined,
          Colors.orangeAccent,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CatalogScreen()),
          ),
        ),
        _card(
          context,
          'Chatbot AI',
          'Resuelve dudas de garantías y promociones',
          Icons.assistant_outlined,
          Colors.pinkAccent,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatScreen()),
          ),
        ),
        _card(
          context,
          'Panel Admin',
          'Gestionar productos, stock y campañas',
          Icons.admin_panel_settings_outlined,
          Colors.indigoAccent,
          () => _handleAdminPanelTap(context),
        ),
      ],
    );
  }

  Widget _card(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color accentColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withOpacity(0.14),
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: GlassEffect(
            sigmaX: 12,
            sigmaY: 12,
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 38,
                    color: accentColor,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                      height: 1.3,
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

  Widget _glowCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _bg() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B1222),
              Color(0xFF131D31),
              Color(0xFF1B2A47),
            ],
          ),
        ),
      );
}
