import 'package:flutter/material.dart';

class InstructionsSection extends StatelessWidget {
  final List<dynamic> instructions;

  const InstructionsSection({super.key, required this.instructions});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Instructions", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Lexend')),
        SizedBox(height: 8),
        Column(
          children: instructions.map((step) {
            return _CollapsibleInstructionCard(
              stepNumber: step['step_number'],
              stepHeader: step['step_header'],
              stepDuration: step['step_duration'],
              instructionText: step['instruction_text'],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CollapsibleInstructionCard extends StatefulWidget {
  final int stepNumber;
  final String stepHeader;
  final String stepDuration;
  final String instructionText;

  const _CollapsibleInstructionCard({required this.stepNumber, required this.stepHeader, required this.stepDuration, required this.instructionText});

  @override
  CollapsibleInstructionCardState createState() => CollapsibleInstructionCardState();
}

class CollapsibleInstructionCardState extends State<_CollapsibleInstructionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Card(
        color: Colors.white10,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        child: Padding(
                      padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(backgroundColor: Colors.white24, child: Text("${widget.stepNumber}", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Lexend'))),
                  SizedBox(width: 12),
                  Expanded(child: Text(widget.stepHeader, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Lexend'))),
                  Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.white70),
                ],
              ),
              if (_isExpanded) ...[
                SizedBox(height: 8),
                Text(widget.instructionText, style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Lexend')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
