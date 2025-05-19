import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'https://your-vercel-domain.vercel.app/api';

  static Future<Map<String, dynamic>> sendOTP(String phoneNumber) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone_number': phoneNumber}),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> verifyOTP(
    String phoneNumber,
    String otp, {
    String? username,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone_number': phoneNumber,
        'otp': otp,
        if (username != null) 'username': username,
      }),
    );

    return jsonDecode(response.body);
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