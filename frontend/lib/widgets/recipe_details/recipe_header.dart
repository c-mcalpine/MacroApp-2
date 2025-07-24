import 'package:flutter/material.dart';
import '../common/network_image_widget.dart';

class RecipeHeader extends StatelessWidget {
  final Map<String, dynamic> recipe;

  const RecipeHeader({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: NetworkImageWidget(
            imageUrl: recipe['image_url'] ?? '',
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        Positioned.fill(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(recipe['name'] ?? "Unknown Recipe", textAlign: TextAlign.center, style: TextStyle(fontSize: 28, color: Colors.white, fontFamily: 'Lexend')),
              SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: (recipe['tags'] as List<dynamic>? ?? []).map((tag) {
                  return Chip(label: Text(tag['tag_name'] ?? "Unknown", style: TextStyle(color: Colors.white, fontFamily: 'Lexend')));
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
