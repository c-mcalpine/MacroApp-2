import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/screens/recipe_details_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key});

  @override
  SearchResultsScreenState createState() => SearchResultsScreenState();
}

class SearchResultsScreenState extends State<SearchResultsScreen> {
  String query = "";
  late Future<List<dynamic>> searchResults;

  @override
  void initState() {
    super.initState();
    searchResults = ApiService.searchRecipes(query);
  }

  void _onSearchChanged(String value) {
    setState(() {
      query = value;
      searchResults = ApiService.searchRecipes(query);
    });
  }

  void navigateToRecipe(int recipeId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailsScreen(
          recipeId: recipeId,
          onHearted: (heartedData) {
            // Handle hearted state
          },
        ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Search recipes...",
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
          ),
          onChanged: _onSearchChanged,
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: searchResults,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(
              child: Text(
                "An error occurred while searching. Please try again later.",
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
            return Center(
              child: Text(
                "No recipes found for \"$query\".",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Lexend',
                ),
                textAlign: TextAlign.center,
              ),
            );
          } else {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var recipe = snapshot.data![index];
                return GestureDetector(
                  onTap: () => navigateToRecipe(recipe['recipe_id']),
                  child: Card(
                    color: Colors.white10,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          recipe['image_url'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(
                        recipe['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lexend',
                        ),
                      ),
                      subtitle: Text(
                        recipe['short_description'] ?? "",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: 'Lexend',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
