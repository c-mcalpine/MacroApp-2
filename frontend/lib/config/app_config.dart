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
    // Load from .env file in all build modes
    await dotenv.load(fileName: ".env");
    
    // Validate required configuration
    if (supabaseUrl.isEmpty ||
        supabaseAnonKey.isEmpty ||
        apiBaseUrl.isEmpty) {
      throw Exception(
          'Missing required environment variables. Please check your configuration.');
    }
  }
  
  // Helper method to check if we're in debug mode
  bool get isDebugMode => kDebugMode;
} 