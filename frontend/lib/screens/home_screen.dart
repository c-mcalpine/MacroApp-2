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
    try {
      // Get user ID and name
      final userId = await AuthService.getUserId();
      final name = await AuthService.getUserName();
      
      if (userId == null) {
        print('No user ID found');
        setState(() {
          isLoading = false;
          heartedRecipes = [];
          customLists = {};
          userName = null;
        });
        return;
      }

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
    } catch (e, stack) {
      print('Error loading user data: $e');
      print('Stack trace: $stack');
      setState(() {
        isLoading = false;
        heartedRecipes = [];
        customLists = {};
        userName = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.deepOrange),
              SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    final List<Widget> _pages = [
      ExploreRecipesScreen(onRecipeSelected: (recipeId) {
        // Handle recipe selection
      }),
      SearchScreen(),
      ProfileScreen(
        heartedRecipes: heartedRecipes,
        customLists: customLists,
        onLogout: widget.onLogout,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.black,
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.white54,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
} 