import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<void> _subirEjercicioAFirestore() async {
    final titulo = _titleController.text.trim();
    final descripcion = _descriptionController.text.trim();

    if (_temaSeleccionado == null || _temaSeleccionado!.isEmpty) {
      showDialog(
        context: context,
        builder:
            (_) => const AlertDialog(
              title: Text('Tema no seleccionado'),
              content: Text(
                'Debes seleccionar un tema antes de subir el ejercicio.',
              ),
            ),
      );
      return;
    }

    if (titulo.isEmpty || descripcion.isEmpty) {
      showDialog(
        context: context,
        builder:
            (_) => const AlertDialog(
              title: Text('Campos vacíos'),
              content: Text('Debes completar el título y la descripción.'),
            ),
      );
      return;
    }

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

    final snapshot = await ejerciciosRef.get();
    final ejercicioId =
        '${_temaSeleccionado}_${(snapshot.docs.length + 1).toString().padLeft(2, '0')}';
    final versionId = 'Version_01';

    final pasos =
        _stepsControllers
            .map((step) => step['latex'].text.trim())
            .where((p) => p.isNotEmpty)
            .toList();
    final descripciones =
        _stepsControllers
            .map((step) => step['desc'].text.trim())
            .where((d) => d.isNotEmpty)
            .toList();

    final ejerRef = ejerciciosRef.doc(ejercicioId);

    try {
      await ejerRef.set({
        'Titulo': titulo,
        'DesEjercicio': descripcion,
        'Autor': user?.displayName ?? '',
        'AutorId': user?.uid ?? '',
        'CalPromedio': '',
        'FechCreacion': now,
        'FechMod': now,
        'versionActual': versionId,
      });

      await ejerRef.collection('Versiones').doc(versionId).set({
        'Titulo': 'Versión 1',
        'Descripcion': descripcion,
        'Fecha': now,
        'AutorId': user?.uid ?? '',
        'PasosEjer': pasos,
        'DescPasos': descripciones,
      });

      if (!mounted) return;
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Ejercicio subido'),
              content: const Text(
                'Tu ejercicio fue guardado correctamente en Firestore.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Aceptar'),
                ),
              ],
            ),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Error al subir'),
              content: Text('Ocurrió un error al guardar en Firestore: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Aceptar'),
                ),
              ],
            ),
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
                      backgroundColor: Colors.blue.shade50,
                      padding: const EdgeInsets.all(10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
  Widget build(BuildContext context) {
    final int activeStepIndex = _stepsControllers.lastIndexWhere(
      (step) => step['locked'] == false,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF036799),
      appBar: AppBar(
        backgroundColor: const Color(0xFF048DD2),
        title: const Text('Study Connect'),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Inicio', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Ranking', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Contenidos',
              style: TextStyle(color: Colors.white),
            ),
          ),
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //TODO: Hacer que el renderizado de la descripcion sea haga mas grande conforme al texto
                  Container(
                    width: 300,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF48C9EF),
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
                          'Vista previa (LaTeX):',
                          style: TextStyle(color: Colors.white),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Math.tex(
                              _titleController.text.trim().isEmpty
                                  ? r'\text{Escribe un título para mostrarlo aquí}'
                                  : _titleController.text.trim().replaceAll(
                                    ' ',
                                    r'\ ',
                                  ),
                              textStyle: const TextStyle(fontSize: 16),
                            ),
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
                          'Vista previa (LaTeX):',
                          style: TextStyle(color: Colors.white),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Math.tex(
                              _descriptionController.text.trim().isEmpty
                                  ? r'\text{Escribe una descripción para mostrarla aquí}'
                                  : _descriptionController.text
                                      .trim()
                                      .replaceAll(' ', r'\ '),
                              textStyle: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/images/funciones.png',
                              height: 300,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  //ToDo: Cambiar a un widget de imagen
                  const SizedBox(width: 20),

                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ListView.builder(
                        itemCount: _stepsControllers.length,
                        itemBuilder: (context, index) {
                          final step = _stepsControllers[index];
                          final locked = step['locked'] as bool;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Paso ${index + 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        if (!locked &&
                                            index == activeStepIndex) ...[
                                          if (index > 0)
                                            TextButton.icon(
                                              onPressed:
                                                  () => _removeStep(index),
                                              icon: const Icon(
                                                Icons.remove_circle,
                                                color: Colors.red,
                                                size: 28,
                                              ),
                                              label: const Text(
                                                "Eliminar paso",
                                              ),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.red,
                                              ),
                                            ),
                                          TextButton.icon(
                                            onPressed: () => _addStep(index),
                                            icon: const Icon(
                                              Icons.add_circle,
                                              color: Colors.green,
                                              size: 28,
                                            ),
                                            label: const Text("Agregar paso"),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.green,
                                            ),
                                          ),
                                        ],
                                        if (locked)
                                          TextButton.icon(
                                            onPressed: () => _unlockStep(index),
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.orange,
                                              size: 26,
                                            ),
                                            label: const Text("Modificar paso"),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.orange,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Text('Descripción del paso:'),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: step['desc'],
                                  maxLines: 2,
                                  readOnly: locked,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Describe brevemente qué se hace en este paso',
                                    border: const OutlineInputBorder(),
                                    filled: locked,
                                    fillColor:
                                        locked ? Colors.grey.shade300 : null,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text('Expresión LaTeX:'),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: step['latex'],
                                  readOnly: locked,
                                  decoration: InputDecoration(
                                    hintText:
                                        r'Escribe aquí usando LaTeX, por ejemplo: x^2 + 1 = 0',
                                    border: const OutlineInputBorder(),
                                    filled: locked,
                                    fillColor:
                                        locked ? Colors.grey.shade300 : null,
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
                                              !(_showKeyboard[index] ?? false);
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
                                      padding: const EdgeInsets.only(top: 12),
                                      child: _latexKeyboard(index),
                                    ),
                                ],
                                const SizedBox(height: 10),
                                const Text(
                                  'Vista previa:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Math.tex(
                                    step['latex'].text.isEmpty
                                        ? r'\text{Escribe una expresión para verla aquí}'
                                        : step['latex'].text,
                                    mathStyle: MathStyle.display,
                                    textStyle: const TextStyle(fontSize: 18),
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
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _botonAccion('Subir', Icons.upload, () async {
                  await _subirEjercicioAFirestore();
                }),
                const SizedBox(width: 20),
                _botonAccion('Cancelar', Icons.cancel, () {
                  Navigator.pushNamed(context, '/');
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _botonAccion(String texto, IconData icono, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icono, size: 18),
      label: Text(texto),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}
