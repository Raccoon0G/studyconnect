import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/services.dart';
import '../models/pregunta_model.dart';
import '../widgets/widgets.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AutoevaluationPage extends StatefulWidget {
  const AutoevaluationPage({super.key});

  @override
  State<AutoevaluationPage> createState() => _AutoevaluationPageState();
}

class _AutoevaluationPageState extends State<AutoevaluationPage> {
  final List<String> temasDisponibles = [
    "Funciones algebraicas y trascendentes",
    "Límites de funciones y continuidad",
    "Derivada y optimización",
    "Técnicas de integración",
  ];

  List<String> temasSeleccionados = [];
  Map<String, List<Map<String, dynamic>>> preguntasPorTema = {};
  String? temaSeleccionado;
  Map<int, String> respuestasUsuario = {};
  bool yaCalificado = false;
  int puntaje = 0;
  bool cargando = false;
  bool mostrarBotonGenerarNuevas = false;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final EvaluacionService evaluacionService = EvaluacionService();

  User? user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
  }

  Future<void> obtenerPreguntas(List<String> temas) async {
    if (user == null) {
      _mostrarError("Debes iniciar sesión para generar evaluaciones.");
      return;
    }

    setState(() {
      cargando = true;
      yaCalificado = false;
      respuestasUsuario.clear();
      puntaje = 0;
      preguntasPorTema.clear();
      temaSeleccionado = null;
    });

    try {
      final temaKey = temas.first;
      final snapshot =
          await firestore
              .collection('banco_preguntas')
              .doc(temaKey)
              .collection('preguntas')
              .limit(25)
              .get();

      final preguntas =
          snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();

      final lastEval =
          await firestore
              .collection('evaluaciones_realizadas')
              .where('uid_usuario', isEqualTo: user?.uid)
              .where('tema', isEqualTo: temaKey)
              .orderBy('fecha_realizacion', descending: true)
              .limit(1)
              .get();

      List<String> preguntasAnteriores = [];
      if (lastEval.docs.isNotEmpty) {
        preguntasAnteriores = List<String>.from(
          lastEval.docs.first['preguntas_ids'] ?? [],
        );
      }

      final idsActuales = preguntas.map((p) => p['id']).toList();
      final repetidas =
          idsActuales.where((id) => preguntasAnteriores.contains(id)).length;

      setState(() {
        preguntasPorTema = {
          temaKey: List<Map<String, dynamic>>.from(preguntas),
        };
        temaSeleccionado = temaKey;
        cargando = false;
        mostrarBotonGenerarNuevas = repetidas >= 13;
      });
    } catch (e) {
      setState(() => cargando = false);
      print("Error al obtener preguntas: $e");
      _mostrarError("Error al obtener preguntas de Firestore:\n$e");
    }
  }

  Future<void> _mostrarError(String mensaje) async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Error"),
            content: Text(mensaje),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Aceptar"),
              ),
            ],
          ),
    );
  }

  void _calificar() {
    final preguntas = preguntasPorTema[temaSeleccionado] ?? [];
    int score = 0;

    for (int i = 0; i < preguntas.length; i++) {
      final correcta = preguntas[i]["respuesta_correcta"];
      final respuesta = respuestasUsuario[i];
      if (respuesta != null && respuesta == correcta) {
        score++;
      }
    }

    final preguntasIds = preguntas.map((p) => p['id'] ?? '').toList();
    firestore.collection('evaluaciones_realizadas').add({
      'uid_usuario': user?.uid,
      'nombre_usuario': user?.displayName ?? '',
      'tema': temaSeleccionado,
      'preguntas_ids': preguntasIds,
      'respuestas_usuario': respuestasUsuario,
      'calificacion': score,
      'fecha_realizacion': FieldValue.serverTimestamp(),
    });

    setState(() {
      yaCalificado = true;
      puntaje = score;
    });
  }

  Future<void> generarPreguntasExternas() async {
    try {
      setState(() => cargando = true);
      final nuevasPreguntas = await evaluacionService.obtenerPreguntas([
        temaSeleccionado!,
      ]);
      setState(() {
        preguntasPorTema = {
          temaSeleccionado!:
              nuevasPreguntas[temaSeleccionado!]!
                  .map(
                    (p) => {
                      'pregunta': p.pregunta,
                      'opciones': p.opciones,
                      'respuesta_correcta': p.respuestaCorrecta,
                    },
                  )
                  .toList(),
        };
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      _mostrarError("Error al generar preguntas automáticamente:\n$e");
    }
  }

  // En build() solo agregamos el aviso + botón si mostrarBotonGenerarNuevas == true
  Widget _avisoGenerarNuevas() {
    return Column(
      children: [
        const Text(
          "Se han encontrado preguntas repetidas. ¿Deseas generar nuevas preguntas?",
          style: TextStyle(color: Colors.red),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () async {
            await generarPreguntasExternas();
          },
          child: const Text("Generar nuevas preguntas"),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final preguntas = preguntasPorTema[temaSeleccionado] ?? [];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF048DD2),
        title: const Text('Study Connect'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/'),
            child: const Text('Inicio', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/ranking'),
            child: const Text('Ranking', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/content'),
            child: const Text(
              'Contenidos',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const NotificationIconWidget(),
          TextButton(
            onPressed: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Perfil',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Temas disponibles",
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
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
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed:
                      temasSeleccionados.isNotEmpty
                          ? () => obtenerPreguntas(temasSeleccionados)
                          : null,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Generar evaluación"),
                ),
                if (mostrarBotonGenerarNuevas) ...[
                  const SizedBox(height: 16),
                  _avisoGenerarNuevas(),
                ],
                const SizedBox(height: 20),
                if (cargando)
                  const Center(child: CircularProgressIndicator())
                else if (preguntasPorTema.isEmpty)
                  const Text("Selecciona temas y presiona 'Generar evaluación'")
                else
                  Expanded(
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
                          decoration: const InputDecoration(
                            labelText: "Selecciona un tema",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.builder(
                            itemCount: preguntas.length,
                            itemBuilder: (context, index) {
                              final pregunta = preguntas[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Pregunta ${index + 1}: ${pregunta["pregunta"]}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Column(
                                        children:
                                            (pregunta["opciones"]
                                                    as Map<String, String>)
                                                .entries
                                                .map((entry) {
                                                  return RadioListTile<String>(
                                                    title: Text(
                                                      "${entry.key}) ${entry.value}",
                                                    ),
                                                    value: entry.key,
                                                    groupValue:
                                                        respuestasUsuario[index],
                                                    onChanged: (value) {
                                                      setState(() {
                                                        respuestasUsuario[index] =
                                                            value!;
                                                      });
                                                    },
                                                  );
                                                })
                                                .toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
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
                                  : _calificar,
                          child: Text(
                            yaCalificado ? "Reiniciar evaluación" : "Calificar",
                          ),
                        ),
                        if (yaCalificado)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Text(
                              "Tu puntaje: $puntaje / ${preguntas.length}",
                              style: const TextStyle(
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
          );
        },
      ),
    );
  }
}
