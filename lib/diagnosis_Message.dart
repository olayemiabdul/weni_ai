import 'package:flutter/material.dart';
import 'package:weni_ai/messageBubble_class.dart';

class DiagnosisMessage extends StatelessWidget {
  const DiagnosisMessage({
    super.key,
    required this.carProblems,
  });
  final List<Diagnosis> carProblems;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 350, // Increased height to accommodate more content
            child: PageView.builder(
              itemCount: carProblems.length,
              itemBuilder: (context, index) => DiagnosticCard(
                problem: carProblems[index].problem,
                solution: carProblems[index].solution,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DiagnosticCard extends StatelessWidget {
  const DiagnosticCard(
      {super.key, required this.problem, required this.solution});

  final String problem;
  final String solution;

  @override
  Widget build(BuildContext context) {
    var windowWidth = MediaQuery.of(context).size.width;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(10),
      child: Container(
        width: windowWidth * 0.8,
        padding: const EdgeInsets.all(16),
        child: ListView(
          //crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Problem Title
            Text(
              'Problem',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              problem,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),

            // Solution Section
            Text(
              'Solution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              solution,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
