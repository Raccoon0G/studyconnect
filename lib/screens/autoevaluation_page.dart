import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AutoevaluationPage extends StatefulWidget {
  @override
  _AutoevaluationPageState createState() => _AutoevaluationPageState();
}

class _AutoevaluationPageState extends State<AutoevaluationPage> {
  final List<String> temasDisponibles = [
    "Funciones algebraicas y trascendentes",
    "Límites de funciones y continuidad",
    "Derivada y optimización",
    "Técnicas de integración",
  ];

  List<String> temasSeleccionados = [];
  Map<String, List<dynamic>> preguntasPorTema = {};
  String? temaSeleccionado;
  Map<int, String> respuestasUsuario = {};
  bool yaCalificado = false;
  int puntaje = 0;
  bool cargando = false;

  Future<void> obtenerPreguntas(List<String> temas) async {
    setState(() {
      cargando = true;
      yaCalificado = false;
      respuestasUsuario.clear();
      puntaje = 0;
      preguntasPorTema.clear();
      temaSeleccionado = null;
    });

    try {
      final response = await http.post(
        Uri.parse("https://hook.us2.make.com/dqn70pg36b3bxurrbgbiint46wr1gias"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"temas": temas}),
      );

      print("🟣 RESPONSE STATUS: ${response.statusCode}");
      print("🟣 RESPONSE BODY:\n${response.body}");

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);

          if (data is Map<String, dynamic> && data.isNotEmpty) {
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
            throw Exception("La respuesta está vacía o mal estructurada.");
          }
        } catch (e) {
          throw Exception("Error al decodificar JSON: $e");
        }
      } else {
        throw Exception(
          "Respuesta HTTP ${response.statusCode}: ${response.body}",
        );
      }
    } catch (e) {
      setState(() => cargando = false);
      _mostrarError("No se pudieron obtener las preguntas.\n\n$e");
    }
  }

  void _mostrarError(String mensaje) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Error"),
            content: Text(mensaje),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Aceptar"),
              ),
            ],
          ),
    );
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
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children:
                  temasDisponibles.map((tema) {
                    final seleccionado = temasSeleccionados.contains(tema);
                    return FilterChip(
                      label: Text(tema),
                      selected: seleccionado,
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            temasSeleccionados.add(tema);
                          } else {
                            temasSeleccionados.remove(tema);
                          }
                        });
                      },
                    );
                  }).toList(),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed:
                  temasSeleccionados.isNotEmpty
                      ? () => obtenerPreguntas(temasSeleccionados)
                      : null,
              child: Text("Generar evaluación"),
            ),
            SizedBox(height: 20),
            cargando
                ? Center(child: CircularProgressIndicator())
                : preguntasPorTema.isEmpty
                ? Text("Selecciona temas y presiona 'Generar evaluación'")
                : Expanded(
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
          ],
        ),
      ),
    );
  }
}
