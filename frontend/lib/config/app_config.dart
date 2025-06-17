import 'package:flutter/foundation.dart' show kDebugMode;

/// A class to manage application configuration across different environments
class AppConfig {
  // Singleton pattern
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  // Accessors for compile-time environment values
  String get supabaseUrl => const String.fromEnvironment('SUPABASE_URL');
  String get supabaseAnonKey => const String.fromEnvironment('SUPABASE_ANON_KEY');
  String get apiBaseUrl => const String.fromEnvironment('API_BASE_URL');

  // Validate configuration; called during startup
  Future<void> initialize() async {
    if (supabaseUrl.isEmpty ||
        supabaseAnonKey.isEmpty ||
        apiBaseUrl.isEmpty) {
      throw Exception(
          'Missing required --dart-define values. Please provide SUPABASE_URL, SUPABASE_ANON_KEY and API_BASE_URL.');
    }
  }

  // Helper method to check if we're in debug mode
  bool get isDebugMode => kDebugMode;
}
