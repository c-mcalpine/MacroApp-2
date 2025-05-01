import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';

class ApiService {
  static final String baseUrl = dotenv.env['API_BASE_URL']!;

  // Helper method to get authenticated headers
  static Future<Map<String, String>> _getHeaders() async {
    return await AuthService.getAuthHeaders();
  }

  static Future<List<dynamic>> getRecipes() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/recipes'), headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load recipes');
    }
  }

  static Future<Map<String, dynamic>> getRecipeDetails(int recipeId) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/recipe/$recipeId'), headers: headers);
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
      final response = await http.post(
        Uri.parse('$baseUrl/recipe/$recipeId/chat'),
        headers: headers,
        body: json.encode({"message": message}),
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
    final url = Uri.parse("$baseUrl/instacart/shopping-list"); // Remove redundant '/api' prefix
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({"ingredients": ingredients}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
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
    final response = await http.get(Uri.parse('$baseUrl/recipes/search?q=$query'), headers: headers);
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
    final response = await http.get(Uri.parse('$baseUrl/users/$userId/hearted-recipes'), headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load hearted recipes');
    }
  }

  static Future<bool> heartRecipe(int recipeId) async {
    final headers = await _getHeaders();
    final userId = await AuthService.getUserId();
    final response = await http.post(
      Uri.parse('$baseUrl/users/$userId/heart-recipe'),
      headers: headers,
      body: jsonEncode({"recipe_id": recipeId}),
    );
    return response.statusCode == 200;
  }

  static Future<bool> unheartRecipe(int recipeId) async {
    final headers = await _getHeaders();
    final userId = await AuthService.getUserId();
    final response = await http.post(
      Uri.parse('$baseUrl/users/$userId/unheart-recipe'),
      headers: headers,
      body: jsonEncode({"recipe_id": recipeId}),
    );
    return response.statusCode == 200;
  }

  static Future<List<dynamic>> getUserCustomLists() async {
    final headers = await _getHeaders();
    final userId = await AuthService.getUserId();
    final response = await http.get(Uri.parse('$baseUrl/users/$userId/custom-lists'), headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load custom lists');
    }
  }

  static Future<bool> createCustomList(String listName) async {
    final headers = await _getHeaders();
    final userId = await AuthService.getUserId();
    final response = await http.post(
      Uri.parse('$baseUrl/users/$userId/custom-lists'),
      headers: headers,
      body: jsonEncode({"list_name": listName}),
    );
    return response.statusCode == 200;
  }

  static Future<bool> addRecipeToCustomList(String listId, int recipeId) async {
    final headers = await _getHeaders();
    final userId = await AuthService.getUserId();
    final response = await http.post(
      Uri.parse('$baseUrl/users/$userId/custom-lists/$listId/add-recipe'),
      headers: headers,
      body: jsonEncode({"recipe_id": recipeId}),
    );
    return response.statusCode == 200;
  }
}
