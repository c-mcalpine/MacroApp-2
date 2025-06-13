import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// A class to manage application configuration across different environments
class AppConfig {
  // Singleton pattern
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  // Accessors for environment values
  String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';
  
  // Initialize configuration based on environment
  Future<void> initialize() async {
    try {
      // Load from .env file in all build modes
      await dotenv.load(fileName: ".env");
      
      if (kDebugMode) {
        print('Environment variables loaded:');
        print('SUPABASE_URL: ${dotenv.env['SUPABASE_URL']}');
        print('SUPABASE_ANON_KEY: ${dotenv.env['SUPABASE_ANON_KEY']}');
        print('API_BASE_URL: ${dotenv.env['API_BASE_URL']}');
      }
      
      // Validate required configuration
      if (supabaseUrl.isEmpty ||
          supabaseAnonKey.isEmpty ||
          apiBaseUrl.isEmpty) {
        throw Exception(
            'Missing required environment variables. Please check your configuration.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading .env file: $e');
      }
      // In production, try to load from the app bundle
      try {
        await dotenv.load(fileName: "assets/.env");
      } catch (e) {
        if (kDebugMode) {
          print('Error loading .env from assets: $e');
        }
        rethrow;
      }
    }
  }
  
  // Helper method to check if we're in debug mode
  bool get isDebugMode => kDebugMode;
} 