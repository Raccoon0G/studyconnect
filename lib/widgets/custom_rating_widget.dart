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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final isFilled = index < rating;
        return MouseRegion(
          onEnter: enableHoverEffect ? (_) => onRatingChanged(index + 1) : null,
          child: IconButton(
            icon: Icon(
              isFilled ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: size,
            ),
            tooltip: '${index + 1} estrella${index == 0 ? '' : 's'}',
            onPressed: () => onRatingChanged(index + 1),
          ),
        );
      }),
    );
  }
}
