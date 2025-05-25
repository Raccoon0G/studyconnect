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
  bool yaSeNotificoIA = false;
  bool envioExitoso = false;

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

    cargarTotalesPorTema();
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

  Map<String, int> totalPreguntasPorTema = {};

  Future<void> cargarTotalesPorTema() async {
    for (final tema in temasDisponibles) {
      final snapshot =
          await firestore
              .collection('preguntas_por_tema')
              .where('tema', isEqualTo: tema)
              .get();

      totalPreguntasPorTema[tema] = snapshot.size;
    }
    setState(() {}); // Actualiza UI
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

    Map<String, List<Map<String, dynamic>>> nuevasPreguntasPorTema = {};
    bool activarGenerarNuevas = false;

    for (String tema in temas) {
      final snapshot =
          await firestore
              .collection('preguntas_por_tema')
              .where('tema', isEqualTo: tema)
              .get();

      List<Map<String, dynamic>> todas =
          snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();

      // Shuffle aleatorio (esto mejora aleatoriedad)
      todas.shuffle();

      // Revisión del historial
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

      // Filtra las nuevas primero
      List<Map<String, dynamic>> noRepetidas =
          todas.where((p) => !preguntasAnteriores.contains(p['id'])).toList();

      // Si no hay suficientes nuevas, rellena aleatoriamente
      List<Map<String, dynamic>> seleccionadas = [];

      if (noRepetidas.length >= cantidadPreguntas) {
        seleccionadas = noRepetidas.take(cantidadPreguntas).toList();
      } else {
        seleccionadas = [...noRepetidas];
        List<Map<String, dynamic>> restantes =
            todas
                .where(
                  (p) => !seleccionadas.map((e) => e['id']).contains(p['id']),
                )
                .toList();

        restantes.shuffle();
        int faltantes = cantidadPreguntas - seleccionadas.length;
        seleccionadas.addAll(restantes.take(faltantes));
      }

      // Contar cuántas están repetidas
      final repetidas =
          seleccionadas
              .where((p) => preguntasAnteriores.contains(p['id']))
              .length;

      final limiteRepetidas = cantidadPreguntas ~/ 10; // 10% de repetidas
      if (repetidas >= limiteRepetidas) {
        print("⚠️ Alta cantidad de repetidas: $repetidas");
        // Solo sirve como mensaje informativo ahora
      }
      // Mapear para usar en UI
      final preguntasMapeadas =
          seleccionadas.map((p) {
            return {
              'pregunta': p['pregunta'],
              'opciones': p['opciones'],
              'respuesta_correcta':
                  p['respuesta_correcta'] ?? p['respuestaCorrecta'],
              'id': p['id'],
            };
          }).toList();

      nuevasPreguntasPorTema[tema] = preguntasMapeadas;

      // Guardar evaluación generada
      await firestore.collection('evaluaciones_realizadas').add({
        'uid_usuario': user!.uid,
        'nombre_usuario': await _obtenerNombreDesdeUsuarios(user!.uid),
        'tema': tema,
        'preguntas_ids': seleccionadas.map((p) => p['id']).toList(),
        'respuestas_usuario': {},
        'calificacion': 0,
        'fecha_realizacion': FieldValue.serverTimestamp(),
      });
    }

    setState(() {
      preguntasPorTema = nuevasPreguntasPorTema;
      temaSeleccionado = nuevasPreguntasPorTema.keys.first;
      mostrarBotonGenerarNuevas = activarGenerarNuevas;
      cargando = false;
    });
  }

  Widget _botonGenerarConIA() {
    return Card(
      color: Colors.yellow[100],
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "⚠️ ¿Preguntas agotadas o repetidas?",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Center(
                child: const Text(
                  "Puedes generar un nuevo conjunto de preguntas mediante IA (ChatGPT). "
                  "Este proceso puede tardar unos segundos y tiene un costo en recursos. "
                  "Úsalo solo si crees que ya no hay preguntas nuevas disponibles.",
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.bolt),
                label: const Text("Generar con IA (Make)"),
                onPressed: () async {
                  if (temasSeleccionados.length != 1) {
                    _mostrarError("Selecciona solo un tema para usar IA.");
                    return;
                  }

                  final tema = temasSeleccionados.first;

                  setState(() {
                    cargando = true;
                    yaCalificado = false;
                    respuestasUsuario.clear();
                    puntaje = 0;
                    yaSeNotificoIA = false;
                    envioExitoso = false;
                  });

                  final notificado = await evaluacionService
                      .notificarGeneracionPreguntas(tema);

                  setState(() {
                    cargando = false;
                    yaSeNotificoIA = notificado;
                  });

                  if (notificado) {
                    await showDialog(
                      context: context,
                      builder:
                          (_) => AlertDialog(
                            title: const Text(
                              "✅ Preguntas generadas con éxito",
                            ),
                            content: const Text(
                              "Las preguntas han sido enviadas correctamente para generarse con IA. El banco de preguntas se actualizará.",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  setState(() => cargando = true);
                                  await Future.delayed(
                                    const Duration(seconds: 3),
                                  ); // ⏳ espera breve
                                  await cargarTotalesPorTema(); // 🔄 refresca contador
                                  setState(() => cargando = false);
                                },
                                child: const Text("Aceptar"),
                              ),
                            ],
                          ),
                    );
                  } else {
                    _mostrarError("No se pudo notificar a Make.");
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _obtenerNombreDesdeUsuarios(String uid) async {
    try {
      final doc = await firestore.collection('usuarios').doc(uid).get();
      if (doc.exists && doc.data()?['Nombre'] != null) {
        return doc['Nombre'];
      }
    } catch (e) {
      print("Error al obtener nombre desde colección usuarios: $e");
    }
    return "Anónimo";
  }

  Future<List<Map<String, dynamic>>> obtenerEvaluacionesPasadas() async {
    if (user == null) return [];

    final snapshot =
        await FirebaseFirestore.instance
            .collection('evaluaciones_realizadas')
            .where('uid_usuario', isEqualTo: user!.uid)
            .orderBy('fecha_realizacion', descending: true)
            .limit(10)
            .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      // Campos que esperas
      final tema = data['tema'] ?? 'Sin tema';
      final calificacionRaw = data['calificacion'] ?? 0;

      final preguntas = (data['preguntas_ids'] as List?)?.length ?? 1;
      final calificacionFinal = ((calificacionRaw / preguntas) * 10).clamp(
        0,
        10,
      );

      // Manejo especial para fecha
      final rawFecha = data['fecha_realizacion'];
      String fechaFormateada = 'Sin fecha';

      // ✅ Solo conviertes si ES un Timestamp
      if (rawFecha is Timestamp) {
        final fecha = rawFecha.toDate();
        fechaFormateada =
            "${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}";
      } else {
        // 🔎 Si no es Timestamp, solo mostramos 'Sin fecha' y avisamos en consola
        print("⚠️ 'fecha_realizacion' no es Timestamp: $rawFecha");
      }

      // Resultado que regresa esta función
      return {
        'tema': tema,
        'calificacion': calificacionFinal.toStringAsFixed(1),
        'fecha': fechaFormateada,
        'preguntas': preguntas,
        'respuestas_usuario': data['respuestas_usuario'] ?? {},
        'preguntas_ids': data['preguntas_ids'] ?? [],
        'respuestas_usuario': data['respuestas_usuario'],
        'docRef': doc.reference, // para obtener detalles si hace falta
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> obtenerDetallesPreguntas(
    List<String> ids,
    String tema,
  ) async {
    final snapshot =
        await firestore
            .collection('preguntas_por_tema')
            .where(FieldPath.documentId, whereIn: ids)
            .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
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

    final uid = user?.uid;
    String nombre = user?.displayName ?? "Anónimo";

    if (uid != null) {
      final doc = await firestore.collection('usuarios').doc(uid).get();
      if (doc.exists && doc.data()?['Nombre'] != null) {
        nombre = doc['Nombre'];
      }
    }

    // ✅ Buscar la evaluación más reciente del tema actual (guardada al generar)
    final lastEval =
        await firestore
            .collection('evaluaciones_realizadas')
            .where('uid_usuario', isEqualTo: uid)
            .where('tema', isEqualTo: temaSeleccionado)
            .orderBy('fecha_realizacion', descending: true)
            .limit(1)
            .get();

    if (lastEval.docs.isNotEmpty) {
      await lastEval.docs.first.reference.update({
        'respuestas_usuario': respuestasUsuario.map(
          (k, v) => MapEntry(k.toString(), v),
        ),
        'calificacion': score,
        'fecha_realizacion': FieldValue.serverTimestamp(),
      });
    }

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("✅ Evaluación guardada"),
            content: const Text(
              "Tus respuestas y calificación han sido guardadas exitosamente.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Aceptar"),
              ),
            ],
          ),
    );

    setState(() {
      yaCalificado = true;
      puntaje = score;
    });

    final calificacionFinal = (score / preguntas.length) * 10;
    final aprobado = calificacionFinal >= 6.0;

    await showCustomDialog(
      context: context,
      titulo: aprobado ? "¡Felicidades, $nombre! 🎉" : "Ánimo, $nombre 😢",
      mensaje:
          aprobado
              ? "Aprobaste con una calificación de ${calificacionFinal.toStringAsFixed(1)}."
              : "Obtuviste ${calificacionFinal.toStringAsFixed(1)}. No te preocupes, sigue practicando y lo lograrás.",
      tipo: aprobado ? CustomDialogType.success : CustomDialogType.error,
    );

    // 🔔 Enviar notificación al calificar
    await NotificationService.crearNotificacion(
      uidDestino: user!.uid, // o el UID del tutor si lo deseas
      tipo: 'calificacion',
      titulo: "✅ Evaluación completada",
      contenido:
          "$nombre has terminado una autoevaluación del tema '$temaSeleccionado'.",
      referenciaId: temaSeleccionado ?? '',
      tema: temaSeleccionado,
      uidEmisor: user?.uid,
      nombreEmisor: nombre,
    );

    if (aprobado) {
      await _audioPlayer.play(AssetSource('audio/applause.mp3'));
      _confettiController.play();
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
        Center(
          child: const Text(
            "Se han encontrado preguntas repetidas. ¿Deseas generar nuevas preguntas con IA?",
            style: TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            icon: const Icon(Icons.bolt),
            label: const Text("Generar con IA (Make)"),
            onPressed: () async {
              if (temasSeleccionados.length != 1) {
                _mostrarError("Selecciona solo un tema para usar IA.");
                return;
              }

              final tema = temasSeleccionados.first;

              setState(() {
                cargando = true;
                yaCalificado = false;
                respuestasUsuario.clear();
                puntaje = 0;
                yaSeNotificoIA = false;
                envioExitoso = false;
              });

              final notificado = await evaluacionService
                  .notificarGeneracionPreguntas(tema);

              setState(() {
                cargando = false;
                yaSeNotificoIA = notificado;
              });

              if (notificado) {
                await showCustomDialog(
                  context: context,
                  titulo: "Preguntas generadas con IA",
                  mensaje:
                      "Se enviaron correctamente a Make para que se generen nuevas preguntas.",
                  tipo: CustomDialogType.success,
                );
              } else {
                _mostrarError("No se pudo notificar a Make.");
              }
            },
          ),
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
          appBar: const CustomAppBar(showBack: true),

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
                    Center(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children:
                            temasDisponibles.map((tema) {
                              final seleccionado = temasSeleccionados.contains(
                                tema,
                              );
                              return FilterChip(
                                label: Text(
                                  "$tema (${totalPreguntasPorTema[tema] ?? 0})",
                                ),
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
                    ),

                    const SizedBox(height: 12),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed:
                            temasSeleccionados.isNotEmpty
                                ? () => obtenerPreguntas(temasSeleccionados)
                                : null,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Generar evaluación"),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (temasSeleccionados.isNotEmpty) _botonGenerarConIA(),

                    const SizedBox(height: 12),
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.history),
                        label: const Text("Ver resultados pasados"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          final historial = await obtenerEvaluacionesPasadas();

                          if (historial.isEmpty) {
                            _mostrarError("No tienes evaluaciones anteriores.");
                            return;
                          }
                          await showDialog(
                            context: context,
                            builder:
                                (_) => AlertDialog(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: const Text(
                                    "🕓 Tus evaluaciones pasadas",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: SizedBox(
                                    width: double.maxFinite,
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      itemCount: historial.length,
                                      separatorBuilder:
                                          (_, __) => const Divider(),

                                      itemBuilder: (context, index) {
                                        final eval = historial[index];
                                        return ListTile(
                                          onTap: () async {
                                            final List<String> ids =
                                                List<String>.from(
                                                  eval['preguntas_ids'] ?? [],
                                                );
                                            final Map<String, dynamic>
                                            respuestas =
                                                Map<String, dynamic>.from(
                                                  eval['respuestas_usuario'] ??
                                                      {},
                                                );
                                            final String tema =
                                                eval['tema'] ??
                                                'Tema desconocido';

                                            final snapshot =
                                                await FirebaseFirestore.instance
                                                    .collection(
                                                      'preguntas_por_tema',
                                                    )
                                                    .where(
                                                      FieldPath.documentId,
                                                      whereIn: ids,
                                                    )
                                                    .get();

                                            final preguntasOrdenadas =
                                                ids
                                                    .map((id) {
                                                      try {
                                                        final doc = snapshot
                                                            .docs
                                                            .firstWhere(
                                                              (d) => d.id == id,
                                                            );
                                                        final data = doc.data();

                                                        final opciones =
                                                            _convertirOpciones(
                                                              data['opciones'],
                                                            );
                                                        final respuestaUsuario =
                                                            respuestas[ids
                                                                .indexOf(id)
                                                                .toString()] ??
                                                            '';

                                                        return {
                                                          'pregunta':
                                                              data['pregunta'],
                                                          'opciones': opciones,
                                                          'respuesta_correcta':
                                                              data['respuesta_correcta'] ??
                                                              data['respuestaCorrecta'],
                                                          'id': doc.id,
                                                          'respuesta_usuario':
                                                              respuestaUsuario,
                                                        };
                                                      } catch (e) {
                                                        print(
                                                          "❌ Pregunta no encontrada: $id",
                                                        );
                                                        return null;
                                                      }
                                                    })
                                                    .where((p) => p != null)
                                                    .toList();

                                            await showDialog(
                                              context: context,
                                              builder:
                                                  (_) => AlertDialog(
                                                    backgroundColor:
                                                        Colors.white,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    title: Text(
                                                      "📘 Preguntas - $tema",
                                                    ),
                                                    content: SizedBox(
                                                      width: double.maxFinite,
                                                      child: ListView.separated(
                                                        shrinkWrap: true,
                                                        itemCount:
                                                            preguntasOrdenadas
                                                                .length,
                                                        separatorBuilder:
                                                            (_, __) =>
                                                                const Divider(),
                                                        itemBuilder: (
                                                          context,
                                                          index,
                                                        ) {
                                                          final p =
                                                              preguntasOrdenadas[index]!;
                                                          final opciones = Map<
                                                            String,
                                                            String
                                                          >.from(p['opciones']);
                                                          final correcta =
                                                              p['respuesta_correcta'];
                                                          final usuario =
                                                              p['respuesta_usuario'];
                                                          final esCorrecta =
                                                              usuario ==
                                                              correcta;

                                                          return Container(
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  esCorrecta
                                                                      ? Colors
                                                                          .green
                                                                          .shade50
                                                                      : Colors
                                                                          .red
                                                                          .shade50,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                            ),
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  12,
                                                                ),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  "Pregunta ${index + 1}",
                                                                  style: const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 6,
                                                                ),
                                                                CustomLatexText(
                                                                  contenido:
                                                                      "🧠 ${p['pregunta']}",
                                                                  fontSize: 18,
                                                                  scrollHorizontal:
                                                                      false,
                                                                  prepararLatex:
                                                                      prepararLaTeX,
                                                                ),
                                                                const SizedBox(
                                                                  height: 10,
                                                                ),
                                                                CustomLatexText(
                                                                  contenido:
                                                                      "✅ Respuesta correcta: $correcta) ${opciones[correcta] ?? ''}",
                                                                  fontSize: 16,
                                                                  color:
                                                                      Colors
                                                                          .green
                                                                          .shade800,
                                                                  scrollHorizontal:
                                                                      false,
                                                                  prepararLatex:
                                                                      prepararLaTeX,
                                                                ),
                                                                CustomLatexText(
                                                                  contenido:
                                                                      "📝 Tu respuesta: $usuario) ${opciones[usuario] ?? 'Sin responder'}",
                                                                  fontSize: 16,
                                                                  color:
                                                                      esCorrecta
                                                                          ? Colors
                                                                              .green
                                                                              .shade800
                                                                          : Colors
                                                                              .red
                                                                              .shade800,
                                                                  scrollHorizontal:
                                                                      false,
                                                                  prepararLatex:
                                                                      prepararLaTeX,
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                            ),
                                                        child: const Text(
                                                          "Cerrar",
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                            );
                                          },
                                          leading: CircleAvatar(
                                            backgroundColor:
                                                Colors.blue.shade100,
                                            child: const Icon(
                                              Icons.school,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          title: Text(
                                            eval['tema'] ?? "Tema desconocido",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          subtitle: Text(
                                            "📅 ${eval['fecha']}",
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          trailing: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                "⭐ ${eval['calificacion']}/10",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      (double.tryParse(
                                                                    eval['calificacion'],
                                                                  ) ??
                                                                  0) <
                                                              6
                                                          ? Colors.red
                                                          : Colors.green[700],
                                                ),
                                              ),
                                              Text(
                                                "${eval['preguntas']} preguntas",
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Cerrar"),
                                    ),
                                  ],
                                ),
                          );
                        },
                      ),
                    ),

                    if (mostrarBotonGenerarNuevas) ...[
                      const SizedBox(height: 16),
                      _avisoGenerarNuevas(),
                    ],
                    const SizedBox(height: 8),
                    // ElevatedButton.icon(
                    //   style: ElevatedButton.styleFrom(
                    //     backgroundColor: Colors.amber,
                    //     foregroundColor: Colors.black,
                    //   ),
                    //   icon: const Icon(Icons.bolt),
                    //   label: const Text(
                    //     "Prueba: generar preguntas con IA (Make)",
                    //   ),
                    //   onPressed: () async {
                    //     if (temasSeleccionados.length != 1) {
                    //       _mostrarError(
                    //         "Selecciona solo un tema para usar IA.",
                    //       );
                    //       return;
                    //     }

                    //     final tema = temasSeleccionados.first;

                    //     setState(() {
                    //       cargando = true;
                    //       yaCalificado = false;
                    //       respuestasUsuario.clear();
                    //       puntaje = 0;
                    //       yaSeNotificoIA = false;
                    //       envioExitoso = false;
                    //     });

                    //     // 🔔 Notificar a Make
                    //     final notificado = await evaluacionService
                    //         .notificarGeneracionPreguntas(tema);

                    //     setState(() {
                    //       cargando = false;
                    //       yaSeNotificoIA = notificado;
                    //     });

                    //     if (notificado) {
                    //       await showCustomDialog(
                    //         context: context,
                    //         titulo: "Preguntas generadas con IA",
                    //         mensaje:
                    //             "Las preguntas fueron generadas correctamente por Make.\n Por",
                    //         tipo: CustomDialogType.success,
                    //       );
                    //     } else {
                    //       _mostrarError("No se pudo notificar a Make.");
                    //     }
                    //   },
                    // ),
                    const SizedBox(height: 20),

                    if (cargando)
                      const Center(child: CircularProgressIndicator())
                    else if (preguntasPorTema.isEmpty)
                      Center(
                        child: const Text(
                          "Selecciona temas y presiona 'Generar evaluación'",
                        ),
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
                                  bool yaSeNotificoIA = false;
                                  bool envioExitoso = false;
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
