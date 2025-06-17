import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import 'api_client.dart';

class AuthService {
  static final String baseUrl = const String.fromEnvironment('API_BASE_URL');
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _isAuthenticatedKey = 'isAuthenticated';
  static const String _authKey = 'auth_data';
  static const String _devModeKey = 'dev_mode';
  static const String _devPhoneKey = 'dev_phone';
  static const String _devOtpKey = 'dev_otp';
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Initialize shared preferences
  static Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final authDataString = await _secureStorage.read(key: _authKey);
    if (authDataString == null) return false;

    try {
      final authData = json.decode(authDataString) as Map<String, dynamic>;
      final token = authData['token'];
      if (token == null) return false;

      // TODO: Add token validation if needed
      return true;
    } catch (e) {
      print('Error checking authentication: $e');
      return false;
    }
  }

  // Get authentication data
  static Future<Map<String, dynamic>?> getAuthData() async {
    final authDataString = await _secureStorage.read(key: _authKey);
    if (authDataString == null) return null;
    
    try {
      return json.decode(authDataString) as Map<String, dynamic>;
    } catch (e) {
      print('Error getting auth data: $e');
      return null;
    }
  }

  // Save authentication data
  static Future<void> _saveAuthData({
    required String token,
    required String userId,
    required String userName,
  }) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    await _secureStorage.write(key: _userIdKey, value: userId);
    await _secureStorage.write(key: _userNameKey, value: userName);
    await _secureStorage.write(key: _isAuthenticatedKey, value: 'true');

    final authData = {
      'token': token,
      'user_id': userId,
      'user_name': userName,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await _secureStorage.write(key: _authKey, value: json.encode(authData));
  }

  // Verify OTP and get authentication token
  static Future<Map<String, dynamic>> verifyOTP(String phoneNumber, String otpCode, {String? username}) async {
    try {
      final response = await ApiClient.verifyOTP(phoneNumber, otpCode, username: username);
      
      if (response['success'] == true) {
        await _saveAuthData(
          token: response['token'],
          userId: response['user_id'],
          userName: response['user_name'],
        );
      }
      
      return response;
    } catch (e) {
      print('Error verifying OTP: $e');
      return {'success': false, 'error': 'Failed to verify OTP'};
    }
  }

  // Logout user
  static Future<void> logout() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userIdKey);
    await _secureStorage.delete(key: _userNameKey);
    await _secureStorage.delete(key: _isAuthenticatedKey);
    await _secureStorage.delete(key: _authKey);
    
    // Update AuthProvider
    final context = navigatorKey.currentContext;
    if (context != null) {
      Provider.of<AuthProvider>(context, listen: false).logout();
    }
  }

  // Get authenticated headers for API requests
  static Future<Map<String, String>> getAuthHeaders() async {
    final authDataString = await _secureStorage.read(key: _authKey);
    if (authDataString == null) {
      return {"Content-Type": "application/json"};
    }
    
    try {
      final authData = json.decode(authDataString) as Map<String, dynamic>;
      final token = authData['token'];
      return {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };
    } catch (e) {
      print('Error getting auth headers: $e');
      return {"Content-Type": "application/json"};
    }
  }

  // Get user ID
  static Future<String?> getUserId() async {
    return await _secureStorage.read(key: _userIdKey);
  }

  // Get user name
  static Future<String?> getUserName() async {
    return await _secureStorage.read(key: _userNameKey);
  }

  // Development mode methods
  static Future<bool> isDevMode() async {
    final prefs = await _prefs;
    return prefs.getBool(_devModeKey) ?? false;
  }

  static Future<void> setDevMode(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_devModeKey, enabled);
  }

  static Future<void> setDevCredentials(String phone, String otp) async {
    final prefs = await _prefs;
    await prefs.setString(_devPhoneKey, phone);
    await prefs.setString(_devOtpKey, otp);
  }

  static Future<Map<String, String>> getDevCredentials() async {
    final prefs = await _prefs;
    return {
      'phone': prefs.getString(_devPhoneKey) ?? '',
      'otp': prefs.getString(_devOtpKey) ?? '123456',
    };
  }

  // Send OTP
  static Future<bool> sendOTP(String phoneNumber) async {
    try {
      final response = await ApiClient.sendOTP(phoneNumber);
      return response['success'] == true;
    } catch (e) {
      print('Error sending OTP: $e');
      return false;
    }
  }

  // Update username
  static Future<Map<String, dynamic>> updateUsername(String phoneNumber, String username) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      final response = await ApiClient.updateUsername(token, username);
      
      if (response['success'] == true) {
        await _saveAuthData(
          token: response['token'],
          userId: response['user_id'],
          userName: response['user_name'],
        );
      }
      
      return response;
    } catch (e) {
      print('Error updating username: $e');
      return {'success': false, 'error': 'Failed to update username'};
    }
  }

  static Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }
} 