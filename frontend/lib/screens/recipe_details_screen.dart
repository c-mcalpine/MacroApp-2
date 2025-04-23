import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/supabase_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend/screens/chatbot_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class RecipeDetailsScreen extends StatefulWidget {
  final int recipeId;
  final Function(Map<String, dynamic>) onHearted; // Callback for hearted recipes

  const RecipeDetailsScreen({super.key, required this.recipeId, required this.onHearted});

  @override
  _RecipeDetailsScreenState createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen>
    with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> recipeDetails;
  int _touchedIndex = -1; // Track the currently touched section
  bool _isHearted = false; // Track if the recipe is hearted
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    recipeDetails = ApiService.getRecipeDetails(widget.recipeId);
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleHeart(Map<String, dynamic> recipe) async {
    setState(() {
      _isHearted = !_isHearted;
    });

    try {
      final userId = await AuthService.getUserId();
      if (userId != null) {
        if (_isHearted) {
          await SupabaseService.heartRecipe(userId, recipe['recipe_id']);
          widget.onHearted(recipe);
          _animationController.forward(from: 0.0);
        } else {
          await SupabaseService.unheartRecipe(userId, recipe['recipe_id']);
        }
      }
    } catch (e) {
      print('Error toggling heart: $e');
      setState(() {
        _isHearted = !_isHearted;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update recipe status')),
      );
    }
  }

  void _shopRecipe(Map<String, dynamic> recipe) async {
    try {
      final ingredients = recipe['ingredients'] ?? [];
      final shoppingListUrl = await ApiService.getInstacartShoppingList(ingredients);

      if (shoppingListUrl != null && await canLaunch(shoppingListUrl)) {
        await launch(shoppingListUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Unable to generate shopping list. Please check your API key and permissions.")),
        );
      }
    } catch (e) {
      if (e.toString().contains("403")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Access denied. Please check your API key and permissions.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error generating shopping list: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,  // Make background transparent to see gradient
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,               // Dark at the top
              Colors.black.withAlpha(200), // Slightly transparent
              Colors.black.withAlpha(100), // More transparent
              Colors.black.withAlpha(0),          // Fully transparent at the bottom
            ],
          ),
        ),
      ),
      title: Text(
        "Recipe Details",
        style: GoogleFonts.lexend(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Heart Icon
          IconButton(
            icon: Icon(
              _isHearted ? Icons.favorite : Icons.favorite_border,
              color: _isHearted ? Colors.red : Colors.white,
            ),
            onPressed: () {
              recipeDetails.then((recipe) {
                _toggleHeart(recipe['recipe']);
              });
            },
          ),
          // Save to List Button
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: () {
              _showSaveToListDialog(context, "Recipe Name", {}); // Replace with actual recipe name and custom lists
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FutureBuilder<Map<String, dynamic>>(
            future: recipeDetails,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError || snapshot.data == null) {
                return Center(
                  child: Text(
                    "Error loading recipe",
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              var recipe = snapshot.data!;
              var recipeDetails = recipe['recipe'];

              return SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Section: Title & Tags
                    Stack(
                      children: [
                        // Background Image
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              recipe['recipe']['image_url'] ?? '',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[800],
                                  child: Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.white,
                                      size: 48,
                                    ),
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            (loadingProgress.expectedTotalBytes ?? 1)
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // Title & Tags Content
                        Positioned.fill(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Recipe Title
                              Text(
                                recipe['recipe']['name'] ?? "Unknown Recipe",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.lexend(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16),
                              // Tags
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: (recipe['tags'] as List<dynamic>? ?? []).map((tag) {
                                  return Chip(
                                    backgroundColor: _getTagColor(tag['tag_name'] ?? "Unknown"),
                                    label: Text(
                                      tag['tag_name'] ?? "Unknown",
                                      style: GoogleFonts.lexend(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    elevation: 4,
                                    shadowColor: Colors.black45,
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    
                    // Cooking Time & Servings
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "⏳ ${recipeDetails['total_time'] ?? 'N/A'} min",
                          style: GoogleFonts.lexend(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "🍽 ${recipeDetails['servings'] ?? 'N/A'} servings",
                          style: GoogleFonts.lexend(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Chatbot, Instacart, and Notes Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Chatbot Button
                        ElevatedButton.icon(
                          onPressed: () => _showChatbotScreen(context, recipe),
                          icon: Icon(Icons.auto_awesome, color: Colors.white),
                          label: Text(
                            "Ask",
                            style: GoogleFonts.lexend(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        // Instacart Integration
                        ElevatedButton.icon(
                          onPressed: () => _shopRecipe(recipe), // Pass the resolved recipe directly
                          icon: Icon(Icons.shopping_cart_outlined, color: Colors.white),
                          label: Text(
                            "Shop",
                            style: GoogleFonts.lexend(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        // Notes Placeholder
                        ElevatedButton.icon(
                          onPressed: () {
                            // Placeholder for Notes integration
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Notes feature coming soon!")),
                            );
                          },
                          icon: Icon(Icons.note_add_outlined, color: Colors.white),
                          label: Text(
                            "Notes",
                            style: GoogleFonts.lexend(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ingredients Section
                        Text(
                          "Ingredients",
                          style: GoogleFonts.lexend(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4), // Minimal spacing
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: (() {
                            // Group ingredients by section_name
                            Map<String, List<dynamic>> groupedIngredients = {};
                            for (var ingredient in recipe['ingredients'] as List<dynamic>) {
                              String sectionName = ingredient['section_name'] ?? "General";
                              if (!groupedIngredients.containsKey(sectionName)) {
                                groupedIngredients[sectionName] = [];
                              }
                              groupedIngredients[sectionName]!.add(ingredient);
                            }

                            // Build UI for each section
                            return groupedIngredients.entries.map((entry) {
                              return Card(
                                color: Colors.white10,
                                margin: EdgeInsets.symmetric(vertical: 4.0), // Minimal margin
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(8.0), // Compact padding
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Section Header
                                      Text(
                                        entry.key,
                                        style: GoogleFonts.lexend(
                                          fontSize: 18, // Slightly smaller font size
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 4), // Minimal spacing
                                      // Ingredients in Two Columns
                                      Wrap(
                                        spacing: 16, // Horizontal spacing between columns
                                        runSpacing: 4, // Vertical spacing between rows
                                        children: entry.value.map((ingredient) {
                                          return SizedBox(
                                            width: (MediaQuery.of(context).size.width - 64) / 2, // Dynamically adjust width for two columns
                                            child: Text(
                                              "• ${ingredient['amount']} ${ingredient['unit']} ${ingredient['name']}",
                                              style: GoogleFonts.lexend(
                                                fontSize: 14, // Compact font size
                                                color: Colors.white70,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList();
                          })(),
                        ),
                        SizedBox(height: 8), // Minimal spacing
                    
                        // Instructions Section
                        Text(
                          "Instructions",
                          style: GoogleFonts.lexend(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: (recipe['instructions'] as List<dynamic>).map((step) {
                            return _CollapsibleInstructionCard(
                              stepNumber: step['step_number'],
                              stepHeader: step['step_header'],
                              stepDuration: step['step_duration'],
                              instructionText: step['instruction_text'],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    
                    // Nutrition Info
                    Text(
                      "Nutrition Facts (Per Serving)",
                      style: GoogleFonts.lexend(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Card(
                      color: Colors.white10,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Pie Chart and Calories-per-Gram Indicator
                            Row(
                              children: [
                                // Pie Chart
                                Expanded(
                                  flex: 2,
                                  child: SizedBox(
                                    height: 120,
                                    child: Builder(
                                      builder: (context) {
                                        var pieChartSections = _getPieChartSections(recipe, _touchedIndex);
                                        if (pieChartSections.isEmpty) {
                                          return Center(
                                            child: Text(
                                              "No nutrition data available",
                                              style: GoogleFonts.lexend(color: Colors.white),
                                            ),
                                          );
                                        }
                                        return PieChart(
                                          PieChartData(
                                            sections: pieChartSections,
                                            centerSpaceRadius: 30,
                                            sectionsSpace: 2,
                                            pieTouchData: PieTouchData(
                                              touchCallback: (event, response) {
                                                if (event.isInterestedForInteractions &&
                                                    response != null &&
                                                    response.touchedSection != null) {
                                                  setState(() {
                                                    _touchedIndex = response
                                                        .touchedSection!
                                                        .touchedSectionIndex;
                                                  });
                                                } else {
                                                  setState(() {
                                                    _touchedIndex = -1;
                                                  });
                                                }
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                // Calories-per-Gram Indicator
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Calories per Gram of Protein",
                                        style: GoogleFonts.lexend(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        _getCaloriesPerGramText(recipe),
                                        style: GoogleFonts.lexend(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: _getCaloriesPerGramColor(recipe),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            // Divider Line
                            Container(
                              height: 1,
                              color: Colors.grey[700],
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                            ),
                            // Nutrients Grid
                            GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 3.5,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: recipe['nutrition'].length,
                              itemBuilder: (context, index) {
                                var nutrient = recipe['nutrition'][index];
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      nutrient['name'] ?? "Unknown",
                                      style: GoogleFonts.lexend(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      "${nutrient['value']} ${nutrient['unit']}",
                                      style: GoogleFonts.lexend(
                                        fontSize: 16,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Meal Prep Tips
                    Text(
                      "Meal Prep Tips",
                      style: GoogleFonts.lexend(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: (recipe['meal_prep_tips'] as List<dynamic>).map((tip) {
                        return Card(
                          color: Colors.white10,
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icon for Storage Type
                                Icon(
                                  _getStorageIcon(tip['storage_type']),
                                  color: Colors.white,
                                  size: 32,
                                ),
                                SizedBox(width: 16),
                                // Tip Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tip['storage_type'] ?? "Unknown",
                                        style: GoogleFonts.lexend(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        tip['details'] ?? "",
                                        style: GoogleFonts.lexend(
                                          fontSize: 16,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
          if (_isHearted)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  double progress = _animationController.value;
                  return Opacity(
                    opacity: 1 - progress,
                    child: Transform.translate(
                      offset: Offset(0, -200 * progress),
                      child: Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 100,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showSaveToListDialog(BuildContext context, String recipeName, Map<String, List<Map<String, dynamic>>> customLists) async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to save recipes')),
        );
        return;
      }

      final recipe = await recipeDetails;
      final recipeId = recipe['recipe']['recipe_id'];
      
      final userLists = await SupabaseService.getCustomLists(userId);
      
      if (userLists.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Create a list first to save recipes')),
        );
        return;
      }

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              "Save to List",
              style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: userLists.map((list) {
                return ListTile(
                  title: Text(
                    list['name'],
                    style: GoogleFonts.lexend(),
                  ),
                  onTap: () async {
                    try {
                      await SupabaseService.addRecipeToList(
                        listId: list['id'],
                        recipeId: recipeId,
                      );
                      
                      setState(() {
                        if (!customLists.containsKey(list['name'])) {
                          customLists[list['name']] = [];
                        }
                        customLists[list['name']]!.add(recipe['recipe']);
                      });
                      
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Recipe added to ${list['name']}')),
                      );
                    } catch (e) {
                      print('Error adding recipe to list: $e');
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to add recipe to list')),
                      );
                    }
                  },
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error showing save dialog: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load lists')),
      );
    }
  }

  void _showChatbotScreen(BuildContext context, Map<String, dynamic> recipe) {
    final recipeId = recipe['recipe']?['recipe_id']; // Correctly extract recipe_id
    print("Navigating to ChatbotScreen with recipeId: $recipeId"); // Log recipeId
    print("Recipe data: $recipe"); // Log the full recipe object for debugging

    if (recipeId == null || recipeId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid recipe data. Cannot open AI chat.")),
      );
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: ChatbotScreen(recipe: recipe),
        ),
        transitionDuration: Duration(milliseconds: 250),
      ),
    );
  }
}

// Collapsible Ingredient Section Widget
class _CollapsibleIngredientSection extends StatefulWidget {
  final String sectionName;
  final List<dynamic> ingredients;

  const _CollapsibleIngredientSection({
    required this.sectionName,
    required this.ingredients,
  });

  @override
  __CollapsibleIngredientSectionState createState() =>
      __CollapsibleIngredientSectionState();
}

class __CollapsibleIngredientSectionState
    extends State<_CollapsibleIngredientSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Row(
            children: [
              Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Text(
                widget.sectionName,
                style: GoogleFonts.lexend(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        if (_isExpanded)
          Card(
            color: Colors.white10,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.ingredients.map((ingredient) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      "• ${ingredient['amount']} ${ingredient['unit']} ${ingredient['name']}${ingredient['notes']}",
                      style: GoogleFonts.lexend(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }
}

// Collapsible Instruction Card Widget
class _CollapsibleInstructionCard extends StatefulWidget {
  final int stepNumber;
  final String stepHeader;
  final String? stepDuration;
  final String instructionText;

  const _CollapsibleInstructionCard({
    required this.stepNumber,
    required this.stepHeader,
    this.stepDuration,
    required this.instructionText,
  });

  @override
  __CollapsibleInstructionCardState createState() =>
      __CollapsibleInstructionCardState();
}

class __CollapsibleInstructionCardState
    extends State<_CollapsibleInstructionCard> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
          if (_isExpanded) {
            _animationController.forward();
          } else {
            _animationController.reverse();
          }
        });
      },
      child: Card(
        color: Colors.white10,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Text(
                      "${widget.stepNumber}",
                      style: GoogleFonts.lexend(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.stepHeader,
                      style: GoogleFonts.lexend(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      // Step Duration
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          widget.stepDuration ?? "—",
                          style: GoogleFonts.lexend(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      // Dropdown Indicator
                      RotationTransition(
                        turns: Tween(begin: 0.0, end: 0.5).animate(_animationController),
                        child: Icon(
                          Icons.expand_more,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_isExpanded) ...[
                SizedBox(height: 8),
                Text(
                  widget.instructionText,
                  style: GoogleFonts.lexend(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Function to determine tag color
Color _getTagColor(String tagName) {
  const goodTags = ["high-protein", "low-carb", "budget"];
  const badTags = ["high cholesterol"];
  const neutralTags = ["moderate", "balanced"];

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

// Function to get pie chart sections
List<PieChartSectionData> _getPieChartSections(Map<String, dynamic> recipe, int touchedIndex) {
  double protein = _getNutrientValue(recipe['nutrition'], "protein");
  double carbs = _getNutrientValue(recipe['nutrition'], "carbs");
  double fat = _getNutrientValue(recipe['nutrition'], "fat");
  double total = protein + carbs + fat;

  if (total <= 0) return [];

  return [
    PieChartSectionData(
      value: (protein / total) * 100,
      color: Colors.green,
      title: touchedIndex == 0
          ? "${protein.toStringAsFixed(0)}g (${((protein / total) * 100).toStringAsFixed(1)}%)"
          : "Protein",
      radius: touchedIndex == 0 ? 60 : 50,
      titleStyle: GoogleFonts.lexend(
        color: Colors.white,
        fontSize: touchedIndex == 0 ? 14 : 12,
        fontWeight: FontWeight.bold,
      ),
    ),
    PieChartSectionData(
      value: (carbs / total) * 100,
      color: Colors.blue,
      title: touchedIndex == 1
          ? "${carbs.toStringAsFixed(0)}g (${((carbs / total) * 100).toStringAsFixed(1)}%)"
          : "Carbs",
      radius: touchedIndex == 1 ? 60 : 50,
      titleStyle: GoogleFonts.lexend(
        color: Colors.white,
        fontSize: touchedIndex == 1 ? 14 : 12,
        fontWeight: FontWeight.bold,
      ),
    ),
    PieChartSectionData(
      value: (fat / total) * 100,
      color: Colors.orange,
      title: touchedIndex == 2
          ? "${fat.toStringAsFixed(0)}g (${((fat / total) * 100).toStringAsFixed(1)}%)"
          : "Fat",
      radius: touchedIndex == 2 ? 60 : 50,
      titleStyle: GoogleFonts.lexend(
        color: Colors.white,
        fontSize: touchedIndex == 2 ? 14 : 12,
        fontWeight: FontWeight.bold,
      ),
    ),
  ];
}

// Function to calculate calories per gram of protein
String _getCaloriesPerGramText(Map<String, dynamic> recipe) {
  double calories = _getNutrientValue(recipe['nutrition'], "calories");
  double protein = _getNutrientValue(recipe['nutrition'], "protein");

  if (protein <= 0) return "No protein data available";

  double calPerGram = calories / protein;

  if (calPerGram < 9) {
    return "Great (${calPerGram.toStringAsFixed(1)} cal/g)";
  } else if (calPerGram <= 12) {
    return "Moderate (${calPerGram.toStringAsFixed(1)} cal/g)";
  } else {
    return "Subprime (${calPerGram.toStringAsFixed(1)} cal/g)";
  }
}

// Function to get color for calories per gram indicator
Color _getCaloriesPerGramColor(Map<String, dynamic> recipe) {
  double calories = _getNutrientValue(recipe['nutrition'], "calories");
  double protein = _getNutrientValue(recipe['nutrition'], "protein");
  double calPerGram = protein > 0 ? calories / protein : 0;

  if (calPerGram < 9) {
    return Colors.green;
  } else if (calPerGram <= 12) {
    return Colors.yellow;
  } else {
    return Colors.red;
  }
}

// Helper function to get nutrient value by name
double _getNutrientValue(List<dynamic> nutrition, String nutrientName) {
  var nutrient = nutrition.firstWhere(
    (item) => (item['name']?.toLowerCase() ?? '') == nutrientName.toLowerCase(),
    orElse: () => null,
  );
  return nutrient != null && nutrient['value'] != null
      ? (nutrient['value'] as num).toDouble()
      : 0.0;
}

// Helper function to get storage type icon
IconData _getStorageIcon(String? storageType) {
  switch (storageType?.toLowerCase()) {
    case "refrigeration":
      return Icons.kitchen; // Fridge icon
    case "freezing":
      return Icons.ac_unit; // Freezer icon
    case "pantry":
      return Icons.inventory_2; // Pantry icon
    default:
      return Icons.info; // Default icon
  }
}
