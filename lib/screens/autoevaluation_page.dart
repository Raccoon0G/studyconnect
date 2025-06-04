import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/utils.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';

// Colores de acento
const Color colorPrimarioAutoevaluacion = Color(0xFF7E57C2);
const Color colorSecundarioAutoevaluacion = Color(0xFF1976D2);
const Color colorTerciarioAutoevaluacion = Colors.amber;

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

  final Map<String, String> mapTemaToClave = {
    "Funciones algebraicas y trascendentes": "FnAlg",
    "Límites de funciones y continuidad": "Lim",
    "Derivada y optimización": "Der",
    "Técnicas de integración": "TecInteg",
  };

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
  int cantidadPreguntas = 25;
  Map<String, int> totalPreguntasPorTema = {};

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

  String _nombreTema(String claveOrNombre) {
    for (var entry in mapTemaToClave.entries) {
      if (entry.value == claveOrNombre) return entry.key;
    }
    return temasDisponibles.contains(claveOrNombre)
        ? claveOrNombre
        : claveOrNombre;
  }

  String _claveTema(String nombreCompleto) {
    return mapTemaToClave[nombreCompleto] ?? nombreCompleto;
  }

  Future<void> cargarTotalesPorTema() async {
    Map<String, int> conteoLocal = {};
    for (final temaNombreCompleto in temasDisponibles) {
      try {
        final snapshot =
            await firestore
                .collection('preguntas_por_tema')
                .where('tema', isEqualTo: temaNombreCompleto)
                .get();
        conteoLocal[temaNombreCompleto] = snapshot.size;
      } catch (e) {
        debugPrint("Error cargando totales para $temaNombreCompleto: $e");
        conteoLocal[temaNombreCompleto] = 0;
      }
    }
    if (mounted) {
      setState(() {
        totalPreguntasPorTema = conteoLocal;
      });
    }
  }

  Future<void> obtenerPreguntas(List<String> temasNombresCompletos) async {
    if (user == null) {
      _mostrarDialogoLogin("Debes iniciar sesión para generar evaluaciones.");
      return;
    }
    setState(() {
      cargando = true;
      yaCalificado = false;
      respuestasUsuario.clear();
      puntaje = 0;
      preguntasPorTema.clear();
      temaSeleccionado = null;
      mostrarBotonGenerarNuevas = false;
    });
    Map<String, List<Map<String, dynamic>>> nuevasPreguntasPorTema = {};
    bool activarGenerarNuevasLocal = false;

    for (String temaNombreCompleto in temasNombresCompletos) {
      try {
        final snapshot =
            await firestore
                .collection('preguntas_por_tema')
                .where('tema', isEqualTo: temaNombreCompleto)
                .get();

        List<Map<String, dynamic>> todas =
            snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList();
        todas.shuffle();

        final lastEval =
            await firestore
                .collection('evaluaciones_realizadas')
                .where('uid_usuario', isEqualTo: user?.uid)
                .where('tema', isEqualTo: temaNombreCompleto)
                .orderBy('fecha_realizacion', descending: true)
                .limit(1)
                .get();

        List<String> preguntasAnteriores = [];
        if (lastEval.docs.isNotEmpty) {
          preguntasAnteriores = List<String>.from(
            lastEval.docs.first['preguntas_ids'] ?? [],
          );
        }
        List<Map<String, dynamic>> noRepetidas =
            todas.where((p) => !preguntasAnteriores.contains(p['id'])).toList();
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
          if (faltantes > 0 && restantes.isNotEmpty) {
            seleccionadas.addAll(
              restantes.take(min(faltantes, restantes.length)),
            );
          }
        }

        final repetidas =
            seleccionadas
                .where((p) => preguntasAnteriores.contains(p['id']))
                .length;
        final limiteRepetidas = cantidadPreguntas ~/ 10;
        if (repetidas >= limiteRepetidas &&
            seleccionadas.length == cantidadPreguntas) {
          print(
            "⚠️ Alta cantidad de repetidas para $temaNombreCompleto: $repetidas de $cantidadPreguntas",
          );
          activarGenerarNuevasLocal = true;
        }

        final preguntasMapeadas =
            seleccionadas
                .map(
                  (p) => {
                    'pregunta': p['pregunta'],
                    'opciones': p['opciones'],
                    'respuesta_correcta':
                        p['respuesta_correcta'] ?? p['respuestaCorrecta'],
                    'id': p['id'],
                  },
                )
                .toList();

        nuevasPreguntasPorTema[temaNombreCompleto] = preguntasMapeadas;

        if (seleccionadas.isNotEmpty) {
          await firestore.collection('evaluaciones_realizadas').add({
            'uid_usuario': user!.uid,
            'nombre_usuario': await _obtenerNombreDesdeUsuarios(user!.uid),
            'tema': temaNombreCompleto,
            'preguntas_ids': seleccionadas.map((p) => p['id']).toList(),
            'respuestas_usuario': {},
            'calificacion': 0,
            'fecha_realizacion': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        debugPrint("Error obteniendo preguntas para $temaNombreCompleto: $e");
        _mostrarError(
          "Error al cargar preguntas para el tema '$temaNombreCompleto'. Intenta de nuevo.",
        );
      }
    }
    if (mounted) {
      setState(() {
        preguntasPorTema = nuevasPreguntasPorTema;
        if (nuevasPreguntasPorTema.isNotEmpty) {
          temaSeleccionado = nuevasPreguntasPorTema.keys.first;
        }
        mostrarBotonGenerarNuevas = activarGenerarNuevasLocal;
        cargando = false;
      });
    }
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
      final String temaNombreCompleto = data['tema'] ?? 'Sin tema';

      final calificacionRaw = data['calificacion'] ?? 0;
      final preguntasCount = (data['preguntas_ids'] as List?)?.length ?? 1;
      final calificacionFinal =
          ((preguntasCount > 0 ? calificacionRaw / preguntasCount : 0) * 10)
              .clamp(0.0, 10.0);

      final rawFecha = data['fecha_realizacion'];
      String fechaFormateada = 'Sin fecha';
      if (rawFecha is Timestamp) {
        final fecha = rawFecha.toDate();
        fechaFormateada =
            "${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}";
      } else {
        print("⚠️ 'fecha_realizacion' no es Timestamp: $rawFecha");
      }
      return {
        'tema': temaNombreCompleto,
        'calificacion': calificacionFinal.toStringAsFixed(1),
        'fecha': fechaFormateada,
        'preguntas':
            preguntasCount == 1 && (data['preguntas_ids'] as List?) == null
                ? 0
                : preguntasCount,
        'respuestas_usuario': Map<String, dynamic>.from(
          data['respuestas_usuario'] ?? {},
        ),
        'preguntas_ids': List<String>.from(data['preguntas_ids'] ?? []),
        'docRef': doc.reference,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> obtenerDetallesPreguntas(
    List<String> ids,
    String temaNombreCompletoContexto,
  ) async {
    if (ids.isEmpty) return [];
    List<Map<String, dynamic>> detalles = [];
    try {
      final snapshot =
          await firestore
              .collection('preguntas_por_tema')
              .where(FieldPath.documentId, whereIn: ids)
              .get();

      detalles =
          snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();

      List<Map<String, dynamic>> detallesOrdenados = [];
      for (String id in ids) {
        final detalle = detalles.firstWhere(
          (d) => d['id'] == id,
          orElse: () => {},
        );
        if (detalle.isNotEmpty) detallesOrdenados.add(detalle);
      }
      return detallesOrdenados;
    } catch (e) {
      debugPrint(
        "Error obteniendo detalles de preguntas para el tema $temaNombreCompletoContexto: $e",
      );
    }
    return [];
  }

  Future<void> _mostrarError(String mensaje) async {
    if (!mounted) return;
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

  Future<void> _mostrarDialogoLogin(String mensaje) async {
    if (!mounted) return;
    final theme = Theme.of(context);
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: theme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Text(
              "Inicio de Sesión Requerido",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            content: Text(
              mensaje,
              style: GoogleFonts.poppins(
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancelar",
                  style: GoogleFonts.poppins(color: theme.colorScheme.primary),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimarioAutoevaluacion,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/login');
                },
                child: Text("Iniciar Sesión", style: GoogleFonts.poppins()),
              ),
            ],
          ),
    );
  }

  Future<void> _mostrarDialogoSimple(
    BuildContext context, {
    required String titulo,
    required String contenido,
  }) async {
    if (!mounted) return;
    final theme = Theme.of(context);
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: theme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Text(
              titulo,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            content: Text(
              contenido,
              style: GoogleFonts.poppins(
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Aceptar",
                  style: GoogleFonts.poppins(color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
    );
  }

  void _calificar() async {
    if (temaSeleccionado == null) return;
    final preguntas = preguntasPorTema[temaSeleccionado!] ?? [];
    if (preguntas.isEmpty) {
      _mostrarError("No hay preguntas para calificar.");
      return;
    }
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

    final uid = user?.uid;
    String nombre = "Usuario";
    if (user != null) {
      nombre = await _obtenerNombreDesdeUsuarios(user!.uid);
    }

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

    _mostrarDialogoSimple(
      context,
      titulo: "✅ Evaluación Guardada",
      contenido:
          "Tus respuestas y calificación han sido guardadas exitosamente.",
    );
    if (mounted) {
      setState(() {
        yaCalificado = true;
        puntaje = score;
      });
    }

    final calificacionFinal =
        (preguntas.isNotEmpty ? (score / preguntas.length) : 0.0) * 10;
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
    if (user != null) {
      await NotificationService.crearNotificacion(
        uidDestino: user!.uid,
        tipo: 'calificacion',
        titulo: "✅ Evaluación completada",
        contenido:
            "$nombre has terminado una autoevaluación del tema '$temaSeleccionado'.",
        referenciaId: temaSeleccionado ?? '',
        tema: temaSeleccionado,
        uidEmisor: user?.uid,
        nombreEmisor: nombre,
      );
    }
    if (aprobado) {
      if (mounted) await _audioPlayer.play(AssetSource('audio/applause.mp3'));
      if (mounted) _confettiController.play();
      if (mounted) _confettiLeftController.play();
      if (mounted) _confettiRightController.play();
      if (mounted) _confettiBottomController.play();
    }
  }

  Map<String, String> _convertirOpciones(dynamic rawOpciones) {
    if (rawOpciones is Map) {
      return rawOpciones.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } else if (rawOpciones is List) {
      final letras = ['A', 'B', 'C', 'D', 'E'];
      Map<String, String> opcionesConvertidas = {};
      for (int i = 0; i < rawOpciones.length && i < letras.length; i++) {
        opcionesConvertidas[letras[i]] = rawOpciones[i].toString();
      }
      return opcionesConvertidas;
    }
    return {};
  }

  void _volverASeleccion() {
    setState(() {
      preguntasPorTema.clear();
      respuestasUsuario.clear();
      yaCalificado = false;
      puntaje = 0;
      temasSeleccionados.clear();
      temaSeleccionado = null;
      mostrarBotonGenerarNuevas = false;
    });
  }

  Widget _buildConfiguracionUI(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 20, left: 4, right: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Configura tu Autoevaluación",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 24),
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
              decoration: InputDecoration(
                labelText: "Cantidad de preguntas por tema",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.format_list_numbered),
                filled: true,
              ),
              dropdownColor: theme.canvasColor,
            ),
            const SizedBox(height: 20),
            Text(
              "Selecciona los temas:",
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children:
                  temasDisponibles.map((temaNombreCompleto) {
                    final seleccionado = temasSeleccionados.contains(
                      temaNombreCompleto,
                    );
                    final total =
                        totalPreguntasPorTema[temaNombreCompleto] ?? 0;
                    return FilterChip(
                      label: Text(
                        "$temaNombreCompleto ($total)",
                        style: GoogleFonts.poppins(
                          color:
                              seleccionado
                                  ? theme.colorScheme.onPrimary
                                  : theme.chipTheme.labelStyle?.color,
                        ),
                      ),
                      selected: seleccionado,
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            temasSeleccionados.add(temaNombreCompleto);
                          } else {
                            temasSeleccionados.remove(temaNombreCompleto);
                          }
                        });
                      },
                      selectedColor: colorPrimarioAutoevaluacion,
                      checkmarkColor: theme.colorScheme.onPrimary,
                      backgroundColor: theme.chipTheme.backgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color:
                              seleccionado
                                  ? colorPrimarioAutoevaluacion
                                  : theme.dividerColor,
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorPrimarioAutoevaluacion,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onPressed:
                  temasSeleccionados.isNotEmpty
                      ? () => obtenerPreguntas(temasSeleccionados)
                      : null,
              icon: const Icon(Icons.play_circle_outline_rounded, size: 22),
              label: const Text("Generar Evaluación"),
            ),
            const SizedBox(height: 12),
            if (temasSeleccionados.length == 1 && mostrarBotonGenerarNuevas)
              _avisoGenerarNuevas(),
            if (temasSeleccionados.length == 1 && !mostrarBotonGenerarNuevas)
              _buildBotonGenerarConIAEstilizado(
                context,
                temasSeleccionados.first,
              ),
            const SizedBox(height: 16),
            TextButton.icon(
              icon: const Icon(Icons.history_rounded),
              label: const Text("Ver Resultados Pasados"),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () async {
                final historial = await obtenerEvaluacionesPasadas();
                if (!mounted) return;
                if (historial.isEmpty) {
                  _mostrarError("No tienes evaluaciones anteriores.");
                  return;
                }
                await showDialog(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        backgroundColor:
                            Theme.of(context).dialogBackgroundColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Text(
                          "🕓 Tus Evaluaciones Pasadas",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: historial.length,
                            separatorBuilder:
                                (_, __) => const Divider(height: 1),
                            itemBuilder: (ctx, idx) {
                              final eval = historial[idx];
                              final String temaActualParaDetalles =
                                  eval['tema']!;
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: colorSecundarioAutoevaluacion
                                      .withOpacity(0.15),
                                  child: Icon(
                                    Icons.school_outlined,
                                    color: colorSecundarioAutoevaluacion,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  temaActualParaDetalles,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Text(
                                  "📅 ${eval['fecha']}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "⭐ ${eval['calificacion']}/10",
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color:
                                            (double.tryParse(
                                                          eval['calificacion'],
                                                        ) ??
                                                        0) <
                                                    6
                                                ? theme.colorScheme.error
                                                : Colors.green[700],
                                      ),
                                    ),
                                    Text(
                                      "${eval['preguntas']} preguntas",
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: theme.textTheme.bodySmall?.color
                                            ?.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  if (!mounted) return;
                                  Navigator.pop(context);

                                  final List<String> idsPreguntas =
                                      eval['preguntas_ids'];
                                  final Map<String, dynamic>
                                  respuestasDeUsuarioHistorial =
                                      eval['respuestas_usuario'];

                                  if (idsPreguntas.isEmpty) {
                                    _mostrarError(
                                      "No hay detalles de preguntas para esta evaluación.",
                                    );
                                    return;
                                  }

                                  final detallesPreguntas =
                                      await obtenerDetallesPreguntas(
                                        idsPreguntas,
                                        temaActualParaDetalles,
                                      );

                                  if (!mounted) return;
                                  _mostrarDialogoDetallesEvaluacion(
                                    context,
                                    temaActualParaDetalles,
                                    detallesPreguntas,
                                    respuestasDeUsuarioHistorial,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "Cerrar",
                              style: GoogleFonts.poppins(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonGenerarConIAEstilizado(
    BuildContext context,
    String temaNombreCompletoParaIA,
  ) {
    final theme = Theme.of(context);
    final claveTemaParaServicioIA = _claveTema(temaNombreCompletoParaIA);

    return Card(
      elevation: 2,
      color: Colors.amber.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.amber.shade800,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  "Opción IA: Nuevas Preguntas",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "Genera un set fresco de preguntas para '$temaNombreCompletoParaIA' usando IA (puede tardar unos segundos).",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.9),
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                "Solicitar a IA",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              onPressed: () async {
                if (user == null) {
                  _mostrarDialogoLogin(
                    "Debes iniciar sesión para usar esta función.",
                  );
                  return;
                }
                setState(() {
                  cargando = true;
                });
                final notificado = await evaluacionService
                    .notificarGeneracionPreguntas(claveTemaParaServicioIA);
                if (!mounted) return;
                setState(() {
                  cargando = false;
                });

                if (notificado) {
                  await showDialog(
                    context: context,
                    builder:
                        (_) => AlertDialog(
                          backgroundColor: theme.cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          title: Text(
                            "✅ Solicitud Enviada",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: Text(
                            "Tu solicitud para generar nuevas preguntas con IA ha sido enviada. El banco de preguntas se actualizará pronto.",
                            style: GoogleFonts.poppins(),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                "Entendido",
                                style: GoogleFonts.poppins(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                  );
                  await cargarTotalesPorTema();
                } else {
                  _mostrarError(
                    "No se pudo enviar la solicitud de generación con IA. Intenta más tarde.",
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _avisoGenerarNuevas() {
    return Column(
      children: [
        const Center(
          child: Text(
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
              if (user == null) {
                _mostrarDialogoLogin("Debes iniciar sesión.");
                return;
              }
              if (temasSeleccionados.length != 1) {
                _mostrarError("Selecciona solo un tema para usar IA.");
                return;
              }
              final temaParaIA = temasSeleccionados.first;

              setState(() {
                cargando = true;
                yaSeNotificoIA = false;
                envioExitoso = false;
              });

              final notificado = await evaluacionService
                  .notificarGeneracionPreguntas(_claveTema(temaParaIA));

              if (!mounted) return;
              setState(() {
                cargando = false;
                yaSeNotificoIA = notificado;
                envioExitoso = notificado;
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

  // DIÁLOGO DE DETALLES DE EVALUACIÓN PASADA (AJUSTADO AL DISEÑO ORIGINAL CON EMOJIS)
  Future<void> _mostrarDialogoDetallesEvaluacion(
    BuildContext context,
    String temaEvaluacion,
    List<Map<String, dynamic>> preguntasConDetalles,
    Map<String, dynamic> respuestasUsuarioHistorial,
  ) async {
    final theme = Theme.of(context);
    await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor:
                Colors.white, // Fondo blanco como en tu diseño original
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              "Revisión: $temaEvaluacion",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            content: SizedBox(
              width: double.maxFinite,
              child:
                  preguntasConDetalles.isEmpty
                      ? Center(
                        child: Text(
                          "No se encontraron detalles para las preguntas.",
                          style: GoogleFonts.poppins(),
                        ),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: preguntasConDetalles.length,
                        itemBuilder: (context, index) {
                          final pData = preguntasConDetalles[index];
                          final String preguntaTexto =
                              pData['pregunta'] ?? 'Pregunta no disponible';
                          final opciones = _convertirOpciones(
                            pData['opciones'],
                          );
                          final String correcta =
                              pData['respuesta_correcta'] ??
                              pData['respuestaCorrecta'] ??
                              '';
                          final String? respuestaUsuario =
                              respuestasUsuarioHistorial[index.toString()];
                          final bool esCorrecta = respuestaUsuario == correcta;

                          return Card(
                            elevation: 1.0, // Elevación sutil
                            margin: const EdgeInsets.only(bottom: 10),
                            color:
                                esCorrecta
                                    ? Colors.green.shade50
                                    : (respuestaUsuario != null &&
                                            respuestaUsuario.isNotEmpty
                                        ? Colors.red.shade50
                                        : Colors.grey.shade200),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Pregunta ${index + 1}:",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: CustomLatexText(
                                      contenido: "🧠 $preguntaTexto",
                                      fontSize: 16,
                                      prepararLatex: prepararLaTeX,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // No mostramos "Opciones:" explícitamente para un look más limpio como el original
                                  ...opciones.entries.map((opcion) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        left: 8.0,
                                        top: 2.0,
                                      ),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: CustomLatexText(
                                          contenido:
                                              "${opcion.key}) ${opcion.value}",
                                          fontSize: 14,
                                          prepararLatex: prepararLaTeX,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  const SizedBox(height: 8),
                                  const Divider(
                                    height: 1,
                                    thickness: 0.5,
                                  ), // Opcional si quieres el divisor
                                  const SizedBox(height: 6),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: CustomLatexText(
                                      contenido:
                                          "✅ Respuesta correcta: $correcta) ${opciones[correcta] ?? ''}",
                                      fontSize: 14,
                                      prepararLatex: prepararLaTeX,
                                      color:
                                          Colors
                                              .green
                                              .shade900, // Color más oscuro para mejor contraste
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: CustomLatexText(
                                      contenido:
                                          "${esCorrecta ? '✅' : (respuestaUsuario != null && respuestaUsuario.isNotEmpty ? '❌' : '📝')} Tu respuesta: ${respuestaUsuario != null && opciones.containsKey(respuestaUsuario) ? '$respuestaUsuario) ${opciones[respuestaUsuario]}' : (respuestaUsuario == null || respuestaUsuario.isEmpty ? 'No respondida' : respuestaUsuario)}",
                                      fontSize: 14,
                                      prepararLatex: prepararLaTeX,
                                      color:
                                          esCorrecta
                                              ? Colors.green.shade900
                                              : Colors.red.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  "Cerrar",
                  style: GoogleFonts.poppins(
                    color: colorPrimarioAutoevaluacion,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preguntasDelTemaActual =
        (temaSeleccionado != null &&
                preguntasPorTema.containsKey(temaSeleccionado))
            ? preguntasPorTema[temaSeleccionado!] ?? []
            : [];

    return Stack(
      children: [
        Scaffold(
          appBar: const CustomAppBar(
            titleText: "Autoevaluación",
            showBack: true,
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.all(
                  constraints.maxWidth > 700 ? 20.0 : 12.0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (preguntasPorTema.isEmpty && !cargando)
                          _buildConfiguracionUI(context),

                        if (cargando)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 50.0),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),

                        if (preguntasPorTema.isNotEmpty &&
                            !cargando &&
                            temaSeleccionado != null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 4.0,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: temaSeleccionado,
                                    items:
                                        preguntasPorTema.keys
                                            .map(
                                              (temaNombre) => DropdownMenuItem(
                                                value: temaNombre,
                                                child: Text(
                                                  temaNombre,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
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
                                    decoration: InputDecoration(
                                      labelText: "Viendo preguntas del tema",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                    ),
                                    dropdownColor: theme.canvasColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Tooltip(
                                  message: "Configurar nueva evaluación",
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.settings_backup_restore_rounded,
                                      size: 28,
                                    ),
                                    onPressed: _volverASeleccion,
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          theme
                                              .colorScheme
                                              .surfaceContainerHighest,
                                      foregroundColor:
                                          theme.colorScheme.primary,
                                      padding: const EdgeInsets.all(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: preguntasDelTemaActual.length,
                            itemBuilder: (context, index) {
                              final pregunta = preguntasDelTemaActual[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: CustomLatexQuestionCard(
                                  numero: index + 1,
                                  pregunta: pregunta["pregunta"],
                                  opciones: _convertirOpciones(
                                    pregunta["opciones"],
                                  ),
                                  seleccionada: respuestasUsuario[index],
                                  onChanged: (value) {
                                    if (!yaCalificado) {
                                      setState(() {
                                        respuestasUsuario[index] = value;
                                      });
                                    }
                                  },
                                  mostrarCorrecta: yaCalificado,
                                  respuestaCorrecta:
                                      pregunta["respuesta_correcta"] ??
                                      pregunta["respuestaCorrecta"],
                                  respuestaUsuario: respuestasUsuario[index],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          if (preguntasDelTemaActual.isNotEmpty)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    yaCalificado
                                        ? colorSecundarioAutoevaluacion
                                        : colorPrimarioAutoevaluacion,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                textStyle: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed:
                                  yaCalificado
                                      ? _volverASeleccion // BOTÓN PRINCIPAL AHORA ES "NUEVA EVALUACIÓN"
                                      : (respuestasUsuario.length ==
                                              preguntasDelTemaActual.length
                                          ? _calificar
                                          : null),
                              child: Text(
                                yaCalificado
                                    ? "Nueva Evaluación"
                                    : "Calificar Evaluación",
                              ),
                            ),

                          // --- BOTÓN ADICIONAL "REINTENTAR EVALUACIÓN ACTUAL" ---
                          if (yaCalificado &&
                              preguntasDelTemaActual.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text("Reintentar Evaluación Actual"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colorPrimarioAutoevaluacion,
                                side: BorderSide(
                                  color: colorPrimarioAutoevaluacion
                                      .withOpacity(0.7),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                textStyle: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  respuestasUsuario.clear();
                                  yaCalificado = false;
                                  puntaje = 0;
                                });
                              },
                            ),
                          ],

                          // --- FIN BOTÓN ADICIONAL ---
                          if (yaCalificado) ...[
                            const SizedBox(height: 24),
                            CustomScoreCard(
                              puntaje: puntaje,
                              total: preguntasDelTemaActual.length,
                            ),
                          ],
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Widgets de Confeti
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
        Align(
          alignment: Alignment.centerLeft,
          child: ConfettiWidget(
            confettiController: _confettiLeftController,
            blastDirection: 0,
            emissionFrequency: 0.05,
            numberOfParticles: 10,
            maxBlastForce: 15,
            minBlastForce: 5,
            gravity: 0.3,
            shouldLoop: false,
            colors: const [Colors.green, Colors.pink, Colors.blue],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: ConfettiWidget(
            confettiController: _confettiRightController,
            blastDirection: 3.14,
            emissionFrequency: 0.05,
            numberOfParticles: 10,
            maxBlastForce: 15,
            minBlastForce: 5,
            gravity: 0.3,
            shouldLoop: false,
            colors: const [Colors.orange, Colors.purple, Colors.yellow],
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: ConfettiWidget(
            confettiController: _confettiBottomController,
            blastDirection: -3.14 / 2,
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
