import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pregunta_model.dart';

class EvaluacionService {
  static const _url =
      "https://hook.us2.make.com/2tx6w48rcjsco7o6ki24v8ecztiqyywf";

  Future<Map<String, List<Pregunta>>> obtenerPreguntas(
    List<String> temas,
  ) async {
    final response = await http.post(
      Uri.parse(_url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"temas": temas}),
    );

    if (response.statusCode != 200) {
      throw Exception("Error en la solicitud: ${response.body}");
    }

    final data = jsonDecode(response.body);

    final Map<String, List<Pregunta>> resultado = {};
    data.forEach((key, value) {
      resultado[key] =
          (value as List)
              .map((item) => Pregunta.fromJson(item as Map<String, dynamic>))
              .toList();
    });

    return resultado;
  }
}
