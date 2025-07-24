import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class DevSettingsScreen extends StatefulWidget {
  const DevSettingsScreen({Key? key}) : super(key: key);

  @override
  DevSettingsScreenState createState() => DevSettingsScreenState();
}

class DevSettingsScreenState extends State<DevSettingsScreen> {
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
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Development settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
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
        title: const Text(
          "Development Settings",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Lexend',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dev Mode Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Development Mode",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Lexend',
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
            const SizedBox(height: 24),
            
            // Dev Credentials
            if (_isDevMode) ...[
              const Text(
                "Development Credentials",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Lexend',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: "Enter phone number for dev mode",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _otpController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "OTP Code",
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: "Enter OTP code for dev mode",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Note: In development mode, any OTP code will be accepted for the specified phone number.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontFamily: 'Lexend',
                ),
              ),
            ],
            
            const Spacer(),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Save Settings",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Lexend',
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