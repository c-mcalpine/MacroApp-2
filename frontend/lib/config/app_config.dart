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
      supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
    } else {
      // In production, use hardcoded values
      // IMPORTANT: Replace these with your actual production values
      supabaseUrl = 'https://your-production-supabase-url.supabase.co';
      supabaseAnonKey = 'your-production-supabase-anon-key';
      apiBaseUrl = 'https://your-production-api-url.com';
    }
  }
  
  // Helper method to check if we're in debug mode
  bool get isDebugMode => kDebugMode;
} 