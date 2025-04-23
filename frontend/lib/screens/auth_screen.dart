import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/screens/username_setup_screen.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  final VoidCallback onAuthenticated;
  const AuthScreen({Key? key, this.onLogout, required this.onAuthenticated}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool otpSent = false;
  bool isLoading = false;
  String? errorMessage;
  String selectedCountryCode = '+1'; // Default to US
  
  // Common country codes with their flags
  final List<Map<String, String>> countryCodes = [
    {'code': '+1', 'country': 'US', 'flag': '🇺🇸'},
    {'code': '+44', 'country': 'UK', 'flag': '🇬🇧'},
    {'code': '+33', 'country': 'FR', 'flag': '🇫🇷'},
    {'code': '+49', 'country': 'DE', 'flag': '🇩🇪'},
    {'code': '+81', 'country': 'JP', 'flag': '🇯🇵'},
    {'code': '+86', 'country': 'CN', 'flag': '🇨🇳'},
    {'code': '+91', 'country': 'IN', 'flag': '🇮🇳'},
    {'code': '+61', 'country': 'AU', 'flag': '🇦🇺'},
    {'code': '+55', 'country': 'BR', 'flag': '🇧🇷'},
    {'code': '+52', 'country': 'MX', 'flag': '🇲🇽'},
  ];
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 1200));
    _scaleAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack);
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => errorMessage = "Please enter your phone number");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    // Combine country code with phone number
    final fullPhoneNumber = '$selectedCountryCode$phone';
    final success = await AuthService.sendOTP(fullPhoneNumber);
    
    setState(() {
      isLoading = false;
      if (success) {
        otpSent = true;
        errorMessage = null;
      } else {
        errorMessage = "Failed to send OTP. Please try again.";
      }
    });
  }

  Future<void> _verifyOTP() async {
    final phone = _phoneController.text.trim();
    final code = _otpController.text.trim();
    if (phone.isEmpty || code.isEmpty) {
      setState(() => errorMessage = "Please enter both phone number and OTP");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    // Combine country code with phone number for verification
    final fullPhoneNumber = '$selectedCountryCode$phone';
    final result = await AuthService.verifyOTP(fullPhoneNumber, code);
    
    setState(() {
      isLoading = false;
      if (result['success'] == true) {
        // Show username setup screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UsernameSetupScreen(
              phoneNumber: fullPhoneNumber,
              onComplete: () {
                widget.onAuthenticated();
              },
            ),
          ),
        );
      } else {
        errorMessage = result['error'] ?? "Invalid OTP. Please try again.";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40),
                // Logo and tagline
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Text(
                    "macro.",
                    style: GoogleFonts.lexend(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                SlideTransition(
                  position: _slideAnimation,
                  child: Text(
                    "Meal prep made personal",
                    style: GoogleFonts.lexend(
                      fontSize: 20,
                      color: Colors.white70,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                SizedBox(height: 40),
                
                // Animation placeholder
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    height: 200,
                    margin: EdgeInsets.only(bottom: 40),
                    child: Center(
                      child: Icon(
                        Icons.restaurant_menu,
                        size: 120,
                        color: Colors.deepOrange.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
                
                // Phone input with country code selector
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    children: [
                      // Country code dropdown
                      Container(
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedCountryCode,
                            dropdownColor: Colors.black,
                            icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                            style: TextStyle(color: Colors.white),
                            isExpanded: true,
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            items: countryCodes.map((country) {
                              return DropdownMenuItem<String>(
                                value: country['code'],
                                child: Row(
                                  children: [
                                    Text(country['flag']!),
                                    SizedBox(width: 8),
                                    Text(country['code']!),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedCountryCode = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      // Phone number input
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          style: TextStyle(color: Colors.white),
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: "Enter your phone number",
                            hintStyle: TextStyle(color: Colors.white54),
                            prefixIcon: Icon(Icons.phone, color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white12,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.deepOrange),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // OTP input (only shown after OTP is sent)
                if (otpSent) ...[
                  SizedBox(height: 16),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: TextField(
                      controller: _otpController,
                      style: TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Enter the OTP",
                        hintStyle: TextStyle(color: Colors.white54),
                        prefixIcon: Icon(Icons.lock_outline, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white12,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.deepOrange),
                        ),
                      ),
                    ),
                  ),
                ],
                
                // Error message
                if (errorMessage != null) ...[
                  SizedBox(height: 16),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      errorMessage!,
                      style: GoogleFonts.lexend(
                        color: Colors.redAccent,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
                
                SizedBox(height: 24),
                
                // Action button
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : (otpSent ? _verifyOTP : _sendOTP),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              otpSent ? "Verify OTP" : "Send OTP",
                              style: GoogleFonts.lexend(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Terms and privacy
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: Text(
                      "By continuing, you agree to our Terms of Service and Privacy Policy",
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
