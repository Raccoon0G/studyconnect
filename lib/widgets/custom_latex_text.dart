import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/preparar_latex.dart';

/// Un widget para mostrar texto LaTeX de manera segura y estilizada.
class CustomLatexText extends StatelessWidget {
  final String contenido;
  final double fontSize;
  final Color color;
  final bool scrollHorizontal;
  final int? maxWords;

  const CustomLatexText({
    super.key,
    required this.contenido,
    this.fontSize = 20,
    this.color = Colors.black,
    this.scrollHorizontal = true,
    this.maxWords,
  });

  @override
  Widget build(BuildContext context) {
    final contenidoPreparado = prepararLaTeX(contenido);

    // Limitar el número de palabras si se especifica
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
