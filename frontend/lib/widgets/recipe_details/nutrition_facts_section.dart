import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class NutritionFactsSection extends StatelessWidget {
  final List<dynamic> nutrition;

  const NutritionFactsSection({super.key, required this.nutrition});

  @override
  Widget build(BuildContext context) {
    double protein = _getNutrientValue(nutrition, "Protein");
    double carbs = _getNutrientValue(nutrition, "Carbs");
    double fat = _getNutrientValue(nutrition, "Fat");
    double calories = _getNutrientValue(nutrition, "Calories");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Nutrition Facts (Per Serving)", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Lexend')),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 120,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(value: (protein / calories) * 100, color: Colors.green, title: "Protein"),
                      PieChartSectionData(value: (carbs / calories) * 100, color: Colors.blue, title: "Carbs"),
                      PieChartSectionData(value: (fat / calories) * 100, color: Colors.orange, title: "Fat"),
                    ],
                    centerSpaceRadius: 30,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Calories per Gram of Protein", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Lexend')),
                  Text("${(calories / protein).toStringAsFixed(1)} cal/g", style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Lexend')),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

double _getNutrientValue(List<dynamic> nutrition, String nutrientName) {
  var nutrient = nutrition.firstWhere((item) => item['nutrient_name'] == nutrientName, orElse: () => null);
  return nutrient != null ? (nutrient['value'] as num).toDouble() : 0.0;
}
