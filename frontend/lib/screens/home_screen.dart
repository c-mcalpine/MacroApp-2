import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/supabase_service.dart';
import 'package:frontend/screens/explore_recipes_screen.dart';
import 'package:frontend/screens/search_screen.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const HomeScreen({
    super.key,
    required this.onLogout,
  });

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> heartedRecipes = [];
  Map<String, List<Map<String, dynamic>>> customLists = {};
  bool isLoading = true;
  String? userName;
  static final Logger _logger = Logger();

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
        if (kDebugMode) {
          _logger.w('No user ID found');
        }
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
      
      // Load custom lists and their recipes from Supabase
      final customListsData = await SupabaseService.getCustomLists(userId);
      final Map<String, List<Map<String, dynamic>>> formattedLists = {};
      for (var list in customListsData) {
        final listRecipes = await SupabaseService.getRecipesForList(list['id']);
        formattedLists[list['name']] =
            listRecipes.map((r) => r['recipes'] as Map<String, dynamic>).toList();
      }
      
      setState(() {
        heartedRecipes = heartedRecipesData.map((item) => item['recipes'] as Map<String, dynamic>).toList();
        customLists = formattedLists;
        userName = name;
        isLoading = false;
      });
    } catch (e, stack) {
      if (kDebugMode) {
        _logger.e('Error loading user data: $e');
        _logger.e('Stack trace: $stack');
      }
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
      return const Scaffold(
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

    final List<Widget> pages = [
      ExploreRecipesScreen(onRecipeSelected: (recipeId) {
        // Handle recipe selection
      }),
      const SearchScreen(),
      ProfileScreen(
        heartedRecipes: heartedRecipes,
        customLists: customLists,
        onLogout: widget.onLogout,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) async {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 2) {
            await _loadUserData();
          }
        },
        backgroundColor: Colors.black,
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.white54,
        items: const [
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