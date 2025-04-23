import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/screens/list_details_screen.dart';

class SavedRecipesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> heartedRecipes; // Pass hearted recipes
  final Map<String, List<Map<String, dynamic>>> customLists; // Pass custom lists

  const SavedRecipesScreen({super.key, 
    required this.heartedRecipes,
    required this.customLists,
  });

  @override
  _SavedRecipesScreenState createState() => _SavedRecipesScreenState();
}

class _SavedRecipesScreenState extends State<SavedRecipesScreen> {
  void _navigateToListDetails(String listName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListDetailsScreen(
          listName: listName,
          recipes: widget.customLists[listName] ?? [],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Saved Recipes",
          style: GoogleFonts.lexend(color: Colors.white, fontSize: 24),
        ),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hearted Recipes Section
            Text(
              "Hearted Recipes",
              style: GoogleFonts.lexend(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: widget.heartedRecipes.isEmpty
                  ? Center(
                      child: Text(
                        "No hearted recipes yet.",
                        style: GoogleFonts.lexend(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.heartedRecipes.length,
                      itemBuilder: (context, index) {
                        var recipe = widget.heartedRecipes[index];
                        return Card(
                          color: Colors.white10,
                          margin: EdgeInsets.only(right: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            width: 150,
                            padding: EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: DecorationImage(
                                        image: NetworkImage(recipe['image_url']),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  recipe['name'],
                                  style: GoogleFonts.lexend(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Icon(Icons.favorite, color: Colors.red, size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(height: 24),

            // Custom Lists Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "My Lists",
                  style: GoogleFonts.lexend(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    _showCreateListDialog();
                  },
                ),
              ],
            ),
            SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: widget.customLists.keys.length,
              itemBuilder: (context, index) {
                String listName = widget.customLists.keys.elementAt(index);
                return Card(
                  color: Colors.white10,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    title: Text(
                      listName,
                      style: GoogleFonts.lexend(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Icon(Icons.arrow_forward, color: Colors.white),
                    onTap: () => _navigateToListDetails(listName),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      backgroundColor: Colors.black,
    );
  }

  void _showCreateListDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String? newListName;
        return AlertDialog(
          title: Text(
            "Create New List",
            style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            decoration: InputDecoration(hintText: "Enter list name"),
            onChanged: (value) {
              newListName = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (newListName != null && newListName!.trim().isNotEmpty) {
                  setState(() {
                    widget.customLists[newListName!.trim()] = [];
                  });
                }
                Navigator.pop(context);
              },
              child: Text("Create"),
            ),
          ],
        );
      },
    );
  }
}
