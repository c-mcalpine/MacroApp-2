import 'package:flutter/material.dart';
import '../widgets/common/network_image_widget.dart';

class ListDetailsScreen extends StatelessWidget {
  final String listName;
  final List<Map<String, dynamic>> recipes;

  const ListDetailsScreen({super.key, required this.listName, required this.recipes});

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> sortedRecipes = List.from(recipes)
      ..sort((a, b) => a['name'].compareTo(b['name']));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          listName,
          style: TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'Lexend'),
        ),
        backgroundColor: Colors.black,
      ),
      body: sortedRecipes.isEmpty
          ? Center(
              child: Text(
                "No recipes in this list.",
                style: TextStyle(color: Colors.white70, fontFamily: 'Lexend'),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedRecipes.length,
              itemBuilder: (context, index) {
                var recipe = sortedRecipes[index];
                return Card(
                  color: Colors.white10,
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 25,
                      child: ClipOval(
                        child: NetworkImageWidget(
                          imageUrl: recipe['image_url'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    title: Text(
                      recipe['name'],
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lexend',
                      ),
                    ),
                    trailing: Icon(Icons.arrow_forward, color: Colors.white),
                    onTap: () {
                      // Navigate to recipe details
                    },
                  ),
                );
              },
            ),
      backgroundColor: Colors.black,
    );
  }
}
