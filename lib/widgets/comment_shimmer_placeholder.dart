import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

//Un widget que muestra un efecto de carga para los comentarios
// Utiliza el paquete Shimmer para crear un efecto de brillo en los elementos de la interfaz de usuario
class CustomShimmerComment extends StatelessWidget {
  const CustomShimmerComment({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 100,
                    height: 16,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.star, color: Colors.amber.shade300, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 12,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                height: 12,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 6),
              Container(width: 150, height: 12, color: Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }
}
