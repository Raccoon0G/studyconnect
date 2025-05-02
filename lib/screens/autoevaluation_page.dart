import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/utils.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';

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
  late ConfettiController _confettiController;
  late ConfettiController _confettiLeftController;
  late ConfettiController _confettiRightController;
  late ConfettiController _confettiBottomController;

  final AudioPlayer _audioPlayer = AudioPlayer();

  User? user;
  int cantidadPreguntas = 25; // Default

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _confettiLeftController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _confettiRightController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _confettiBottomController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _confettiLeftController.dispose();
    _confettiRightController.dispose();
    _confettiBottomController.dispose();
    _audioPlayer.dispose();
    super.dispose();
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

    Map<String, List<Map<String, dynamic>>> nuevasPreguntas = {};
    bool activarGenerarNuevas = false;

    for (String tema in temas) {
      final snapshot =
          await firestore
              .collection('preguntas_por_tema')
              .where('tema', isEqualTo: tema)
              .orderBy('timestamp', descending: true)
              .limit(cantidadPreguntas)
              .get();

      if (snapshot.size < cantidadPreguntas) {
        await _mostrarError(
          "No hay suficientes preguntas disponibles para '$tema'. Se encontraron solo ${snapshot.size}.",
        );
        continue; // O puedes saltar o poner las que haya
      }

      final preguntas =
          snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();

      // Revisar última evaluación del usuario
      final lastEval =
          await firestore
              .collection('evaluaciones_realizadas')
              .where('uid_usuario', isEqualTo: user?.uid)
              .where('tema', isEqualTo: tema)
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

      nuevasPreguntas[tema] = preguntas;

      if (repetidas >= 13) {
        activarGenerarNuevas = true;
      }
    }

    setState(() {
      preguntasPorTema = nuevasPreguntas;
      temaSeleccionado = nuevasPreguntas.keys.first;
      mostrarBotonGenerarNuevas = activarGenerarNuevas;
      cargando = false;
    });
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

  void _calificar() async {
    final preguntas = preguntasPorTema[temaSeleccionado] ?? [];
    int score = 0;

    for (int i = 0; i < preguntas.length; i++) {
      final correcta =
          preguntas[i]["respuesta_correcta"] ??
          preguntas[i]["respuestaCorrecta"];
      final respuesta = respuestasUsuario[i];
      if (respuesta != null && respuesta.trim() == correcta.trim()) {
        score++;
      }
    }

    final preguntasIds = preguntas.map((p) => p['id'] ?? '').toList();

    // 🔄 Obtener nombre real del usuario desde la colección `usuarios`
    final uid = user?.uid;
    String nombre = user?.displayName ?? "Anónimo";

    if (uid != null) {
      final doc = await firestore.collection('usuarios').doc(uid).get();
      if (doc.exists && doc.data()?['Nombre'] != null) {
        nombre = doc['Nombre'];
      }
    }

    await firestore.collection('evaluaciones_realizadas').add({
      'uid_usuario': uid,
      'nombre_usuario': nombre,
      'tema': temaSeleccionado,
      'preguntas_ids': preguntasIds,
      'respuestas_usuario': respuestasUsuario.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'calificacion': score,
      'fecha_realizacion': FieldValue.serverTimestamp(),
    });

    setState(() {
      yaCalificado = true;
      puntaje = score;
    });

    final calificacionFinal = (score / preguntas.length) * 10;
    final aprobado = calificacionFinal >= 6.0;

    // 🎉 Mostrar diálogo dinámico con emoji

    await showCustomDialog(
      context: context,
      titulo: aprobado ? "¡Felicidades, $nombre! 🎉" : "Ánimo, $nombre 😢",
      mensaje:
          aprobado
              ? "Aprobaste con una calificación de ${calificacionFinal.toStringAsFixed(1)}."
              : "Obtuviste ${calificacionFinal.toStringAsFixed(1)}. No te preocupes, sigue practicando y lo lograrás.",
      tipo: aprobado ? CustomDialogType.success : CustomDialogType.error,
    );

    if (aprobado) {
      await _audioPlayer.play(AssetSource('audio/applause.mp3'));
      _confettiController.play(); // solo si aprobó
      _confettiLeftController.play();
      _confettiRightController.play();
      _confettiBottomController.play();
    }
  }

  Future<void> generarPreguntasExternas() async {
    try {
      setState(() => cargando = true);
      if (user == null || user!.uid.isEmpty) {
        _mostrarError("No se pudo identificar al usuario.");
        return;
      }

      final uid = user!.uid;
      final nombre =
          (user!.displayName == null || user!.displayName!.isEmpty)
              ? "Anónimo"
              : user!.displayName!;

      final tema = temasSeleccionados.first;
      final nuevasPreguntas = await evaluacionService
          .obtenerPreguntasDesdeFirestore(tema, cantidad: cantidadPreguntas);

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

  Map<String, String> _convertirOpciones(dynamic rawOpciones) {
    if (rawOpciones is Map) {
      return Map<String, String>.from(rawOpciones);
    } else if (rawOpciones is List) {
      final letras = ['A', 'B', 'C', 'D', 'E'];
      return {
        for (int i = 0; i < rawOpciones.length; i++)
          letras[i]: rawOpciones[i].toString(),
      };
    } else {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final preguntas = preguntasPorTema[temaSeleccionado] ?? [];

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF048DD2),
            title: const Text('Study Connect'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/'),
                child: const Text(
                  'Inicio',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/ranking'),
                child: const Text(
                  'Ranking',
                  style: TextStyle(color: Colors.white),
                ),
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
                onPressed: () => Navigator.pushNamed(context, '/user_profile'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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
                    DropdownButtonFormField<int>(
                      value: cantidadPreguntas,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            cantidadPreguntas = value;
                          });
                        }
                      },
                      items:
                          [5, 10, 15, 20, 25, 30]
                              .map(
                                (n) => DropdownMenuItem(
                                  value: n,
                                  child: Text('$n preguntas'),
                                ),
                              )
                              .toList(),
                      decoration: const InputDecoration(
                        labelText: "Cantidad de preguntas",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children:
                          temasDisponibles.map((tema) {
                            final seleccionado = temasSeleccionados.contains(
                              tema,
                            );
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
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                      ),
                      icon: const Icon(Icons.bolt),
                      label: const Text(
                        "Prueba: generar preguntas con IA (Make)",
                      ),
                      onPressed: () async {
                        if (temasSeleccionados.length != 1) {
                          _mostrarError(
                            "Para generar preguntas con IA, selecciona solo un tema.",
                          );
                          return;
                        }

                        setState(() => cargando = true);
                        try {
                          final tema = temasSeleccionados.first;
                          final nuevasPreguntas = await evaluacionService
                              .obtenerPreguntasDesdeFirestore(
                                tema,
                                cantidad: cantidadPreguntas,
                              );

                          if (nuevasPreguntas.isEmpty) {
                            _mostrarError(
                              "No se encontraron preguntas generadas por IA.",
                            );
                            return;
                          }

                          setState(() {
                            preguntasPorTema = {
                              for (var tema in nuevasPreguntas.keys)
                                tema:
                                    nuevasPreguntas[tema]!
                                        .map(
                                          (p) => {
                                            'pregunta': p.pregunta,
                                            'opciones': p.opciones,
                                            'respuesta_correcta':
                                                p.respuestaCorrecta,
                                          },
                                        )
                                        .toList(),
                            };
                            temaSeleccionado = nuevasPreguntas.keys.first;
                            cargando = false;
                            yaCalificado = false;
                            respuestasUsuario.clear();
                            puntaje = 0;
                          });
                        } catch (e) {
                          print("Error al generar preguntas: $e");
                          setState(() => cargando = false);
                          _mostrarError(
                            "Error al generar preguntas desde Make:\n$e",
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    if (cargando)
                      const Center(child: CircularProgressIndicator())
                    else if (preguntasPorTema.isEmpty)
                      const Text(
                        "Selecciona temas y presiona 'Generar evaluación'",
                      )
                    else
                      Expanded(
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: temaSeleccionado,
                              items:
                                  preguntasPorTema.keys
                                      .map(
                                        (tema) => DropdownMenuItem(
                                          value: tema,
                                          child: Text(tema),
                                        ),
                                      )
                                      .toList(),
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
                                  return CustomLatexQuestionCard(
                                    numero: index + 1,
                                    pregunta: pregunta["pregunta"],
                                    opciones: _convertirOpciones(
                                      pregunta["opciones"],
                                    ),
                                    seleccionada: respuestasUsuario[index],
                                    onChanged: (value) {
                                      setState(() {
                                        respuestasUsuario[index] = value;
                                      });
                                    },
                                    mostrarCorrecta: yaCalificado,
                                    respuestaCorrecta:
                                        pregunta["respuesta_correcta"] ??
                                        pregunta["respuestaCorrecta"],
                                    respuestaUsuario: respuestasUsuario[index],
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
                                yaCalificado
                                    ? "Reiniciar evaluación"
                                    : "Calificar",
                              ),
                            ),
                            if (yaCalificado)
                              CustomScoreCard(
                                puntaje: puntaje,
                                total: preguntas.length,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),

        // 🎊 Confetti flotante (fuera del Scaffold)
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            maxBlastForce: 20,
            minBlastForce: 8,
            gravity: 0.3,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.purple,
              Colors.orange,
              Colors.pink,
            ],
          ),
        ),
        // Lado izquierdo
        Align(
          alignment: Alignment.centerLeft,
          child: ConfettiWidget(
            confettiController: _confettiLeftController,
            blastDirection: 0, // Hacia la derecha
            emissionFrequency: 0.05,
            numberOfParticles: 10,
            maxBlastForce: 15,
            minBlastForce: 5,
            gravity: 0.3,
            shouldLoop: false,
            colors: const [Colors.green, Colors.pink, Colors.blue],
          ),
        ),

        // Lado derecho
        Align(
          alignment: Alignment.centerRight,
          child: ConfettiWidget(
            confettiController: _confettiRightController,
            blastDirection: 3.14, // Hacia la izquierda
            emissionFrequency: 0.05,
            numberOfParticles: 10,
            maxBlastForce: 15,
            minBlastForce: 5,
            gravity: 0.3,
            shouldLoop: false,
            colors: const [Colors.orange, Colors.purple, Colors.yellow],
          ),
        ),

        // Desde abajo
        Align(
          alignment: Alignment.bottomCenter,
          child: ConfettiWidget(
            confettiController: _confettiBottomController,
            blastDirection: -3.14 / 2, // Hacia arriba
            emissionFrequency: 0.08,
            numberOfParticles: 20,
            maxBlastForce: 18,
            minBlastForce: 8,
            gravity: 0.2,
            shouldLoop: false,
            colors: const [Colors.cyan, Colors.red, Colors.lime],
          ),
        ),
      ],
    );
  }
}
