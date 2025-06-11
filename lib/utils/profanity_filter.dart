// lib/utils/profanity_filter.dart

import 'package:flutter/foundation.dart';

class ProfanityFilter {
  // ✅ CORRECCIÓN: Lista ordenada de la grosería más larga a la más corta.
  // Esto asegura que se detecten las variaciones completas primero.
  static final List<String> _listaDeGroserias = [
    'chinga tu madre cabrones',
    'chinga tu madre pendeja',
    'chinga tu madre pendejo',
    'chinguen a su madre pendejos',
    'chinga tu madre cabrona',
    'chinga tu madre cabron',
    'chinga tu madre imbecil', // Considera quitar la tilde
    'chinga tu madre putas',
    'chinga tu madre puto',
    'chinguen a su madre cabronas',
    'chinguen a su madre cabrones',
    'chinguen a su madre imbeciles', // Considera quitar la tilde
    'chinguen a su madre putas',
    'chinguen a su madre putos',
    'chingue a su madre culero',
    'hijo de la chingada',
    'hija de la chingada',
    'chinguen a su madre',
    'hijo de la verga',
    'hija de la verga',
    'chinga tu madre',
    'chupame la verga',
    'chupame el pito',
    'hijo de perra',
    'hija de perra',
    'hijo de puta',
    'hija de puta',
    'mamavergas',
    'chupapijas',
    'maricones',
    'pendejos',
    'cabrones',
    'culeros',
    'mamadas',
    'maricas',
    'mierda',
    'maricon',
    'pendeja',
    'pendejo',
    'chingada',
    'cabrona',
    'cabron',
    'mamada',
    'culera',
    'culero',
    'putas',
    'putos',
    'verga',
    'idiota',
    'idiotas',
    'marica',
    'jotos',
    'pitos',
    'puta',
    'puto',
    'pito',
    'joto',
    'coño',
  ]..sort(
    (a, b) => b.length.compareTo(a.length),
  ); // Se asegura de ordenar por longitud descendente

  // El mapa de reemplazos está bien.
  static final Map<String, String> _caracteresReemplazo = {
    '@': 'a',
    '4': 'a',
    '3': 'e',
    '1': 'i',
    '!': 'i',
    '|': 'i',
    '0': 'o',
    '5': 's',
    '\$': 's',
    '7': 't',
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    'â': 'a',
    'é': 'e',
    'è': 'e',
    'ë': 'e',
    'ê': 'e',
    'í': 'i',
    'ì': 'i',
    'ï': 'i',
    'î': 'i',
    'ó': 'o',
    'ò': 'o',
    'ö': 'o',
    'ô': 'o',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'û': 'u',
  };

  static String _normalizar(String input) {
    String texto = input.toLowerCase();
    _caracteresReemplazo.forEach((original, reemplazo) {
      texto = texto.replaceAll(original, reemplazo);
    });
    return texto;
  }

  static bool esProfano(String textoOriginal) {
    if (textoOriginal.trim().isEmpty) return false;
    final textoNormalizado = _normalizar(textoOriginal);

    for (final groseria in _listaDeGroserias) {
      if (textoNormalizado.contains(groseria)) {
        return true;
      }
    }
    return false;
  }

  /// ⭐ FUNCIÓN DE CENSURA MEJORADA
  /// Reemplaza las palabras no permitidas con asteriscos (*).
  static String censurar(String textoOriginal) {
    String textoCensurado = textoOriginal;

    for (final groseria in _listaDeGroserias) {
      // Se crea una expresión regular para cada grosería, insensible a mayúsculas/minúsculas.
      final patron = RegExp(RegExp.escape(groseria), caseSensitive: false);

      // Se reemplazan todas las ocurrencias que encuentre en el texto.
      textoCensurado = textoCensurado.replaceAllMapped(patron, (match) {
        // Reemplaza la coincidencia exacta por asteriscos de la misma longitud.
        return '*' * match.group(0)!.length;
      });
    }
    return textoCensurado;
  }
}
