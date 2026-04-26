import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true, _rememberMe = true, _isLoading = false;
  final _emailController = TextEditingController(),
      _passController = TextEditingController();
  final _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMsg('Por favor rellena todos los campos');
      return;
    }

    setState(() => _isLoading = true);
    
    final result = await _authService.login(email, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      _showMsg('¡Bienvenido!');
      // Aquí podrías navegar a la siguiente pantalla:
      // Navigator.pushReplacementNamed(context, '/home');
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
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 34,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 12),
                          const Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'WELCOME BACK PLEASE LOGIN TO YOUR ACCOUNT',
                            style: TextStyle(
                              color: Color.fromRGBO(255, 255, 255, 0.72),
                              fontSize: 12,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 32),
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
                                      color: Colors.white70,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: _rememberMe
                                      ? const Icon(
                                          Icons.check,
                                          size: 18,
                                          color: Color(0xFF0B1222),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Remember Me',
                                style: TextStyle(
                                  color: Color.fromRGBO(255, 255, 255, 0.87),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromRGBO(
                                255,
                                255,
                                255,
                                0.9,
                              ),
                              foregroundColor: const Color(0xFF0B1222),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _isLoading ? null : _handleLogin,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF0B1222),
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Entrar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                foregroundColor: const Color.fromRGBO(
                                  255,
                                  255,
                                  255,
                                  0.72,
                                ),
                              ),
                              child: const Text('Forgot Password'),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Center(
                            child: Text(
                              "Don't Have an account? Signup",
                              style: TextStyle(
                                color: Color.fromRGBO(255, 255, 255, 0.68),
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
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
            colors: [Color(0xFF0B1222), Color(0xFF151F36)],
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
