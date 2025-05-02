class Pregunta {
  final String id;
  final String pregunta;
  final Map<String, String> opciones;
  final String respuestaCorrecta;
  final String dificultad;

  Pregunta({
    required this.id,
    required this.pregunta,
    required this.opciones,
    required this.respuestaCorrecta,
    required this.dificultad,
  });

  factory Pregunta.fromJson(Map<String, dynamic> json) {
    return Pregunta(
      id: json['id'] ?? '',
      pregunta: json['pregunta'],
      opciones: Map<String, String>.from(json['opciones']),
      respuestaCorrecta: json['respuestaCorrecta'],
      dificultad: json['dificultad'],
    );
  }
}
