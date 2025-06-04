import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/services.dart'; // Asumo que aquí está EvaluacionService y NotificationService
import '../widgets/widgets.dart'; // Asumo CustomAppBar, CustomLatexQuestionCard, CustomScoreCard, showCustomDialog
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/utils.dart'; // Asumo que aquí está prepararLaTeX y CustomDialogType
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math'; // Para min() y max() en paginación

// Colores (los usaremos como acentos)
const Color azulSecundario = Color(0xFF1976D2);
const Color moradoPrimario = Color(0xFF7E57C2);
const Color colorBotonPrimario = moradoPrimario;
const Color colorBotonSecundario = azulSecundario;

class AutoevaluationPage extends StatefulWidget {
  const AutoevaluationPage({super.key});

  @override
  State<AutoevaluationPage> createState() => _AutoevaluationPageState();
}

class _AutoevaluationPageState extends State<AutoevaluationPage> {
  final List<String> temasDisponibles = [
    // Estos son los nombres completos para mostrar en UI
    "Funciones algebraicas y trascendentes",
    "Límites de funciones y continuidad",
    "Derivada y optimización",
    "Técnicas de integración",
  ];

  // Mapeo de nombres completos a claves para Firestore (si es diferente o para consistencia)
  final Map<String, String> mapTemaToClave = {
    "Funciones algebraicas y trascendentes": "FnAlg",
    "Límites de funciones y continuidad": "Lim",
    "Derivada y optimización": "Der",
    "Técnicas de integración": "TecInteg",
  };

  // Mapeo de claves a nombres completos (inverso para _nombreTema)
  // Se generará a partir de mapTemaToClave o puedes definirlo como _nombreTema lo hace

  List<String> temasSeleccionados =
      []; // Almacena los nombres completos de los temas seleccionados
  Map<String, List<Map<String, dynamic>>> preguntasPorTema =
      {}; // Clave: Nombre completo del tema
  String?
  temaSeleccionado; // Tema activo (nombre completo) una vez generada la evaluación
  Map<int, String> respuestasUsuario = {};
  bool yaCalificado = false;
  int puntaje = 0;
  bool cargando = false;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final EvaluacionService evaluacionService = EvaluacionService();

  late ConfettiController _confettiController;
  late ConfettiController _confettiLeftController;
  late ConfettiController _confettiRightController;
  late ConfettiController _confettiBottomController;

  final AudioPlayer _audioPlayer = AudioPlayer();
  User? user;
  int cantidadPreguntas = 25;

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

  Map<String, int> totalPreguntasPorTema =
      {}; // Clave: Nombre completo del tema

  //=============== MÉTODO FALTANTE AÑADIDO AQUÍ ===============//
  String _nombreTema(String clave) {
    // Convierte clave Firestore a nombre legible
    // Este es el inverso de mapTemaToClave, o puedes usar una estructura similar
    switch (clave) {
      case 'FnAlg':
        return 'Funciones algebraicas y trascendentes';
      case 'Lim':
        return 'Límites de funciones y continuidad';
      case 'Der':
        return 'Derivada y optimización';
      case 'TecInteg':
        return 'Técnicas de integración';
      // También manejar el caso inverso si recibes el nombre completo y necesitas la clave
      case "Funciones algebraicas y trascendentes":
        return "Funciones algebraicas y trascendentes";
      case "Límites de funciones y continuidad":
        return "Límites de funciones y continuidad";
      case "Derivada y optimización":
        return "Derivada y optimización";
      case "Técnicas de integración":
        return "Técnicas de integración";
      default:
        return clave;
    }
  }

  String _claveTema(String nombreCompleto) {
    // Convierte nombre legible a clave Firestore
    return mapTemaToClave[nombreCompleto] ??
        nombreCompleto; // Fallback a nombreCompleto si no se encuentra
  }

  Future<void> cargarTotalesPorTema() async {
    Map<String, int> conteoLocal = {};
    for (final temaNombreCompleto in temasDisponibles) {
      // Iterar sobre nombres completos
      final claveTema = _claveTema(
        temaNombreCompleto,
      ); // Obtener la clave para Firestore
      try {
        final snapshot =
            await firestore
                .collection('preguntas_por_tema')
                .where(
                  'tema',
                  isEqualTo: claveTema,
                ) // Usar la clave del tema para la consulta
                .count()
                .get();
        conteoLocal[temaNombreCompleto] = snapshot.count ?? 0;
      } catch (e) {
        debugPrint(
          "Error cargando totales para $claveTema ($temaNombreCompleto): $e",
        );
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

    for (String temaNombreCompleto in temasNombresCompletos) {
      final claveTema = _claveTema(
        temaNombreCompleto,
      ); // Usar clave para la consulta
      try {
        final snapshot =
            await firestore
                .collection('preguntas_por_tema')
                .where('tema', isEqualTo: claveTema)
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
                .where('tema', isEqualTo: claveTema) // Usar claveTema
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
          seleccionadas.addAll(restantes.take(faltantes));
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

        // Usar nombre completo como clave para el mapa de UI
        nuevasPreguntasPorTema[temaNombreCompleto] = preguntasMapeadas;

        await firestore.collection('evaluaciones_realizadas').add({
          'uid_usuario': user!.uid,
          'nombre_usuario': await _obtenerNombreDesdeUsuarios(user!.uid),
          'tema': claveTema, // Guardar claveTema en Firestore
          'preguntas_ids': seleccionadas.map((p) => p['id']).toList(),
          'respuestas_usuario': {},
          'calificacion': 0,
          'fecha_realizacion': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint(
          "Error obteniendo preguntas para $claveTema ($temaNombreCompleto): $e",
        );
        _mostrarError(
          "Error al cargar preguntas para el tema '$temaNombreCompleto'. Intenta de nuevo.",
        );
      }
    }

    if (mounted) {
      setState(() {
        preguntasPorTema = nuevasPreguntasPorTema;
        if (nuevasPreguntasPorTema.isNotEmpty) {
          temaSeleccionado =
              nuevasPreguntasPorTema
                  .keys
                  .first; // temaSeleccionado es nombre completo
        }
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
      final claveTema =
          data['tema'] ?? 'Sin tema'; // Esto es la clave, ej: 'FnAlg'
      final temaNombreCompleto = _nombreTema(
        claveTema,
      ); // Convertir a nombre legible

      final calificacionRaw = data['calificacion'] ?? 0;
      final preguntasCount = (data['preguntas_ids'] as List?)?.length ?? 1;
      final calificacionFinal =
          ((calificacionRaw / (preguntasCount > 0 ? preguntasCount : 1)) * 10)
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
        'tema': temaNombreCompleto, // Usar nombre completo para UI
        'clave_tema': claveTema, // Mantener clave por si se necesita
        'calificacion': calificacionFinal.toStringAsFixed(1),
        'fecha': fechaFormateada,
        'preguntas': preguntasCount,
        'respuestas_usuario': data['respuestas_usuario'] ?? {},
        'preguntas_ids': data['preguntas_ids'] ?? [], 'docRef': doc.reference,
      };
    }).toList();
  }

  Future<void> _mostrarError(String mensaje) async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              "Error",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(mensaje, style: GoogleFonts.poppins()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Aceptar",
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _calificar() async {
    if (temaSeleccionado == null) return; // No hay tema activo
    final claveTemaSeleccionado = _claveTema(
      temaSeleccionado!,
    ); // Convertir a clave para Firestore
    final preguntas = preguntasPorTema[temaSeleccionado!] ?? [];

    if (preguntas.isEmpty) return;
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
    String nombre = user?.displayName ?? "Anónimo";
    if (uid != null) {
      final doc = await firestore.collection('usuarios').doc(uid).get();
      if (doc.exists && doc.data()?['Nombre'] != null) {
        nombre = doc['Nombre'];
      }
    }

    final lastEval =
        await firestore
            .collection('evaluaciones_realizadas')
            .where('uid_usuario', isEqualTo: uid)
            .where('tema', isEqualTo: claveTemaSeleccionado) // Usar claveTema
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
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              "✅ Evaluación Guardada",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              "Tus respuestas y calificación han sido guardadas exitosamente.",
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Aceptar",
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
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
    await NotificationService.crearNotificacion(
      uidDestino: user!.uid,
      tipo: 'calificacion',
      titulo: "✅ Evaluación completada",
      contenido:
          "$nombre has terminado una autoevaluación del tema '${_nombreTema(claveTemaSeleccionado)}'.", // Usar nombre legible
      referenciaId: claveTemaSeleccionado,
      tema: claveTemaSeleccionado,
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

  Map<String, String> _convertirOpciones(dynamic rawOpciones) {
    if (rawOpciones is Map) {
      return Map<String, String>.from(rawOpciones);
    } else if (rawOpciones is List) {
      final letras = ['A', 'B', 'C', 'D', 'E'];
      return {
        for (int i = 0; i < rawOpciones.length && i < letras.length; i++)
          letras[i]: rawOpciones[i].toString(),
      };
    } else {
      return {};
    }
  }

  void _volverASeleccion() {
    setState(() {
      preguntasPorTema.clear();
      respuestasUsuario.clear();
      yaCalificado = false;
      puntaje = 0;
      temasSeleccionados.clear();
      temaSeleccionado = null;
    });
  }

  Widget _buildConfiguracionUI(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(
        bottom: 20,
        left: 4,
        right: 4,
      ), // Margen ligero para no pegar a bordes
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.cardColor, // Usar color de tarjeta del tema
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
              dropdownColor:
                  theme.canvasColor, // Color de fondo del desplegable
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
                      selectedColor: colorBotonPrimario,
                      checkmarkColor: theme.colorScheme.onPrimary,
                      backgroundColor: theme.chipTheme.backgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color:
                              seleccionado
                                  ? colorBotonPrimario
                                  : theme.dividerColor,
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorBotonPrimario,
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
            if (temasSeleccionados.length == 1)
              _buildBotonGenerarConIAEstilizado(
                context,
                temasSeleccionados.first,
              ),
            const SizedBox(height: 16),
            TextButton.icon(
              // Cambiado a TextButton para un look más secundario
              icon: const Icon(Icons.history_rounded),
              label: const Text("Ver Resultados Pasados"),
              style: TextButton.styleFrom(
                foregroundColor:
                    theme.colorScheme.primary, // Usar color primario del tema
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
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (ctx, idx) {
                              final eval = historial[idx];
                              return ListTile(
                                onTap: () async {
                                  if (!mounted) return;
                                  Navigator.pop(
                                    context,
                                  ); // Cierra el diálogo de historial
                                  // Lógica para cargar y mostrar la revisión de esta evaluación
                                  // Esto podría implicar cargar las preguntas y respuestas
                                  // y establecer un estado de "revisión" en la UI.
                                  _mostrarError(
                                    "Funcionalidad de revisar evaluación pasada no implementada completamente.",
                                  );
                                },
                                leading: CircleAvatar(
                                  backgroundColor: colorBotonSecundario
                                      .withOpacity(0.15),
                                  child: Icon(
                                    Icons.school_outlined,
                                    color: colorBotonSecundario,
                                  ),
                                ),
                                title: Text(
                                  eval['tema'] ?? "Tema desconocido",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
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
                                        fontSize: 15,
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
                                        fontSize: 11,
                                        color: theme.textTheme.bodySmall?.color
                                            ?.withOpacity(0.7),
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
    // Usar _claveTema para obtener la clave que necesita tu servicio de IA
    final claveTemaParaIA = _claveTema(temaNombreCompletoParaIA);

    return Card(
      elevation: 2,
      color: theme.colorScheme.secondaryContainer.withOpacity(0.7),
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
                  color: theme.colorScheme.onSecondaryContainer,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  "Opción IA: Nuevas Preguntas",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSecondaryContainer,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "Genera un set fresco de preguntas para '${_nombreTema(claveTemaParaIA)}' usando IA (puede tardar unos segundos).", // Mostrar nombre legible
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.9),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
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
                setState(() {
                  cargando = true;
                });
                final notificado = await evaluacionService
                    .notificarGeneracionPreguntas(
                      claveTemaParaIA,
                    ); // Enviar clave a servicio
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // temaSeleccionado ahora guarda el nombre completo, ej: "Funciones algebraicas..."
    final preguntasDelTemaActual =
        (temaSeleccionado != null)
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
                ), // Padding ajustado
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 800,
                    ), // Ancho máximo un poco reducido
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (preguntasPorTema.isEmpty && !cargando)
                          _buildConfiguracionUI(context),

                        if (cargando)
                          const Center(
                            heightFactor: 5,
                            child: CircularProgressIndicator(),
                          ),

                        if (preguntasPorTema.isNotEmpty &&
                            !cargando &&
                            temaSeleccionado != null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: temaSeleccionado,
                                    items:
                                        preguntasPorTema.keys
                                            .map(
                                              (temaNombreCompleto) =>
                                                  DropdownMenuItem(
                                                    value: temaNombreCompleto,
                                                    child: Text(
                                                      _nombreTema(
                                                        temaNombreCompleto,
                                                      ),
                                                    ),
                                                  ),
                                            )
                                            .toList(),
                                    onChanged: (nuevoTemaNombreCompleto) {
                                      setState(() {
                                        temaSeleccionado =
                                            nuevoTemaNombreCompleto;
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
                                      backgroundColor: theme
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withOpacity(0.8),
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
                                    setState(() {
                                      respuestasUsuario[index] = value;
                                    });
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
                                        ? colorBotonSecundario
                                        : colorBotonPrimario,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ), // Botón más alto
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
                                      ? () {
                                        setState(() {
                                          _volverASeleccion();
                                        });
                                      }
                                      : _calificar,
                              child: Text(
                                yaCalificado
                                    ? "Nueva Evaluación"
                                    : "Calificar Evaluación",
                              ),
                            ),
                          if (yaCalificado) ...[
                            const SizedBox(height: 24),
                            CustomScoreCard(
                              puntaje: puntaje,
                              total: preguntasDelTemaActual.length,
                            ),
                          ],
                          const SizedBox(height: 20), // Espacio al final
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
