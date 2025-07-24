import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  
  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  bool _isOtpSent = false;
  bool _showUsernameInput = false;
  String _selectedCountryCode = '+1';

  final List<Map<String, String>> _countryCodes = [
    {'code': '+1', 'name': 'US/CA'},
    {'code': '+44', 'name': 'UK'},
    {'code': '+91', 'name': 'IN'},
    {'code': '+86', 'name': 'CN'},
    {'code': '+81', 'name': 'JP'},
    {'code': '+82', 'name': 'KR'},
    {'code': '+61', 'name': 'AU'},
    {'code': '+52', 'name': 'MX'},
    {'code': '+55', 'name': 'BR'},
    {'code': '+33', 'name': 'FR'},
    {'code': '+49', 'name': 'DE'},
    {'code': '+39', 'name': 'IT'},
    {'code': '+34', 'name': 'ES'},
    {'code': '+7', 'name': 'RU'},
    {'code': '+971', 'name': 'UAE'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  String get _fullPhoneNumber => '$_selectedCountryCode${_phoneController.text}';

  Future<void> _sendOTP() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await AuthService.sendOTP(_fullPhoneNumber);
      if (mounted) {
        if (success) {
          setState(() => _isOtpSent = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP sent successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send OTP')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await AuthService.verifyOTP(
        _fullPhoneNumber,
        _otpController.text,
      );

      if (mounted) {
        if (result['success'] == true) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          await authProvider.login(_fullPhoneNumber, userName: result['user_name']);
        } else if (result['code'] == 'need_username') {
          setState(() => _showUsernameInput = true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? 'Invalid OTP')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _completeSignup() async {
    if (_usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a username')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await AuthService.verifyOTP(
        _fullPhoneNumber,
        _otpController.text,
        username: _usernameController.text,
      );

      if (mounted) {
        if (result['success'] == true) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          await authProvider.login(_fullPhoneNumber, userName: result['user_name']);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? 'Failed to complete signup')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(flex: 1),
                        const Icon(
                          Icons.restaurant_menu,
                          size: 80,
                          color: Colors.deepOrange,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Welcome to Macro',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Lexend',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your personal recipe companion',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            fontFamily: 'Lexend',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        if (!_showUsernameInput) ...[
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: DropdownButton<String>(
                                  value: _selectedCountryCode,
                                  dropdownColor: Colors.grey[900],
                                  style: const TextStyle(color: Colors.white),
                                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                                  underline: const SizedBox(),
                                  items: _countryCodes.map((country) {
                                    return DropdownMenuItem(
                                      value: country['code'],
                                      child: Text('${country['code']} ${country['name']}'),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _selectedCountryCode = value);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _phoneController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Phone Number',
                                    hintStyle: const TextStyle(color: Colors.white54),
                                    filled: true,
                                    fillColor: Colors.white12,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  enabled: !_isOtpSent,
                                ),
                              ),
                            ],
                          ),
                          if (_isOtpSent) ...[
                            const SizedBox(height: 16),
                            TextField(
                              controller: _otpController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Enter OTP',
                                hintStyle: const TextStyle(color: Colors.white54),
                                prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                                filled: true,
                                fillColor: Colors.white12,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ] else ...[
                          TextField(
                            controller: _usernameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Choose a username',
                              hintStyle: const TextStyle(color: Colors.white54),
                              prefixIcon: const Icon(Icons.person, color: Colors.white70),
                              filled: true,
                              fillColor: Colors.white12,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : () {
                            if (_showUsernameInput) {
                              _completeSignup();
                            } else if (_isOtpSent) {
                              _verifyOTP();
                            } else {
                              _sendOTP();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _showUsernameInput
                                      ? 'Complete Signup'
                                      : (_isOtpSent ? 'Verify OTP' : 'Send OTP'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Lexend',
                                  ),
                                ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'By continuing, you agree to our Terms of Service and Privacy Policy',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                            fontFamily: 'Lexend',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Spacer(flex: 2),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 