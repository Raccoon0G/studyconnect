import 'dart:html' as html;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:screenshot/screenshot.dart';

class ExerciseViewPage extends StatefulWidget {
  final String tema;
  final String ejercicioId;

  const ExerciseViewPage({
    super.key,
    required this.tema,
    required this.ejercicioId,
  });

  @override
  State<ExerciseViewPage> createState() => _ExerciseViewPageState();
}

class _ExerciseViewPageState extends State<ExerciseViewPage> {
  final ScreenshotController _screenshotController = ScreenshotController();

  Map<String, dynamic>? ejercicioData;
  List<String> pasos = [];
  List<String> descripciones = [];
  List<Map<String, dynamic>> comentarios = [];

  @override
  void initState() {
    super.initState();
    _cargarDatosDesdeFirestore();
    _cargarComentarios();
  }

  Future<void> _cargarDatosDesdeFirestore() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final docRef = firestore
          .collection('calculo')
          .doc(widget.tema)
          .collection('Ejer${widget.tema}')
          .doc(widget.ejercicioId);

      final docSnap = await docRef.get();
      final data = docSnap.data();
      if (data == null) return;

      final versionId = data['versionActual'] ?? 'Version_01';
      final versionSnap =
          await docRef.collection('Versiones').doc(versionId).get();
      final versionData = versionSnap.data();

      setState(() {
        ejercicioData = data;
        pasos = List<String>.from(versionData?['PasosEjer'] ?? []);
        descripciones = List<String>.from(versionData?['DescPasos'] ?? []);
      });
    } catch (e) {
      debugPrint('❌ Error al cargar ejercicio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar el ejercicio.')),
        );
      }
    }
  }

  Future<void> _cargarComentarios() async {
    final query =
        await FirebaseFirestore.instance
            .collection('comentarios_ejercicios')
            .where('ejercicioId', isEqualTo: widget.ejercicioId)
            .where('tema', isEqualTo: widget.tema)
            .orderBy('timestamp', descending: true)
            .get();

    setState(() {
      comentarios = query.docs.map((doc) => doc.data()).toList();
    });
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
                  onPressed: () async {
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid == null) return;

                    if (commentController.text.isNotEmpty && rating > 0) {
                      final comentario = {
                        'usuarioId': uid,
                        'ejercicioId': widget.ejercicioId,
                        'tema': widget.tema,
                        'comentario': commentController.text,
                        'estrellas': rating,
                        'timestamp': Timestamp.now(),
                      };

                      await FirebaseFirestore.instance
                          .collection('comentarios_ejercicios')
                          .add(comentario);

                      final snapshot =
                          await FirebaseFirestore.instance
                              .collection('comentarios_ejercicios')
                              .where(
                                'ejercicioId',
                                isEqualTo: widget.ejercicioId,
                              )
                              .where('tema', isEqualTo: widget.tema)
                              .get();

                      final allRatings =
                          snapshot.docs
                              .map((doc) => doc['estrellas'] as int)
                              .toList();
                      final promedio =
                          allRatings.isEmpty
                              ? 0.0
                              : allRatings.reduce((a, b) => a + b) /
                                  allRatings.length;

                      await FirebaseFirestore.instance
                          .collection('calculo')
                          .doc(widget.tema)
                          .collection('Ejer${widget.tema}')
                          .doc(widget.ejercicioId)
                          .update({'CalPromedio': promedio});

                      _cargarComentarios();
                      Navigator.pop(context);
                    }
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

  @override
  Widget build(BuildContext context) {
    if (ejercicioData == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF036799),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final autor = ejercicioData?['Autor'] ?? 'Anónimo';
    final fecha = (ejercicioData?['FechMod'] as Timestamp?)?.toDate();
    final cal =
        double.tryParse((ejercicioData?['CalPromedio'] ?? '0').toString()) ?? 0;
    final titulo = ejercicioData?['Titulo'] ?? '';
    final desc = ejercicioData?['DesEjercicio'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF036799),
      appBar: AppBar(
        backgroundColor: const Color(0xFF048DD2),
        title: const Text('Study Connect'),
      ),
      body: Screenshot(
        controller: _screenshotController,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Autor: $autor',
                      style: const TextStyle(color: Colors.white),
                    ),
                    if (fecha != null)
                      Text(
                        'Fecha: ${fecha.day}/${fecha.month}/${fecha.year}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < cal.round() ? Icons.star : Icons.star_border,
                          color: Colors.yellow,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${comentarios.length} comentario${comentarios.length == 1 ? '' : 's'}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ListView(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Math.tex(desc, mathStyle: MathStyle.display),
                    ),
                    const SizedBox(height: 20),
                    ...List.generate(pasos.length, (index) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (index < descripciones.length)
                                Text(
                                  'Paso ${index + 1}: ${descripciones[index]}',
                                ),
                              Math.tex(
                                pasos[index],
                                mathStyle: MathStyle.display,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                    ExpansionTile(
                      title: Text(
                        'Comentarios (${comentarios.length})',
                        style: const TextStyle(color: Colors.white),
                      ),
                      children:
                          comentarios.map((c) {
                            final timestamp = c['timestamp'] as Timestamp?;
                            final date = timestamp?.toDate();
                            final formattedDate =
                                date != null
                                    ? '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}'
                                    : '';
                            return ListTile(
                              leading: const Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                              title: Text(
                                c['nombre'] ?? 'Anónimo',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (formattedDate.isNotEmpty)
                                    Text(
                                      formattedDate,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  Text(
                                    c['comentario'] ?? '',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  Row(
                                    children: List.generate(5, (i) {
                                      return Icon(
                                        i < (c['estrellas'] ?? 0)
                                            ? Icons.star
                                            : Icons.star_border,
                                        size: 16,
                                        color: Colors.yellow,
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FirebaseAuth.instance.currentUser != null
                            ? _botonAccion(
                              'Calificar',
                              Icons.star,
                              _mostrarDialogoCalificacion,
                            )
                            : ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text(
                                        'Iniciar sesión requerida',
                                      ),
                                      content: const Text(
                                        'Debes iniciar sesión para comentar.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            Navigator.pushNamed(
                                              context,
                                              '/login',
                                            );
                                          },
                                          child: const Text('Iniciar sesión'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              icon: const Icon(Icons.lock),
                              label: const Text('Inicia sesión'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),

                        const SizedBox(width: 20),
                        _botonAccion(
                          'Compartir',
                          Icons.share,
                          _compartirCapturaConFacebookWeb,
                        ),
                      ],
                    ),
                  ],
                ),
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
      html.window.open(
        'https://www.facebook.com/sharer/sharer.php?u=https://tu-sitio.com',
        '_blank',
      );
    }
  }

  Widget _botonAccion(String texto, IconData icono, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icono),
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
