import 'package:flutter/material.dart';
import 'package:study_connect/widgets/custom_latex_text.dart';

import '../utils/utils.dart';

class CustomLatexQuestionCard extends StatefulWidget {
  final String pregunta;
  final int numero;
  final Map<String, String> opciones;
  final String? seleccionada;
  final void Function(String) onChanged;

  final String? respuestaCorrecta;
  final bool mostrarCorrecta;
  final String? respuestaUsuario;

  const CustomLatexQuestionCard({
    super.key,
    required this.pregunta,
    required this.numero,
    required this.opciones,
    required this.seleccionada,
    required this.onChanged,
    this.respuestaCorrecta,
    this.mostrarCorrecta = false,
    this.respuestaUsuario,
  });

  @override
  State<CustomLatexQuestionCard> createState() =>
      _CustomLatexQuestionCardState();
}

class _CustomLatexQuestionCardState extends State<CustomLatexQuestionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _opacityAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool sinRespuesta = widget.respuestaUsuario == null;
    bool esCorrecta = widget.respuestaUsuario == widget.respuestaCorrecta;
    bool esIncorrecta = !sinRespuesta && !esCorrecta;

    Color fondo = Colors.white;
    if (widget.mostrarCorrecta) {
      if (esCorrecta) fondo = Colors.green.shade50;
      if (esIncorrecta) fondo = Colors.red.shade50;
      if (sinRespuesta) fondo = Colors.grey.shade100;
    }

    Widget contenidoCard = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomLatexText(
            contenido: "Pregunta ${widget.numero}: ${widget.pregunta}",
            fontSize: 18,
            color: Colors.black87,
            scrollHorizontal: true,
            prepararLatex: prepararLaTeX,
          ),
          const SizedBox(height: 12),
          Column(
            children:
                widget.opciones.entries.map((entry) {
                  final letra = entry.key;
                  final texto = entry.value;
                  Color colorTexto = Colors.black;
                  Icon? icono;

                  if (widget.mostrarCorrecta &&
                      widget.respuestaCorrecta != null) {
                    if (letra == widget.respuestaCorrecta &&
                        letra == widget.respuestaUsuario) {
                      colorTexto = Colors.green;
                      icono = const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      );
                    } else if (letra == widget.respuestaUsuario &&
                        letra != widget.respuestaCorrecta) {
                      colorTexto = Colors.red;
                      icono = const Icon(Icons.cancel, color: Colors.red);
                    } else if (letra == widget.respuestaCorrecta) {
                      colorTexto = Colors.green;
                      icono = const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                      );
                    }
                  }

                  return RadioListTile<String>(
                    value: letra,
                    groupValue: widget.seleccionada,
                    onChanged: (value) {
                      if (value != null && !widget.mostrarCorrecta) {
                        widget.onChanged(value);
                      }
                    },
                    title: CustomLatexText(
                      contenido: "$letra) $texto",
                      fontSize: 16,
                      color: colorTexto,
                      prepararLatex: prepararLaTeX,
                    ),
                    secondary: icono,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                  );
                }).toList(),
          ),
          if (widget.mostrarCorrecta &&
              widget.respuestaCorrecta != null &&
              (!esCorrecta || sinRespuesta))
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomLatexText(
                      contenido:
                          "Respuesta correcta: ${widget.respuestaCorrecta}) ${widget.opciones[widget.respuestaCorrecta]}",
                      fontSize: 16,
                      color: Colors.green.shade800,
                      prepararLatex: prepararLaTeX,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    // Agregamos la animación solo si fue incorrecta
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (widget.mostrarCorrecta)
            BoxShadow(
              color:
                  esCorrecta
                      ? Colors.green.withOpacity(0.3)
                      : esIncorrecta
                      ? Colors.red.withOpacity(0.3)
                      : Colors.transparent,
              blurRadius: 6,
              spreadRadius: 1,
            ),
        ],
      ),
      child:
          esIncorrecta
              ? FadeTransition(opacity: _opacityAnim, child: contenidoCard)
              : contenidoCard,
    );
  }
}
