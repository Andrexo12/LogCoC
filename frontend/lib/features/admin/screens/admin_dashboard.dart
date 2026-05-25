import 'dart:ui';
import '../../../widgets/glass_effect.dart';
import 'package:flutter/material.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/screens/login_screen.dart';
import 'product_management_screen.dart';
import 'ar_settings_screen.dart';
import 'ai_training_screen.dart';
import 'qr_generator_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    await AuthService().logout();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 768;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1222),
      appBar: AppBar(
        title: const Text(
          'Panel de Administración',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0B1222),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Cerrar Sesión',
            onPressed: () => _handleLogout(context),
          )
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bienvenido, Administrador',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Gestione los productos, códigos QR, configuraciones de AR y entrenamiento de IA.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isDesktop ? 3 : 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.0,
                  children: [
                    _buildAdminCard(
                      context,
                      'Inventario',
                      'Gestionar stock y precios',
                      Icons.inventory_2_outlined,
                      Colors.blueAccent,
                      const ProductManagementScreen(),
                    ),
                    _buildAdminCard(
                      context,
                      'Generar QR',
                      'Generar códigos para productos',
                      Icons.qr_code_2_rounded,
                      Colors.tealAccent,
                      const QrGeneratorScreen(),
                    ),
                    _buildAdminCard(
                      context,
                      'Ajustes AR',
                      'Configurar visualización 3D',
                      Icons.view_in_ar_rounded,
                      Colors.purpleAccent,
                      const ARSettingsScreen(),
                    ),
                    _buildAdminCard(
                      context,
                      'Entrenar IA',
                      'Promociones y campañas',
                      Icons.psychology_outlined,
                      Colors.orangeAccent,
                      const AITrainingScreen(),
                    ),
                    _buildAdminCard(
                      context,
                      'Reportes',
                      'Estadísticas de escaneo',
                      Icons.bar_chart_rounded,
                      Colors.tealAccent,
                      null, // Próximamente
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color accentColor,
    Widget? screen,
  ) {
    final bool isEnabled = screen != null;

    return GestureDetector(
      onTap: isEnabled
          ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Esta función estará disponible próximamente')),
              );
            },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(isEnabled ? 0.05 : 0.02),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(isEnabled ? 0.15 : 0.05),
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: GlassEffect(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 40,
                    color: isEnabled ? accentColor : Colors.white24,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isEnabled ? Colors.white : Colors.white38,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isEnabled ? Colors.white.withOpacity(0.5) : Colors.white12,
                      fontSize: 11,
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
            colors: [
              Color(0xFF0B1222),
              Color(0xFF131D31),
              Color(0xFF1B2A47),
            ],
          ),
        ),
      );
}
