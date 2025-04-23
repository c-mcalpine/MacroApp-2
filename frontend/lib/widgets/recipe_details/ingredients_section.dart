import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IngredientsSection extends StatelessWidget {
  final List<dynamic> ingredients;

  const IngredientsSection({super.key, required this.ingredients});

  @override
  Widget build(BuildContext context) {
    var groupedIngredients = _groupBySection(ingredients);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupedIngredients.entries.map((entry) => _ExpandableIngredientCard(sectionName: entry.key, ingredients: entry.value)).toList(),
    );
  }

  Map<String, List<dynamic>> _groupBySection(List<dynamic> ingredients) {
    return {
      for (var ingredient in ingredients)
        ingredient['section_name'] ?? "General": (ingredients.where((i) => i['section_name'] == ingredient['section_name'])).toList()
    };
  }
}

class _ExpandableIngredientCard extends StatefulWidget {
  final String sectionName;
  final List<dynamic> ingredients;

  const _ExpandableIngredientCard({required this.sectionName, required this.ingredients});

  @override
  __ExpandableIngredientCardState createState() => __ExpandableIngredientCardState();
}

class __ExpandableIngredientCardState extends State<_ExpandableIngredientCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Row(children: [Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.white), Text(widget.sectionName, style: GoogleFonts.lexend(color: Colors.white, fontSize: 20))]),
        ),
        if (_isExpanded)
          Column(
            children: widget.ingredients.map((ingredient) => Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text("• ${ingredient['amount']} ${ingredient['unit']} ${ingredient['name']}", style: GoogleFonts.lexend(color: Colors.white70)))).toList(),
          ),
      ],
    );
  }
}
