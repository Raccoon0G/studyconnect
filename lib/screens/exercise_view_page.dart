//todo Darle major presentacion, agregar imagenes, y mejorar el diseño
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import 'package:intl/intl.dart';

import 'package:study_connect/services/notification_service.dart';
import 'package:study_connect/widgets/widgets.dart';
import 'package:study_connect/utils/utils.dart';

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
    _cargarTodo();
  }

  Future<void> _cargarDatosDesdeFirestore() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('calculo')
              .doc(widget.tema)
              .collection('Ejer${widget.tema}')
              .doc(widget.ejercicioId)
              .get();

      if (!doc.exists) {
        throw Exception('Documento no encontrado');
      }

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
          versionesSnap.docs
              .map((d) => {'id': d.id, 'fecha': d['Fecha']})
              .toList();

      versionSeleccionada = versionId;
    } catch (e) {
      print('Error al cargar datos: $e');
      _mostrarError('Error al cargar datos', e.toString());
    }
  }

  void _mostrarError(String titulo, String mensaje) {
    showCustomDialog(
      context: context,
      titulo: titulo,
      mensaje: mensaje,
      tipo: CustomDialogType.error,
      botones: [
        DialogButton(
          texto: 'Cerrar',
          onPressed: () async {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
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
    try {
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
    } catch (e) {
      _mostrarError('Error al cargar comentarios', e.toString());
    }
  }

  Future<void> _eliminarComentario(Map<String, dynamic> comentario) async {
    try {
      final query =
          await FirebaseFirestore.instance
              .collection('comentarios_ejercicios')
              .where('usuarioId', isEqualTo: comentario['usuarioId'])
              .where('comentario', isEqualTo: comentario['comentario'])
              .where('timestamp', isEqualTo: comentario['timestamp'])
              .get();

      for (final doc in query.docs) {
        await doc.reference.delete();
      }

      await _cargarComentarios();
      await _cargarDatosDesdeFirestore();

      // 🎯 Mostrar SnackBar bonito
      if (mounted) {
        // Verificamos si el widget está montado
        showFeedbackDialogAndSnackbar(
          //  Mostrar el diálogo y Snackbar de éxito al eliminar
          context: context,
          titulo: '¡Éxito!',
          mensaje: 'Comentario elimnado correctamente.',
          tipo: CustomDialogType.success,
          snackbarMessage: '✅ ¡Comentario Eliminado!',
          snackbarSuccess: true,
        );
        //Opcion 1 para mostrar snackbar mas facil sin tanto clic
        // showCustomSnackbar(
        // context: context,
        // message: ' Comentario eliminado con éxito',
        // success: true,
        // );
      }
    } catch (e) {
      if (mounted) {
        showFeedbackDialogAndSnackbar(
          context: context,
          titulo: 'Error',
          mensaje: 'Ocurrió un error al eliminar el comentario.',
          tipo: CustomDialogType.error,
          snackbarMessage: 'Error al eliminar.',
          snackbarSuccess: false,
        );
        // showCustomSnackbar(
        //   context: context,
        //   message: 'Error al eliminar comentario',
        //   success: false,
        // );
      }
    }
  }

  Future<void> _cargarTodo() async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('calculo')
          .doc(widget.tema)
          .collection('Ejer${widget.tema}')
          .doc(widget.ejercicioId);

      //  Lanzamos las 3 consultas en paralelo
      final results = await Future.wait([
        docRef.get(),
        docRef.collection('Versiones').orderBy('Fecha', descending: true).get(),
        FirebaseFirestore.instance
            .collection('comentarios_ejercicios')
            .where('ejercicioId', isEqualTo: widget.ejercicioId)
            .where('tema', isEqualTo: widget.tema)
            .orderBy('timestamp', descending: true)
            .get(),
      ]);

      final doc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final versionesSnap = results[1] as QuerySnapshot<Map<String, dynamic>>;
      final comentariosSnap = results[2] as QuerySnapshot<Map<String, dynamic>>;

      if (!doc.exists) {
        throw Exception('No se encontró el ejercicio.');
      }

      final versionId = doc['versionActual'];
      final version =
          await doc.reference.collection('Versiones').doc(versionId).get();

      setState(() {
        ejercicioData = doc.data();
        pasos = List<String>.from(version['PasosEjer'] ?? []);
        descripciones = List<String>.from(version['DescPasos'] ?? []);
        versiones =
            versionesSnap.docs.map((d) {
              return {'id': d.id, 'fecha': d['Fecha']};
            }).toList();
        versionSeleccionada = versionId;
        comentarios = comentariosSnap.docs.map((e) => e.data()).toList();
      });
    } catch (e) {
      _mostrarError('Error al cargar datos', e.toString());
    }
  }

  Widget _columnaIzquierda({
    required Map<String, dynamic> ejercicioData,
    required String tema,
    required String ejercicioId,
    required List<Map<String, dynamic>> versiones,
    required String? versionSeleccionada,
    required List<Map<String, dynamic>> comentarios,
    required void Function(String) onVersionChanged,
  }) {
    final autor = ejercicioData['Autor'] ?? 'Anónimo';
    final fecha = (ejercicioData['FechMod'] as Timestamp?)?.toDate();
    final calificacion = calcularPromedioEstrellas(comentarios);

    final Map<String, String> nombresTemas = {
      'FnAlg': 'Funciones algebraicas y trascendentes',
      'Lim': 'Límites de funciones y continuidad',
      'Der': 'Derivada y optimización',
      'TecInteg': 'Técnicas de integración',
    };

    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF055B84),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoWithIcon(
            icon: Icons.person_outlined,
            text: 'Autor: $autor',
            alignment: MainAxisAlignment.center,
            iconAlignment: Alignment.center,
            textColor: Colors.white,
            textSize: 20,
            //maxWidthText: 335,
          ),
          const SizedBox(height: 8),
          InfoWithIcon(
            icon: Icons.book,
            text: 'Tema: ${nombresTemas[tema] ?? tema}',
            alignment: MainAxisAlignment.center,
            iconAlignment: Alignment.center,
            textColor: Colors.white,
            textSize: 17,
            //maxWidthText: 280,
          ),
          const SizedBox(height: 8),
          InfoWithIcon(
            icon: Icons.assignment,
            text: 'Ejercicio: $ejercicioId',
            alignment: MainAxisAlignment.center,
            iconAlignment: Alignment.center,
            textColor: Colors.white,
            textSize: 17,
          ),
          const SizedBox(height: 8),
          InfoWithIcon(
            icon: Icons.update,
            text: 'Versión actual: $versionSeleccionada',
            alignment: MainAxisAlignment.center,
            iconAlignment: Alignment.center,
            textColor: Colors.white,
            textSize: 17,
          ),

          const SizedBox(height: 8),

          if (versiones.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(
                  0xFFF6F3FA,
                ), // mismo color de fondo de tus Cards
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
              child: Semantics(
                label: 'Seleccionar la versión para calificar el ejercicio',
                child: CustomDropdownVersiones(
                  versionSeleccionada: versionSeleccionada,
                  versiones: versiones,
                  onChanged: (value) {
                    setState(() {
                      versionSeleccionada = value;
                    });
                    _cargarVersionSeleccionada(value);
                  },
                ),
              ),
            ),
          const SizedBox(height: 8),
          InfoWithIcon(
            icon: Icons.change_circle,
            text: 'Última modificación:',
            alignment: MainAxisAlignment.center,
            iconAlignment: Alignment.center,
            textColor: Colors.white,
            textSize: 17,
          ),
          const SizedBox(height: 4),
          InfoWithIcon(
            icon: Icons.calendar_today,
            text:
                fecha != null
                    ? DateFormat('dd/MM/yyyy').format(fecha)
                    : 'Sin fecha',
            alignment: MainAxisAlignment.center,
            iconAlignment: Alignment.center,
            textColor: Colors.white,
            textSize: 17,
          ),

          const SizedBox(height: 12),
          InfoWithIcon(
            icon: Icons.task_sharp,
            text: 'Calificación promedio:',
            alignment: MainAxisAlignment.center,
            iconAlignment: Alignment.center,
            textColor: Colors.white,
            textSize: 17,
          ),
          const SizedBox(height: 8),
          CustomStarRating(
            valor: calificacion,
            size: 30, // Puedes ajustar el tamaño si quieres
            color: Colors.amber,
            duration: const Duration(milliseconds: 800),
          ), //promedio estrellas comentarios

          const SizedBox(height: 8),
          Center(
            child: Text(
              '${calificacion.toStringAsFixed(1)} / 5.0',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const Divider(color: Colors.white54),
          Center(
            child: Text(
              '${comentarios.length} comentario(s)',
              style: const TextStyle(color: Colors.white60),
            ),
          ),
          const SizedBox(height: 38),

          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 285, minHeight: 220),
            child: const ExerciseCarousel(),
          ),
        ],
      ),
    );
  }

  Widget _columnaDerecha({
    required Map<String, dynamic> ejercicioData,
    required List<String> pasos,
    required List<String> descripciones,
    required List<Map<String, dynamic>> comentarios,
    required bool esPantallaChica,
  }) {
    final nombre = ejercicioData['Titulo'] ?? '';
    final desc = ejercicioData['DesEjercicio'] ?? '';

    final contenido = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                  child: CustomLatexText(
                    contenido: nombre,
                    fontSize: 22,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
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
            color: const Color(0xFFF6F3FA),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paso ${i + 1}:',
                    style: GoogleFonts.ebGaramond(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // DESCRIPCIÓN y PASO (combinados)
                  Builder(
                    builder: (context) {
                      // aquí recibes el context
                      try {
                        final pasoLatex = prepararLaTeX(pasos[i]);
                        final descLatex =
                            (i < descripciones.length)
                                ? prepararLaTeX(descripciones[i])
                                : '';

                        final mostrarAmbos = pasoLatex != descLatex;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (descLatex.isNotEmpty)
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: CustomLatexText(
                                  contenido: descLatex,
                                  fontSize: 20,
                                  color: Colors.black,
                                ),
                              ),
                            if (mostrarAmbos && pasoLatex.isNotEmpty)
                              const SizedBox(height: 10),
                            if (mostrarAmbos && pasoLatex.isNotEmpty)
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: CustomLatexText(
                                  contenido: pasoLatex,
                                  fontSize: 22,
                                  color: Colors.black87,
                                ),
                              ),
                            if (pasoLatex.isNotEmpty)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: pasos[i]),
                                    );
                                    showCustomSnackbar(
                                      context: context,
                                      message: 'Código LaTeX copiado',
                                      success: true,
                                    );
                                  },
                                  icon: const Icon(Icons.copy, size: 18),
                                  label: const Text('Copiar LaTeX'),
                                ),
                              ),
                          ],
                        );
                      } catch (e) {
                        return const Text(
                          '⚠️ Error al mostrar el paso',
                          style: TextStyle(color: Colors.redAccent),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        // la dividi en en 4 casos para que se desplieguen bien , descripcion y paso son iguales Solo se muestra uno una vez , si el paso y la descripcion son diferentes se muestran ambos uno arriba de otro , solo hay paso solo se muestra paso y si solo hay descripcion solo se muestra la descripcion :D
        //todo
        const SizedBox(height: 16),
        const Divider(color: Colors.black87, height: 20),

        CustomExpansionTileComentarios(
          comentarios: comentarios,
          onEliminarComentario: _eliminarComentario,
        ),

        const SizedBox(height: 40),
        CustomFeedbackCard(
          accion: 'Calificar',
          numeroComentarios: comentarios.length,
          onCalificar: _mostrarDialogoCalificacion,
          onCompartir: _compartirCapturaConFacebookWeb,
        ),

        const SizedBox(height: 20),
      ],
    );
    if (esPantallaChica) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
          child: contenido, //  aquí va el contenido
        ),
      );
    } else {
      // 🖥️ Pantalla grande: Scroll sólo en pasos
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [contenido],
        ),
      );
    }
  }

  void _mostrarDialogoCalificacion() {
    final TextEditingController controller = TextEditingController();
    bool enviando = false;

    int rating = 0; //
    bool comoAnonimo = false;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Cerrar",
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedValue = Curves.easeInOut.transform(animation.value);
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, (1 - curvedValue) * 100),
            child: StatefulBuilder(
              builder: (context, setStateDialog) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  contentPadding: const EdgeInsets.all(24),
                  content: _buildContenidoDialogo(
                    controller,
                    () => comoAnonimo, //  lo pasamos como función getter
                    (val) => setStateDialog(() => comoAnonimo = val),
                    () => rating,
                    (val) => setStateDialog(() => rating = val),
                    enviando,
                    (val) => setStateDialog(() => enviando = val),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildContenidoDialogo(
    TextEditingController controller,
    bool Function() getComoAnonimo,
    void Function(bool) setComoAnonimo,
    int Function() getRating,
    void Function(int) setRating,
    bool enviando,
    void Function(bool) setEnviando,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Califica este ejercicio',
                    style: GoogleFonts.ebGaramond(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CustomRatingWidget(
              rating: getRating(),
              onRatingChanged: (nuevoValor) => setRating(nuevoValor),
              enableHoverEffect: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Comentario',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: getComoAnonimo(),
              onChanged: (val) {
                if (val != null) setComoAnonimo(val);
              },
              title: const Text('Comentar como anónimo'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
              child: DropdownButtonFormField<String>(
                value: versionSeleccionada,
                isExpanded: true,
                items:
                    versiones.map((ver) {
                      final fecha = (ver['fecha'] as Timestamp?)?.toDate();
                      final formatted =
                          fecha != null
                              ? DateFormat('dd/MM/yyyy').format(fecha)
                              : 'Sin fecha';
                      return DropdownMenuItem<String>(
                        value: ver['id'],
                        child: Text('Versión ${ver['id']} - $formatted'),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => versionSeleccionada = value);
                  }
                },
                decoration: const InputDecoration.collapsed(
                  hintText: 'Seleccionar versión',
                ),
                dropdownColor: Colors.white,
              ),
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed:
                      enviando
                          ? null
                          : () async {
                            if (controller.text.trim().isEmpty ||
                                getRating() == 0) {
                              showCustomDialog(
                                context: context,
                                titulo: 'Campos incompletos',
                                mensaje:
                                    'Por favor escribe un comentario y selecciona una calificación.',
                                tipo: CustomDialogType.error,
                                botones: [
                                  DialogButton(
                                    texto: 'Aceptar',
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  DialogButton(
                                    texto: 'Intentar de nuevo',
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      _mostrarDialogoCalificacion();
                                    },
                                  ),
                                ],
                              );

                              return;
                            }

                            setEnviando(true);
                            await _enviarComentario(
                              controller.text
                                  .trim(), // hacer trim sirve para eliminar espacios en blanco al inicio y al final
                              getRating(),
                              getComoAnonimo(),
                            );
                            setEnviando(false);
                            Navigator.pop(context);
                          },
                  icon:
                      enviando
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.send),
                  label: Text(enviando ? 'Enviando...' : 'Enviar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _enviarComentario(
    String texto,
    int rating,
    bool comoAnonimo,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || texto.isEmpty || rating == 0) return;

    final userData =
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();
    final comentario = {
      'usuarioId': user.uid,
      'nombre': comoAnonimo ? 'Anónimo' : userData['Nombre'],
      'comentario': texto,
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
            .where('ejercicioId', isEqualTo: widget.ejercicioId)
            .where('tema', isEqualTo: widget.tema)
            .get();

    final ratings = calSnap.docs.map((d) => d['estrellas'] as int).toList();
    double promedio = 0.0;
    if (ratings.isNotEmpty) {
      promedio = ratings.reduce((a, b) => a + b) / ratings.length;
    }

    await FirebaseFirestore.instance
        .collection('calculo')
        .doc(widget.tema)
        .collection('Ejer${widget.tema}')
        .doc(widget.ejercicioId)
        .update({'CalPromedio': promedio});

    await _cargarComentarios();
    await _cargarDatosDesdeFirestore();
    //Opcion 1
    // if (context.mounted) {
    // Navigator.of(
    // context,
    // rootNavigator: true,
    // ).pop(); // cerrar el AlertDialog de calificación
    // }
    // showFeedbackDialogAndSnackbar(
    //   context: context,
    //   titulo: '¡Éxito!',
    //   mensaje: ' Comentario enviado exitosamente.',
    //   tipo: CustomDialogType.error,
    //   snackbarMessage: '✅ Comentario enviado exitosamente.',
    //   snackbarSuccess: true,
    // );
    // Opcion 2
    // await closeDialogAndShowSnackbar(
    // context: context,
    // message: '✅ Comentario enviado exitosamente.',
    // success: true,
    // );

    // Opción 3 para mostrar snackbar más fácil sin tanto clic
    showCustomSnackbar(
      context: context,
      message: '✅ Comentario enviado exitosamente.',
      success: true,
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
    final screenWidth = MediaQuery.of(context).size.width;

    final bool esMovilMuyPequeno = screenWidth <= 480;
    final bool esMovilGrande = screenWidth > 480 && screenWidth <= 800;
    final bool esTabletOLaptopChica = screenWidth > 800 && screenWidth <= 1200;
    final bool esLaptopGrande = screenWidth > 1200 && screenWidth <= 1900;
    final bool esUltraWide = screenWidth > 1900;

    return Scaffold(
      backgroundColor: const Color(0xFF036799),
      appBar: AppBar(
        backgroundColor: const Color(0xFF048DD2),
        title: const Text('Study Connect'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/'),
            child: const Tooltip(
              message: 'Ir a Inicio',
              child: Text('Inicio', style: TextStyle(color: Colors.white)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/ranking'),
            child: const Tooltip(
              message: 'Ir a Ranking',
              child: Text('Ranking', style: TextStyle(color: Colors.white)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/content'),
            child: const Tooltip(
              message: 'Ir a Contenido',
              child: Text('Contenido', style: TextStyle(color: Colors.white)),
            ),
          ),
          const NotificationIconWidget(),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/user_profile'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Tooltip(
                message: 'Ir a perfil',
                child: Text('Perfil', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Screenshot(
        controller: _screenshotController,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 2500),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (esMovilMuyPequeno || esMovilGrande) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: _columnaIzquierda(
                            ejercicioData: ejercicioData ?? {},
                            tema: widget.tema,
                            ejercicioId: widget.ejercicioId,
                            versiones: versiones,
                            versionSeleccionada: versionSeleccionada,
                            comentarios: comentarios,
                            onVersionChanged: (newVersion) {
                              setState(() {
                                versionSeleccionada = newVersion;
                              });
                              _cargarVersionSeleccionada(newVersion);
                            },
                          ),
                        ),
                        SliverPadding(padding: const EdgeInsets.only(top: 20)),
                        SliverToBoxAdapter(
                          child: _columnaDerecha(
                            ejercicioData: ejercicioData ?? {},
                            pasos: pasos,
                            descripciones: descripciones,
                            comentarios: comentarios,
                            esPantallaChica: true,
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: esTabletOLaptopChica ? 2 : 1,
                          child: _columnaIzquierda(
                            ejercicioData: ejercicioData ?? {},
                            tema: widget.tema,
                            ejercicioId: widget.ejercicioId,
                            versiones: versiones,
                            versionSeleccionada: versionSeleccionada,
                            comentarios: comentarios,
                            onVersionChanged: (newVersion) {
                              setState(() {
                                versionSeleccionada = newVersion;
                              });
                              _cargarVersionSeleccionada(newVersion);
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: esTabletOLaptopChica ? 2 : 3,
                          child: _columnaDerecha(
                            ejercicioData: ejercicioData ?? {},
                            pasos: pasos,
                            descripciones: descripciones,
                            comentarios: comentarios,
                            esPantallaChica: false,
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
