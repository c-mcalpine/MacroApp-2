import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';

class ApiService {
  static final String baseUrl = dotenv.env['API_BASE_URL']!.replaceAll('/api', '');
  static final http.Client _client = http.Client();

  static void _logEnvVars() {
    print('ApiService initialization:');
    print('API_BASE_URL: ${dotenv.env['API_BASE_URL']}');
    print('Base URL after processing: $baseUrl');
    print('All env vars: ${dotenv.env}');
  }

  // Helper method to get authenticated headers
  static Future<Map<String, String>> _getHeaders() async {
    _logEnvVars(); // Log when headers are requested
    final headers = await AuthService.getAuthHeaders();
    headers.addAll({
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    });
    return headers;
  }

  static Future<List<dynamic>> getRecipes() async {
    try {
      print('Getting recipes from: $baseUrl/api/recipes');
      final headers = await _getHeaders();
      print('Request headers: $headers');
      
      final response = await _client.get(
        Uri.parse('$baseUrl/api/recipes'),
        headers: headers,
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );
      
      print('Response status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic> && data.containsKey('recipes')) {
          return data['recipes'];
        } else if (data is List) {
          return data;
        } else {
          print('Unexpected response format: $data');
          throw Exception('Unexpected response format');
        }
      } else {
        print('Failed to load recipes. Status code: ${response.statusCode}');
        print('Error response: ${response.body}');
        throw Exception('Failed to load recipes: ${response.statusCode}');
      }
    } on TimeoutException {
      print('Request timed out');
      throw Exception('Request timed out');
    } catch (e) {
      print('Exception in getRecipes: $e');
      if (e is http.ClientException) {
        print('Network error details: ${e.message}');
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getRecipeDetails(int recipeId) async {
    final headers = await _getHeaders();
    final response = await _client.get(
      Uri.parse('$baseUrl/api/recipe/$recipeId'),
      headers: headers,
    ).timeout(
      Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('Request timed out');
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Recipe not found');
    }
  }

  static Future<String> chatWithAI(int recipeId, String message) async {
    try {
      final headers = await _getHeaders();
      print("Sending recipeId: $recipeId with message: $message"); // Log recipeId and message
      final response = await _client.post(
        Uri.parse('$baseUrl/api/recipe/$recipeId/chat'),
        headers: headers,
        body: json.encode({"message": message}),
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)["response"];
      } else if (response.statusCode == 404) {
        print("Error: Recipe not found for recipeId: $recipeId");
        throw Exception('Recipe not found');
      } else {
        print("Error: ${response.statusCode}, Body: ${response.body}");
        throw Exception('AI chat failed');
      }
    } catch (e) {
      print("Exception during chatWithAI: $e");
      throw Exception('AI chat failed');
    }
  }

  static Future<String?> getInstacartShoppingList(List<dynamic> ingredients) async {
    final url = Uri.parse("$baseUrl/api/instacart/shopping-list");
    try {
      final headers = await _getHeaders();
      final response = await _client.post(
        Uri.parse('$baseUrl/api/instacart/shopping-list'),
        headers: headers,
        body: json.encode({"ingredients": ingredients}),
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data["shopping_list_url"];
      } else {
        print("Error: ${response.statusCode}, Body: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception: $e");
      return null;
    }
  }

  static Future<List<dynamic>> searchRecipes(String query) async {
    final headers = await _getHeaders();
    final response = await _client.get(
      Uri.parse('$baseUrl/api/recipes/search?q=$query'),
      headers: headers,
    ).timeout(
      Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('Request timed out');
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load recipes');
    }
  }

  // User-specific API calls
  static Future<List<dynamic>> getUserHeartedRecipes() async {
    final headers = await _getHeaders();
    final userId = await AuthService.getUserId();
    final response = await _client.get(
      Uri.parse('$baseUrl/api/users/$userId/hearted-recipes'),
      headers: headers,
    ).timeout(
      Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('Request timed out');
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load hearted recipes');
    }
  }

  static Future<bool> heartRecipe(int recipeId) async {
    final headers = await _getHeaders();
    final userId = await AuthService.getUserId();
    final response = await _client.post(
      Uri.parse('$baseUrl/api/users/$userId/heart-recipe'),
      headers: headers,
      body: json.encode({"recipe_id": recipeId}),
    ).timeout(
      Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('Request timed out');
      },
    );
    return response.statusCode == 200;
  }

  static Future<bool> unheartRecipe(int recipeId) async {
    final headers = await _getHeaders();
    final userId = await AuthService.getUserId();
    final response = await _client.post(
      Uri.parse('$baseUrl/api/users/$userId/unheart-recipe'),
      headers: headers,
      body: json.encode({"recipe_id": recipeId}),
    ).timeout(
      Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('Request timed out');
      },
    );
    return response.statusCode == 200;
  }

  static Future<List<dynamic>> getUserCustomLists() async {
    final headers = await _getHeaders();
    final userId = await AuthService.getUserId();
    final response = await _client.get(
      Uri.parse('$baseUrl/api/users/$userId/custom-lists'),
      headers: headers,
    ).timeout(
      Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('Request timed out');
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load custom lists');
    }
  }

  static Future<bool> createCustomList(String listName) async {
    final headers = await _getHeaders();
    final userId = await AuthService.getUserId();
    final response = await _client.post(
      Uri.parse('$baseUrl/api/users/$userId/custom-lists'),
      headers: headers,
      body: json.encode({"list_name": listName}),
    ).timeout(
      Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('Request timed out');
      },
    );
    return response.statusCode == 200;
  }

  static Future<bool> addRecipeToCustomList(String listId, int recipeId) async {
    final headers = await _getHeaders();
    final userId = await AuthService.getUserId();
    final response = await _client.post(
      Uri.parse('$baseUrl/api/users/$userId/custom-lists/$listId/add-recipe'),
      headers: headers,
      body: json.encode({"recipe_id": recipeId}),
    ).timeout(
      Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('Request timed out');
      },
    );
    return response.statusCode == 200;
  }
}
