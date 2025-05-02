import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> migrarPreguntasPorTema() async {
  final firestore = FirebaseFirestore.instance;

  final Map<String, String> clavesTema = {
    "Funciones algebraicas y trascendentes": "FnAlg",
    "Límites de funciones y continuidad": "Lim",
    "Derivada y optimización": "Der",
    "Técnicas de integración": "TecInteg",
  };

  final snapshot = await firestore.collection('preguntas_por_tema').get();

  for (final doc in snapshot.docs) {
    final data = doc.data();
    final tema = data['tema'];

    if (tema == null || !clavesTema.containsKey(tema)) {
      print("❌ Documento ignorado por tema inválido: ${doc.id}");
      continue;
    }

    final clave = clavesTema[tema];

    await firestore
        .collection('preguntas_por_temas')
        .doc(clave)
        .collection('preguntas')
        .doc(doc.id)
        .set(data); // Copiar

    await firestore
        .collection('preguntas_por_tema')
        .doc(doc.id)
        .delete(); // Eliminar

    print("✅ Migrado y eliminado: ${doc.id}");
  }

  print("🎉 Migración completa.");
}
