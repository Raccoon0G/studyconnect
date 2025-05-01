class Pregunta {
  final String pregunta;
  final Map<String, String> opciones;
  final String respuestaCorrecta;
  final String dificultad; // Asegúrate de que esto esté aquí

  Pregunta({
    required this.pregunta,
    required this.opciones,
    required this.respuestaCorrecta,
    required this.dificultad, // Y aquí también
  });

  factory Pregunta.fromJson(Map<String, dynamic> json) {
    return Pregunta(
      pregunta: json['pregunta'],
      opciones: Map<String, String>.from(json['opciones']),
      respuestaCorrecta: json['respuestaCorrecta'],
      dificultad: json['dificultad'], // importante para Make
    );
  }
}
