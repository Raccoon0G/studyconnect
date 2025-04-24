// ExerciseViewPage completo con: calificación dinámica, eliminación y edición de comentarios, estrella parcial, nombres, anónimo, y validaciones
//todo Darle major presentacion, agregar imagenes, y mejorar el diseño
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import 'package:intl/intl.dart';

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
  final currentUser = FirebaseAuth.instance.currentUser;

  List<Map<String, dynamic>> versiones = [];
  String? versionSeleccionada;

  @override
  void initState() {
    super.initState();
    _cargarDatosDesdeFirestore();
    _cargarComentarios();
  }

  Future<void> _cargarDatosDesdeFirestore() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('calculo')
            .doc(widget.tema)
            .collection('Ejer${widget.tema}')
            .doc(widget.ejercicioId)
            .get();

    final versionId = doc['versionActual'];
    final version =
        await doc.reference.collection('Versiones').doc(versionId).get();

    setState(() {
      ejercicioData = doc.data();
      pasos = List<String>.from(version['PasosEjer'] ?? []);
      descripciones = List<String>.from(version['DescPasos'] ?? []);
    });

    final versionesSnap =
        await doc.reference
            .collection('Versiones')
            .orderBy('Fecha', descending: true)
            .get();

    versiones =
        versionesSnap.docs.map((d) {
          return {'id': d.id, 'fecha': d['Fecha']};
        }).toList();

    versionSeleccionada = versionId;

    setState(() {
      versionSeleccionada = versionId;
    });
  }

  Future<void> _cargarVersionSeleccionada(String versionId) async {
    final docRef = FirebaseFirestore.instance
        .collection('calculo')
        .doc(widget.tema)
        .collection('Ejer${widget.tema}')
        .doc(widget.ejercicioId);

    final versionDoc =
        await docRef.collection('Versiones').doc(versionId).get();
    final versionData = versionDoc.data();

    setState(() {
      pasos = List<String>.from(versionData?['PasosEjer'] ?? []);
      descripciones = List<String>.from(versionData?['DescPasos'] ?? []);
    });
  }

  Future<void> _cargarComentarios() async {
    final snap =
        await FirebaseFirestore.instance
            .collection('comentarios_ejercicios')
            .where('ejercicioId', isEqualTo: widget.ejercicioId)
            .where('tema', isEqualTo: widget.tema)
            .orderBy('timestamp', descending: true)
            .get();

    setState(() {
      comentarios = snap.docs.map((e) => e.data()).toList();
    });
  }

  void _mostrarDialogoCalificacion() {
    final TextEditingController controller = TextEditingController();
    bool comoAnonimo = false;
    int rating = 0;

    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Califica este ejercicio'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          5,
                          (i) => IconButton(
                            icon: Icon(
                              i < rating ? Icons.star : Icons.star_border,
                              color: Colors.yellow,
                            ),
                            onPressed: () => setState(() => rating = i + 1),
                          ),
                        ),
                      ),
                      TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          labelText: 'Comentario',
                        ),
                      ),
                      CheckboxListTile(
                        value: comoAnonimo,
                        onChanged: (val) => setState(() => comoAnonimo = val!),
                        title: const Text('Comentar como anónimo'),
                      ),
                    ],
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: DropdownButton<String>(
                        value: versionSeleccionada,
                        dropdownColor: Colors.white,
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white,
                        ),
                        underline: const SizedBox(),
                        style: const TextStyle(color: Colors.black),
                        items:
                            versiones.map<DropdownMenuItem<String>>((ver) {
                              final fecha =
                                  (ver['fecha'] as Timestamp?)?.toDate();
                              final formatted =
                                  fecha != null
                                      ? DateFormat('dd/MM/yyyy').format(fecha)
                                      : 'Sin fecha';
                              return DropdownMenuItem<String>(
                                value: ver['id'],
                                child: Text(
                                  'Versión ${ver['id']} - $formatted',
                                ),
                              );
                            }).toList(),
                        onChanged: (String? value) {
                          if (value != null) {
                            setState(() => versionSeleccionada = value);
                            _cargarVersionSeleccionada(value);
                          }
                        },
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null ||
                            controller.text.isEmpty ||
                            rating == 0)
                          return;

                        final userData =
                            await FirebaseFirestore.instance
                                .collection('usuarios')
                                .doc(user.uid)
                                .get();
                        final nombre = userData['Nombre'] ?? 'Anónimo';
                        final comentario = {
                          'usuarioId': user.uid,
                          'nombre': comoAnonimo ? 'Anónimo' : nombre,
                          'comentario': controller.text,
                          'estrellas': rating,
                          'timestamp': Timestamp.now(),
                          'tema': widget.tema,
                          'ejercicioId': widget.ejercicioId,
                          'modificado': false,
                        };

                        await FirebaseFirestore.instance
                            .collection('comentarios_ejercicios')
                            .add(comentario);

                        final calSnap =
                            await FirebaseFirestore.instance
                                .collection('comentarios_ejercicios')
                                .where(
                                  'ejercicioId',
                                  isEqualTo: widget.ejercicioId,
                                )
                                .where('tema', isEqualTo: widget.tema)
                                .get();

                        final ratings =
                            calSnap.docs
                                .map((d) => d['estrellas'] as int)
                                .toList();
                        final promedio =
                            ratings.reduce((a, b) => a + b) / ratings.length;

                        await FirebaseFirestore.instance
                            .collection('calculo')
                            .doc(widget.tema)
                            .collection('Ejer${widget.tema}')
                            .doc(widget.ejercicioId)
                            .update({'CalPromedio': promedio});

                        _cargarComentarios();
                        Navigator.pop(context);
                      },
                      child: const Text('Enviar'),
                    ),
                  ],
                ),
          ),
    );
  }

  Widget _estrellaConDecimal(double valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        if (valor >= i + 1)
          return const Icon(Icons.star, color: Colors.yellow, size: 20);
        if (valor > i && valor < i + 1)
          return Icon(Icons.star_half, color: Colors.yellow, size: 20);
        return const Icon(Icons.star_border, color: Colors.yellow, size: 20);
      }),
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
    final calificacion =
        double.tryParse(ejercicioData?['CalPromedio'].toString() ?? '0') ?? 0.0;
    final nombre = ejercicioData?['Titulo'] ?? '';
    final autor = ejercicioData?['Autor'] ?? 'Anónimo';
    final fecha = (ejercicioData?['FechMod'] as Timestamp?)?.toDate();
    final desc = ejercicioData?['DesEjercicio'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF036799),
      appBar: AppBar(
        backgroundColor: const Color(0xFF048DD2),
        title: const Text('Study Connect'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/');
            },
            child: const Text('Inicio', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/ranking');
            },
            child: const Text('Ranking', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/content');
            },
            child: const Text(
              'Contenidos',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Columna izquierda (info autor + imagen)
              Expanded(
                flex: 1,
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF055B84),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoConIcono(
                        Icons.person,
                        'Autor: $autor',
                        alineacion: MainAxisAlignment.center,
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Version :',
                          style: GoogleFonts.ebGaramond(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (versiones.isNotEmpty)
                        Center(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              dropdownColor: Colors.white,
                              value: versionSeleccionada,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                              ),
                              style: GoogleFonts.ebGaramond(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              items:
                                  versiones.map((ver) {
                                    final fecha =
                                        (ver['fecha'] as Timestamp?)?.toDate();
                                    final formatted =
                                        fecha != null
                                            ? DateFormat(
                                              'dd/MM/yyyy',
                                            ).format(fecha)
                                            : 'Sin fecha';
                                    return DropdownMenuItem<String>(
                                      value: ver['id'] as String,
                                      child: Text('${ver['id']} - $formatted'),
                                    );
                                  }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => versionSeleccionada = val);
                                  _cargarVersionSeleccionada(val);
                                }
                              },
                            ),
                          ),
                        ),

                      Center(
                        child: Text(
                          'Última actualización :',
                          style: GoogleFonts.ebGaramond(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          fecha != null
                              ? DateFormat('dd/MM/yy').format(fecha)
                              : '---',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          'Calificación :',
                          style: GoogleFonts.ebGaramond(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _estrellaConDecimal(calificacion),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          '${calificacion.toStringAsFixed(1)} / 5.0',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Divider(color: Colors.white54),
                      Center(
                        child: Text(
                          '${comentarios.length} comentario(s)',
                          style: const TextStyle(color: Colors.white60),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Imagen decorativa
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/funciones.png',
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => const Text(
                                'No se pudo cargar la imagen.',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 20),
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView(
                    children: [
                      Text(
                        'Título del ejercicio:',
                        style: GoogleFonts.ebGaramond(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: const Color(0xFFF6F3FA),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Math.tex(
                                  nombre
                                      .replaceAll(' ', r'\ ')
                                      .replaceAll('\n', r'\\'),
                                  mathStyle: MathStyle.display,
                                  textStyle: const TextStyle(
                                    fontSize: 22,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      _infoConIcono(
                        Icons.info,
                        'Tema: ${widget.tema}',
                        colorTexto: Colors.black,
                        tamanoTexto: 17,
                      ),
                      const SizedBox(height: 8),
                      _infoConIcono(
                        Icons.info,
                        'Ejercicio: ${widget.ejercicioId}',
                        colorTexto: Colors.black,
                        tamanoTexto: 17,
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: Colors.black87, height: 20),

                      const Text(
                        'Descripción del ejercicio:',
                        style: TextStyle(fontSize: 18, color: Colors.black),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F3FA),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          dividirDescripcionEnLineas(desc),
                          style: GoogleFonts.ebGaramond(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                          softWrap: true,
                          textAlign: TextAlign.justify,
                        ),
                      ),

                      //todo
                      const SizedBox(height: 20),
                      const Divider(color: Colors.black87, height: 20),
                      const Text(
                        'Pasos a seguir:',
                        style: TextStyle(fontSize: 18, color: Colors.black),
                      ),
                      ...List.generate(
                        pasos.length,
                        (i) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Paso ${i + 1}:',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (i < descripciones.length)
                                  Math.tex(
                                    descripciones[i]
                                        .replaceAll(' ', r'\ ')
                                        .replaceAll('\n', r'\\'),
                                    mathStyle: MathStyle.display,
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Math.tex(
                                    pasos[i]
                                        .replaceAll(' ', r'\,')
                                        .replaceAll('\n', r'\\'),
                                    mathStyle: MathStyle.display,
                                    textStyle: const TextStyle(fontSize: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ExpansionTile(
                        title: Text(
                          'Comentarios (${comentarios.length})',
                          style: const TextStyle(color: Colors.black),
                        ),
                        children:
                            comentarios.map((c) {
                              final fecha =
                                  (c['timestamp'] as Timestamp?)?.toDate();
                              final formatted =
                                  fecha != null
                                      ? DateFormat(
                                        'dd/MM/yyyy HH:mm',
                                      ).format(fecha)
                                      : '';
                              final editable =
                                  c['usuarioId'] ==
                                  FirebaseAuth.instance.currentUser?.uid;

                              return ListTile(
                                leading: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        c['nombre'] ?? 'Anónimo',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    if (editable)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 20,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () async {
                                          final docs =
                                              await FirebaseFirestore.instance
                                                  .collection(
                                                    'comentarios_ejercicios',
                                                  )
                                                  .where(
                                                    'usuarioId',
                                                    isEqualTo: c['usuarioId'],
                                                  )
                                                  .where(
                                                    'comentario',
                                                    isEqualTo: c['comentario'],
                                                  )
                                                  .where(
                                                    'timestamp',
                                                    isEqualTo: c['timestamp'],
                                                  )
                                                  .get();
                                          for (final d in docs.docs) {
                                            await d.reference.delete();
                                          }
                                          _cargarComentarios();
                                        },
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      formatted,
                                      style: const TextStyle(
                                        color: Colors.white60,
                                      ),
                                    ),
                                    Text(
                                      c['comentario'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    _estrellaConDecimal(
                                      (c['estrellas'] ?? 0).toDouble(),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(height: 40),
                      Card(
                        color: const Color(0xFFF6F3FA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 6,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                '¿Te fue útil este ejercicio?',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              if (comentarios.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${comentarios.length} persona(s) ya lo calificaron',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 20,
                                runSpacing: 12,
                                alignment: WrapAlignment.center,
                                children: [
                                  currentUser != null
                                      ? _botonAccion(
                                        'Calificar',
                                        Icons.star,
                                        _mostrarDialogoCalificacion,
                                      )
                                      : ElevatedButton.icon(
                                        onPressed:
                                            () => showDialog(
                                              context: context,
                                              builder:
                                                  (_) => AlertDialog(
                                                    title: const Text(
                                                      'Inicia sesión',
                                                    ),
                                                    content: const Text(
                                                      'Debes iniciar sesión para comentar.',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed:
                                                            () =>
                                                                Navigator.pushNamed(
                                                                  context,
                                                                  '/login',
                                                                ),
                                                        child: const Text(
                                                          'Iniciar sesión',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                            ),
                                        icon: const Icon(Icons.lock),
                                        label: const Text('Inicia sesión'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey,
                                        ),
                                      ),
                                  _botonAccion(
                                    'Compartir',
                                    Icons.share,
                                    _compartirCapturaConFacebookWeb,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                '¡Comparte este ejercicio con tus compañeros!',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//Widget _botonAccion(String texto, IconData icono, VoidCallback accion) {
//  return ElevatedButton.icon(
//    onPressed: accion,
//    icon: Icon(icono),
//    label: Text(texto),
//    style: ElevatedButton.styleFrom(
//      backgroundColor: Colors.blue,
//      foregroundColor: Colors.white,
//      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//    ),
//  );
//}

String dividirDescripcionEnLineas(
  String texto, {
  int maxPalabrasPorLinea = 25,
}) {
  final palabras = texto.split(' ');
  final buffer = StringBuffer();

  for (int i = 0; i < palabras.length; i++) {
    buffer.write(palabras[i]);
    if ((i + 1) % maxPalabrasPorLinea == 0 && i != palabras.length - 1) {
      buffer.write('\n'); // salto de línea visible
    } else if (i != palabras.length - 1) {
      buffer.write(' ');
    }
  }

  return buffer.toString();
}

Widget _infoConIcono(
  IconData icon,
  String texto, {
  MainAxisAlignment alineacion = MainAxisAlignment.start,
  Color colorTexto = Colors.white, // Nuevo parámetro
  double tamanoTexto = 18, // Nuevo parámetro
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: alineacion,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: colorTexto, size: 18),
        const SizedBox(width: 8),
        Text(
          texto,
          style: GoogleFonts.ebGaramond(
            color: colorTexto,
            fontSize: tamanoTexto,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
