import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
        SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await AuthService.sendOTP(_fullPhoneNumber);
      if (success) {
        setState(() => _isOtpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OTP sent successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send OTP')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter the OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await AuthService.verifyOTP(
        _fullPhoneNumber,
        _otpController.text,
      );

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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeSignup() async {
    if (_usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a username')),
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

      if (result['success'] == true) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.login(_fullPhoneNumber, userName: result['user_name']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Failed to complete signup')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
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
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Spacer(flex: 1),
                        Icon(
                          Icons.restaurant_menu,
                          size: 80,
                          color: Colors.deepOrange,
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Welcome to Macro',
                          style: GoogleFonts.lexend(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Your personal recipe companion',
                          style: GoogleFonts.lexend(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 48),
                        if (!_showUsernameInput) ...[
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: DropdownButton<String>(
                                  value: _selectedCountryCode,
                                  dropdownColor: Colors.grey[900],
                                  style: TextStyle(color: Colors.white),
                                  icon: Icon(Icons.arrow_drop_down, color: Colors.white70),
                                  underline: SizedBox(),
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
                              SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _phoneController,
                                  style: TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Phone Number',
                                    hintStyle: TextStyle(color: Colors.white54),
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
                            SizedBox(height: 16),
                            TextField(
                              controller: _otpController,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Enter OTP',
                                hintStyle: TextStyle(color: Colors.white54),
                                prefixIcon: Icon(Icons.lock, color: Colors.white70),
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
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Choose a username',
                              hintStyle: TextStyle(color: Colors.white54),
                              prefixIcon: Icon(Icons.person, color: Colors.white70),
                              filled: true,
                              fillColor: Colors.white12,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: 24),
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
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
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
                                  style: GoogleFonts.lexend(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'By continuing, you agree to our Terms of Service and Privacy Policy',
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Spacer(flex: 2),
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