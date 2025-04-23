import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/screens/recipe_details_screen.dart';
import 'package:frontend/screens/search_results_screen.dart';

class ExploreRecipesScreen extends StatefulWidget {
  final Function(int) onRecipeSelected; // Callback for recipe selection

  const ExploreRecipesScreen({super.key, required this.onRecipeSelected});

  @override
  _ExploreRecipesScreenState createState() => _ExploreRecipesScreenState();
}

class _ExploreRecipesScreenState extends State<ExploreRecipesScreen> with TickerProviderStateMixin {
  final List<String> filters = [
    "Recently Added",
    "Popular",
    "Based on Past Orders",
    "High Protein",
    "Quick & Easy",
    "Meal Prep Friendly"
  ];

  final List<bool> selectedFilters = List.generate(6, (index) => false);
  bool isProfileOpen = false;
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Future<List<dynamic>> recipes;

  final List<Map<String, dynamic>> filterOptions = [
    {"label": "🥗 Vegetarian", "key": "Vegetarian", "type": "diet_plan"},
    {"label": "🐟 Pescetarian", "key": "Pescetarian", "type": "diet_plan"},
    {"label": "🌱 Vegan", "key": "Vegan", "type": "diet_plan"},
    {"label": "🥛 Lactose Free", "key": "Lactose Free", "type": "diet_plan"},
    {"label": "🌾 Gluten Free", "key": "Gluten Free", "type": "diet_plan"},
    {"label": "🥜 Nut Free", "key": "Nut Free", "type": "diet_plan"},
    {"label": "🦐 Shellfish-Free", "key": "Shellfish", "type": "diet_plan", "isExclusion": true},
    {"label": "🍖 Beef", "key": "Beef", "type": "ingredient"},
    {"label": "🍗 Chicken", "key": "Chicken", "type": "ingredient"},
    {"label": "🐖 Pork", "key": "Pork", "type": "ingredient"},
    {"label": "🍤 Seafood", "key": "Seafood", "type": "ingredient"},
    {"label": "🍝 Italian", "key": "Italian", "type": "cuisine"},
    {"label": "🍣 Asian", "key": "Asian", "type": "cuisine"},
    {"label": "🍛 Middle Eastern", "key": "Middle Eastern", "type": "cuisine"},
    {"label": "🌮 Mexican-American", "key": "Mexican-American", "type": "cuisine"},
    {"label": "🍔 American", "key": "American", "type": "cuisine"},
    {"label": "🍱 Bulk Meal Prep", "key": "Bulk Meal Prep", "type": "tag"},
    {"label": "🧽 Quick Cleanup", "key": "Quick Cleanup", "type": "tag"},
    {"label": "🥘 One-Pot", "key": "One-Pot", "type": "tag"},
    {"label": "⏱ <1 Hour", "key": "<1 Hour", "type": "tag"},
  ];

  List<String> activeFilters = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _opacityAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    recipes = ApiService.getRecipes();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void navigateToRecipe(int recipeId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailsScreen(
          recipeId: recipeId,
          onHearted: (Map<String, dynamic> heartedData) {
            // Handle the hearted state here
            heartedData['isHearted'] ?? false;
          },
        ),
      ),
    );
  }

  void toggleProfile() {
    setState(() {
      if (isProfileOpen) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
      isProfileOpen = !isProfileOpen;
    });
  }

  void applyFilters() {
    setState(() {
      recipes = ApiService.getRecipes().then((allRecipes) {
        try {
          return allRecipes.where((recipe) {
            for (var filter in activeFilters) {
              final match = filterOptions.firstWhere((option) => option['key'] == filter);

              if (match['type'] == 'diet_plan') {
                final plans = recipe['diet_plans'] as List<dynamic>? ?? [];
                if (!plans.any((dp) =>
                    (dp['name'] ?? '').toString().toLowerCase() == filter.toLowerCase())) {
                  return false;
                }
              }

              if (match['type'] == 'ingredient') {
                final ingredients = recipe['ingredients'] as List<dynamic>? ?? [];
                if (!ingredients.any((ing) =>
                    (ing['name'] ?? '').toString().toLowerCase() == filter.toLowerCase())) {
                  return false;
                }
              }

              if (match['type'] == 'tag') {
                final tags = recipe['tags'] as List<dynamic>? ?? [];
                if (!tags.any((tag) =>
                    (tag['tag_name'] ?? '').toString().toLowerCase() == filter.toLowerCase())) {
                  return false;
                }
              }

              if (match['type'] == 'cuisine') {
                final cuisine = (recipe['cuisine'] ?? '').toString().toLowerCase();
                if (cuisine != filter.toLowerCase()) {
                  return false;
                }
              }
            }
            return true;
          }).toList();
        } catch (e, stack) {
          print("🔥 Filter error: $e");
          print("📌 Stack trace: $stack");
          return [];
        }
      });
    });
  }

  Widget _buildFilterChip(String label, String key, {bool isExclusion = false}) {
    return StatefulBuilder(
      builder: (context, setState) {
        return FilterChip(
          label: Text(
            label,
            style: GoogleFonts.lexend(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          selected: activeFilters.contains(key),
          selectedColor: isExclusion ? Colors.red : Colors.deepOrange,
          backgroundColor: Colors.grey[800],
          shape: StadiumBorder(side: BorderSide(color: Colors.white)),
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                activeFilters.add(key);
              } else {
                activeFilters.remove(key);
              }
              applyFilters(); // Immediately apply filters and update UI
            });
          },
        );
      },
    );
  }

  void openFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Filter Options",
                    style: GoogleFonts.lexend(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: filterOptions.map((option) {
                      return _buildFilterChip(
                        option['label'],
                        option['key'],
                        isExclusion: option['isExclusion'] ?? false,
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  final List<Map<String, String>> promos = [
    {"title": "20% Off First Order", "image": "https://via.placeholder.com/500"},
    {"title": "New High Protein Recipes!", "image": "https://via.placeholder.com/500"},
    {"title": "Try Keto-Friendly Meals", "image": "https://via.placeholder.com/500"},
    {"title": "Exclusive Vegan Recipes", "image": "https://via.placeholder.com/500"},
    {"title": "Best Meal Prep Ideas", "image": "https://via.placeholder.com/500"}
  ];

  final List<Map<String, dynamic>> sections = [
    {"title": "Breakfast", "recipes": []},
    {"title": "Lunch & Dinner", "recipes": []},
    {"title": "Snacks", "recipes": []},
    {"title": "Dessert", "recipes": []}
  ];

  void navigateToSection(String sectionTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeSectionScreen(sectionTitle: sectionTitle, filters: filters),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "macro.",
              style: GoogleFonts.lexend(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            IconButton(
              icon: Icon(Icons.search, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SearchResultsScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.symmetric(horizontal: 16),
            children: [
              // Persistent Filter Pills with Filter Button
              Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.filter_list, color: Colors.white),
                      onPressed: openFilterModal,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(filters.length, (index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0),
                              child: ChoiceChip(
                                label: Text(
                                  filters[index],
                                  style: GoogleFonts.lexend(
                                    color: selectedFilters[index] ? Colors.black : Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                selected: selectedFilters[index],
                                selectedColor: Colors.white,
                                backgroundColor: Colors.black,
                                shape: StadiumBorder(side: BorderSide(color: Colors.white)),
                                onSelected: (bool selected) {
                                  setState(() {
                                    selectedFilters[index] = selected;
                                  });
                                },
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Promo Cards
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: promos.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 200,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(promos[index]['image']!),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            alignment: Alignment.bottomLeft,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                              ),
                            ),
                            child: Text(
                              promos[index]['title']!,
                              style: GoogleFonts.lexend(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 24),
              // Fetch and Display Recipes by Section
              FutureBuilder<List<dynamic>>(
                future: recipes,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "An error occurred while loading recipes. Please try again later.",
                        style: GoogleFonts.lexend(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        "No recipes available at the moment.",
                        style: GoogleFonts.lexend(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  } else {
                    Map<String, List<dynamic>> categorizedRecipes = {
                      "Breakfast": [],
                      "Lunch & Dinner": [],
                      "Snacks": [],
                      "Dessert": []
                    };
                    for (var recipe in snapshot.data!) {
                      if (recipe['meal_type'] != null && categorizedRecipes.containsKey(recipe['meal_type'])) {
                        categorizedRecipes[recipe['meal_type']]!.add(recipe);
                      }
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: categorizedRecipes.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () => navigateToSection(entry.key),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: GoogleFonts.lexend(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                                  ],
                                ),
                              ),
                              SizedBox(height: 9),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3, // Increase the number of columns
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 2 / 3, // Adjust aspect ratio for smaller tiles
                                ),
                                itemCount: entry.value.length,
                                itemBuilder: (context, recipeIndex) {
                                  var recipe = entry.value[recipeIndex];
                                  return GestureDetector(
                                    onTap: () => navigateToRecipe(recipe['recipe_id']),
                                    child: Stack(
                                      children: [
                                        // Recipe Image
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              image: DecorationImage(
                                                image: NetworkImage(recipe['image_url']),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Gradient Overlay
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Recipe Short Name
                                        Positioned(
                                          bottom: 8,
                                          left: 8,
                                          right: 8,
                                          child: Text(
                                            recipe['short_name'] ?? recipe['name'],
                                            style: GoogleFonts.lexend(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              shadows: [
                                                Shadow(
                                                  offset: Offset(0, 1),
                                                  blurRadius: 4,
                                                  color: Colors.black,
                                                ),
                                              ],
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        // Tags on the Right Side
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: (recipe['tags'] as List<dynamic>? ?? []).map((tag) {
                                              return Container(
                                                margin: EdgeInsets.only(bottom: 4),
                                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: _getTagColor(tag['tag_name'] ?? "Unknown"),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  tag['tag_name'] ?? '',
                                                  style: GoogleFonts.lexend(
                                                    fontSize: 10,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  }
                },
              ),
            ],
          ),
          // Profile Drawer
          if (isProfileOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: toggleProfile,
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: 300),
                  opacity: isProfileOpen ? 0.5 : 0.0,
                  child: Container(
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Positioned(
                right: (1 - _controller.value) * -300,
                top: 0,
                bottom: 0,
                child: FadeTransition(
                  opacity: _opacityAnimation,
                  child: Container(
                    width: 300,
                    color: Colors.black,
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 16),
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.person, size: 50, color: Colors.white),
                        ),
                        SizedBox(height: 12),
                        Text(
                          "User Name",
                          style: GoogleFonts.lexend(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {},
                          child: Text(
                            "View Profile",
                            style: GoogleFonts.lexend(fontSize: 16, color: Colors.deepOrange),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Divider(color: Colors.white24, thickness: 1, height: 24),
                        _buildProfileOption(Icons.tune, "Preferences"),
                        _buildProfileOption(Icons.history, "Recipe History"),
                        _buildProfileOption(Icons.people, "Refer a Friend"),
                        _buildProfileOption(Icons.help_outline, "Help"),
                        _buildProfileOption(Icons.settings, "Settings"),
                        _buildProfileOption(Icons.menu_book, "Blog"),
                        Divider(color: Colors.white24, thickness: 1, height: 24),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.lexend(fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Color _getTagColor(String tagName) {
    const goodTags = ["High-Protein", "Low-Carb", "Budget"];
    const badTags = ["High Cholesterol"];
    const neutralTags = ["Moderate", "Balanced"];

    if (goodTags.contains(tagName)) {
      return Colors.green[700]!;
    } else if (badTags.contains(tagName)) {
      return Colors.red[700]!;
    } else if (neutralTags.contains(tagName)) {
      return Colors.yellow[700]!;
    } else {
      return Colors.grey[600]!; // Default color for unknown tags
    }
  }
}

class RecipeSectionScreen extends StatefulWidget {
  final String sectionTitle;
  final List<String> filters;
  const RecipeSectionScreen({super.key, required this.sectionTitle, required this.filters});

  @override
  _RecipeSectionScreenState createState() => _RecipeSectionScreenState();
}

class _RecipeSectionScreenState extends State<RecipeSectionScreen> {
  late List<bool> selectedFilters;
  late Future<List<dynamic>> sectionRecipes;

  @override
  void initState() {
    super.initState();
    selectedFilters = List.generate(widget.filters.length, (index) => false);
    sectionRecipes = fetchSectionRecipes(widget.sectionTitle);
  }

  Future<List<dynamic>> fetchSectionRecipes(String sectionTitle) async {
    List<dynamic> allRecipes = await ApiService.getRecipes();
    List<dynamic> filteredRecipes = allRecipes
        .where((recipe) => recipe['meal_type'] == sectionTitle)
        .toList();
    filteredRecipes.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    return filteredRecipes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.sectionTitle,
          style: GoogleFonts.lexend(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(widget.filters.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: ChoiceChip(
                      label: Text(
                        widget.filters[index],
                        style: GoogleFonts.lexend(
                          color: selectedFilters[index] ? Colors.black : Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      selected: selectedFilters[index],
                      selectedColor: Colors.white,
                      backgroundColor: Colors.black,
                      shape: StadiumBorder(side: BorderSide(color: Colors.white)),
                      onSelected: (bool selected) {
                        setState(() {
                          selectedFilters[index] = selected;
                        });
                      },
                    ),
                  );
                }),
              ),
            ),
            SizedBox(height: 8),
            TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search ${widget.sectionTitle} recipes...",
                hintStyle: TextStyle(color: Colors.white54),
                prefixIcon: Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: sectionRecipes,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Error loading recipes",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  } else if (snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        "No recipes available for ${widget.sectionTitle}",
                        style: GoogleFonts.lexend(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    );
                  } else {
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 2 / 3,
                      ),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        var recipe = snapshot.data![index];
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecipeDetailsScreen(
                                recipeId: recipe['recipe_id'],
                                onHearted: (heartedData) {
                                  // Handle hearted state
                                },
                              ),
                            ),
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: NetworkImage(recipe['image_url']),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                left: 8,
                                right: 8,
                                child: Text(
                                  recipe['name'] ?? '',
                                  style: GoogleFonts.lexend(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(0, 1),
                                        blurRadius: 4,
                                        color: Colors.black,
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Tags on the Right Side
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: (recipe['tags'] as List<dynamic>? ?? []).map((tag) {
                                    return Container(
                                      margin: EdgeInsets.only(bottom: 4),
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getTagColor(tag['tag_name'] ?? "Unknown"),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        tag['tag_name'] ?? '',
                                        style: GoogleFonts.lexend(
                                          fontSize: 10,
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTagColor(String tagName) {
    const goodTags = ["High-Protein", "Low-Carb", "Budget"];
    const badTags = ["High Cholesterol"];
    const neutralTags = ["Moderate", "Balanced"];

    if (goodTags.contains(tagName)) {
      return Colors.green[700]!;
    } else if (badTags.contains(tagName)) {
      return Colors.red[700]!;
    } else if (neutralTags.contains(tagName)) {
      return Colors.yellow[700]!;
    } else {
      return Colors.grey[600]!; // Default color for unknown tags
    }
  }
}
