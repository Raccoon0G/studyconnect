import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/preparar_latex.dart';

/// Función para crear encabezados de DataColumn con estilo LaTeX.
DataColumn buildCustomDataColumn(
  String contenido, {
  Alignment alignment = Alignment.center,
  double fontSize = 16,
  Color color = Colors.black,
  FontWeight fontWeight = FontWeight.bold,
}) {
  final contenidoPreparado = prepararLaTeX(contenido);

  return DataColumn(
    label: Align(
      alignment: alignment,
      child: Math.tex(
        contenidoPreparado,
        mathStyle: MathStyle.display,
        textStyle: GoogleFonts.ebGaramond(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        ),
      ),
    ),
  );
}
