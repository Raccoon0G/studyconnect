import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pregunta_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EvaluacionService {
  static const _url =
      "https://hook.us2.make.com/2tx6w48rcjsco7o6ki24v8ecztiqyywf";
  //static const _url =
  // "https://penta0m.app.n8n.cloud/webhook-test/189d874d-4274-4e11-b12c-c408340c4638";

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<Map<String, List<Pregunta>>> obtenerPreguntasDesdeFirestore(
    String tema, {
    int cantidad = 25,
  }) async {
    final snapshot =
        await firestore
            .collection('preguntas_por_tema')
            .where('tema', isEqualTo: tema)
            .orderBy('timestamp', descending: true)
            .limit(cantidad)
            .get();

    final preguntas =
        snapshot.docs.map((doc) {
          final data = doc.data();
          return Pregunta(
            id: doc.id,
            pregunta: data['pregunta'] ?? '',
            opciones: Map<String, String>.from(data['opciones']),
            respuestaCorrecta: data['respuestaCorrecta'] ?? '',
            dificultad: data['dificultad'] ?? '',
          );
        }).toList();

    return {tema: preguntas};
  }
}
