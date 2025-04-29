import 'package:flutter/material.dart';

/// Widget que dibuja estrellas animadas representando un valor decimal exacto (por ejemplo, 4.3 estrellas).
class CustomStarRating extends StatelessWidget {
  final double valor;
  final double size;
  final Duration duration;

  final dynamic color;
  final Alignment geometryAlignment;

  const CustomStarRating({
    super.key,
    required this.valor,
    this.size = 30,
    this.duration = const Duration(milliseconds: 800),
    this.color = Colors.amber,
    this.geometryAlignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: valor),
      duration: duration,
      curve: Curves.easeOut,
      builder: (context, valueAnimado, child) {
        return Align(
          alignment: geometryAlignment,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final porcentaje = (valueAnimado - i).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Stack(
                  children: [
                    Icon(
                      Icons.star_border,
                      size: size,
                      color: Colors.amber.shade300,
                    ),
                    ShaderMask(
                      shaderCallback:
                          (bounds) => LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            stops: [porcentaje, porcentaje],
                            colors: [color, Colors.transparent],
                          ).createShader(bounds),
                      blendMode: BlendMode.srcATop,
                      child: Icon(Icons.star, size: size, color: Colors.white),
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
