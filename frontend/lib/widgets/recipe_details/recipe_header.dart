import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              recipe['image_url'] ?? '',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[800], child: Icon(Icons.broken_image, color: Colors.white, size: 48)),
            ),
          ),
        ),
        Positioned.fill(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(recipe['name'] ?? "Unknown Recipe", textAlign: TextAlign.center, style: GoogleFonts.lexend(fontSize: 28, color: Colors.white)),
              SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: (recipe['tags'] as List<dynamic>? ?? []).map((tag) {
                  return Chip(label: Text(tag['tag_name'] ?? "Unknown", style: GoogleFonts.lexend(color: Colors.white)));
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
