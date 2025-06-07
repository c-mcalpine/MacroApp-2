import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/services/api_service.dart';
import 'package:flutter/foundation.dart';

class ChatbotScreen extends StatefulWidget {
  final Map<String, dynamic> recipe;

  const ChatbotScreen({super.key, required this.recipe});

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _messages = []; // Stores chat messages
  bool _isLoading = false; // Track loading state for AI responses

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
            "Ask a Question",
            style: GoogleFonts.lexend(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      body: Column(
        children: [
          // Chat Messages
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blueAccent : Colors.grey[800],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      message['content']!,
                      style: GoogleFonts.lexend(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(color: Colors.blueAccent),
            ),
          // Text Input
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    maxLines: null,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      hintStyle: TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    final userMessage = _chatController.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': userMessage});
      _chatController.clear();
      _isLoading = true;
    });

    try {
      // Correctly extract the recipeId
      final recipeId = widget.recipe['recipe']?['recipe_id'];
      if (kDebugMode) {
        print("Sending message to AI for recipeId: $recipeId");
        print("Recipe data in ChatbotScreen: ${widget.recipe}");
      }

      if (recipeId == null || recipeId <= 0) {
        throw Exception("Invalid recipeId");
      }

      final aiResponse = await ApiService.chatWithAI(recipeId, userMessage);
      setState(() {
        _messages.add({'role': 'ai', 'content': aiResponse});
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'ai', 'content': "Error: ${e.toString()}"}); // Display error message
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
