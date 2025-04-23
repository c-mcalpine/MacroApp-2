import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RecipeInfoRow extends StatelessWidget {
  final Map<String, dynamic> recipe;

  const RecipeInfoRow({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("⏳ ${recipe['total_time']} min", style: GoogleFonts.lexend(fontSize: 18, color: Colors.white)),
        Text("🍽 ${recipe['servings']} servings", style: GoogleFonts.lexend(fontSize: 18, color: Colors.white)),
      ],
    );
  }
}
