import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class DevSettingsScreen extends StatefulWidget {
  const DevSettingsScreen({Key? key}) : super(key: key);

  @override
  _DevSettingsScreenState createState() => _DevSettingsScreenState();
}

class _DevSettingsScreenState extends State<DevSettingsScreen> {
  bool _isDevMode = false;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final isDevMode = await AuthService.isDevMode();
    final devCreds = await AuthService.getDevCredentials();
    
    setState(() {
      _isDevMode = isDevMode;
      _phoneController.text = devCreds['phone'] ?? '';
      _otpController.text = devCreds['otp'] ?? '123456';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await AuthService.setDevMode(_isDevMode);
    if (_isDevMode) {
      await AuthService.setDevCredentials(
        _phoneController.text,
        _otpController.text,
      );
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Development settings saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Development Settings",
          style: GoogleFonts.lexend(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dev Mode Toggle
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Development Mode",
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Switch(
                    value: _isDevMode,
                    onChanged: (value) {
                      setState(() {
                        _isDevMode = value;
                      });
                    },
                    activeColor: Colors.deepOrange,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            
            // Dev Credentials
            if (_isDevMode) ...[
              Text(
                "Development Credentials",
                style: GoogleFonts.lexend(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: "Enter phone number for dev mode",
                  hintStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _otpController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "OTP Code",
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: "Enter OTP code for dev mode",
                  hintStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                "Note: In development mode, any OTP code will be accepted for the specified phone number.",
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
            
            Spacer(),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Save Settings",
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 