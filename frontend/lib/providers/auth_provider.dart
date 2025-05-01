import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';

class AuthProvider with ChangeNotifier {
  String? _phoneNumber;
  String? _userName;
  bool _isAuthenticated = false;

  String? get phoneNumber => _phoneNumber;
  String? get userName => _userName;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> login(String phoneNumber, {String? userName}) async {
    _phoneNumber = phoneNumber;
    _userName = userName;
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> logout() async {
    _phoneNumber = null;
    _userName = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> updateUsername({required String phoneNumber, required String newUsername}) async {
    await SupabaseService.updateUsername(phoneNumber, newUsername);
    _userName = newUsername;
    notifyListeners();
  }
} 