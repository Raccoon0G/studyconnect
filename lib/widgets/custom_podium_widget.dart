import 'package:flutter/material.dart';

class PodiumWidget extends StatelessWidget {
  final List<Map<String, dynamic>> top3;

  const PodiumWidget({super.key, required this.top3});

  @override
  Widget build(BuildContext context) {
    final podium = List.generate(3, (i) => i < top3.length ? top3[i] : null);

    return Column(
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
        TweenAnimationBuilder<double>(
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
                    260,
                    Colors.grey.shade400,
                    '🥈',
                  ),
                  const SizedBox(width: 24),
                  _buildPlace(context, podium[0], 1, 320, Colors.amber, '🥇'),
                  const SizedBox(width: 24),
                  _buildPlace(
                    context,
                    podium[2],
                    3,
                    220,
                    Colors.brown.shade400,
                    '🥉',
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 20),
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
    Color color,
    String medal,
  ) {
    final nombre = user?['nombre'] ?? 'Vacío';
    final puntos = user?['prom']?.toDouble() ?? 0;
    final foto = user?['foto'] ?? '';
    final bool esPrimero = place == 1;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (esPrimero)
              Positioned(
                top: -20,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(seconds: 1),
                  tween: Tween(begin: 0.9, end: 1.1),
                  curve: Curves.easeInOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: const Icon(
                        Icons.emoji_events,
                        size: 48,
                        color: Colors.amberAccent,
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: EdgeInsets.only(top: esPrimero ? 16 : 0),
              child: CircleAvatar(
                radius: 75,
                backgroundImage: foto.isNotEmpty ? NetworkImage(foto) : null,
                backgroundColor: Colors.white,
                child:
                    foto.isEmpty
                        ? Icon(
                          Icons.person,
                          size: 60,
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
            width: 140,
            child: Text(
              nombre,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${puntos.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.orangeAccent,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        TweenAnimationBuilder<double>(
          duration: const Duration(seconds: 2),
          tween: Tween(begin: 0.95, end: 1.05),
          curve: Curves.easeInOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 100,
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
                  child: Text(medal, style: const TextStyle(fontSize: 30)),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
