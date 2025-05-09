// lib/utils/preparar_latex_seguro.dart

/// Mapa de caracteres especiales de LaTeX a su escape.
/// Solo los imprescindibles en math mode: # $ % &
const Map<String, String> _latexEscapes = {
  '#': r'\#',
  r'$': r'\$',
  '%': r'\%',
  '&': r'\&',
};

/// Sanitiza un texto para Math.tex():
/// 0) Elimina **todas** ocurrencias de delimitadores LaTeX: \[ \] , \( \), $$ $$
/// 1) Escapa solo # $ % &
/// 2) Filtra caracteres de control
/// 3) (Opcional) Acorta si >2000 chars
/// 4) Fallback si queda vacío
String prepararLaTeXSeguro(String texto) {
  // 0) Quita delimitadores en cualquier posición:
  var raw =
      texto
          .replaceAll(RegExp(r'\\\[|\\\]'), '') // elimina \[ y \]
          .replaceAll(RegExp(r'\\\(|\\\)'), '') // elimina \( y \)
          .replaceAll(RegExp(r'\$\$'), '') // elimina $$ ... $$
          .trim();

  if (raw.isEmpty) {
    return r'\text{– contenido vacío –}';
  }

  // 1) Escapa solo los caracteres problemáticos
  var escaped = raw.splitMapJoin(
    RegExp(_latexEscapes.keys.map(RegExp.escape).join('|')),
    onMatch: (m) => _latexEscapes[m.group(0)]!,
    onNonMatch: (chunk) => chunk,
  );

  // 2) Filtra caracteres de control invisibles (tabs, returns, etc.)
  escaped = escaped.replaceAll(RegExp(r'[\x00-\x1F]'), '');

  // 3) (Opcional) Limita longitud para no romper el parser
  if (escaped.length > 2000) {
    escaped = escaped.substring(0, 2000) + r'\text{…}';
  }

  // 4) Fallback si quedó vacío tras todo
  if (escaped.trim().isEmpty) {
    return r'\text{Contenido no válido para LaTeX}';
  }

  return escaped;
}
