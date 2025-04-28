/// Función auxiliar que calcula el promedio de estrellas a partir de una lista de comentarios.
double calcularPromedioEstrellas(List<Map<String, dynamic>> comentarios) {
  if (comentarios.isEmpty) return 0.0;
  final total = comentarios.fold<double>(
    0.0,
    (sum, c) => sum + (c['estrellas'] ?? 0),
  );
  return total / comentarios.length;
}
