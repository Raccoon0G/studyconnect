import 'package:flutter/material.dart';

/// Dibuja estrellas para que el usuario pueda seleccionar una calificación (interactiva).
class CustomRatingWidget extends StatelessWidget {
  final int rating;
  final void Function(int) onRatingChanged;
  final double size;
  final bool enableHoverEffect;

  const CustomRatingWidget({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.size = 32,
    this.enableHoverEffect = false,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          final isFilled = index < rating;
          return IconButton(
            icon: Icon(
              isFilled ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: size, // sigue recibiendo el size que le pases
            ),
            onPressed: () => onRatingChanged(index + 1),
          );
        }),
      ),
    );
  }
}
