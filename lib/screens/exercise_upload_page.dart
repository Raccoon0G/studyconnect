import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:study_connect/services/services.dart';
import 'package:study_connect/utils/utils.dart';
import 'package:study_connect/widgets/exercise_carousel.dart';

import '../widgets/widgets.dart';

class ExerciseUploadPage extends StatefulWidget {
  const ExerciseUploadPage({super.key});

  @override
  State<ExerciseUploadPage> createState() => _ExerciseUploadPageState();
}

class _ExerciseUploadPageState extends State<ExerciseUploadPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<Map<String, dynamic>> _stepsControllers = [
    {
      'latex': TextEditingController(),
      'desc': TextEditingController(),
      'locked': false,
    },
  ];
  Map<int, bool> _showKeyboard = {};
  List<String> _recentSymbols = [];

  String? _temaSeleccionado;

  final Map<String, String> temasDisponibles = {
    'FnAlg': 'Funciones algebraicas y trascendentes',
    'Lim': 'Límites de funciones y continuidad',
    'Der': 'Derivada y optimización',
    'TecInteg': 'Técnicas de integración',
  };

  bool _subiendo = false;
  bool _exitoAlSubir = false;

  String? _ejercicioId; // Si es edición o nueva versión
  String? _modo; // 'editar', 'nueva_version' o null
  String? _versionActualId;
  bool _cargando = true;

  Future<String> generarNuevoIdSeguro(
    CollectionReference ejerciciosRef,
    String tema,
  ) async {
    final docs = await ejerciciosRef.get();
    final idsExistentes = docs.docs.map((d) => d.id).toSet();

    int i = 1;
    String nuevoId;

    do {
      nuevoId = '${tema}_${i.toString().padLeft(2, '0')}';
      i++;
    } while (idsExistentes.contains(nuevoId));

    return nuevoId;
  }

  Future<void> reproducirSonidoExito() async {
    final player = AudioPlayer();
    await player.play(AssetSource('audio/successed.mp3'));
  }

  Future<void> reproducirSonidoError() async {
    final player = AudioPlayer();
    await player.play(AssetSource('audio/error.mp3'));
  }

  String obtenerMensajeLogroEjercicio(int total) {
    if (total == 1) {
      return "¡Subiste tu primer ejercicio! 🥳 Bienvenido a la comunidad de creadores.";
    } else if (total == 5) {
      return "¡5 ejercicios subidos! 🥈 Logro: Colaborador Activo. ¡Sigue así!";
    } else if (total == 10) {
      return "¡10 ejercicios! 🥇 Logro: Colaborador Avanzado. ¡Tu esfuerzo está marcando la diferencia!";
    } else if (total == 20) {
      return "¡20 ejercicios! 🏆 Logro: Master Contributor. Eres un ejemplo para todos.";
    } else if (total % 10 == 0) {
      return "¡$total ejercicios! ⭐ ¡Nivel leyenda en la comunidad! Sigue sumando éxitos.";
    } else if (total >= 3 && total < 5) {
      return "¡Vas por buen camino! Ya llevas $total ejercicios.";
    } else if (total > 20 && total % 5 == 0) {
      return "¡Wow! $total ejercicios subidos. Eres inspiración total. 👏";
    } else {
      // Mensaje random motivacional para otros casos
      final frases = [
        "¡Genial! Cada ejercicio cuenta.",
        "¡Buen aporte! Sigamos aprendiendo juntos.",
        "¡Suma puntos para el ranking con cada aporte!",
        "¡Estás ayudando a muchos estudiantes!",
        "¡No te detengas! Cada vez eres mejor.",
        "¡Buen trabajo! Sigue compartiendo tu conocimiento.",
        "¡Tu aportación ayuda a toda la comunidad!",
        "¡Así se hace! Cada ejercicio cuenta.",
        "¡Genial! ¡Otro paso hacia el top del ranking!",
        "¡No te detengas! 💪",
        "¡Eres parte clave de la comunidad Study Connect!",
      ];
      return frases[DateTime.now().millisecondsSinceEpoch % frases.length];
    }
  }

  Future<void> _subirEjercicioAFirestore() async {
    if (_subiendo) return;

    final titulo = _titleController.text.trim();
    final descripcion = _descriptionController.text.trim();

    if (_temaSeleccionado == null || _temaSeleccionado!.isEmpty) {
      await showCustomDialog(
        context: context,
        titulo: 'Tema no seleccionado',
        mensaje: 'Debes seleccionar un tema antes de subir el ejercicio.',
        tipo: CustomDialogType.warning,
      );
      return;
    }

    if (titulo.isEmpty || descripcion.isEmpty) {
      await showCustomDialog(
        context: context,
        titulo: 'Campos vacíos',
        mensaje: 'Debes completar el título y la descripción.',
        tipo: CustomDialogType.warning,
      );
      return;
    }

    setState(() => _subiendo = true);

    final firestore = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;
    final now = DateTime.now();

    final temasSubcoleccion = {
      'Der': 'EjerDer',
      'FnAlg': 'EjerFnAlg',
      'Lim': 'EjerLim',
      'TecInteg': 'EjerTecInteg',
    };

    final subcoleccion =
        temasSubcoleccion[_temaSeleccionado] ?? 'EjerDesconocido';
    final ejerciciosRef = firestore
        .collection('calculo')
        .doc(_temaSeleccionado)
        .collection(subcoleccion);

    try {
      final pasosLimpios =
          _stepsControllers
              .map((step) => prepararLaTeXSeguro(step['latex'].text))
              .where((p) => p.isNotEmpty)
              .toList();

      final descripciones =
          _stepsControllers
              .map((step) => step['desc'].text.trim())
              .where((d) => d.isNotEmpty)
              .toList();

      // Determina si es editar, nueva versión o nuevo
      if (_modo == 'editar' && _ejercicioId != null) {
        // --- Editar ejercicio existente y versión actual ---
        final ejerRef = ejerciciosRef.doc(_ejercicioId);
        await ejerRef.update({
          'Titulo': titulo,
          'DesEjercicio': descripcion,
          'FechMod': now,
        });

        // Actualiza la versión actual
        await ejerRef.collection('Versiones').doc(_versionActualId).update({
          'Titulo': 'Versión editada',
          'Descripcion': descripcion,
          'Fecha': now,
          'PasosEjer': pasosLimpios,
          'DescPasos': descripciones,
        });

        await showFeedbackDialogAndSnackbar(
          context: context,
          titulo: '¡Editado!',
          mensaje: 'El ejercicio fue editado exitosamente.',
          tipo: CustomDialogType.success,
          snackbarMessage: 'Ejercicio editado',
          snackbarSuccess: true,
        );
        Navigator.pushReplacementNamed(
          context,
          '/exercise_view',
          arguments: {'tema': _temaSeleccionado!, 'ejercicioId': _ejercicioId!},
        );
      } else if (_modo == 'nueva_version' && _ejercicioId != null) {
        // --- Crear nueva versión y actualizar campo versionActual ---
        final ejerRef = ejerciciosRef.doc(_ejercicioId);
        final versiones = await ejerRef.collection('Versiones').get();
        final versionNum = versiones.docs.length + 1;
        final nuevaVersionId =
            'Version_${versionNum.toString().padLeft(2, '0')}';

        await ejerRef.collection('Versiones').doc(nuevaVersionId).set({
          'Titulo': 'Versión $versionNum',
          'Descripcion': descripcion,
          'Fecha': now,
          'AutorId': user?.uid ?? '',
          'PasosEjer': pasosLimpios,
          'DescPasos': descripciones,
        });

        await ejerRef.update({'FechMod': now, 'versionActual': nuevaVersionId});

        await showFeedbackDialogAndSnackbar(
          context: context,
          titulo: '¡Nueva versión!',
          mensaje: 'Nueva versión agregada exitosamente.',
          tipo: CustomDialogType.success,
          snackbarMessage: 'Nueva versión guardada',
          snackbarSuccess: true,
        );
        Navigator.pushReplacementNamed(
          context,
          '/exercise_view',
          arguments: {'tema': _temaSeleccionado!, 'ejercicioId': _ejercicioId!},
        );
      } else {
        // --- Crear nuevo ejercicio (original) ---
        final ejercicioId = await generarNuevoIdSeguro(
          ejerciciosRef,
          _temaSeleccionado!,
        );

        final versionId = 'Version_01';

        String autorNombre = '';
        if (user != null) {
          final userDoc =
              await firestore.collection('usuarios').doc(user.uid).get();
          autorNombre = userDoc.data()?['Nombre'] ?? '';
        }

        final ejerRef = ejerciciosRef.doc(ejercicioId);

        await ejerRef.set({
          'Titulo': titulo,
          'DesEjercicio': descripcion,
          'Autor': autorNombre,
          'AutorId': user?.uid ?? '',
          'CalPromedio': 0.0,
          'FechCreacion': now,
          'FechMod': now,
          'versionActual': versionId,
        });

        await ejerRef.collection('Versiones').doc(versionId).set({
          'Titulo': 'Versión 1',
          'Descripcion': descripcion,
          'Fecha': now,
          'AutorId': user?.uid ?? '',
          'PasosEjer': pasosLimpios,
          'DescPasos': descripciones,
        });

        int totalSubidos = 1;
        if (user != null) {
          final userRef = firestore.collection('usuarios').doc(user.uid);
          await firestore.runTransaction((transaction) async {
            final snapshot = await transaction.get(userRef);
            final actual = snapshot.data()?['EjerSubidos'] ?? 0;
            totalSubidos = actual + 1;
            transaction.update(userRef, {'EjerSubidos': totalSubidos});
          });
        }

        await actualizarTodoCalculoDeUsuario(uid: user!.uid);

        final mensajeGamificacion = obtenerMensajeLogroEjercicio(totalSubidos);
        if (user != null) {
          await NotificationService.crearNotificacion(
            uidDestino: user.uid,
            tipo: 'ejercicio',
            titulo: '¡Ejercicio subido correctamente!',
            contenido: mensajeGamificacion,
            referenciaId: ejercicioId,
            tema: _temaSeleccionado,
            uidEmisor: user.uid,
            nombreEmisor: autorNombre.isNotEmpty ? autorNombre : 'Tú',
          );
        }

        await LocalNotificationService.show(
          title: 'Ejercicio subido',
          body: '¡Tu ejercicio fue guardado exitosamente!',
        );

        await reproducirSonidoExito();

        await showFeedbackDialogAndSnackbar(
          context: context,
          titulo: '¡Éxito!',
          mensaje: 'El ejercicio se subió correctamente a la plataforma.',
          tipo: CustomDialogType.success,
          snackbarMessage: 'Ejercicio guardado con éxito',
          snackbarSuccess: true,
        );
      }

      setState(() {
        _exitoAlSubir = true;
        _subiendo = false;
      });

      // Limpiar campos si es nuevo (solo si quieres)
      if (_modo == null) {
        setState(() {
          _temaSeleccionado = null;
          _titleController.clear();
          _descriptionController.clear();
          _stepsControllers.clear();
          _stepsControllers.add({
            'latex': TextEditingController(),
            'desc': TextEditingController(),
            'locked': false,
          });
          _showKeyboard.clear();
          _recentSymbols.clear();
          _exitoAlSubir = false;
          _subiendo = false;
        });
      }
    } catch (e) {
      await reproducirSonidoError();
      setState(() => _subiendo = false);

      await showFeedbackDialogAndSnackbar(
        context: context,
        titulo: 'Error al subir ejercicio',
        mensaje: e.toString(),
        tipo: CustomDialogType.error,
        snackbarMessage: '❌ Hubo un error al subir el ejercicio.',
        snackbarSuccess: false,
      );
    }
  }

  void _addStep(int index) {
    final current = _stepsControllers[index];
    if (current['latex'].text.trim().isEmpty &&
        current['desc'].text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa el paso actual antes de agregar otro.'),
        ),
      );
      return;
    }
    setState(() {
      _stepsControllers[index]['locked'] = true;
      _stepsControllers.add({
        'latex': TextEditingController(),
        'desc': TextEditingController(),
        'locked': false,
      });
    });
  }

  void _removeStep(int index) {
    if (_stepsControllers.length > 1) {
      setState(() {
        _stepsControllers.removeAt(index);
      });
    }
  }

  void _unlockStep(int index) {
    setState(() {
      _stepsControllers[index]['locked'] = false;
    });
  }

  void _insertLatexSymbol(int stepIndex, String symbol) {
    final controller =
        _stepsControllers[stepIndex]['latex'] as TextEditingController;
    final oldText = controller.text;
    final selection = controller.selection;
    final newText = oldText.replaceRange(
      selection.start,
      selection.end,
      symbol,
    );
    controller.text = newText;
    controller.selection = TextSelection.collapsed(
      offset: selection.start + symbol.length,
    );

    setState(() {
      _recentSymbols.remove(symbol);
      _recentSymbols.insert(0, symbol);
      if (_recentSymbols.length > 8) {
        _recentSymbols = _recentSymbols.sublist(
          0,
          8,
        ); // máximo 8 símbolos recientes
      }
    });
  }

  Widget _latexKeyboard(int stepIndex) {
    Widget buildGroup(String label, List<String> items) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                items.map((symbol) {
                  return ElevatedButton(
                    onPressed: () => _insertLatexSymbol(stepIndex, symbol),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade400,
                      foregroundColor: Colors.blue.shade100,
                      padding: const EdgeInsets.all(10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),

                      side: BorderSide(color: Colors.blue.shade600, width: 1),
                      elevation: 2, //sombra para que resalten
                    ),
                    child: Math.tex(
                      symbol,
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  );
                }).toList(),
          ),
        ],
      );
    }

    final funciones = [
      'f(x) =',
      'x',
      'y',
      '\\frac{x}{y}',
      'a^2',
      'b^n',
      '\\sqrt{x}',
      '\\sqrt[3]{x}',
      '\\left|x\\right|',
      '\\log(x)',
      '\\ln(x)',
      '\\exp(x)',
      '\\sin',
      '\\cos',
      '\\tan',
      '\\sec(x)',
      '\\csc(x)',
      '\\cot(x)',
      '\\arcsin(x)',
      '\\arccos(x)',
      '\\arctan(x)',
      '\\left(x + y\\right)^2',
      '\\left(x - y\\right)^2',
      '\\left(x + a\\right)^n',
      'a\\cdot x + b',
    ];
    final limites = [
      '\\lim_{x \\to a}',
      '\\lim_{x \\to \\infty}',
      '\\lim_{x \\to 0^+}',
      '\\lim_{x \\to 0^-}',
      '\\to',
      '\\infty',
      '\\neq',
      '\\leq',
      '\\geq',
      '\\approx',
      '\\delta',
      '\\epsilon',
      '\\forall',
      '\\exists',
      '\\text{indeterminado}',
      '\\text{continuo}',
      '\\text{discontinuidad}',
      '\\left|x - a\\right| < \\delta',
      '\\left|f(x) - L\\right| < \\epsilon',
      '\\lim_{h \\to 0}',
      '\\lim_{x \\to c^-}',
      '\\lim_{x \\to c^+}',
      '\\lim_{x \\to c} f(x)',
      '\\text{si } \\delta > 0',
      '\\text{y } \\epsilon > 0',
    ];
    final derivadas = [
      '\\frac{dy}{dx}',
      "f'(x)",
      "f''(x)",
      "f'''(x)",
      '\\max',
      '\\min',
      '\\nabla',
      '\\partial',
      '\\frac{\\partial}{\\partial x}',
      'f\'(x)',
      '\\frac{dy}{dx}',
      '\\frac{d^2y}{dx^2}',
      '\\frac{d}{dx}',
      '\\nabla f',
      '\\partial f / \\partial x',
      '\\frac{\\partial^2 f}{\\partial x^2}',
      '\\text{máx}',
      '\\text{mín}',
      '\\text{críticos}',
      '\\text{pendiente}',
      '\\text{tangente}',
      '\\text{inflexión}',
      '\\text{creciente}',
      '\\text{decreciente}',
      '\\text{concavidad}',
      '\\left(\\frac{d}{dx}\\right)^n',
      '\\frac{d}{dt}',
      '\\text{regla del producto}',
      '\\text{regla del cociente}',
      '\\text{regla de la cadena}',
      '\\frac{du}{dx} \\cdot \\frac{dv}{du}',
      '\\text{donde } f\'(x) = 0',
    ];
    final integrales = [
      '\\int',
      '\\int_{a}^{b}',
      '\\int x\\,dx',
      '\\int x^n\\,dx',
      '\\int e^x\\,dx',
      '\\int \\frac{1}{x}\\,dx',
      '\\int \\sin x\\,dx',
      '\\int \\cos x\\,dx',
      '\\int \\tan x\\,dx',
      '\\int \\sec^2 x\\,dx',
      '\\int u dv',
      '\\text{partes}',
      '\\text{por sustitución}',
      '\\text{trigonométrica}',
      '\\sum_{n=1}^{\\infty}',
      '\\prod_{i=1}^{n}',
      '\\int \\sqrt{x}\\,dx',
      '\\int x^{-1}\\,dx',
      '\\frac{1}{b-a} \\int_{a}^{b}',
      '\\text{área bajo la curva}',
      '\\text{volumen}',
      '\\text{longitud de arco}',
      '\\text{cambio de variable}',
      '\\int_{-a}^{a} f(x) dx',
    ];

    // Construimos la lista dinámica de widgets
    List<Widget> groups = [];

    if (_recentSymbols.isNotEmpty) {
      groups.add(buildGroup('Recientes', _recentSymbols));
      groups.add(const SizedBox(height: 10));
    }

    groups.addAll([
      buildGroup('Funciones algebraicas y trascendentales', funciones),
      const SizedBox(height: 10),
      buildGroup('Límites de funciones y continuidad', limites),
      const SizedBox(height: 10),
      buildGroup('Derivada y optimización', derivadas),
      const SizedBox(height: 10),
      buildGroup('Técnicas de integración', integrales),
    ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groups,
    );
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void initState() {
    super.initState();
    _leerArgumentosYPreparar();
  }

  Future<void> _cargarDatosEjercicio() async {
    if (_ejercicioId == null || _temaSeleccionado == null) return;
    final temasSubcoleccion = {
      'Der': 'EjerDer',
      'FnAlg': 'EjerFnAlg',
      'Lim': 'EjerLim',
      'TecInteg': 'EjerTecInteg',
    };
    final subcoleccion =
        temasSubcoleccion[_temaSeleccionado!] ?? 'EjerDesconocido';
    final ejerRef = FirebaseFirestore.instance
        .collection('calculo')
        .doc(_temaSeleccionado)
        .collection(subcoleccion)
        .doc(_ejercicioId);

    final doc = await ejerRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    _titleController.text = data['Titulo'] ?? '';
    _descriptionController.text = data['DesEjercicio'] ?? '';

    // Obtener la versión actual
    final versionId = _versionActualId ?? data['versionActual'] ?? 'Version_01';
    _versionActualId = versionId;

    final versionDoc =
        await ejerRef.collection('Versiones').doc(versionId).get();

    final pasos = List<String>.from(versionDoc['PasosEjer'] ?? []);
    final descripciones = List<String>.from(versionDoc['DescPasos'] ?? []);

    // Cargar en _stepsControllers
    _stepsControllers.clear();
    for (int i = 0; i < pasos.length; i++) {
      _stepsControllers.add({
        'latex': TextEditingController(text: pasos[i]),
        'desc': TextEditingController(
          text: i < descripciones.length ? descripciones[i] : '',
        ),
        'locked': false,
      });
    }
    if (_stepsControllers.isEmpty) {
      _stepsControllers.add({
        'latex': TextEditingController(),
        'desc': TextEditingController(),
        'locked': false,
      });
    }
  }

  Future<void> _leerArgumentosYPreparar() async {
    // Esperar a que el contexto esté listo
    await Future.delayed(Duration.zero);

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      _modo = args['modo'] as String?;
      _ejercicioId = args['ejercicioId'] as String?;
      _temaSeleccionado = args['tema'] as String?;
      _versionActualId = args['versionId'] as String?;

      if (_modo == 'editar' || _modo == 'nueva_version') {
        await _cargarDatosEjercicio();
      }
    }
    setState(() {
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final int activeStepIndex = _stepsControllers.lastIndexWhere(
      (step) => step['locked'] == false,
    );

    return Scaffold(
      appBar: const CustomAppBar(showBack: true),

      // ===== CAMBIO: El backgroundColor lo quitamos, y aquí va el gradiente:
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF036799), Color(0xFF048DD2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Si la pantalla es grande (laptop o más), usa Row
                    if (constraints.maxWidth > 850) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- COLUMNA IZQUIERDA (CON LA SOLUCIÓN FLEXIBLE) ---
                          Container(
                            width: 340,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF055B84),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tema :',
                                  style: TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: DropdownButtonFormField<String>(
                                    value: _temaSeleccionado,
                                    isExpanded: true,
                                    hint: const Text('Selecciona un tema'),
                                    items:
                                        temasDisponibles.entries.map((entry) {
                                          return DropdownMenuItem<String>(
                                            value: entry.key,
                                            child: Text(
                                              entry.value,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _temaSeleccionado = value;
                                      });
                                    },
                                    decoration: const InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_modo == 'editar' &&
                                    _versionActualId != null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 12,
                                      bottom: 4,
                                    ), //Ajuste de padding
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Editando la versión: $_versionActualId',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (_modo == 'nueva_version' &&
                                    _ejercicioId != null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 12,
                                      bottom: 4,
                                    ), //Ajuste de padding
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.lightBlue.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Agregando nueva versión para: $_ejercicioId',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Título',
                                  style: TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _titleController,
                                  decoration: const InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Vista previa (Título):',
                                  style: TextStyle(color: Colors.white),
                                ),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Builder(
                                    builder: (_) {
                                      final raw = _titleController.text;
                                      final isPlain =
                                          raw.trim().isNotEmpty &&
                                          !RegExp(
                                            r'[\\\^\_\{\}]',
                                          ).hasMatch(raw);

                                      if (raw.trim().isEmpty) {
                                        return Text(
                                          'Escribe un título',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey.shade600,
                                          ),
                                        );
                                      } else if (isPlain) {
                                        return Text(
                                          raw,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        );
                                      } else {
                                        return SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: CustomLatexText(
                                            contenido: raw,
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Descripción',
                                  style: TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _descriptionController,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.all(10),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Vista previa (Descripción):',
                                  style: TextStyle(color: Colors.white),
                                ),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _descriptionController.text.isEmpty
                                        ? 'Escribe una descripción'
                                        : dividirDescripcionEnLineas(
                                          _descriptionController.text,
                                        ),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // --- CAMBIO PRINCIPAL AQUÍ ---
                                // Se envuelve en Flexible para que se encoja si no hay espacio
                                Flexible(
                                  child: Center(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: SizedBox(
                                        width: double.infinity,
                                        // Se elimina la altura fija para permitir que sea flexible
                                        child: AspectRatio(
                                          aspectRatio: 4 / 3,
                                          child: Container(
                                            // Se añade una restricción de altura máxima para que no crezca indefinidamente
                                            constraints: const BoxConstraints(
                                              maxHeight: 244,
                                            ),
                                            color: Colors.white10,
                                            child: const ExerciseCarousel(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 20),

                          // --- COLUMNA DERECHA (SIN CAMBIOS) ---
                          // Ahora funcionará correctamente porque la columna izquierda no se desborda
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ListView.builder(
                                itemCount: _stepsControllers.length,
                                itemBuilder: (context, index) {
                                  final step = _stepsControllers[index];
                                  final locked = step['locked'] as bool;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 36),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Paso ${index + 1}',
                                              style: GoogleFonts.ebGaramond(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.black,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                if (!locked &&
                                                    index ==
                                                        activeStepIndex) ...[
                                                  if (index > 0)
                                                    TextButton.icon(
                                                      onPressed:
                                                          () => _removeStep(
                                                            index,
                                                          ),
                                                      icon: const Icon(
                                                        Icons.remove_circle,
                                                        color: Colors.red,
                                                        size: 28,
                                                      ),
                                                      label: const Text(
                                                        "Eliminar paso",
                                                      ),
                                                      style:
                                                          TextButton.styleFrom(
                                                            foregroundColor:
                                                                Colors.red,
                                                          ),
                                                    ),
                                                  TextButton.icon(
                                                    onPressed:
                                                        () => _addStep(index),
                                                    icon: const Icon(
                                                      Icons.add_circle,
                                                      color: Colors.green,
                                                      size: 28,
                                                    ),
                                                    label: const Text(
                                                      "Agregar paso",
                                                    ),
                                                    style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          Colors.green,
                                                    ),
                                                  ),
                                                ],
                                                if (locked)
                                                  TextButton.icon(
                                                    onPressed:
                                                        () =>
                                                            _unlockStep(index),
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      color: Colors.orange,
                                                      size: 26,
                                                    ),
                                                    label: const Text(
                                                      "Modificar paso",
                                                    ),
                                                    style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          Colors.orange,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Descripción del paso:',
                                          style: GoogleFonts.roboto(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        TextField(
                                          controller: step['desc'],
                                          maxLines: 2,
                                          readOnly: locked,
                                          textAlign: TextAlign.justify,
                                          decoration: InputDecoration(
                                            hintText:
                                                'Describe brevemente qué se hace en este paso',
                                            border: const OutlineInputBorder(),
                                            filled: locked,
                                            fillColor:
                                                locked
                                                    ? Colors.grey.shade300
                                                    : null,
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        Text(
                                          'Expresión LaTeX:',
                                          style: GoogleFonts.roboto(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        TextField(
                                          controller: step['latex'],
                                          readOnly: locked,
                                          textAlign: TextAlign.left,
                                          decoration: InputDecoration(
                                            hintText:
                                                r'Escribe aquí usando LaTeX, por ejemplo: x^2 + 1 = 0',
                                            border: const OutlineInputBorder(),
                                            filled: locked,
                                            fillColor:
                                                locked
                                                    ? Colors.grey.shade300
                                                    : null,
                                          ),
                                          onChanged: (_) => setState(() {}),
                                        ),
                                        if (!locked) ...[
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: TextButton.icon(
                                              onPressed: () {
                                                setState(() {
                                                  _showKeyboard[index] =
                                                      !(_showKeyboard[index] ??
                                                          false);
                                                });
                                              },
                                              icon: Icon(
                                                _showKeyboard[index] == true
                                                    ? Icons.keyboard_hide
                                                    : Icons.keyboard,
                                                color: Colors.blue,
                                              ),
                                              label: Text(
                                                _showKeyboard[index] == true
                                                    ? 'Ocultar calculadora'
                                                    : 'Mostrar calculadora',
                                                style: const TextStyle(
                                                  color: Colors.blue,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (_showKeyboard[index] == true)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 12,
                                              ),
                                              child: _latexKeyboard(index),
                                            ),
                                        ],
                                        const SizedBox(height: 10),
                                        Text(
                                          'Vista previa:',
                                          style: GoogleFonts.ebGaramond(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.black,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        Container(
                                          width: double.infinity,
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.05,
                                                ),
                                                blurRadius: 6,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                            border: Border.all(
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Builder(
                                            builder: (context) {
                                              final rawInput =
                                                  step['latex'].text;
                                              final isPlainText =
                                                  rawInput.trim().isNotEmpty &&
                                                  !RegExp(
                                                    r'[\\\^\_\{\}]',
                                                  ).hasMatch(rawInput);

                                              if (rawInput.trim().isEmpty) {
                                                return Text(
                                                  'Escribe una expresión para verla aquí',
                                                  style: TextStyle(
                                                    fontStyle: FontStyle.italic,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                );
                                              } else if (isPlainText) {
                                                return Text(
                                                  rawInput,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.black87,
                                                    height: 1.4,
                                                  ),
                                                );
                                              } else {
                                                return SingleChildScrollView(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  child: CustomLatexText(
                                                    contenido: rawInput,
                                                    fontSize: 20,
                                                    color: Colors.black87,
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Si es pantalla chica (tablet/móvil), acomoda vertical
                      return ListView(
                        children: [
                          //TODO: Hacer que el renderizado de la descripcion se haga mas grande conforme al texto
                          Container(
                            width: 340,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF055B84),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tema :',
                                  style: TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: DropdownButtonFormField<String>(
                                    value: _temaSeleccionado,
                                    isExpanded: true,
                                    hint: const Text('Selecciona un tema'),
                                    items:
                                        temasDisponibles.entries.map((entry) {
                                          return DropdownMenuItem<String>(
                                            value: entry.key,
                                            child: Text(
                                              entry.value,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _temaSeleccionado = value;
                                      });
                                    },
                                    decoration: const InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_modo == 'editar' &&
                                    _versionActualId != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Editando la versión: $_versionActualId',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (_modo == 'nueva_version' &&
                                    _ejercicioId != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.lightBlue.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Agregando nueva versión para: $_ejercicioId',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),

                                const Text(
                                  'Título',
                                  style: TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _titleController,
                                  decoration: const InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Vista previa (Título):',
                                  style: TextStyle(color: Colors.white),
                                ),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Builder(
                                    builder: (_) {
                                      final raw = _titleController.text;
                                      final isPlain =
                                          raw.trim().isNotEmpty &&
                                          !RegExp(
                                            r'[\\\^\_\{\}]',
                                          ).hasMatch(raw);

                                      if (raw.trim().isEmpty) {
                                        return Text(
                                          'Escribe un título',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey.shade600,
                                          ),
                                        );
                                      } else if (isPlain) {
                                        return Text(
                                          raw,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        );
                                      } else {
                                        return SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: CustomLatexText(
                                            contenido: raw,
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Descripción',
                                  style: TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _descriptionController,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.all(10),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Vista previa (Descripción):',
                                  style: TextStyle(color: Colors.white),
                                ),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _descriptionController.text.isEmpty
                                        ? 'Escribe una descripción '
                                        : dividirDescripcionEnLineas(
                                          _descriptionController.text,
                                        ),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Center(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 300,
                                      child: AspectRatio(
                                        aspectRatio: 4 / 3,
                                        child: Container(
                                          color: Colors.white10,
                                          child: const ExerciseCarousel(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _stepsControllers.length,
                              itemBuilder: (context, index) {
                                final step = _stepsControllers[index];
                                final locked = step['locked'] as bool;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 36),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Paso ${index + 1}',
                                            style: GoogleFonts.ebGaramond(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.black,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              if (!locked &&
                                                  index == activeStepIndex) ...[
                                                if (index > 0)
                                                  TextButton.icon(
                                                    onPressed:
                                                        () =>
                                                            _removeStep(index),
                                                    icon: const Icon(
                                                      Icons.remove_circle,
                                                      color: Colors.red,
                                                      size: 28,
                                                    ),
                                                    label: const Text(
                                                      "Eliminar paso",
                                                    ),
                                                    style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          Colors.red,
                                                    ),
                                                  ),
                                                TextButton.icon(
                                                  onPressed:
                                                      () => _addStep(index),
                                                  icon: const Icon(
                                                    Icons.add_circle,
                                                    color: Colors.green,
                                                    size: 28,
                                                  ),
                                                  label: const Text(
                                                    "Agregar paso",
                                                  ),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.green,
                                                  ),
                                                ),
                                              ],
                                              if (locked)
                                                TextButton.icon(
                                                  onPressed:
                                                      () => _unlockStep(index),
                                                  icon: const Icon(
                                                    Icons.edit,
                                                    color: Colors.orange,
                                                    size: 26,
                                                  ),
                                                  label: const Text(
                                                    "Modificar paso",
                                                  ),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.orange,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Descripción del paso:',
                                        style: GoogleFonts.roboto(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      TextField(
                                        controller: step['desc'],
                                        maxLines: 2,
                                        readOnly: locked,
                                        textAlign: TextAlign.justify,
                                        decoration: InputDecoration(
                                          hintText:
                                              'Describe brevemente qué se hace en este paso',
                                          border: const OutlineInputBorder(),
                                          filled: locked,
                                          fillColor:
                                              locked
                                                  ? Colors.grey.shade300
                                                  : null,
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      Text(
                                        'Expresión LaTeX:',
                                        style: GoogleFonts.roboto(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      TextField(
                                        controller: step['latex'],
                                        readOnly: locked,
                                        textAlign: TextAlign.left,
                                        decoration: InputDecoration(
                                          hintText:
                                              r'Escribe aquí usando LaTeX, por ejemplo: x^2 + 1 = 0',
                                          border: const OutlineInputBorder(),
                                          filled: locked,
                                          fillColor:
                                              locked
                                                  ? Colors.grey.shade300
                                                  : null,
                                        ),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                      if (!locked) ...[
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                _showKeyboard[index] =
                                                    !(_showKeyboard[index] ??
                                                        false);
                                              });
                                            },
                                            icon: Icon(
                                              _showKeyboard[index] == true
                                                  ? Icons.keyboard_hide
                                                  : Icons.keyboard,
                                              color: Colors.blue,
                                            ),
                                            label: Text(
                                              _showKeyboard[index] == true
                                                  ? 'Ocultar calculadora'
                                                  : 'Mostrar calculadora',
                                              style: const TextStyle(
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (_showKeyboard[index] == true)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 12,
                                            ),
                                            child: _latexKeyboard(index),
                                          ),
                                      ],
                                      const SizedBox(height: 10),
                                      Text(
                                        'Vista previa:',
                                        style: GoogleFonts.ebGaramond(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.05,
                                              ),
                                              blurRadius: 6,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Builder(
                                          builder: (context) {
                                            final rawInput = step['latex'].text;
                                            final isPlainText =
                                                rawInput.trim().isNotEmpty &&
                                                !RegExp(
                                                  r'[\\\^\_\{\}]',
                                                ).hasMatch(rawInput);

                                            if (rawInput.trim().isEmpty) {
                                              return Text(
                                                'Escribe una expresión para verla aquí',
                                                style: TextStyle(
                                                  fontStyle: FontStyle.italic,
                                                  color: Colors.grey.shade600,
                                                ),
                                              );
                                            } else if (isPlainText) {
                                              return Text(
                                                rawInput,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.black87,
                                                  height: 1.4,
                                                ),
                                              );
                                            } else {
                                              return SingleChildScrollView(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: CustomLatexText(
                                                  contenido: rawInput,
                                                  fontSize: 20,
                                                  color: Colors.black87,
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: _exitoAlSubir ? 1.07 : 1.0,
                    duration: const Duration(milliseconds: 330),
                    curve: Curves.easeOutBack,
                    child: _botonAccion(
                      _subiendo
                          ? 'Subiendo...'
                          : _exitoAlSubir
                          ? '¡Subido!'
                          : 'Subir',
                      _subiendo
                          ? Icons.hourglass_top
                          : _exitoAlSubir
                          ? Icons.check_circle_outline
                          : Icons.upload,
                      () async {
                        if (!_subiendo && !_exitoAlSubir) {
                          await _subirEjercicioAFirestore();
                        }
                      },
                      backgroundColor:
                          _exitoAlSubir
                              ? Colors.green.shade600
                              : (_subiendo
                                  ? Colors.grey.shade800
                                  : const Color(0xFF1A1A1A)),
                    ),
                  ),
                  const SizedBox(width: 20),
                  _botonAccion('Cancelar', Icons.cancel, () {
                    Navigator.pushNamed(context, '/');
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botonAccion(
    String texto,
    IconData icono,
    VoidCallback onPressed, {
    Color? backgroundColor,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icono, size: 18),
      label: Text(texto),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}
