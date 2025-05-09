import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../utils/utils.dart';

class CustomLatexPreview extends StatelessWidget {
  final String rawLatex;
  const CustomLatexPreview({super.key, required this.rawLatex});

  @override
  Widget build(BuildContext context) {
    try {
      return Math.tex(
        prepararLaTeXSeguro(rawLatex),
        mathStyle: MathStyle.display,
        textStyle: const TextStyle(fontSize: 18),
      );
    } catch (_) {
      return const Text(
        '⚠ Error al renderizar LaTeX',
        style: TextStyle(color: Colors.red),
      );
    }
  }
}
