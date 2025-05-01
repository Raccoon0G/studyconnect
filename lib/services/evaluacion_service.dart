import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pregunta_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EvaluacionService {
  static const _url =
      "https://hook.us2.make.com/2tx6w48rcjsco7o6ki24v8ecztiqyywf";

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<Map<String, List<Pregunta>>> obtenerPreguntasDesdeFirestore(
    String tema,
  ) async {
    final snapshot =
        await firestore
            .collection('preguntas_por_tema')
            .where('tema', isEqualTo: tema)
            .orderBy('timestamp', descending: true)
            .limit(25)
            .get();

    final preguntas =
        snapshot.docs.map((doc) {
          final data = doc.data();
          return Pregunta(
            pregunta: data['pregunta'] ?? '',
            opciones: Map<String, String>.from(data['opciones']),
            respuestaCorrecta: data['respuestaCorrecta'] ?? '',
            dificultad: data['dificultad'] ?? '',
          );
        }).toList();

    return {tema: preguntas};
  }
}
