String prepararLaTeX(String texto) {
  try {
    return texto
        .replaceAllMapped(
          RegExp(r'(?<!\\) '),
          (m) => r'\ ',
        ) // espacios normales
        .replaceAll('\n', r'\\') // saltos de línea
        .replaceAllMapped(
          RegExp(r'([{}])'),
          (m) => '\\${m[0]}',
        ); // escapa {} si aparecen sueltos
  } catch (_) {
    return 'Contenido inválido';
  }
}

/// Divide un texto largo en varias líneas cada cierto número de palabras para mejor legibilidad.
String dividirDescripcionEnLineas(
  String texto, {
  int maxPalabrasPorLinea = 25,
}) {
  final palabras = texto.split(' ');
  final buffer = StringBuffer();

  for (int i = 0; i < palabras.length; i++) {
    buffer.write(palabras[i]);
    if ((i + 1) % maxPalabrasPorLinea == 0 && i != palabras.length - 1) {
      buffer.write('\n'); // salto de línea visible
    } else if (i != palabras.length - 1) {
      buffer.write(' ');
    }
  }

  return buffer.toString();
}
