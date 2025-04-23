import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MealPrepTipsSection extends StatelessWidget {
  final List<dynamic> tips;

  const MealPrepTipsSection({super.key, required this.tips});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Meal Prep Tips", style: GoogleFonts.lexend(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        SizedBox(height: 8),
        Column(
          children: tips.map((tip) {
            return Card(
              color: Colors.white10,
              margin: EdgeInsets.symmetric(vertical: 8.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_getStorageIcon(tip['storage_type']), color: Colors.white, size: 32),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tip['storage_type'] ?? "Unknown", style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(height: 8),
                          Text(tip['details'] ?? "", style: GoogleFonts.lexend(fontSize: 16, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

IconData _getStorageIcon(String? storageType) {
  switch (storageType?.toLowerCase()) {
    case "refrigeration":
      return Icons.kitchen; 
    case "freezing":
      return Icons.ac_unit; 
    case "pantry":
      return Icons.inventory_2; 
    default:
      return Icons.info;
  }
}
