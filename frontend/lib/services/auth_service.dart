import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/services/supabase_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';

class AuthService {
  static final String baseUrl = dotenv.env['API_BASE_URL']!;
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _isAuthenticatedKey = 'isAuthenticated';
  static const String _authKey = 'auth_data';
  static const String _devModeKey = 'dev_mode';
  static const String _devPhoneKey = 'dev_phone';
  static const String _devOtpKey = 'dev_otp';
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Initialize shared preferences
  static Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

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

  // Send OTP to phone number
  static Future<bool> sendOTP(String phoneNumber) async {
    try {
      // Check if in dev mode
      if (await isDevMode()) {
        // In dev mode, just save the phone number and return success
        await setDevCredentials(phoneNumber, '123456');
        return true;
      }

      // Format phone number to E.164 format if needed
      String formattedPhone = phoneNumber;
      if (!phoneNumber.startsWith('+')) {
        // Remove any non-digit characters
        String digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
        // Add US country code if not present
        formattedPhone = '+1$digitsOnly';
      }

      final response = await http.post(
        Uri.parse("$baseUrl/auth/send-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone_number": formattedPhone}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Failed to send OTP: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Exception during sendOTP: $e");
      return false;
    }
  }

  // Verify OTP and get authentication token
  static Future<Map<String, dynamic>> verifyOTP(String phoneNumber, String otpCode, {String? username}) async {
    try {
      // Check if in dev mode
      if (await isDevMode()) {
        final devCreds = await getDevCredentials();
        
        // In dev mode, accept any OTP if phone matches
        if (phoneNumber == devCreds['phone']) {
          // Check if user exists in Supabase
          final user = await SupabaseService.getUserByPhone(phoneNumber);
          
          if (user == null && username != null) {
            // Create new user in Supabase
            await SupabaseService.createUser(phoneNumber, username);
          }
          
          // Save auth data
          await _saveAuthData(
            token: 'dev_token',
            userId: phoneNumber,
            userName: username ?? 'User',
          );
          
          // Update AuthProvider
          final context = navigatorKey.currentContext;
          if (context != null) {
            Provider.of<AuthProvider>(context, listen: false).login(phoneNumber, userName: username ?? 'User');
          }
          
          return {
            'success': true,
            'user_id': phoneNumber,
            'user_name': username ?? 'User',
          };
        }
        
        return {'success': false, 'error': 'Invalid OTP'};
      }

      final response = await http.post(
        Uri.parse("$baseUrl/auth/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone_number": phoneNumber,
          "otp_code": otpCode,
          if (username != null) 'username': username,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['token'] != null) {
          // Check if user exists in Supabase
          final user = await SupabaseService.getUserByPhone(phoneNumber);
          
          if (user == null && username != null) {
            // Create new user in Supabase
            await SupabaseService.createUser(phoneNumber, username);
          }
          
          // Save auth data
          await _saveAuthData(
            token: data['token'],
            userId: data['user_id'] ?? phoneNumber,
            userName: data['user_name'] ?? username ?? 'User',
          );
          
          // Update AuthProvider
          final context = navigatorKey.currentContext;
          if (context != null) {
            Provider.of<AuthProvider>(context, listen: false).login(
              phoneNumber,
              userName: data['user_name'] ?? username ?? 'User',
            );
          }
          
          return {
            'success': true,
            'user_id': data['user_id'] ?? phoneNumber,
            'user_name': data['user_name'] ?? username ?? 'User',
          };
        }
      }
      return {'success': false, 'error': 'Invalid OTP'};
    } catch (e) {
      print("Exception during verifyOTP: $e");
      return {'success': false, 'error': 'Authentication failed'};
    }
  }

  // Save authentication data to SharedPreferences
  static Future<void> _saveAuthData({
    required String token,
    required String userId,
    required String userName,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userNameKey, userName);
    await prefs.setBool(_isAuthenticatedKey, true);
    
    // Also save the complete auth data
    final authData = {
      'token': token,
      'user_id': userId,
      'user_name': userName,
    };
    await prefs.setString(_authKey, json.encode(authData));
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final prefs = await _prefs;
    final token = prefs.getString(_tokenKey);
    if (token == null) return false;

    // TODO: Add token validation if needed
    return true;
  }

  // Get authentication token
  static Future<String?> getToken() async {
    final prefs = await _prefs;
    return prefs.getString(_tokenKey);
  }

  // Get user ID
  static Future<String?> getUserId() async {
    final prefs = await _prefs;
    return prefs.getString(_userIdKey);
  }

  // Get user name
  static Future<String?> getUserName() async {
    final prefs = await _prefs;
    return prefs.getString(_userNameKey);
  }

  // Logout user
  static Future<void> logout() async {
    final prefs = await _prefs;
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.setBool(_isAuthenticatedKey, false);
    await prefs.remove(_authKey);
  }

  // Get authenticated headers for API requests
  static Future<Map<String, String>> getAuthHeaders() async {
    final prefs = await _prefs;
    final token = prefs.getString(_tokenKey);
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // Update username
  static Future<Map<String, dynamic>> updateUsername(String phoneNumber, String newUsername) async {
    try {
      // Update username in Supabase
      await SupabaseService.updateUsername(phoneNumber, newUsername);
      
      // Update local storage
      final prefs = await _prefs;
      await prefs.setString(_userNameKey, newUsername);
      
      // Update auth data
      final authDataString = prefs.getString(_authKey);
      if (authDataString != null) {
        final authData = json.decode(authDataString) as Map<String, dynamic>;
        authData['user_name'] = newUsername;
        await prefs.setString(_authKey, json.encode(authData));
      }
      
      return {
        'success': true,
        'user_name': newUsername,
      };
    } catch (e) {
      print('Error updating username: $e');
      return {
        'success': false,
        'error': 'Failed to update username',
      };
    }
  }

  static Future<Map<String, dynamic>?> getAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final authDataString = prefs.getString(_authKey);
    if (authDataString == null) return null;
    
    try {
      return json.decode(authDataString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
} 