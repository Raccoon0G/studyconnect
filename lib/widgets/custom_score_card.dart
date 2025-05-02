import 'package:flutter/material.dart';

class CustomScoreCard extends StatelessWidget {
  final int puntaje;
  final int total;

  const CustomScoreCard({
    super.key,
    required this.puntaje,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green[100],
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          "Tu puntaje: $puntaje / $total",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
