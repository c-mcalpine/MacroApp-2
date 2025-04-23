import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/services/api_service.dart';

class SearchScreen extends StatefulWidget {
  final Function(int) onRecipeSelected;
  const SearchScreen({super.key, required this.onRecipeSelected});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String query = "";
  List<dynamic> searchResults = [];
  bool isLoading = false;
  final TextEditingController _controller = TextEditingController();

  void _performSearch(String input) async {
    setState(() {
      isLoading = true;
    });

    try {
      final allRecipes = await ApiService.getRecipes();
      final results = allRecipes.where((recipe) {
        final name = recipe['name'].toLowerCase();
        final tags = (recipe['tags'] as List<dynamic>).map((t) => t['tag_name'].toLowerCase());
        return name.contains(input.toLowerCase()) || tags.any((tag) => tag.contains(input.toLowerCase()));
      }).toList();

      setState(() {
        searchResults = results;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        searchResults = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Search", style: GoogleFonts.lexend(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              style: TextStyle(color: Colors.white),
              onChanged: (value) => setState(() => query = value),
              onSubmitted: _performSearch,
              decoration: InputDecoration(
                hintText: "Search by name or tag...",
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
            isLoading
                ? CircularProgressIndicator()
                : searchResults.isEmpty && query.isNotEmpty
                    ? Text("No results found.", style: TextStyle(color: Colors.white70))
                    : Expanded(
                        child: GridView.builder(
                          itemCount: searchResults.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 3 / 4,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemBuilder: (context, index) {
                            final recipe = searchResults[index];
                            return GestureDetector(
                              onTap: () => widget.onRecipeSelected(recipe['recipe_id']),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: NetworkImage(recipe['image_url']),
                                          fit: BoxFit.cover,
                                        ),
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
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                                          ),
                                        ),
                                        child: Text(
                                          recipe['short_name'] ?? recipe['name'],
                                          style: GoogleFonts.lexend(color: Colors.white, fontWeight: FontWeight.bold),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
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
