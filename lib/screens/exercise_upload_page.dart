import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

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
    setState(() {});
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
      'f \(x) =',
      'x',
      'y',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildGroup('Funciones algebraicas y trascendentales', funciones),
        const SizedBox(height: 10),
        buildGroup('Límites de funciones y continuidad', limites),
        const SizedBox(height: 10),
        buildGroup('Derivada y optimización', derivadas),
        const SizedBox(height: 10),
        buildGroup('Técnicas de integración', integrales),
      ],
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
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                'assets/images/funciones.png',
                                height: 600,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                _botonAccion('Subir', Icons.upload, () {
                  final titulo = _titleController.text;
                  _showSnack('Subido ejercicio: $titulo');
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
