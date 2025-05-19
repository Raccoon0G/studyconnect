import 'package:flutter/material.dart';
import 'package:study_connect/widgets/widgets.dart';

class PodiumWidget extends StatelessWidget {
  final List<Map<String, dynamic>> top3;

  const PodiumWidget({super.key, required this.top3});

  @override
  Widget build(BuildContext context) {
    final podium = List.generate(3, (i) => i < top3.length ? top3[i] : null);

    // 🟦 Tamaños responsivos:
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double maxPodiumHeight = screenHeight * 0.32;
    final double minPodiumHeight = 120;

    double avatarRadius = screenWidth < 600 ? 36 : 75; // Responsivo
    double baseHeight = (maxPodiumHeight).clamp(minPodiumHeight, 240);
    double second = (baseHeight * 0.81).clamp(minPodiumHeight, 220);
    double first = (baseHeight * 1.0).clamp(minPodiumHeight, 280);
    double third = (baseHeight * 0.68).clamp(minPodiumHeight, 170);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '🏆 Top 3 del Ranking',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0, end: 1),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPlace(
                      context,
                      podium[1],
                      2,
                      second,
                      avatarRadius,
                      Colors.grey.shade400,
                      '🥈',
                    ),
                    const SizedBox(width: 20),
                    _buildPlace(
                      context,
                      podium[0],
                      1,
                      first,
                      avatarRadius + 8,
                      Colors.amber,
                      '🥇',
                    ),
                    const SizedBox(width: 20),
                    _buildPlace(
                      context,
                      podium[2],
                      3,
                      third,
                      avatarRadius - 8,
                      Colors.brown.shade400,
                      '🥉',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '¡Contribuye más y escala en el ranking!',
          style: TextStyle(
            color: Colors.orangeAccent,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildPlace(
    BuildContext context,
    Map<String, dynamic>? user,
    int place,
    double height,
    double avatarRadius, // NUEVO parámetro
    Color color,
    String medal,
  ) {
    final nombre = user?['nombre'] ?? 'Vacío';
    final puntos = user?['prom']?.toDouble() ?? 0;
    final foto = user?['foto'] ?? '';
    final bool esPrimero = place == 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (esPrimero)
              Positioned(
                top: -18,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(seconds: 1),
                  tween: Tween(begin: 0.9, end: 1.1),
                  curve: Curves.easeInOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: const Icon(
                        Icons.emoji_events,
                        size: 42,
                        color: Colors.amberAccent,
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: EdgeInsets.only(top: esPrimero ? 12 : 0),
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundImage: foto.isNotEmpty ? NetworkImage(foto) : null,
                backgroundColor: Colors.white,
                child:
                    foto.isEmpty
                        ? Icon(
                          Icons.person,
                          size: avatarRadius * 0.8,
                          color: Colors.grey.shade700,
                        )
                        : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Tooltip(
          message: '$nombre – ${puntos.toStringAsFixed(2)} estrellas',
          child: SizedBox(
            width: avatarRadius * 2,
            child: Text(
              nombre,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 4),
        SingleAnimatedStarRating(valor: puntos),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          duration: const Duration(seconds: 2),
          tween: Tween(begin: 0.95, end: 1.05),
          curve: Curves.easeInOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                width: avatarRadius * 1.3,
                height: height,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: 3,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(medal, style: const TextStyle(fontSize: 28)),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
