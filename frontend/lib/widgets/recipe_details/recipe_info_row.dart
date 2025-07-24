import 'package:flutter/material.dart';

class RecipeInfoRow extends StatelessWidget {
  final Map<String, dynamic> recipe;

  const RecipeInfoRow({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("⏳ ${recipe['total_time']} min", style: TextStyle(fontSize: 18, color: Colors.white, fontFamily: 'Lexend')),
        Text("🍽 ${recipe['servings']} servings", style: TextStyle(fontSize: 18, color: Colors.white, fontFamily: 'Lexend')),
      ],
    );
  }
}
