import 'package:flutter/material.dart';
import 'package:study_connect/widgets/custom_latex_text.dart';

class CustomLatexQuestionCard extends StatelessWidget {
  final String pregunta;
  final int numero;
  final Map<String, String> opciones;
  final String? seleccionada;
  final void Function(String) onChanged;
  final String? respuestaCorrecta;
  final bool mostrarRespuesta;

  const CustomLatexQuestionCard({
    super.key,
    required this.pregunta,
    required this.numero,
    required this.opciones,
    required this.seleccionada,
    required this.onChanged,
    this.respuestaCorrecta,
    this.mostrarRespuesta = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomLatexText(
              contenido: "Pregunta $numero: $pregunta",
              fontSize: 18,
              color: Colors.black87,
              scrollHorizontal: false,
            ),
            const SizedBox(height: 12),
            Column(
              children:
                  opciones.entries.map((entry) {
                    final esCorrecta =
                        mostrarRespuesta && entry.key == respuestaCorrecta;
                    return Container(
                      decoration: BoxDecoration(
                        color: esCorrecta ? Colors.green.shade100 : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: RadioListTile<String>(
                        value: entry.key,
                        groupValue: seleccionada,
                        onChanged: (value) {
                          if (value != null) onChanged(value);
                        },
                        title: CustomLatexText(
                          contenido: "${entry.key}) ${entry.value}",
                          fontSize: 16,
                          scrollHorizontal: true,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 0,
                        ),
                      ),
                    );
                  }).toList(),
            ),
            if (mostrarRespuesta && respuestaCorrecta != null)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: CustomLatexText(
                        contenido:
                            "Respuesta correcta: ${opciones[respuestaCorrecta] ?? ''}",
                        fontSize: 16,
                        color: Colors.green.shade800,
                        scrollHorizontal: true,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
