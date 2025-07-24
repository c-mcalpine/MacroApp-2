import 'package:flutter/material.dart';
import 'package:frontend/screens/list_details_screen.dart';
import '../widgets/common/network_image_widget.dart';

class SavedRecipesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> heartedRecipes; // Pass hearted recipes
  final Map<String, List<Map<String, dynamic>>> customLists; // Pass custom lists

  const SavedRecipesScreen({super.key, 
    required this.heartedRecipes,
    required this.customLists,
  });

  @override
  SavedRecipesScreenState createState() => SavedRecipesScreenState();
}

class SavedRecipesScreenState extends State<SavedRecipesScreen> {
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
        title: const Text(
          "Saved Recipes",
          style: TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'Lexend'),
        ),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hearted Recipes Section
            const Text(
              "Hearted Recipes",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Lexend',
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: widget.heartedRecipes.isEmpty
                  ? const Center(
                      child: Text(
                        "No hearted recipes yet.",
                        style: TextStyle(color: Colors.white70, fontFamily: 'Lexend'),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.heartedRecipes.length,
                      itemBuilder: (context, index) {
                        var recipe = widget.heartedRecipes[index];
                        return Card(
                          color: Colors.white10,
                          margin: const EdgeInsets.only(right: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            width: 150,
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: NetworkImageWidget(
                                      imageUrl: recipe['image_url'],
                                      fit: BoxFit.cover,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  recipe['name'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Lexend',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                const Icon(Icons.favorite, color: Colors.red, size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 24),

            // Custom Lists Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "My Lists",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Lexend',
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    _showCreateListDialog();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.customLists.keys.length,
              itemBuilder: (context, index) {
                String listName = widget.customLists.keys.elementAt(index);
                return Card(
                  color: Colors.white10,
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    title: Text(
                      listName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lexend',
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward, color: Colors.white),
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
          title: const Text(
            "Create New List",
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Lexend'),
          ),
          content: TextField(
            decoration: const InputDecoration(hintText: "Enter list name"),
            onChanged: (value) {
              newListName = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
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
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }
}
