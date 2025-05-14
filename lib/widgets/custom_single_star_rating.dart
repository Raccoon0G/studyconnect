import 'package:flutter/material.dart';

/// Muestra un número seguido de una estrella animada completamente (sin fracciones).
class SingleAnimatedStarRating extends StatelessWidget {
  final double valor; // Ejemplo: 4.3
  final double size;
  final Duration duration;
  final Color color;

  const SingleAnimatedStarRating({
    super.key,
    required this.valor,
    this.size = 24,
    this.duration = const Duration(milliseconds: 500),
    this.color = Colors.amber,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          valor.toStringAsFixed(1),
          style: const TextStyle(
            color: Colors.orangeAccent,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: duration,
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Icon(Icons.star, size: size, color: color),
            );
          },
        ),
      ],
    );
  }
}
