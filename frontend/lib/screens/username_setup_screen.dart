import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';

class UsernameSetupScreen extends StatefulWidget {
  final String phoneNumber;
  final VoidCallback onComplete;

  const UsernameSetupScreen({
    super.key,
    required this.phoneNumber,
    required this.onComplete,
  });

  @override
  UsernameSetupScreenState createState() => UsernameSetupScreenState();
}

class UsernameSetupScreenState extends State<UsernameSetupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  Future<void> _saveUsername() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => errorMessage = "Please enter a username");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final result = await AuthService.updateUsername(widget.phoneNumber, username);
    
    setState(() {
      isLoading = false;
      if (result['success'] == true) {
        widget.onComplete();
      } else {
        errorMessage = result['error'] ?? "Failed to update username";
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Set Your Username",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Lexend',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Choose a username to personalize your experience",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontFamily: 'Lexend',
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Enter your username",
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.person, color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.deepOrange),
                  ),
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                    fontFamily: 'Lexend',
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _saveUsername,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Continue",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Lexend',
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 