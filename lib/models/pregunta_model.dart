class PreguntaModel {
  final String id;
  final String pregunta;
  final Map<String, String> opciones;
  final String respuestaCorrecta;
  final String dificultad;

  PreguntaModel({
    required this.id,
    required this.pregunta,
    required this.opciones,
    required this.respuestaCorrecta,
    required this.dificultad,
  });

  factory PreguntaModel.fromJson(Map<String, dynamic> json) {
    return PreguntaModel(
      id: json['id'] ?? '',
      pregunta: json['pregunta'],
      opciones: Map<String, String>.from(json['opciones']),
      respuestaCorrecta: json['respuestaCorrecta'],
      dificultad: json['dificultad'],
    );
  }
}
