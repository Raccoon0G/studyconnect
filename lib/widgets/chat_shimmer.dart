import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer genérico que pinta un contenedor con padding
class CustomShimmer extends StatelessWidget {
  final Widget child;
  const CustomShimmer({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: child,
    );
  }
}

/// Shimmer específico para cada fila de chat (avatar + nombre + hora)
class ShimmerChatTile extends StatelessWidget {
  const ShimmerChatTile({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomShimmer(
      child: ListTile(
        leading: CircleAvatar(radius: 20, backgroundColor: Colors.white),
        title: Container(width: 100, height: 14, color: Colors.white),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(width: 40, height: 12, color: Colors.white),
        ),
      ),
    );
  }
}
