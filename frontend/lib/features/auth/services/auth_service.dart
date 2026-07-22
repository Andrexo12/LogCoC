import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api_service.dart';

class AuthService {
  static String get baseUrl => ApiService.baseUrl;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = data['access_token'];
        final user = data['user'] ?? {};
        final role = user['role'] ?? 'scanner';
        final userEmail = user['email'] ?? email;
        
        await _saveAuthData(token, role, userEmail);
        return {'success': true, 'token': token, 'role': role};
      } else {
        return {'success': false, 'message': data['detail'] ?? 'Error desconocido'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<void> _saveAuthData(String token, String role, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
    await prefs.setString('user_role', role);
    await prefs.setString('user_email', email);
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_role');
    await prefs.remove('user_email');
  }

  Future<Map<String, dynamic>> register(String firstName, String lastName, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'password': password,
          'role': 'admin' // Piden registrar administradores para aprobarlos
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Registrado con éxito. Espera aprobación.'};
      } else {
        return {'success': false, 'message': data['detail'] ?? 'Error desconocido'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<List<dynamic>> getPendingUsers() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/auth/pending-users'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('Error al cargar usuarios pendientes: $e');
      return [];
    }
  }

  Future<bool> approveUser(int userId) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/auth/approve-user/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error al aprobar usuario: $e');
      return false;
    }
  }
}
