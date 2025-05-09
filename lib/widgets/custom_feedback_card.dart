import 'package:flutter/material.dart';
import 'package:study_connect/widgets/custom_action_buttons_row.dart';

class CustomFeedbackCard extends StatelessWidget {
  final int numeroComentarios;
  final VoidCallback onCalificar;
  final VoidCallback onCompartir;
  final String accion;

  const CustomFeedbackCard({
    super.key,
    required this.numeroComentarios,
    required this.onCalificar,
    required this.onCompartir,
    required this.accion,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF6F3FA),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      margin: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              '¿Te fue útil este ejercicio o material?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (numeroComentarios > 0) ...[
              const SizedBox(height: 4),
              Text(
                '$numeroComentarios persona(s) ya lo calificaron',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
            const SizedBox(height: 16),

            // usamos el nuevo CustomActionButtonsRow con isloggedIn y isCalificado
            // para mostrar los botones de calificar y compartir
            CustomActionButtonsRow(
              onCalificar: onCalificar,
              onCompartir: onCompartir,
              accion: accion,
            ),

            const SizedBox(height: 16),
            const Text(
              '¡Compartelo con tus compañeros!',
              style: TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
