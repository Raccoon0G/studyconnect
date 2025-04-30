import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AutoevaluacionInteractivaPage extends StatefulWidget {
  const AutoevaluacionInteractivaPage({super.key});

  @override
  _AutoevaluacionInteractivaPageState createState() =>
      _AutoevaluacionInteractivaPageState();
}

class _AutoevaluacionInteractivaPageState
    extends State<AutoevaluacionInteractivaPage> {
  Map<String, List<dynamic>> preguntasPorTema = {};
  String? temaSeleccionado;
  Map<int, String> respuestasUsuario = {};
  bool yaCalificado = false;
  int puntaje = 0;
  bool cargando = false;

  Future<void> obtenerPreguntasConTema(String tema) async {
    setState(() {
      cargando = true;
      yaCalificado = false;
      respuestasUsuario.clear();
      puntaje = 0;
    });

    try {
      final response = await http.post(
        Uri.parse("https://hook.us2.make.com/2tx6w48rcjsco7o6ki24v8ecztiqyywf"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "temas": [tema],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final Map<String, List<dynamic>> organizado = {};

        data.forEach((key, value) {
          organizado[key] = List<Map<String, dynamic>>.from(value);
        });

        setState(() {
          preguntasPorTema = organizado;
          temaSeleccionado = organizado.keys.first;
          cargando = false;
        });
      } else {
        throw Exception("Error HTTP: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => cargando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al obtener preguntas: $e")));
    }
  }

  @override
  void initState() {
    super.initState();
  }

  void calificar() {
    final preguntas = preguntasPorTema[temaSeleccionado] ?? [];
    int score = 0;

    for (int i = 0; i < preguntas.length; i++) {
      final correcta = preguntas[i]["respuesta_correcta"];
      final respuesta = respuestasUsuario[i];
      if (respuesta != null && respuesta == correcta) {
        score++;
      }
    }

    setState(() {
      yaCalificado = true;
      puntaje = score;
    });
  }

  @override
  Widget build(BuildContext context) {
    final preguntas = preguntasPorTema[temaSeleccionado] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text("Autoevaluación"),
        backgroundColor: Colors.indigo,
      ),
      body:
          cargando
              ? Center(child: CircularProgressIndicator())
              : preguntas.isEmpty
              ? Center(child: Text("No hay preguntas disponibles"))
              : Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: temaSeleccionado,
                      items:
                          preguntasPorTema.keys.map((tema) {
                            return DropdownMenuItem(
                              value: tema,
                              child: Text(tema),
                            );
                          }).toList(),
                      onChanged: (nuevoTema) {
                        setState(() {
                          temaSeleccionado = nuevoTema;
                          respuestasUsuario.clear();
                          yaCalificado = false;
                          puntaje = 0;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: "Selecciona un tema",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: preguntas.length,
                        itemBuilder: (context, index) {
                          final pregunta = preguntas[index];
                          final opciones = Map<String, dynamic>.from(
                            pregunta["opciones"],
                          );

                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 8),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Pregunta ${index + 1}: ${pregunta["pregunta"]}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  ...opciones.entries.map((entry) {
                                    return RadioListTile<String>(
                                      title: Text(
                                        "${entry.key}) ${entry.value}",
                                      ),
                                      value: entry.key,
                                      groupValue: respuestasUsuario[index],
                                      onChanged:
                                          yaCalificado
                                              ? null
                                              : (value) {
                                                setState(() {
                                                  respuestasUsuario[index] =
                                                      value!;
                                                });
                                              },
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed:
                          yaCalificado
                              ? () {
                                setState(() {
                                  respuestasUsuario.clear();
                                  yaCalificado = false;
                                  puntaje = 0;
                                });
                              }
                              : calificar,
                      child: Text(
                        yaCalificado ? "Reiniciar evaluación" : "Calificar",
                      ),
                    ),
                    if (yaCalificado)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(
                          "Tu puntaje: $puntaje / ${preguntas.length}",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }
}
