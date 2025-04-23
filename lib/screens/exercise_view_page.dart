import 'dart:html' as html;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
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
  List<Map<String, dynamic>> versionesPrevias = [];

  @override
  void initState() {
    super.initState();
    _cargarDatosDesdeFirestore();
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

      final versionesSnap =
          await docRef
              .collection('Versiones')
              .orderBy('Fecha', descending: true)
              .get();

      final versiones =
          versionesSnap.docs
              .where((v) => v.id != versionId)
              .map((doc) => {'id': doc.id, 'data': doc.data()})
              .toList();

      setState(() {
        ejercicioData = data;
        pasos = List<String>.from(versionData?['PasosEjer'] ?? []);
        descripciones = List<String>.from(versionData?['DescPasos'] ?? []);
        comentarios = List<Map<String, dynamic>>.from(
          data['Comentarios'] ?? [],
        );
        versionesPrevias = versiones;
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
                    if (commentController.text.isNotEmpty && rating > 0) {
                      final comentario = {
                        'usuario': 'Tú',
                        'comentario': commentController.text,
                        'estrellas': rating,
                      };

                      await FirebaseFirestore.instance
                          .collection('calculo')
                          .doc(widget.tema)
                          .collection('Ejer${widget.tema}')
                          .doc(widget.ejercicioId)
                          .update({
                            'Comentarios': FieldValue.arrayUnion([comentario]),
                          });

                      setState(() {
                        comentarios.add(comentario);
                      });

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
        int.tryParse(
          (ejercicioData?['CalPromedio'] ?? '0').toString().split('.').first,
        ) ??
        0;
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
                    i < cal ? Icons.star : Icons.star_border,
                    color: Colors.yellow,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Math.tex(
                  desc,
                  mathStyle: MathStyle.display,
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Solución paso a paso:',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: [
                    ...List.generate(pasos.length, (index) {
                      return Card(
                        elevation: 2,
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
                              const SizedBox(height: 6),
                              Math.tex(
                                pasos[index],
                                mathStyle: MathStyle.display,
                                textStyle: const TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (versionesPrevias.isNotEmpty) ...[
                      const Divider(height: 30),
                      const Text(
                        'Versiones anteriores:',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      ...versionesPrevias.map((ver) {
                        final v = ver['data'];
                        final ps = List<String>.from(v['PasosEjer'] ?? []);
                        final ds = List<String>.from(v['DescPasos'] ?? []);
                        final fecha = (v['Fecha'] as Timestamp?)?.toDate();
                        return Card(
                          color: Colors.grey.shade200,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Versión ${ver['id']} — ${fecha != null ? '${fecha.day}/${fecha.month}/${fecha.year}' : ''}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                ...List.generate(ps.length, (i) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (i < ds.length)
                                          Text('Paso ${i + 1}: ${ds[i]}'),
                                        Math.tex(
                                          ps[i],
                                          mathStyle: MathStyle.display,
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                    const Divider(),
                    const Text(
                      'Comentarios:',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    ...comentarios.map(
                      (c) => ListTile(
                        leading: const Icon(Icons.person, color: Colors.white),
                        title: Text(
                          c['usuario'] ?? 'Anónimo',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _botonAccion(
                    'Calificar',
                    Icons.star,
                    _mostrarDialogoCalificacion,
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
      ),
    );
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
