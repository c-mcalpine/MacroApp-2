import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static SupabaseClient? _client;
  static bool _isInitialized = false;
  
  // Initialize Supabase client
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final supabaseUrl = dotenv.env['SUPABASE_URL'];
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
      
      print('Initializing Supabase with:');
      print('URL: $supabaseUrl');
      print('Anon Key present: ${supabaseAnonKey != null}');
      
      if (supabaseUrl == null || supabaseAnonKey == null) {
        print('ERROR: Supabase environment variables are missing. Please check your .env file.');
        _isInitialized = false;
        return;
      }
      
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      
      _client = Supabase.instance.client;
      _isInitialized = true;
      
      // Test the connection
      try {
        final response = await _client!.from('users').select().limit(1);
        print('Successfully connected to Supabase. Test query response: $response');
      } catch (e) {
        print('Connected to Supabase but test query failed: $e');
      }
    } catch (e) {
      print('Error initializing Supabase: $e');
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
  
  // User operations
  static Future<Map<String, dynamic>?> getUserByPhone(String phoneNumber) async {
    try {
      if (!_isInitialized) {
        print('Supabase not initialized. Returning mock user data.');
        return {
          'id': 'mock-user-id',
          'phone_number': phoneNumber,
          'username': 'Mock User',
          'created_at': DateTime.now().toIso8601String(),
        };
      }
      
      // Try to get the user
      final response = await client
          .from('users')
          .select()
          .eq('phone_number', phoneNumber)
          .maybeSingle();
      
      if (response == null) {
        print('No user found with phone number: $phoneNumber');
        return null;
      }
      
      return response;
    } catch (e) {
      print('Error getting user by phone: $e');
      if (e.toString().contains('relation "users" does not exist')) {
        print('Users table does not exist. Creating table...');
        try {
          // Note: You need to create the table in Supabase dashboard
          print('Please create the users table in your Supabase dashboard with the following SQL:');
          print('''
            create table public.users (
              id uuid default uuid_generate_v4() primary key,
              phone_number text unique not null,
              username text,
              created_at timestamp with time zone default timezone('utc'::text, now()) not null
            );
          ''');
        } catch (tableError) {
          print('Error creating users table: $tableError');
        }
      }
      return null;
    }
  }
  
  static Future<Map<String, dynamic>> createUser({
    required String phoneNumber,
    required String username,
  }) async {
    try {
      if (!_isInitialized) {
        print('Supabase not initialized. Returning mock user data.');
        return {
          'id': 'mock-user-id',
          'phone_number': phoneNumber,
          'username': username,
          'created_at': DateTime.now().toIso8601String(),
        };
      }
      
      // Check if user already exists
      final existingUser = await getUserByPhone(phoneNumber);
      if (existingUser != null) {
        print('User already exists with phone number: $phoneNumber');
        return existingUser;
      }
      
      // Create new user
      final response = await client
          .from('users')
          .insert({
            'phone_number': phoneNumber,
            'username': username,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      
      print('Successfully created user: $response');
      return response;
    } catch (e) {
      print('Error creating user: $e');
      if (e.toString().contains('relation "users" does not exist')) {
        print('Users table does not exist. Please create it in the Supabase dashboard.');
      }
      throw Exception('Failed to create user: $e');
    }
  }
  
  static Future<Map<String, dynamic>> updateUsername({
    required String phoneNumber,
    required String newUsername,
  }) async {
    try {
      if (!_isInitialized) {
        throw Exception('Supabase is not initialized. Please check your environment variables and try again.');
      }
      
      // Check if user exists
      final existingUser = await getUserByPhone(phoneNumber);
      if (existingUser == null) {
        print('No user found with phone number: $phoneNumber. Creating new user...');
        return await createUser(
          phoneNumber: phoneNumber,
          username: newUsername,
        );
      }
      
      // Update username
      final response = await client
          .from('users')
          .update({'username': newUsername})
          .eq('phone_number', phoneNumber)
          .select()
          .single();
      
      print('Successfully updated username: $response');
      return response;
    } catch (e) {
      print('Error updating username: $e');
      throw Exception('Failed to update username: $e');
    }
  }
  
  // Recipe operations
  static Future<List<Map<String, dynamic>>> getHeartedRecipes(String userId) async {
    try {
      if (!_isInitialized) {
        print('Supabase not initialized. Returning mock hearted recipes.');
        return [
          {
            'recipe_id': 1,
            'recipes': {
              'id': 1,
              'name': 'Mock Recipe 1',
              'description': 'This is a mock recipe',
              'image_url': 'https://via.placeholder.com/150',
            }
          },
          {
            'recipe_id': 2,
            'recipes': {
              'id': 2,
              'name': 'Mock Recipe 2',
              'description': 'This is another mock recipe',
              'image_url': 'https://via.placeholder.com/150',
            }
          }
        ];
      }
      
      // Get the user by phone number first
      final user = await getUserByPhone(userId);
      if (user == null) {
        print('User not found for phone number: $userId');
        return [];
      }
      
      final response = await client
          .from('hearted_recipes')
          .select('recipe_id, recipes(*)')
          .eq('user_id', user['id']);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting hearted recipes: $e');
      return [];
    }
  }
  
  static Future<bool> heartRecipe(String userId, int recipeId) async {
    try {
      if (!_isInitialized) {
        print('Supabase not initialized. Mocking heart recipe operation.');
        return true;
      }
      
      // Get the user by phone number first
      final user = await getUserByPhone(userId);
      if (user == null) {
        print('User not found for phone number: $userId');
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
      print('Error hearting recipe: $e');
      return false;
    }
  }
  
  static Future<bool> unheartRecipe(String userId, int recipeId) async {
    try {
      if (!_isInitialized) {
        print('Supabase not initialized. Mocking unheart recipe operation.');
        return true;
      }
      
      // Get the user by phone number first
      final user = await getUserByPhone(userId);
      if (user == null) {
        print('User not found for phone number: $userId');
        return false;
      }
      
      await client
          .from('hearted_recipes')
          .delete()
          .eq('user_id', user['id'])
          .eq('recipe_id', recipeId);
      
      return true;
    } catch (e) {
      print('Error unhearting recipe: $e');
      return false;
    }
  }
  
  // Custom lists operations
  static Future<List<Map<String, dynamic>>> getCustomLists(String userId) async {
    try {
      if (!_isInitialized) {
        print('Supabase not initialized. Returning mock custom lists.');
        return [
          {
            'id': 'mock-list-1',
            'user_id': userId,
            'name': 'My Favorite Recipes',
            'created_at': DateTime.now().toIso8601String(),
          },
          {
            'id': 'mock-list-2',
            'user_id': userId,
            'name': 'Weekend Meals',
            'created_at': DateTime.now().toIso8601String(),
          }
        ];
      }
      
      // Get the user by phone number first
      final user = await getUserByPhone(userId);
      if (user == null) {
        print('User not found for phone number: $userId');
        return [];
      }
      
      final response = await client
          .from('custom_lists')
          .select()
          .eq('user_id', user['id']);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting custom lists: $e');
      return [];
    }
  }
  
  static Future<Map<String, dynamic>> createCustomList({
    required String userId,
    required String listName,
  }) async {
    try {
      if (!_isInitialized) {
        print('Supabase not initialized. Returning mock custom list.');
        return {
          'id': 'mock-list-${DateTime.now().millisecondsSinceEpoch}',
          'user_id': userId,
          'name': listName,
          'created_at': DateTime.now().toIso8601String(),
        };
      }
      
      // Get the user by phone number first
      final user = await getUserByPhone(userId);
      if (user == null) {
        print('User not found for phone number: $userId');
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
      print('Error creating custom list: $e');
      rethrow;
    }
  }
  
  static Future<bool> addRecipeToList({
    required String listId,
    required int recipeId,
  }) async {
    try {
      if (!_isInitialized) {
        print('Supabase not initialized. Mocking add recipe to list operation.');
        return true;
      }
      
      await client
          .from('list_recipes')
          .insert({
            'list_id': listId,
            'recipe_id': recipeId,
            'added_at': DateTime.now().toIso8601String(),
          });
      
      return true;
    } catch (e) {
      print('Error adding recipe to list: $e');
      return false;
    }
  }
} 