import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/supabase_service.dart';
import 'package:frontend/screens/explore_recipes_screen.dart';
import 'package:frontend/screens/search_screen.dart';
import 'package:frontend/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const HomeScreen({
    super.key,
    required this.onLogout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> heartedRecipes = [];
  Map<String, List<Map<String, dynamic>>> customLists = {};
  bool isLoading = true;
  String? userName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get user ID and name
      final userId = await AuthService.getUserId();
      final name = await AuthService.getUserName();
      
      if (userId != null) {
        // Load hearted recipes from Supabase
        final heartedRecipesData = await SupabaseService.getHeartedRecipes(userId);
        
        // Load custom lists from Supabase
        final customListsData = await SupabaseService.getCustomLists(userId);
        
        // Convert custom lists to the expected format
        final Map<String, List<Map<String, dynamic>>> formattedLists = {};
        for (var list in customListsData) {
          formattedLists[list['name']] = [];
        }
        
        setState(() {
          heartedRecipes = heartedRecipesData.map((item) => item['recipes'] as Map<String, dynamic>).toList();
          customLists = formattedLists;
          userName = name;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepOrange),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          ExploreRecipesScreen(
            onRecipeSelected: (recipeId) {
              // Handle recipe selection
            },
          ),
          SearchScreen(
            onRecipeSelected: (recipeId) {
              // Handle recipe selection
            },
          ),
          ProfileScreen(
            heartedRecipes: heartedRecipes,
            customLists: customLists,
            onLogout: widget.onLogout,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.whatshot), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.white60,
        backgroundColor: Colors.black,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
} 