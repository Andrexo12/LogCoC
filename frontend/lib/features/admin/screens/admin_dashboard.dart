import 'package:flutter/material.dart';
import '../../auth/services/auth_service.dart';
import '../../statistics/statistics_screen.dart';
import 'product_management_screen.dart';
import 'qr_generator_screen.dart';
import 'ar_settings_screen.dart';
import 'ai_training_screen.dart';
import 'user_approval_screen.dart';
import 'audit_log_screen.dart';
import 'package:logw_front/core/theme/app_colors.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const StatisticsScreen(),
    const ProductManagementScreen(),
    const QrGeneratorScreen(),
    const ARSettingsScreen(),
    const AITrainingScreen(),
    const UserApprovalScreen(),
    const AuditLogScreen(),
  ];

  Future<void> _handleLogout(BuildContext context) async {
    await AuthService().logout();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    }
  }

  Widget _buildSidebarItem(int index, String title, IconData icon) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.tertiary : AppColors.textMuted),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textMuted,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 768;

    if (!isDesktop) {
      // For mobile, maybe just show a bottom navigation bar or a drawer
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Innova Admin'),
          backgroundColor: AppColors.background,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        drawer: Drawer(
          backgroundColor: AppColors.surface,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: AppColors.background),
                child: Center(
                  child: Image.asset(
                    'assets/images/innova_logo_2.png',
                    height: 35,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback just in case
                      return const Text('INNOVA', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2));
                    },
                  ),
                ),
              ),
              _buildSidebarItem(0, 'Estadísticas', Icons.bar_chart_rounded),
              _buildSidebarItem(1, 'Inventario', Icons.inventory_2_outlined),
              _buildSidebarItem(2, 'Generar QR', Icons.qr_code_2_rounded),
              _buildSidebarItem(3, 'Ajustes AR', Icons.view_in_ar_rounded),
              _buildSidebarItem(4, 'Entrenar IA', Icons.psychology_outlined),
              _buildSidebarItem(5, 'Aceptar Usuarios', Icons.person_add_outlined),
              _buildSidebarItem(6, 'Bitácora', Icons.history_rounded),
              const Divider(color: Colors.white24),
              ListTile(
                leading: const Icon(Icons.storefront_rounded, color: AppColors.info),
                title: const Text('Volver a Inicio', style: TextStyle(color: AppColors.info)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text('Cerrar Sesión', style: TextStyle(color: AppColors.error)),
                onTap: () => _handleLogout(context),
              )
            ],
          ),
        ),
        body: _screens[_selectedIndex],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: AppColors.surface,
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo INNOVA
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Image.asset(
                          'assets/images/innova_logo_2.png',
                          height: 25,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Row(
                              children: const [
                                Icon(Icons.dashboard_customize_rounded, color: AppColors.tertiary, size: 28),
                                SizedBox(width: 12),
                                Text(
                                  'INNOVA',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildSidebarItem(0, 'Dashboard', Icons.bar_chart_rounded),
                      const SizedBox(height: 8),
                      _buildSidebarItem(1, 'Inventario', Icons.inventory_2_outlined),
                      const SizedBox(height: 8),
                      _buildSidebarItem(2, 'Generar QR', Icons.qr_code_2_rounded),
                      const SizedBox(height: 8),
                      _buildSidebarItem(3, 'Ajustes AR', Icons.view_in_ar_rounded),
                      const SizedBox(height: 8),
                      _buildSidebarItem(4, 'Entrenar IA', Icons.psychology_outlined),
                      const SizedBox(height: 8),
                      _buildSidebarItem(5, 'Aceptar Usuarios', Icons.person_add_outlined),
                      const SizedBox(height: 8),
                      _buildSidebarItem(6, 'Bitácora', Icons.history_rounded),
                    ],
                  ),
                ),
                const Spacer(),
                const Divider(color: Colors.white24, indent: 24, endIndent: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.storefront_rounded, color: AppColors.info),
                    title: const Text('Volver a Inicio', style: TextStyle(color: AppColors.textSecondary)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    hoverColor: AppColors.info.withOpacity(0.1),
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                    title: const Text('Cerrar Sesión', style: TextStyle(color: AppColors.textSecondary)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    hoverColor: AppColors.error.withOpacity(0.1),
                    onTap: () => _handleLogout(context),
                  ),
                ),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              ),
              child: Container(
                color: AppColors.background,
                child: _screens[_selectedIndex],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
