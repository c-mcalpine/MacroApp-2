import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class ApiClient {
  static const String baseUrl = String.fromEnvironment('API_BASE_URL');
  static final Logger _logger = Logger();

  static void _logEnvVars() {
    if (kDebugMode) {
      _logger.i('ApiClient initialization:');
      _logger.i('API_BASE_URL: $baseUrl');
    }
  }

  static Future<Map<String, dynamic>> testApi() async {
    try {
      _logEnvVars(); // Log when testApi is called
      if (kDebugMode) {
        _logger.i('Testing API connection...');
      }
      final response = await http.get(
        Uri.parse('$baseUrl/test'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (kDebugMode) {
        _logger.i('Test response status code: ${response.statusCode}');
        _logger.i('Test response body: ${response.body}');
      }

      return jsonDecode(response.body);
    } catch (e) {
      if (kDebugMode) {
        _logger.e('Error testing API: $e');
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> sendOTP(String phoneNumber) async {
    try {
      if (kDebugMode) {
        _logger.i('Sending OTP request to: $baseUrl/auth/send-otp');
        _logger.i('Phone number: $phoneNumber');
      }
      
      final uri = Uri.parse('$baseUrl/auth/send-otp');
      if (kDebugMode) {
        _logger.i('Full URI: $uri');
      }
      
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (kDebugMode) {
        _logger.i('Request headers: $headers');
      }
      
      final body = jsonEncode({'phone_number': phoneNumber});
      if (kDebugMode) {
        _logger.i('Request body: $body');
      }
      
      final response = await http.post(
        uri,
        headers: headers,
        body: body,
      );

      if (kDebugMode) {
        _logger.i('Response status code: ${response.statusCode}');
        _logger.i('Response headers: ${response.headers}');
        _logger.i('Response body: ${response.body}');
      }

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to send OTP: ${errorData['error']}${errorData['details'] ? ' - ${errorData['details']}' : ''}');
      }

      return jsonDecode(response.body);
    } catch (e) {
      if (kDebugMode) {
        _logger.e('Error in sendOTP: $e');
        if (e is http.ClientException) {
          _logger.e('Network error details: ${e.message}');
          if (e.message.contains('Failed to fetch')) {
            _logger.e('Possible CORS issue. Check if the API endpoint is accessible and CORS is properly configured.');
            _logger.e('Make sure the API endpoint is accessible at: $baseUrl/auth/send-otp');
          }
        }
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> verifyOTP(
    String phoneNumber,
    String otp, {
    String? username,
  }) async {
    try {
      if (kDebugMode) {
        _logger.i('Verifying OTP for phone: $phoneNumber');
      }
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'phone_number': phoneNumber,
          'otp': otp,
          if (username != null) 'username': username,
        }),
      );

      if (kDebugMode) {
        _logger.i('Verify OTP response status code: ${response.statusCode}');
        _logger.i('Verify OTP response body: ${response.body}');
      }

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to verify OTP: ${errorData['error']}');
      }

      final data = jsonDecode(response.body);
      
      // Ensure all required fields are present
      if (!data.containsKey('success') || !data.containsKey('token') || !data.containsKey('user_id')) {
        throw Exception('Invalid response format from server');
      }

      // Ensure user_name is present, use a default if not
      if (!data.containsKey('user_name')) {
        data['user_name'] = username ?? 'User';
      }

      return data;
    } catch (e) {
      if (kDebugMode) {
        _logger.e('Error in verifyOTP: $e');
        if (e is http.ClientException) {
          _logger.e('Network error details: ${e.message}');
        }
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updateUsername(
    String token,
    String username,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/update-username'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'username': username}),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getAllRecipes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/recipes'),
      headers: {'Content-Type': 'application/json'},
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getRecipeById(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/recipe/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> chatWithRecipe(
    String token,
    String recipeId,
    String message,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/recipe/chat'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'recipe_id': recipeId,
        'message': message,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> searchRecipes(
    String query, {
    double? minProtein,
    double? minCarbs,
    double? minFat,
    double? maxCalories,
  }) async {
    final queryParams = {
      'q': query,
      if (minProtein != null) 'min_protein': minProtein.toString(),
      if (minCarbs != null) 'min_carbs': minCarbs.toString(),
      if (minFat != null) 'min_fat': minFat.toString(),
      if (maxCalories != null) 'max_calories': maxCalories.toString(),
    };

    final response = await http.get(
      Uri.parse('$baseUrl/search').replace(queryParameters: queryParams),
      headers: {'Content-Type': 'application/json'},
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> generateShoppingList(
    String token,
    List<String> ingredients,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/instacart/shopping-list'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'ingredients': ingredients}),
    );

    return jsonDecode(response.body);
  }
} 