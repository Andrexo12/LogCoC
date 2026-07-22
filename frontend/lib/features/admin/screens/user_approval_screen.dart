import 'package:flutter/material.dart';
import '../../auth/services/auth_service.dart';
import 'package:logw_front/core/theme/app_colors.dart';

class UserApprovalScreen extends StatefulWidget {
  const UserApprovalScreen({super.key});

  @override
  State<UserApprovalScreen> createState() => _UserApprovalScreenState();
}

class _UserApprovalScreenState extends State<UserApprovalScreen> {
  final _authService = AuthService();
  List<dynamic> _pendingUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await _authService.getPendingUsers();
    setState(() {
      _pendingUsers = users;
      _isLoading = false;
    });
  }

  Future<void> _approveUser(int userId) async {
    final success = await _authService.approveUser(userId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario aprobado correctamente')),
      );
      _loadUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al aprobar usuario')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Aceptar Usuarios', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.tertiary))
          : _pendingUsers.isEmpty
              ? const Center(
                  child: Text('No hay usuarios pendientes',
                      style: TextStyle(color: Colors.white70)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingUsers.length,
                  itemBuilder: (context, index) {
                    final u = _pendingUsers[index];
                    return Card(
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.tertiary,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          u['email'] ?? '',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: ElevatedButton.icon(
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Aprobar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _approveUser(u['id']),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
