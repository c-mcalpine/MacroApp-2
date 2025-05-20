import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// A class to manage application configuration across different environments
class AppConfig {
  // Singleton pattern
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  // Configuration values
  late final String supabaseUrl;
  late final String supabaseAnonKey;
  late final String apiBaseUrl;
  
  // Initialize configuration based on environment
  Future<void> initialize() async {
    if (kDebugMode) {
      // In debug mode, load from .env file
      await dotenv.load(fileName: ".env");
    }
    
    // Use environment variables in both debug and production
    supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
    
    // Validate required configuration
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty || apiBaseUrl.isEmpty) {
      throw Exception('Missing required environment variables. Please check your configuration.');
    }
  }
  
  // Helper method to check if we're in debug mode
  bool get isDebugMode => kDebugMode;
} 