import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/utils.dart';

typedef PrepararLatexFunction = String Function(String);

class CustomLatexText extends StatelessWidget {
  final String contenido;
  final double fontSize;
  final Color color;
  final bool scrollHorizontal;
  final int? maxWords;

  /// Permite inyectar una función personalizada para preparar LaTeX.
  /// Por defecto usa [prepararLaTeXSeguro].
  final PrepararLatexFunction prepararLatex;

  const CustomLatexText({
    super.key,
    required this.contenido,
    this.fontSize = 20,
    this.color = Colors.black,
    this.scrollHorizontal = true,
    this.maxWords,
    this.prepararLatex = prepararLaTeXSeguro, // 👈 valor por defecto
  });

  @override
  Widget build(BuildContext context) {
    final contenidoPreparado = prepararLatex(contenido);

    // Limita palabras si se solicita
    String texto = contenido;
    if (maxWords != null && texto.isNotEmpty) {
      final partes = texto.split(' ');
      if (partes.length > maxWords!) {
        texto = partes.take(maxWords!).join(' ') + ' …';
      }
    }

    final latexWidget = Math.tex(
      contenidoPreparado,
      mathStyle: MathStyle.display,
      textStyle: GoogleFonts.ebGaramond(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );

    if (scrollHorizontal) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: latexWidget,
      );
    } else {
      return latexWidget;
    }
  }
}
