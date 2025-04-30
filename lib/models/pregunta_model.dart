class Pregunta {
  final String pregunta;
  final Map<String, String> opciones;
  final String respuestaCorrecta;

  Pregunta({
    required this.pregunta,
    required this.opciones,
    required this.respuestaCorrecta,
  });

  factory Pregunta.fromJson(Map<String, dynamic> json) {
    return Pregunta(
      pregunta: json["pregunta"],
      opciones: Map<String, String>.from(json["opciones"]),
      respuestaCorrecta: json["respuesta_correcta"],
    );
  }
}
