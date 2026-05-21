import 'package:flutter/material.dart';
import 'product_management_screen.dart';
import 'ar_settings_screen.dart';
import 'ai_training_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administrador'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildAdminCard(
              context,
              'Productos',
              Icons.inventory,
              Colors.blue,
              const ProductManagementScreen(),
            ),
            _buildAdminCard(
              context,
              'Ajustes AR',
              Icons.view_in_ar,
              Colors.purple,
              const ARSettingsScreen(),
            ),
            _buildAdminCard(
              context,
              'Entrenar IA',
              Icons.psychology,
              Colors.orange,
              const AITrainingScreen(),
            ),
            _buildAdminCard(
              context,
              'Reportes',
              Icons.bar_chart,
              Colors.green,
              null, // Próximamente
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context, String title, IconData icon, Color color, Widget? screen) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: screen != null ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => screen)) : null,
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
