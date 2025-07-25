import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:logger/logger.dart';
import 'auth_service.dart';

class ApiService {
  static final String baseUrl =
      const String.fromEnvironment('API_BASE_URL').replaceAll('/api', '');
  static late final Dio _dio;
  static late final http.Client _httpClient;
  static final Logger _logger = Logger();

  static void init() {
    _httpClient = http.Client();
    
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    // Add interceptors for logging
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (kDebugMode) {
          _logger.i('REQUEST[${options.method}] => PATH: ${options.path}');
          _logger.i('Headers: ${options.headers}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          _logger.i('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
        }
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        if (kDebugMode) {
          _logger.e('ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}');
          _logger.e('Error type: ${e.type}');
          _logger.e('Error message: ${e.message}');
          if (e.response != null) {
            _logger.e('Error response: ${e.response?.data}');
          }
        }
        return handler.next(e);
      },
    ));
  }

  static void _logEnvVars() {
    if (kDebugMode) {
      _logger.i('ApiService initialization:');
      _logger.i('API_BASE_URL: $baseUrl');
      _logger.i('Is Web: $kIsWeb');
    }
  }

  // Helper method to get authenticated headers
  static Future<Map<String, String>> _getHeaders() async {
    _logEnvVars();
    final headers = await AuthService.getAuthHeaders();
    return headers;
  }

  static Future<List<dynamic>> getRecipes() async {
    try {
      if (kDebugMode) {
        _logger.i('Getting recipes from: $baseUrl/api/recipes');
      }
      final headers = await _getHeaders();
      if (kDebugMode) {
        _logger.i('Request headers: $headers');
      }

      if (kIsWeb) {
        // Use http package for web
        final response = await _httpClient.get(
          Uri.parse('$baseUrl/api/recipes'),
          headers: headers,
        );
        
        if (kDebugMode) {
          _logger.i('Response status code: ${response.statusCode}');
          _logger.i('Response headers: ${response.headers}');
          _logger.i('Response body: ${response.body}');
        }
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data is Map<String, dynamic> && data.containsKey('recipes')) {
            return data['recipes'];
          } else if (data is List) {
            return data;
          } else {
            if (kDebugMode) {
              _logger.e('Unexpected response format: $data');
            }
            throw Exception('Unexpected response format');
          }
        } else {
          if (kDebugMode) {
            _logger.e('Failed to load recipes. Status code: ${response.statusCode}');
            _logger.e('Error response: ${response.body}');
          }
          throw Exception('Failed to load recipes: ${response.statusCode}');
        }
      } else {
        // Use dio for mobile
        final response = await _dio.get(
          '/api/recipes',
          options: Options(
            headers: headers,
            validateStatus: (status) => status! < 500,
          ),
        );
        
        if (kDebugMode) {
          _logger.i('Response status code: ${response.statusCode}');
          _logger.i('Response headers: ${response.headers}');
          _logger.i('Response data: ${response.data}');
        }
        
        if (response.statusCode == 200) {
          final data = response.data;
          if (data is Map<String, dynamic> && data.containsKey('recipes')) {
            return data['recipes'];
          } else if (data is List) {
            return data;
          } else {
            if (kDebugMode) {
              _logger.e('Unexpected response format: $data');
            }
            throw Exception('Unexpected response format');
          }
        } else {
          if (kDebugMode) {
            _logger.e('Failed to load recipes. Status code: ${response.statusCode}');
            _logger.e('Error response: ${response.data}');
          }
          throw Exception('Failed to load recipes: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        _logger.e('Exception in getRecipes: $e');
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getRecipeDetails(int recipeId) async {
    final headers = await _getHeaders();
    
    if (kIsWeb) {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/recipe/$recipeId'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Recipe not found');
      }
    } else {
      final response = await _dio.get(
        '/api/recipe/$recipeId',
        options: Options(
          headers: headers,
          validateStatus: (status) => status! < 500,
        ),
      );
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Recipe not found');
      }
    }
  }

  static Future<String> chatWithAI(int recipeId, String message) async {
    try {
      final headers = await _getHeaders();
      final token = await AuthService.getToken();
      if (kDebugMode) {
        _logger.i("Sending recipeId: $recipeId with message: $message");
      }
      
      if (kIsWeb) {
        final response = await _httpClient.post(
          Uri.parse('$baseUrl/api/recipe/chat'),
          headers: headers,
          body: json.encode({
            "recipe_id": recipeId,
            "message": message,
            if (token != null) "token": token,
          }),
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return data["response"];
        } else if (response.statusCode == 404) {
          if (kDebugMode) {
            _logger.e("Error: Recipe not found for recipeId: $recipeId");
          }
          throw Exception('Recipe not found');
        } else {
          if (kDebugMode) {
            _logger.e("Error: ${response.statusCode}, Body: ${response.body}");
          }
          throw Exception('AI chat failed');
        }
      } else {
        final response = await _dio.post(
          '/api/recipe/chat',
          options: Options(
            headers: headers,
            validateStatus: (status) => status! < 500,
          ),
          data: {
            "recipe_id": recipeId,
            "message": message,
            if (token != null) "token": token,
          },
        );
        
        if (response.statusCode == 200) {
          return response.data["response"];
        } else if (response.statusCode == 404) {
          if (kDebugMode) {
            _logger.e("Error: Recipe not found for recipeId: $recipeId");
          }
          throw Exception('Recipe not found');
        } else {
          if (kDebugMode) {
            _logger.e("Error: ${response.statusCode}, Body: ${response.data}");
          }
          throw Exception('AI chat failed');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        _logger.e("Exception during chatWithAI: $e");
      }
      throw Exception('AI chat failed');
    }
  }

  static Future<String?> getInstacartShoppingList(List<dynamic> ingredients) async {
    try {
      final headers = await _getHeaders();
      final token = await AuthService.getToken();
      
      if (kIsWeb) {
        final response = await _httpClient.post(
          Uri.parse('$baseUrl/api/instacart/shopping-list'),
          headers: headers,
          body: json.encode({
            "ingredients": ingredients,
            if (token != null) "token": token,
          }),
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return data["shopping_list_url"];
        } else {
          if (kDebugMode) {
            _logger.e("Error: ${response.statusCode}, Body: ${response.body}");
          }
          return null;
        }
      } else {
        final response = await _dio.post(
          '/api/instacart/shopping-list',
          options: Options(
            headers: headers,
            validateStatus: (status) => status! < 500,
          ),
          data: {
            "ingredients": ingredients,
            if (token != null) "token": token,
          },
        );
        
        if (response.statusCode == 200) {
          return response.data["shopping_list_url"];
        } else {
          if (kDebugMode) {
            _logger.e("Error: ${response.statusCode}, Body: ${response.data}");
          }
          return null;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        _logger.e("Exception: $e");
      }
      return null;
    }
  }

  static Future<List<dynamic>> searchRecipes(String query) async {
    final headers = await _getHeaders();
    
    if (kIsWeb) {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/search').replace(queryParameters: {'q': query}),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load recipes');
      }
    } else {
      final response = await _dio.get(
        '/api/search',
        options: Options(
          headers: headers,
          validateStatus: (status) => status! < 500,
        ),
        queryParameters: {'q': query},
      );
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load recipes');
      }
    }
  }

  // User-specific API calls
  static Future<List<dynamic>> getUserHeartedRecipes() async {
    final headers = await _getHeaders();
    final userId = await AuthService.getUserId();
    
    if (kIsWeb) {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/users/$userId/hearted-recipes'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load hearted recipes');
      }
    } else {
      final response = await _dio.get(
        '/api/users/$userId/hearted-recipes',
        options: Options(
          headers: headers,
          validateStatus: (status) => status! < 500,
        ),
      );
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load hearted recipes');
      }
    }
  }

  static Future<bool> heartRecipe(int recipeId) async {
    final headers = await _getHeaders();
    final userId = await AuthService.getUserId();
    
    if (kIsWeb) {
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/users/$userId/heart-recipe'),
        headers: headers,
        body: json.encode({"recipe_id": recipeId}),
      );
      
      return response.statusCode == 200;
    } else {
      final response = await _dio.post(
        '/api/users/$userId/heart-recipe',
        options: Options(
          headers: headers,
          validateStatus: (status) => status! < 500,
        ),
        data: {"recipe_id": recipeId},
      );
      
      return response.statusCode == 200;
    }
  }

  static Future<bool> unheartRecipe(int recipeId) async {
    final headers = await _getHeaders();
    final userId = await AuthService.getUserId();
    
    if (kIsWeb) {
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/users/$userId/unheart-recipe'),
        headers: headers,
        body: json.encode({"recipe_id": recipeId}),
      );
      
      return response.statusCode == 200;
    } else {
      final response = await _dio.post(
        '/api/users/$userId/unheart-recipe',
        options: Options(
          headers: headers,
          validateStatus: (status) => status! < 500,
        ),
        data: {"recipe_id": recipeId},
      );
      
      return response.statusCode == 200;
    }
  }

  static Future<List<dynamic>> getUserCustomLists() async {
    final headers = await _getHeaders();
    final userId = await AuthService.getUserId();
    
    if (kIsWeb) {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/users/$userId/custom-lists'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load custom lists');
      }
    } else {
      final response = await _dio.get(
        '/api/users/$userId/custom-lists',
        options: Options(
          headers: headers,
          validateStatus: (status) => status! < 500,
        ),
      );
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load custom lists');
      }
    }
  }

  static Future<bool> createCustomList(String listName) async {
    final headers = await _getHeaders();
    final userId = await AuthService.getUserId();
    
    if (kIsWeb) {
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/users/$userId/custom-lists'),
        headers: headers,
        body: json.encode({"list_name": listName}),
      );
      
      return response.statusCode == 200;
    } else {
      final response = await _dio.post(
        '/api/users/$userId/custom-lists',
        options: Options(
          headers: headers,
          validateStatus: (status) => status! < 500,
        ),
        data: {"list_name": listName},
      );
      
      return response.statusCode == 200;
    }
  }

  static Future<bool> addRecipeToCustomList(String listId, int recipeId) async {
    final headers = await _getHeaders();
    final userId = await AuthService.getUserId();
    
    if (kIsWeb) {
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/users/$userId/custom-lists/$listId/add-recipe'),
        headers: headers,
        body: json.encode({"recipe_id": recipeId}),
      );
      
      return response.statusCode == 200;
    } else {
      final response = await _dio.post(
        '/api/users/$userId/custom-lists/$listId/add-recipe',
        options: Options(
          headers: headers,
          validateStatus: (status) => status! < 500,
        ),
        data: {"recipe_id": recipeId},
      );
      
      return response.statusCode == 200;
    }
  }
}
