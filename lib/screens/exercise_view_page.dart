import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';

class ExerciseViewPage extends StatefulWidget {
  const ExerciseViewPage({super.key});

  @override
  State<ExerciseViewPage> createState() => _ExerciseViewPageState();
}

class _ExerciseViewPageState extends State<ExerciseViewPage> {
  final ScreenshotController _screenshotController = ScreenshotController();

  final List<Map<String, dynamic>> comentarios = [
    {'usuario': 'Juan', 'comentario': 'Muy útil, gracias!', 'estrellas': 4},
    {'usuario': 'Ana', 'comentario': 'Excelente explicación.', 'estrellas': 5},
  ];

  @override
  Widget build(BuildContext context) {
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
      body: Screenshot(
        controller: _screenshotController,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Funciones algebraicas y trascendentales',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
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
                          Center(
                            child: Text(
                              'Última actualización',
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 24,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Center(
                            child: Text(
                              '05/11/24',
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              'Autor :',
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Abraham',
                                style: GoogleFonts.roboto(
                                  color: Colors.black,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              'Calificación :',
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (i) {
                              return const Icon(
                                Icons.star,
                                color: Colors.yellow,
                                size: 20,
                              );
                            }),
                          ),
                          const SizedBox(height: 20),
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
                        height: 800,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ejercicio nº 1:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Halla el dominio de definición de las siguientes funciones:\n'
                                'a) y = 1 / (x² - 9)\n'
                                'b) y = √(x - 2)',
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Solución:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'a) x² - 9 = 0 → x = ±3 → Dominio = R − {−3,3}\n'
                                'b) x − 2 ≥ 0 → x ≥ 2 → Dominio = [2, ∞)',
                              ),
                              const SizedBox(height: 300),
                              const Divider(
                                thickness: 1,
                                color: Colors.black26,
                              ),
                              const SizedBox(height: 20),
                              ExpansionTile(
                                title: const Text(
                                  'Comentarios',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black,
                                  ),
                                ),
                                children: [
                                  SizedBox(
                                    height: 200,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.all(8),
                                      itemCount: comentarios.length,
                                      itemBuilder: (context, index) {
                                        final comentario = comentarios[index];
                                        return ListTile(
                                          leading: const Icon(Icons.person),
                                          title: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                comentario['usuario'] ??
                                                    'Anónimo',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(comentario['comentario']),
                                            ],
                                          ),
                                          subtitle: Row(
                                            children: List.generate(5, (i) {
                                              return Icon(
                                                i < comentario['estrellas']
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                size: 16,
                                                color: Colors.yellow,
                                              );
                                            }),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
                  _botonAccion(
                    'Calificar',
                    Icons.star,
                    onPressed: _mostrarDialogoCalificacion,
                  ),
                  const SizedBox(width: 20),
                  _botonAccion(
                    'Compartir',
                    Icons.share,
                    onPressed: _compartirCapturaConFacebookWeb,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _compartirCapturaConFacebookWeb() async {
    final Uint8List? image = await _screenshotController.capture();
    if (image != null) {
      final blob = html.Blob([image]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..target = '_blank'
        ..download = "captura.png"
        ..click();
      html.Url.revokeObjectUrl(url);
      // Abre una nueva pestaña con diálogo para compartir en Facebook
      html.window.open(
        'https://www.facebook.com/sharer/sharer.php?u=https://tu-sitio.com',
        '_blank',
      );
    }
  }

  void _mostrarDialogoCalificacion() {
    int rating = 0;
    final TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Califica este ejercicio"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.yellow,
                        ),
                        onPressed: () {
                          setState(() {
                            rating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      labelText: "Escribe tu comentario",
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (commentController.text.isNotEmpty && rating > 0) {
                      setState(() {
                        comentarios.add({
                          'usuario': 'Tú',
                          'comentario': commentController.text,
                          'estrellas': rating,
                        });
                      });
                    }
                    Navigator.pop(context);
                  },
                  child: const Text("Enviar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _botonAccion(
    String texto,
    IconData icono, {
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      icon: Icon(icono, size: 18),
      label: Text(texto),
    );
  }
}
