import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/screens/recipe_details_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../widgets/common/network_image_widget.dart';

class ExploreRecipesScreen extends StatefulWidget {
  final Function(int) onRecipeSelected; // Callback for recipe selection

  const ExploreRecipesScreen({super.key, required this.onRecipeSelected});

  @override
  ExploreRecipesScreenState createState() => ExploreRecipesScreenState();
}

class ExploreRecipesScreenState extends State<ExploreRecipesScreen> with TickerProviderStateMixin {
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
  static final Logger _logger = Logger();

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

  String _searchQuery = '';
  String _selectedSortMetric = 'newest'; // Default sort
  final List<String> _selectedCuisines = [];
  final List<String> _selectedTags = [];
  RangeValues _proteinRatioRange = const RangeValues(0, 1); // Protein/Calorie ratio range
  RangeValues _priceRange = const RangeValues(0, 50); // Price range in dollars

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacityAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    
    if (kDebugMode) {
      _logger.i('Initializing recipes...');
    }
    recipes = ApiService.getRecipes().catchError((error) {
      if (kDebugMode) {
        _logger.e('Error loading recipes: $error');
      }
      return [];
    });
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
          if (kDebugMode) {
            _logger.e("🔥 Filter error: $e");
            _logger.e("📌 Stack trace: $stack");
          }
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'Lexend',
            ),
          ),
          selected: activeFilters.contains(key),
          selectedColor: isExclusion ? Colors.red : Colors.deepOrange,
          backgroundColor: Colors.grey[800],
          shape: const StadiumBorder(side: BorderSide(color: Colors.white)),
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
      shape: const RoundedRectangleBorder(
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
                  const Text(
                    "Filter Options",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Lexend',
                    ),
                  ),
                  const SizedBox(height: 16),
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

  void _showAdvancedSearch() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              builder: (_, controller) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Advanced Search",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Lexend',
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Search Bar
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Search recipes...",
                          hintStyle: const TextStyle(color: Colors.white54),
                          prefixIcon: const Icon(Icons.search, color: Colors.white),
                          filled: true,
                          fillColor: Colors.white12,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                      ),
                      const SizedBox(height: 24),

                      // Sort By
                      const Text(
                        "Sort By",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Lexend',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Newest'),
                            selected: _selectedSortMetric == 'newest',
                            onSelected: (selected) {
                              setState(() => _selectedSortMetric = 'newest');
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Protein/Cal Ratio'),
                            selected: _selectedSortMetric == 'protein_ratio',
                            onSelected: (selected) {
                              setState(() => _selectedSortMetric = 'protein_ratio');
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Cost/Protein'),
                            selected: _selectedSortMetric == 'cost_protein',
                            onSelected: (selected) {
                              setState(() => _selectedSortMetric = 'cost_protein');
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Meal Prep Score'),
                            selected: _selectedSortMetric == 'meal_prep_score',
                            onSelected: (selected) {
                              setState(() => _selectedSortMetric = 'meal_prep_score');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Protein/Calorie Ratio Range
                      const Text(
                        "Protein/Calorie Ratio",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Lexend',
                        ),
                      ),
                      RangeSlider(
                        values: _proteinRatioRange,
                        min: 0,
                        max: 1,
                        divisions: 20,
                        labels: RangeLabels(
                          _proteinRatioRange.start.toStringAsFixed(2),
                          _proteinRatioRange.end.toStringAsFixed(2),
                        ),
                        onChanged: (RangeValues values) {
                          setState(() => _proteinRatioRange = values);
                        },
                      ),
                      
                      // Price Range
                      const Text(
                        "Price Range (\$)",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Lexend',
                        ),
                      ),
                      RangeSlider(
                        values: _priceRange,
                        min: 0,
                        max: 50,
                        divisions: 50,
                        labels: RangeLabels(
                          "\$${_priceRange.start.toInt()}",
                          "\$${_priceRange.end.toInt()}",
                        ),
                        onChanged: (RangeValues values) {
                          setState(() => _priceRange = values);
                        },
                      ),

                      // Apply Button
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            _applyAdvancedSearch();
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Apply Filters",
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
                );
              },
            );
          },
        );
      },
    );
  }

  void _applyAdvancedSearch() {
    setState(() {
      recipes = ApiService.getRecipes().then((allRecipes) {
        // Filter recipes based on search criteria
        var filteredRecipes = allRecipes.where((recipe) {
          // Text search
          if (_searchQuery.isNotEmpty) {
            final name = (recipe['name'] ?? '').toString().toLowerCase();
            final description = (recipe['description'] ?? '').toString().toLowerCase();
            if (!name.contains(_searchQuery.toLowerCase()) && 
                !description.contains(_searchQuery.toLowerCase())) {
              return false;
            }
          }

          // Protein/Calorie ratio filter
          final protein = recipe['nutrition']?['protein'] ?? 0;
          final calories = recipe['nutrition']?['calories'] ?? 1;
          final proteinRatio = protein / calories;
          if (proteinRatio < _proteinRatioRange.start || 
              proteinRatio > _proteinRatioRange.end) {
            return false;
          }

          // Price filter
          final price = recipe['price'] ?? 0;
          if (price < _priceRange.start || price > _priceRange.end) {
            return false;
          }

          // Cuisine filter
          if (_selectedCuisines.isNotEmpty) {
            final cuisine = recipe['cuisine'] ?? '';
            if (!_selectedCuisines.contains(cuisine)) {
              return false;
            }
          }

          // Tags filter
          if (_selectedTags.isNotEmpty) {
            final tags = (recipe['tags'] as List<dynamic>?)?.map((t) => t['tag_name'].toString()) ?? [];
            if (!_selectedTags.every((tag) => tags.contains(tag))) {
              return false;
            }
          }

          return true;
        }).toList();

        // Sort based on selected metric
        switch (_selectedSortMetric) {
          case 'protein_ratio':
            filteredRecipes.sort((a, b) {
              final aProtein = a['nutrition']?['protein'] ?? 0;
              final aCalories = a['nutrition']?['calories'] ?? 1;
              final bProtein = b['nutrition']?['protein'] ?? 0;
              final bCalories = b['nutrition']?['calories'] ?? 1;
              return (bProtein / bCalories).compareTo(aProtein / aCalories);
            });
            break;
          case 'cost_protein':
            filteredRecipes.sort((a, b) {
              final aPrice = a['price'] ?? 0;
              final aProtein = a['nutrition']?['protein'] ?? 1;
              final bPrice = b['price'] ?? 0;
              final bProtein = b['nutrition']?['protein'] ?? 1;
              return (aPrice / aProtein).compareTo(bPrice / bProtein);
            });
            break;
          case 'meal_prep_score':
            filteredRecipes.sort((a, b) {
              return _calculateMealPrepScore(b).compareTo(_calculateMealPrepScore(a));
            });
            break;
          default: // 'newest'
            filteredRecipes.sort((a, b) {
              final aDate = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
              final bDate = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
              return bDate.compareTo(aDate);
            });
        }

        return filteredRecipes;
      });
    });
  }

  double _calculateMealPrepScore(Map<String, dynamic> recipe) {
    double score = 0;
    
    // Storage type score (refrigerated = 1, frozen = 2)
    final storageType = recipe['storage_type'] ?? '';
    if (storageType == 'refrigerated') score += 1;
    if (storageType == 'frozen') score += 2;

    // Prep time score (inverse relationship - shorter prep time = higher score)
    final prepTime = recipe['prep_time'] ?? 60;
    score += (120 - prepTime) / 30; // Max 4 points for 0 min, 0 points for 120+ min

    // Ingredient count score (fewer ingredients = higher score)
    final ingredientCount = (recipe['ingredients'] as List<dynamic>?)?.length ?? 10;
    score += (20 - ingredientCount) / 5; // Max 4 points for 0 ingredients

    // Bulk meal prep tag bonus
    final tags = (recipe['tags'] as List<dynamic>?)?.map((t) => t['tag_name'].toString()) ?? [];
    if (tags.contains('Bulk Meal Prep')) score += 3;

    return score;
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
            const Text(
              "macro.",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                fontFamily: 'Lexend',
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: _showAdvancedSearch,
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // Persistent Filter Pills with Filter Button
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.filter_list, color: Colors.white),
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
                                  style: TextStyle(
                                    color: selectedFilters[index] ? Colors.black : Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'Lexend',
                                  ),
                                ),
                                selected: selectedFilters[index],
                                selectedColor: Colors.white,
                                backgroundColor: Colors.black,
                                shape: const StadiumBorder(side: BorderSide(color: Colors.white)),
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
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            children: [
                              NetworkImageWidget(
                                imageUrl: promos[index]['image']!,
                                fit: BoxFit.cover,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                alignment: Alignment.bottomLeft,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                                  ),
                                ),
                                child: Text(
                                  promos[index]['title']!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontFamily: 'Lexend',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Fetch and Display Recipes by Section
              FutureBuilder<List<dynamic>>(
                future: recipes,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        "An error occurred while loading recipes. Please try again later.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Lexend',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        "No recipes available at the moment.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Lexend',
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
                    
                    // Shuffle each category's recipes to randomize order
                    categorizedRecipes.forEach((key, recipes) {
                      recipes.shuffle();
                      // Limit to 10 recipes per category
                      if (recipes.length > 10) {
                        recipes.removeRange(10, recipes.length);
                      }
                    });
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: categorizedRecipes.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
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
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontFamily: 'Lexend',
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 220, // Fixed height for the carousel
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: entry.value.length,
                                  itemBuilder: (context, recipeIndex) {
                                    var recipe = entry.value[recipeIndex];
                                    return Container(
                                      width: 160, // Fixed width for each recipe card
                                      margin: const EdgeInsets.only(right: 12),
                                      child: GestureDetector(
                                        onTap: () => navigateToRecipe(recipe['recipe_id']),
                                        child: Stack(
                                          children: [
                                            // Recipe Image
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: NetworkImageWidget(
                                                  imageUrl: recipe['image_url'] ?? 'https://via.placeholder.com/150',
                                                  fit: BoxFit.cover,
                                                  borderRadius: BorderRadius.circular(12),
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
                                                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // Recipe Short Name
                                            Positioned(
                                              bottom: 12,
                                              left: 12,
                                              right: 12,
                                              child: Text(
                                                recipe['short_name'] ?? recipe['name'],
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  shadows: [
                                                    Shadow(
                                                      offset: Offset(0, 1),
                                                      blurRadius: 4,
                                                      color: Colors.black,
                                                    ),
                                                  ],
                                                  fontFamily: 'Lexend',
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            // Tags on the Right Side
                                            Positioned(
                                              top: 12,
                                              right: 12,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: (recipe['tags'] as List<dynamic>? ?? []).take(2).map((tag) {
                                                  return Container(
                                                    margin: const EdgeInsets.only(bottom: 4),
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: _getTagColor(tag['tag_name'] ?? "Unknown"),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      tag['tag_name'] ?? '',
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.white,
                                                        fontFamily: 'Lexend',
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
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
                  duration: const Duration(milliseconds: 300),
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
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        const CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.person, size: 50, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "User Name",
                          style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Lexend'),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {},
                          child: const Text(
                            "View Profile",
                            style: TextStyle(fontSize: 16, color: Colors.deepOrange, fontFamily: 'Lexend'),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const Divider(color: Colors.white24, thickness: 1, height: 24),
                        _buildProfileOption(Icons.tune, "Preferences"),
                        _buildProfileOption(Icons.history, "Recipe History"),
                        _buildProfileOption(Icons.people, "Refer a Friend"),
                        _buildProfileOption(Icons.help_outline, "Help"),
                        _buildProfileOption(Icons.settings, "Settings"),
                        _buildProfileOption(Icons.menu_book, "Blog"),
                        const Divider(color: Colors.white24, thickness: 1, height: 24),
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
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Lexend'),
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
  RecipeSectionScreenState createState() => RecipeSectionScreenState();
}

class RecipeSectionScreenState extends State<RecipeSectionScreen> {
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
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.sectionTitle,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            fontFamily: 'Lexend',
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
                        style: TextStyle(
                          color: selectedFilters[index] ? Colors.black : Colors.white,
                          fontSize: 14,
                          fontFamily: 'Lexend',
                        ),
                      ),
                      selected: selectedFilters[index],
                      selectedColor: Colors.white,
                      backgroundColor: Colors.black,
                      shape: const StadiumBorder(side: BorderSide(color: Colors.white)),
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
            const SizedBox(height: 8),
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search ${widget.sectionTitle} recipes...",
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: sectionRecipes,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        "Error loading recipes",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  } else if (snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        "No recipes available for ${widget.sectionTitle}",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontFamily: 'Lexend',
                        ),
                      ),
                    );
                  } else {
                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: NetworkImageWidget(
                                    imageUrl: recipe['image_url'] ?? 'https://via.placeholder.com/150',
                                    fit: BoxFit.cover,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
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
                                  style: const TextStyle(
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
                                    fontFamily: 'Lexend',
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
                                      margin: const EdgeInsets.only(bottom: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getTagColor(tag['tag_name'] ?? "Unknown"),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        tag['tag_name'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontFamily: 'Lexend',
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
