import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String get baseUrl {
    final Uri uri = Uri.base;
    final String scheme = uri.scheme;
    final String host = uri.host;

    // Check localhost / IP
    if (host == 'localhost' || host == '127.0.0.1') {
      return '$scheme://$host:8000';
    }

    // Dynamic Codespaces port replacing (-5000 to -8000)
    if (host.contains('-5000')) {
      final String backendHost = host.replaceAll('-5000', '-8000');
      return '$scheme://$backendHost';
    }

    // Default fallback
    return 'https://fuzzy-space-capybara-r4r4ggpjwppq3prj5-8000.app.github.dev';
  }

  Future<Map<String, dynamic>> importProductsFile(List<int> fileBytes, String filename) async {
    final token = await _getToken();
    try {
      final uri = Uri.parse('$baseUrl/api/products/import');
      final request = http.MultipartRequest('POST', uri);
      
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      MediaType? contentType;
      final ext = filename.split('.').last.toLowerCase();
      if (ext == 'pdf') {
        contentType = MediaType('application', 'pdf');
      } else if (ext == 'png') {
        contentType = MediaType('image', 'png');
      } else if (ext == 'jpg' || ext == 'jpeg') {
        contentType = MediaType('image', 'jpeg');
      } else if (ext == 'webp') {
        contentType = MediaType('image', 'webp');
      } else if (ext == 'xls') {
        contentType = MediaType('application', 'vnd.ms-excel');
      } else if (ext == 'xlsx') {
        contentType = MediaType('application', 'vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      }

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: filename,
        contentType: contentType,
      );
      request.files.add(multipartFile);
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        Map<String, dynamic> error = {};
        try {
          error = jsonDecode(response.body);
        } catch (_) {}
        return {
          'success': false,
          'message': error['detail'] ?? 'Error al importar archivo',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<Map<String, dynamic>> getProductByQr(String qrId) async {
    final token = await _getToken();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/products/$qrId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['detail'] ?? 'Error desconocido',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  Future<Map<String, dynamic>> askChatbot(String message, {String? qrId}) async {
    final token = await _getToken();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/chatbot/ask'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'message': message,
          'qr_id': qrId,
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'reply': jsonDecode(response.body)['reply'],
        };
      } else {
        return {
          'success': false,
          'message': 'Error al consultar al bot',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  Future<List<dynamic>> getAITraining() async {
    final token = await _getToken();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/ai-training'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error al obtener entrenamiento IA: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> addAITraining(String question, String answer, {String category = 'general'}) async {
    final token = await _getToken();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/ai-training'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'question': question,
          'answer': answer,
          'category': category,
        }),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Guardado con éxito'};
      } else {
        return {'success': false, 'message': 'Error del servidor: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteAITraining(int id) async {
    final token = await _getToken();
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/admin/ai-training/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Eliminado con éxito'};
      } else {
        return {'success': false, 'message': 'Error del servidor: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<List<dynamic>> getProducts({String? type, String? category, String? search}) async {
    final token = await _getToken();
    try {
      final queryParameters = <String, String>{};
      if (type != null && type.isNotEmpty) queryParameters['type'] = type;
      if (category != null && category.isNotEmpty) queryParameters['category'] = category;
      if (search != null && search.isNotEmpty) queryParameters['search'] = search;

      final uri = Uri.parse('$baseUrl/api/products/').replace(queryParameters: queryParameters);
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error al obtener productos: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> productData) async {
    final token = await _getToken();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/products/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(productData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['detail'] ?? 'Error al crear producto',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  Future<Map<String, dynamic>> updateProduct(int productId, Map<String, dynamic> productData) async {
    final token = await _getToken();
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/products/$productId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(productData),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['detail'] ?? 'Error al actualizar producto',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  Future<Map<String, dynamic>> deleteProduct(int productId) async {
    final token = await _getToken();
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/products/$productId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Eliminado con éxito'};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['detail'] ?? 'Error del servidor: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
