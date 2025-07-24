import 'package:flutter/material.dart';

class RecipeSectionScreen extends StatefulWidget {
  final String sectionTitle;
  final List<String> filters;
  const RecipeSectionScreen({super.key, required this.sectionTitle, required this.filters});

  @override
  RecipeSectionScreenState createState() => RecipeSectionScreenState();
}

class RecipeSectionScreenState extends State<RecipeSectionScreen> {
  late List<bool> selectedFilters;

  @override
  void initState() {
    super.initState();
    selectedFilters = List.generate(widget.filters.length, (index) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.sectionTitle,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            fontFamily: 'Lexend',
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(widget.filters.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: ChoiceChip(
                      label: Text(
                        widget.filters[index],
                        style: TextStyle(
                          color: selectedFilters[index] ? Colors.black : Colors.white,
                          fontSize: 14,
                          fontFamily: 'Lexend',
                        ),
                      ),
                      selected: selectedFilters[index],
                      selectedColor: Colors.white,
                      backgroundColor: Colors.black,
                      shape: const StadiumBorder(side: BorderSide(color: Colors.white)),
                      onSelected: (bool selected) {
                        setState(() {
                          selectedFilters[index] = selected;
                        });
                      },
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  "${widget.sectionTitle} Recipes Coming Soon...",
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontFamily: 'Lexend',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}