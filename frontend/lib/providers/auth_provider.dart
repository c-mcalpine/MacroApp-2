import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';

class AuthProvider with ChangeNotifier {
  String? _phoneNumber;
  bool _isAuthenticated = false;

  String? get phoneNumber => _phoneNumber;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> login(String phoneNumber) async {
    _phoneNumber = phoneNumber;
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> logout() async {
    _phoneNumber = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> updateUsername({required String phoneNumber, required String newUsername}) async {
    await SupabaseService.updateUsername(phoneNumber: phoneNumber, newUsername: newUsername);
    notifyListeners();
  }
} 