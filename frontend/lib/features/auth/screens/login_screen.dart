import '../../../widgets/glass_effect.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../../home/screens/dashboard_screen.dart';
import '../../admin/screens/admin_dashboard.dart';
import 'package:logw_front/core/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  final bool isFromAdmin;
  const LoginScreen({super.key, this.isFromAdmin = false});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true, _rememberMe = true, _isLoading = false;
  bool _isLogin = true; // Toggle between Login and Register
  final _emailController = TextEditingController(),
      _passController = TextEditingController(),
      _firstNameController = TextEditingController(),
      _lastNameController = TextEditingController();
  final _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMsg('Por favor rellena todos los campos requeridos');
      return;
    }
    
    if (!_isLogin) {
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      if (firstName.isEmpty || lastName.isEmpty) {
        _showMsg('Por favor introduce tu nombre y apellido');
        return;
      }
      setState(() => _isLoading = true);
      final result = await _authService.register(firstName, lastName, email, password);
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (result['success']) {
        _showMsg(result['message'] ?? 'Registro exitoso. Espera aprobación.');
        setState(() => _isLogin = true); // Vuelve a login
      } else {
        _showMsg('Error: ${result['message']}');
      }
      return;
    }

    setState(() => _isLoading = true);
    
    final result = await _authService.login(email, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      _showMsg('¡Bienvenido!');
      if (!mounted) return;
      
      final String role = result['role'] ?? 'scanner';
      
      if (role == 'admin' || widget.isFromAdmin) {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/');
      }
    } else {
      _showMsg('Error: ${result['message']}');
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          _bg(),
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacementNamed(context, '/');
                    }
                  },
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: Container(
                width: size.width > 600 ? 520 : double.infinity,
                constraints: const BoxConstraints(maxWidth: 520),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 255, 255, 0.08),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: const Color.fromRGBO(255, 255, 255, 0.18),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.35),
                      blurRadius: 32,
                      offset: Offset(0, 20),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: GlassEffect(
                    sigmaX: 18,
                    sigmaY: 18,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 34,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 12),
                          Text(
                            _isLogin ? 'Iniciar Sesión' : 'Registro de Admin',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _isLogin ? 'BIENVENIDO DE NUEVO' : 'CREA TU CUENTA PARA ADMINISTRAR',
                            style: const TextStyle(
                              color: Color.fromRGBO(255, 255, 255, 0.72),
                              fontSize: 12,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 32),
                          if (!_isLogin) ...[
                            _buildTextField('Nombre', Icons.person_outline, _firstNameController, false),
                            const SizedBox(height: 18),
                            _buildTextField('Apellido', Icons.person_outline, _lastNameController, false),
                            const SizedBox(height: 18),
                          ],
                          _buildTextField(
                            'Email',
                            Icons.email_outlined,
                            _emailController,
                            false,
                          ),
                          const SizedBox(height: 18),
                          _buildTextField(
                            'Contraseña',
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            _passController,
                            _obscurePassword,
                            () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                          ),
                          if (_isLogin) ...[
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _rememberMe = !_rememberMe),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: _rememberMe
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.textSecondary,
                                        width: 1.2,
                                      ),
                                    ),
                                    child: _rememberMe
                                        ? const Icon(
                                            Icons.check,
                                            size: 18,
                                            color: AppColors.background,
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Recordarme',
                                  style: TextStyle(
                                    color: Color.fromRGBO(255, 255, 255, 0.87),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 24),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromRGBO(255, 255, 255, 0.9),
                              foregroundColor: AppColors.background,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _isLoading ? null : _handleAuth,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.background,
                                      ),
                                    ),
                                  )
                                : Text(
                                    _isLogin ? 'Entrar' : 'Registrarse',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              setState(() => _isLogin = !_isLogin);
                            },
                            child: Text(
                              _isLogin ? '¿No tienes cuenta? Regístrate' : '¿Ya tienes cuenta? Inicia Sesión',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller,
    bool obscure, [
    VoidCallback? onIconTap,
  ]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color.fromRGBO(255, 255, 255, 0.75),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            hintText: label,
            hintStyle: const TextStyle(
              color: Color.fromRGBO(255, 255, 255, 0.55),
            ),
            filled: true,
            fillColor: const Color.fromRGBO(255, 255, 255, 0.08),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            suffixIcon: GestureDetector(
              onTap: onIconTap,
              child: Icon(
                icon,
                color: const Color.fromRGBO(255, 255, 255, 0.72),
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color.fromRGBO(255, 255, 255, 0.18),
                width: 1.1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color.fromRGBO(255, 255, 255, 0.18),
                width: 1.1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color.fromRGBO(255, 255, 255, 0.28),
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bg() => Stack(
    children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, Color(0xFF151F36)],
          ),
        ),
      ),
      Positioned(left: -80, top: -80, child: _circle(240, 0.12)),
      Positioned(right: -60, top: 100, child: _circle(120, 0.14)),
      Positioned(right: -80, bottom: -80, child: _circle(260, 0.1)),
    ],
  );

  Widget _circle(double size, double opacity) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Color.fromRGBO(255, 255, 255, opacity),
      shape: BoxShape.circle,
    ),
  );
}

