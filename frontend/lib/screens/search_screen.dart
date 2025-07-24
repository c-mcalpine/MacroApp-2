import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/screens/recipe_details_screen.dart';
import '../widgets/common/network_image_widget.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);
  
  @override
  SearchScreenState createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  String _searchQuery = '';
  String _selectedSortMetric = 'newest';
  final List<String> _selectedCuisines = [];
  final List<String> _selectedTags = [];
  RangeValues _proteinRatioRange = const RangeValues(0, 1);
  RangeValues _priceRange = const RangeValues(0, 50);
  Future<List<dynamic>>? _searchResults;

  @override
  void initState() {
    super.initState();
    _searchResults = _fetchInitialResults();
  }

  Future<List<dynamic>> _fetchInitialResults() async {
    final recipes = await ApiService.getRecipes();
    recipes.shuffle();
    return recipes.take(10).toList();
  }

  void _applySearch() {
    setState(() {
      _searchResults = ApiService.getRecipes().then((allRecipes) {
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
      body: SafeArea(
        child: Column(
          children: [
            // Search Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
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
                      setState(() {
                        _searchQuery = value;
                        _applySearch();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Sort Options
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildSortChip('Newest'),
                        const SizedBox(width: 8),
                        _buildSortChip('Protein/Cal Ratio'),
                        const SizedBox(width: 8),
                        _buildSortChip('Cost/Protein'),
                        const SizedBox(width: 8),
                        _buildSortChip('Meal Prep Score'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Filters Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Protein/Calorie Ratio Slider
                  const Text(
                    "Protein/Calorie Ratio",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
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
                      setState(() {
                        _proteinRatioRange = values;
                        _applySearch();
                      });
                    },
                  ),

                  // Price Range Slider
                  const Text(
                    "Price Range (\$)",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
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
                      setState(() {
                        _priceRange = values;
                        _applySearch();
                      });
                    },
                  ),
                ],
              ),
            ),

            // Results
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _searchResults,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
                  }
                  
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        "Error loading recipes",
                        style: TextStyle(color: Colors.white, fontFamily: 'Lexend'),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        "No recipes found",
                        style: TextStyle(color: Colors.white, fontFamily: 'Lexend'),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final recipe = snapshot.data![index];
                      return _buildRecipeCard(recipe);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip(String label) {
    final key = label.toLowerCase().replaceAll('/', '_');
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: _selectedSortMetric == key ? Colors.black : Colors.white,
          fontSize: 14,
          fontFamily: 'Lexend',
        ),
      ),
      selected: _selectedSortMetric == key,
      selectedColor: Colors.white,
      backgroundColor: Colors.white12,
      onSelected: (selected) {
        setState(() {
          _selectedSortMetric = selected ? key : 'newest';
          _applySearch();
        });
      },
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
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
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white12,
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            NetworkImageWidget(
              imageUrl: recipe['image_url'] ?? 'https://via.placeholder.com/150',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                ),
              ),
            ),
            // Recipe Info
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    recipe['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Lexend',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (recipe['nutrition'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      "${recipe['nutrition']['protein']}g protein",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontFamily: 'Lexend',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
