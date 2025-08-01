import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

class SupabaseService {
  static SupabaseClient? _client;
  static bool _isInitialized = false;
  static final Logger _logger = Logger();
  
  // Initialize Supabase client
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _client = Supabase.instance.client;
      _isInitialized = true;
      
      // Test the connection
      try {
        final response = await _client!.from('users').select().limit(1);
        _logger.i('Successfully connected to Supabase. Test query response: $response');
      } catch (e) {
        _logger.w('Connected to Supabase but test query failed: $e');
      }
    } catch (e) {
      _logger.e('Error initializing Supabase: $e');
      _isInitialized = false;
    }
  }
  
  // Get Supabase client
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase client not initialized. Call SupabaseService.initialize() first.');
    }
    return _client!;
  }
  
  // Get user by phone number
  static Future<Map<String, dynamic>?> getUserByPhone(String phoneNumber) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final response = await _client!.from('users').select().eq('phone_number', phoneNumber).single();
      return response;
    } catch (e) {
      if (e.toString().contains('relation "users" does not exist')) {
        _logger.e('ERROR: The users table does not exist in your Supabase database.');
        _logger.e('Please create the table in your Supabase dashboard with the following SQL:');
        _logger.e('''
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  phone_number TEXT UNIQUE NOT NULL,
  name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
''');
      } else {
        _logger.e('Error getting user by phone: $e');
      }
      return null;
    }
  }
  
  // Create a new user
  static Future<Map<String, dynamic>?> createUser(String phoneNumber, String name) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final response = await _client!.from('users').insert({
        'phone_number': phoneNumber,
        'name': name,
      }).select().single();
      
      return response;
    } catch (e) {
      if (e.toString().contains('duplicate key value violates unique constraint')) {
        _logger.e('ERROR: A user with this phone number already exists.');
      } else if (e.toString().contains('relation "users" does not exist')) {
        _logger.e('ERROR: The users table does not exist in your Supabase database.');
        _logger.e('Please create the table in your Supabase dashboard with the following SQL:');
        _logger.e('''
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  phone_number TEXT UNIQUE NOT NULL,
  name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
''');
      } else {
        _logger.e('Error creating user: $e');
      }
      return null;
    }
  }
  
  // Update user's name
  static Future<Map<String, dynamic>?> updateUsername(String phoneNumber, String newName) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final response = await _client!.from('users')
          .update({'name': newName})
          .eq('phone_number', phoneNumber)
          .select()
          .single();
      
      return response;
    } catch (e) {
      if (e.toString().contains('relation "users" does not exist')) {
        _logger.e('ERROR: The users table does not exist in your Supabase database.');
        _logger.e('Please create the table in your Supabase dashboard with the following SQL:');
        _logger.e('''
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  phone_number TEXT UNIQUE NOT NULL,
  name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
''');
      } else {
        _logger.e('Error updating user name: $e');
      }
      return null;
    }
  }
  
  // Recipe operations
  static Future<List<Map<String, dynamic>>> getHeartedRecipes(String userId) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      // Get the user by phone number first
      final user = await getUserByPhone(userId);
      if (user == null) {
        _logger.w('User not found for phone number: $userId');
        return [];
      }
      
      final response = await client
          .from('hearted_recipes')
          .select('recipe_id, recipes(*)')
          .eq('user_id', user['id']);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _logger.e('Error getting hearted recipes: $e');
      return [];
    }
  }
  
  static Future<bool> heartRecipe(String userId, int recipeId) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      // Get the user by phone number first
      final user = await getUserByPhone(userId);
      if (user == null) {
        _logger.w('User not found for phone number: $userId');
        return false;
      }
      
      await client
          .from('hearted_recipes')
          .insert({
            'user_id': user['id'],
            'recipe_id': recipeId,
            'created_at': DateTime.now().toIso8601String(),
          });
      
      return true;
    } catch (e) {
      _logger.e('Error hearting recipe: $e');
      return false;
    }
  }
  
  static Future<bool> unheartRecipe(String userId, int recipeId) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      // Get the user by phone number first
      final user = await getUserByPhone(userId);
      if (user == null) {
        _logger.w('User not found for phone number: $userId');
        return false;
      }
      
      await client
          .from('hearted_recipes')
          .delete()
          .eq('user_id', user['id'])
          .eq('recipe_id', recipeId);
      
      return true;
    } catch (e) {
      _logger.e('Error unhearting recipe: $e');
      return false;
    }
  }
  
  // Custom lists operations
  static Future<List<Map<String, dynamic>>> getCustomLists(String userId) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      // Get the user by phone number first
      final user = await getUserByPhone(userId);
      if (user == null) {
        _logger.w('User not found for phone number: $userId');
        return [];
      }
      
      final response = await client
          .from('custom_lists')
          .select()
          .eq('user_id', user['id']);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _logger.e('Error getting custom lists: $e');
      return [];
    }
  }
  
  static Future<Map<String, dynamic>> createCustomList({
    required String userId,
    required String listName,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      // Get the user by phone number first
      final user = await getUserByPhone(userId);
      if (user == null) {
        _logger.w('User not found for phone number: $userId');
        throw Exception('User not found');
      }
      
      final response = await client
          .from('custom_lists')
          .insert({
            'user_id': user['id'],
            'name': listName,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      
      return response;
    } catch (e) {
      _logger.e('Error creating custom list: $e');
      rethrow;
    }
  }
  
  static Future<bool> addRecipeToList({
    required String listId,
    required int recipeId,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      await client
          .from('list_recipes')
          .insert({
            'list_id': listId,
            'recipe_id': recipeId,
            'added_at': DateTime.now().toIso8601String(),
          });
      
      return true;
    } catch (e) {
      _logger.e('Error adding recipe to list: $e');
      return false;
    }
  }

  static Future<bool> isRecipeHearted(String userId, int recipeId) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final user = await getUserByPhone(userId);
      if (user == null) return false;

      final result = await client
          .from('hearted_recipes')
          .select('id')
          .eq('user_id', user['id'])
          .eq('recipe_id', recipeId)
          .maybeSingle();

      return result != null;
    } catch (e) {
      _logger.e('Error checking hearted state: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getRecipesForList(String listId) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final response = await client
          .from('list_recipes')
          .select('recipe_id, recipes(*)')
          .eq('list_id', listId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _logger.e('Error getting list recipes: $e');
      return [];
    }
  }
}
