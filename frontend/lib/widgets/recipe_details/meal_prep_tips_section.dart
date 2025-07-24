import 'package:flutter/material.dart';

class MealPrepTipsSection extends StatelessWidget {
  final List<dynamic> tips;

  const MealPrepTipsSection({super.key, required this.tips});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Meal Prep Tips", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Lexend')),
        SizedBox(height: 8),
        Column(
          children: tips.map((tip) {
            return Card(
              color: Colors.white10,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_getStorageIcon(tip['storage_type']), color: Colors.white, size: 32),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tip['storage_type'] ?? "Unknown", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Lexend')),
                          SizedBox(height: 8),
                          Text(tip['details'] ?? "", style: TextStyle(fontSize: 16, color: Colors.white70, fontFamily: 'Lexend')),
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
