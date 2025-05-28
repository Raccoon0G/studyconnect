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

import 'package:study_connect/services/services.dart';
import 'package:study_connect/widgets/widgets.dart';
import 'package:study_connect/utils/utils.dart';
import 'package:share_plus/share_plus.dart';

import 'package:path_provider/path_provider.dart'; // Necesario para guardar imagen en móvil
import 'dart:io'; // Necesario para File
import 'package:flutter/foundation.dart'
    show kIsWeb; // Para diferenciar entre web y móvil
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  /// FUNCIÓN PARA CONECTAR LA CUENTA DE FACEBOOK (para el perfil del usuario)
  Future<void> _connectToFacebook() async {
    // Pide permisos. Para publicar en una página, necesitarás 'pages_manage_posts' y 'pages_show_list'.
    final LoginResult result = await FacebookAuth.instance.login(
      permissions: [
        'public_profile',
        'email',
        'pages_manage_posts',
        'pages_show_list',
      ],
    );

    if (result.status == LoginStatus.success) {
      final AccessToken accessToken = result.accessToken!;
      print('✅ Conexión exitosa. Token: ${accessToken.tokenString}');

      // ❗️ AQUÍ DEBES GUARDAR EL accessToken.tokenString EN FIRESTORE
      // en el documento del usuario actual.
      //await FirebaseFirestore.instance.collection('usuarios').doc(currentUser.uid).update({
      // 'facebookAccessToken': accessToken.tokenString,
      //});

      showCustomSnackbar(
        context: context,
        message: '¡Cuenta de Facebook conectada!',
        success: true,
      );
    } else {
      print('Error de conexión: ${result.status}');
      print('Mensaje: ${result.message}');
      showCustomSnackbar(
        context: context,
        message: 'No se pudo conectar con Facebook.',
        success: false,
      );
    }
  }

  /// FUNCIÓN PARA PUBLICAR EL EJERCICIO EN FACEBOOK (se llama desde el BottomSheet)
  Future<void> _postDirectlyToFacebook() async {
    // 1. Obtener el token guardado del usuario desde Firestore
    // final userDoc = await FirebaseFirestore.instance.collection('usuarios').doc(currentUser.uid).get();
    // final String? userToken = userDoc.data()?['facebookAccessToken'];

    // --- Usaremos un token de ejemplo para la demostración ---
    final String? userToken = "TU_TOKEN_DE_ACCESO_GUARDADO_AQUI";

    if (userToken == null) {
      showCustomSnackbar(
        context: context,
        message: 'Primero conecta tu cuenta de Facebook en tu perfil.',
        success: false,
      );
      return;
    }

    // Muestra un diálogo de carga
    showDialog(
      context: context,
      builder: (_) => Center(child: CircularProgressIndicator()),
    );

    try {
      // 2. Tomar el Screenshot
      final Uint8List? imageBytes = await _screenshotController.capture();
      if (imageBytes == null) {
        Navigator.pop(context); // Cierra el diálogo de carga
        showCustomSnackbar(
          context: context,
          message: 'No se pudo capturar la imagen.',
          success: false,
        );
        return;
      }

      // 3. Preparar la llamada a la Graph API de Facebook para subir una foto a una PÁGINA
      // (Publicar en un perfil personal es mucho más restrictivo)
      // NOTA: Necesitas el ID de la página donde quieres publicar.

      //TODO Checar implementacion con api
      final String pageId = "ID_DE_LA_PAGINA_DEL_USUARIO";
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://graph.facebook.com/$pageId/photos'),
      );

      final texto =
          '¡Resolví este ejercicio de ${obtenerNombreTema(widget.tema)} con Study Connect! ${ejercicioData?['Titulo']} #StudyConnect';

      request.fields['caption'] = texto;
      request.fields['access_token'] = userToken;
      request.files.add(
        http.MultipartFile.fromBytes(
          'source',
          imageBytes,
          filename: 'ejercicio.png',
        ),
      );

      // 4. Enviar la publicación
      final response = await request.send();

      Navigator.pop(context); // Cierra el diálogo de carga

      if (response.statusCode == 200) {
        print('✅ Publicación exitosa!');
        showCustomSnackbar(
          context: context,
          message: '¡Publicado en Facebook con éxito!',
          success: true,
        );
      } else {
        final responseData = await response.stream.bytesToString();
        print('Error al publicar: ${response.statusCode}');
        print('Detalles: ${responseData}');
        showCustomSnackbar(
          context: context,
          message: 'Error al publicar en Facebook.',
          success: false,
        );
      }
    } catch (e) {
      Navigator.pop(context); // Cierra el diálogo de carga
      print('Error excepcional: $e');
    }
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

  String obtenerNombreTema(String key) {
    const nombresTemas = {
      'FnAlg': 'Funciones algebraicas y trascendentes',
      'Lim': 'Límites de funciones y continuidad',
      'Der': 'Derivada y optimización',
      'TecInteg': 'Técnicas de integración',
    };
    return nombresTemas[key] ?? key;
  }

  Future<void> _confirmarEliminarEjercicio(
    BuildContext context,
    String tema,
    String ejercicioId,
  ) async {
    final ejercicioRef = FirebaseFirestore.instance
        .collection('calculo')
        .doc(tema)
        .collection('Ejer$tema')
        .doc(ejercicioId);

    final versionesRef = ejercicioRef.collection('Versiones');
    final versionesSnap =
        await versionesRef.orderBy('Fecha', descending: true).get();

    if (versionesSnap.docs.length == 1) {
      // SOLO UNA VERSIÓN: eliminar ejercicio completo
      final confirmar = await showCustomDialog<bool>(
        context: context,
        titulo: 'Eliminar ejercicio completo',
        mensaje:
            'Este ejercicio tiene una única versión. ¿Deseas eliminarlo por completo?',
        tipo: CustomDialogType.warning,
        botones: [
          DialogButton(texto: 'Cancelar', value: false),
          DialogButton(texto: 'Eliminar', value: true),
        ],
      );

      if (confirmar == true) {
        await versionesRef.doc(versionSeleccionada).delete();
        await ejercicioRef.delete();

        final comentariosSnap =
            await FirebaseFirestore.instance
                .collection('comentarios_ejercicios')
                .where('ejercicioId', isEqualTo: ejercicioId)
                .where('tema', isEqualTo: tema)
                .get();
        for (final c in comentariosSnap.docs) {
          await c.reference.delete();
        }

        final autorId = ejercicioData?['AutorId'];
        if (autorId != null && autorId.toString().isNotEmpty) {
          final usuarioRef = FirebaseFirestore.instance
              .collection('usuarios')
              .doc(autorId);
          await usuarioRef.update({'EjerSubidos': FieldValue.increment(-1)});
        }

        if (mounted) Navigator.pop(context, 'eliminado');
      }
    } else {
      // MÁS DE UNA VERSIÓN: eliminar solo la seleccionada
      final confirmar = await showCustomDialog<bool>(
        context: context,
        titulo: 'Eliminar versión del ejercicio',
        mensaje:
            '¿Deseas eliminar la versión seleccionada ($versionSeleccionada) del ejercicio?',
        tipo: CustomDialogType.warning,
        botones: [
          DialogButton(texto: 'Cancelar', value: false),
          DialogButton(texto: 'Eliminar versión', value: true),
        ],
      );

      if (confirmar == true && versionSeleccionada != null) {
        await versionesRef.doc(versionSeleccionada).delete();

        // Si eliminaste la versión actual, asignar la siguiente más reciente
        if (ejercicioData?['versionActual'] == versionSeleccionada) {
          final nuevaVersion =
              versionesSnap.docs
                  .where((v) => v.id != versionSeleccionada)
                  .first;
          await ejercicioRef.update({
            'versionActual': nuevaVersion.id,
            'FechMod': nuevaVersion['Fecha'],
          });
          versionSeleccionada = nuevaVersion.id;
        }

        if (mounted) {
          showCustomSnackbar(
            context: context,
            message: '✅ Versión eliminada correctamente.',
            success: true,
          );
          await _cargarTodo();
        }
      }
    }
  }

  Future<void> _eliminarSoloVersionSeleccionada(
    BuildContext context,
    String tema,
    String ejercicioId,
  ) async {
    if (versionSeleccionada == null) return;
    print('🧾 Versión a eliminar: $versionSeleccionada');

    final confirmar = await showCustomDialog<bool>(
      context: context,
      titulo: 'Eliminar versión',
      mensaje:
          '¿Seguro que deseas eliminar la versión "${versionSeleccionada ?? '(sin seleccionar)'}"?',

      tipo: CustomDialogType.warning,
      botones: [
        DialogButton(texto: 'Cancelar', value: false),
        DialogButton(texto: 'Eliminar versión', value: true),
      ],
    );

    if (confirmar == true) {
      final ejercicioRef = FirebaseFirestore.instance
          .collection('calculo')
          .doc(tema)
          .collection('Ejer$tema')
          .doc(ejercicioId);

      // Eliminar la versión seleccionada
      await ejercicioRef
          .collection('Versiones')
          .doc(versionSeleccionada)
          .delete();

      // Actualizar versionActual si la que se eliminó es la actual
      final doc = await ejercicioRef.get();
      if (doc.exists && doc.data()?['versionActual'] == versionSeleccionada) {
        final nuevasVersiones =
            await ejercicioRef
                .collection('Versiones')
                .orderBy('Fecha', descending: true)
                .get();

        if (nuevasVersiones.docs.isNotEmpty) {
          final nueva = nuevasVersiones.docs.first;
          await ejercicioRef.update({
            'versionActual': nueva.id,
            'FechMod': nueva['Fecha'],
          });
          setState(() {
            versionSeleccionada = nueva.id;
          });
        }
      }

      showCustomSnackbar(
        context: context,
        message: '✅ Versión eliminada correctamente.',
        success: true,
      );

      await _cargarTodo();
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
    required bool esMovil,
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
    final autorId = ejercicioData?['AutorId'] ?? '';
    final currentUser = FirebaseAuth.instance.currentUser;
    final uidActual = currentUser?.uid;
    final estaLogueado = currentUser != null;

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
          const SizedBox(height: 18),

          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 230, minHeight: 120),
            child: const ExerciseCarousel(),
          ),
          //TODO Arreglar botones
          if (estaLogueado && autorId == uidActual)
            Padding(
              padding: const EdgeInsets.only(top: 30.0),
              child: Row(
                // Usamos Row y centramos los botones
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- Botón Editar ---
                  Flexible(
                    // Flexible para que los botones se adapten al espacio
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label:
                          esMovil
                              ? const SizedBox.shrink()
                              : const Text("Editar"), // Oculta texto en móvil
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: esMovil ? 12 : 16,
                        ), // Padding adaptativo
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        // 'this.context' se refiere al context de _ExerciseViewPageState
                        if (this.versionSeleccionada == null) {
                          showCustomDialog(
                            context:
                                this.context, // Usa el context de la clase _ExerciseViewPageState
                            titulo: 'Versión no cargada',
                            mensaje:
                                'Espera a que se carguen los datos antes de editar.',
                            tipo: CustomDialogType.warning,
                          );
                          return;
                        }
                        Navigator.pushNamed(
                          this.context,
                          '/exercise_upload',
                          arguments: {
                            'tema': tema, // 'tema' es parámetro del método
                            'ejercicioId':
                                ejercicioId, // 'ejercicioId' es parámetro
                            'modo': 'editar',
                            'versionId': this.versionSeleccionada,
                          },
                        );
                      },
                    ),
                  ),

                  SizedBox(
                    width: esMovil ? 8 : 12,
                  ), // Espaciador más pequeño en móvil
                  // --- Botón Nueva Versión ---
                  Flexible(
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.white,
                      ),
                      label:
                          esMovil
                              ? const SizedBox.shrink()
                              : const Text(
                                "Nueva V.",
                              ), // Texto abreviado si es necesario
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: esMovil ? 12 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(
                          this.context,
                          '/exercise_upload',
                          arguments: {
                            'tema': tema,
                            'ejercicioId': ejercicioId,
                            'modo': 'nueva_version',
                          },
                        );
                      },
                    ),
                  ),

                  SizedBox(width: esMovil ? 8 : 12),

                  // --- Botón Eliminar (con PopupMenu) ---
                  Flexible(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label:
                          esMovil
                              ? const SizedBox.shrink()
                              : const Text("Eliminar"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: esMovil ? 12 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        final RenderBox button =
                            this.context.findRenderObject() as RenderBox;
                        final Offset offset = button.localToGlobal(Offset.zero);
                        // Ajusta la posición del menú si es necesario, especialmente en móvil
                        final RelativeRect position = RelativeRect.fromLTRB(
                          esMovil
                              ? offset.dx - 80
                              : offset.dx, // Desplaza a la izquierda en móvil
                          offset.dy + button.size.height,
                          esMovil
                              ? offset.dx + button.size.width - 80
                              : offset.dx + button.size.width,
                          offset.dy + button.size.height * 2,
                        );

                        showMenu<String>(
                          context: this.context,
                          position: position,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          items:
                              versiones.length <= 1
                                  ? [
                                    const PopupMenuItem<String>(
                                      value: 'ejercicio',
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.delete_forever,
                                          color: Colors.red,
                                        ),
                                        title: Text(
                                          'Eliminar ejercicio completo',
                                        ),
                                      ),
                                    ),
                                  ]
                                  : [
                                    const PopupMenuItem<String>(
                                      value: 'version',
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                        ),
                                        title: Text('Eliminar versión actual'),
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'ejercicio',
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.delete_forever,
                                          color: Colors.red,
                                        ),
                                        title: Text(
                                          'Eliminar ejercicio completo',
                                        ),
                                      ),
                                    ),
                                  ],
                        ).then((value) {
                          if (value == null) return;
                          if (value == 'version') {
                            _eliminarSoloVersionSeleccionada(
                              this.context,
                              tema,
                              ejercicioId,
                            );
                          } else if (value == 'ejercicio') {
                            _confirmarEliminarEjercicio(
                              this.context,
                              tema,
                              ejercicioId,
                            );
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showSharingOptions() {
    showModalBottomSheet(
      context: context,
      // Bordes redondeados para un look moderno
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            // Usamos Wrap para que se ajuste bien
            children: <Widget>[
              // Título del menú
              const ListTile(
                title: Text(
                  'Compartir ejercicio',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),

              // En tu BottomSheet, añade una nueva opción
              ListTile(
                leading: const Icon(Icons.facebook, color: Color(0xFF1877F2)),
                title: const Text('Publicar en mi Página de Facebook'),
                onTap: () {
                  Navigator.pop(context); // Cierra el menú
                  _postDirectlyToFacebook(); // Llama a la nueva función
                },
              ),

              ListTile(
                leading: const Icon(Icons.facebook, color: Color(0xFF1877F2)),
                title: const Text('Publicar en Facebook'),
                onTap: () {
                  Navigator.pop(context); // Cierra el menú
                  if (ejercicioData != null) {
                    _compartirCapturaYFacebook(
                      ejercicioData!['Titulo'] ?? 'Ejercicio',
                      widget.tema,
                      widget.ejercicioId,
                    );
                  } // Llama a la nueva función
                },
              ),
              // Opción 2: Compartir con Imagen
              ListTile(
                leading: const Icon(
                  Icons.image_outlined,
                  color: Colors.blueAccent,
                ),
                title: const Text('Compartir con Imagen'),
                onTap: () {
                  Navigator.pop(context); // Cierra el menú
                  _shareExercise(
                    withImage: true,
                  ); // Llama a la función que ya creamos
                },
              ),
              // Opción 3: Compartir solo el enlace
              ListTile(
                leading: const Icon(Icons.link_outlined, color: Colors.green),
                title: const Text('Compartir solo Enlace'),
                onTap: () {
                  Navigator.pop(context); // Cierra el menú
                  _shareExercise(withImage: false); // Llama a la función
                },
              ),
              // Opción 4: Copiar el enlace
              ListTile(
                leading: const Icon(Icons.copy_outlined, color: Colors.grey),
                title: const Text('Copiar Enlace'),
                onTap: () {
                  Navigator.pop(context); // Cierra el menú
                  _copyLinkToClipboard(); // Llama a la función para copiar
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _columnaDerecha({
    required Map<String, dynamic> ejercicioData,
    required List<String> pasos,
    required List<String> descripciones,
    required List<Map<String, dynamic>> comentarios,
    required bool esPantallaChica,
    required double screenWidth,
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
                    prepararLatex: prepararLaTeX,
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
                        // 1) Solo tomo el raw de Firestore, sin sanitizar para la descripción:
                        final descText =
                            (i < descripciones.length) ? descripciones[i] : '';
                        // 2) Aquí sí aplico sanitizer / preview solo para la fórmula:
                        final pasoLatex = pasos[i];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ––––– Descripción como texto normal –––––
                            if (descText.trim().isNotEmpty) ...[
                              Text(
                                // si guardaste "\ " en los datos, conviérelos de vuelta
                                descText.replaceAll(r'\ ', ' '),
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // ––––– Fórmula LaTeX –––––
                            if (pasoLatex.trim().isNotEmpty) ...[
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: CustomLatexText(
                                  contenido: pasoLatex,
                                  fontSize: 22,
                                  color: Colors.black87,
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: pasoLatex),
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
          onCompartir: _showSharingOptions,
        ),
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

    // Aquí obtenemos la URL de la foto (o null si no hay)
    final fotoUrl =
        (!comoAnonimo)
            ? (userData.data()?['FotoPerfil'] as String?) ?? user.photoURL
            : null;

    final comentario = {
      'usuarioId': user.uid,
      'nombre': comoAnonimo ? 'Anónimo' : userData['Nombre'],
      'fotoUrl': fotoUrl,
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

    // 🔽 Actualizar calificación del autor (ejercicios, materiales y global)
    final ejercicioDoc =
        await FirebaseFirestore.instance
            .collection('calculo')
            .doc(widget.tema)
            .collection('Ejer${widget.tema}')
            .doc(widget.ejercicioId)
            .get();

    final autorId = ejercicioDoc.data()?['AutorId'];

    if (autorId != null && autorId.toString().isNotEmpty) {
      await actualizarTodoCalculoDeUsuario(uid: autorId);
    }

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

  Future<void> _compartirCapturaYFacebook(
    String titulo,
    String tema,
    String ejercicioId,
  ) async {
    final Uint8List? image = await _screenshotController.capture();
    if (image != null) {
      // Descargar la imagen localmente
      final blob = html.Blob([image]);
      final urlBlob = html.Url.createObjectUrlFromBlob(blob);

      final link =
          html.AnchorElement(href: urlBlob)
            ..setAttribute('download', 'captura_ejercicio.png')
            ..click();

      html.Url.revokeObjectUrl(urlBlob);

      // Después, compartir en Facebook
      final urlEjercicio = Uri.encodeComponent(
        'https://study-connect.app/exercise/$tema/$ejercicioId',
      ); // CAMBIA aquí tu dominio real
      final quote = Uri.encodeComponent('¡Revisa este Ejercicio: $titulo!');
      final facebookUrl =
          'https://www.facebook.com/sharer/sharer.php?u=$urlEjercicio&quote=$quote';

      html.window.open(facebookUrl, '_blank');
    }
  }

  Future<void> _shareExercise({bool withImage = false}) async {
    if (ejercicioData == null) return; // No hacer nada si no hay datos

    // --- Muestra un diálogo de carga para mejorar la UX ---
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final titulo = ejercicioData!['Titulo'] ?? 'Ejercicio increíble';
      final nombreTema = obtenerNombreTema(widget.tema);

      // ❗️ IMPORTANTE: Reemplaza 'tuapp.com' con tu dominio real.
      // Esta URL es la que se abrirá si alguien hace clic en el enlace compartido.
      final url =
          'https://study-connect.app/exercise/${widget.tema}/${widget.ejercicioId}';

      final textoACompartir =
          '📘 ¡Mira este ejercicio sobre "$nombreTema" en Study Connect!\n\n$titulo\n\nEncuéntralo aquí:\n$url';

      XFile? imageFile;

      if (withImage) {
        // --- Captura el screenshot ---
        final Uint8List? imageBytes = await _screenshotController.capture();

        if (imageBytes != null) {
          if (kIsWeb) {
            // En la web, usamos los bytes directamente.
            imageFile = XFile.fromData(
              imageBytes,
              name: 'ejercicio.png',
              mimeType: 'image/png',
            );
          } else {
            // En móvil, guardamos la imagen en un directorio temporal.
            final tempDir = await getTemporaryDirectory();
            final file = await File(
              '${tempDir.path}/ejercicio.png',
            ).writeAsBytes(imageBytes);
            imageFile = XFile(file.path);
          }
        }
      }

      // --- Cierra el diálogo de carga ---
      if (mounted) Navigator.pop(context);

      // --- Usa Share.shareXFiles para compartir texto e imagen ---
      if (imageFile != null) {
        await Share.shareXFiles(
          [imageFile],
          text: textoACompartir,
          subject: 'Ejercicio de Study Connect: $titulo',
        );
      } else {
        // Si no hay imagen (o no se seleccionó la opción), comparte solo el texto.
        await Share.share(
          textoACompartir,
          subject: 'Ejercicio de Study Connect: $titulo',
        );
      }
    } catch (e) {
      // --- Cierra el diálogo de carga en caso de error ---
      if (mounted) Navigator.pop(context);

      // Muestra un snackbar de error
      if (mounted) {
        showCustomSnackbar(
          context: context,
          message: 'Error al intentar compartir: $e',
          success: false,
        );
      }
    }
  }

  /// ✅ NUEVA FUNCIÓN PARA COPIAR ENLACE
  void _copyLinkToClipboard() {
    if (ejercicioData == null) return;

    // ❗️ IMPORTANTE: Reemplaza 'tuapp.com' con tu dominio real.
    final url =
        'https://study-connect.app/exercise/${widget.tema}/${widget.ejercicioId}';

    Clipboard.setData(ClipboardData(text: url)).then((_) {
      showCustomSnackbar(
        context: context,
        message: '✅ Enlace copiado al portapapeles',
        success: true,
      );
    });
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
      appBar: const CustomAppBar(showBack: true),

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
                            esMovil: esMovilMuyPequeno || esMovilGrande,
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
                            screenWidth: screenWidth,
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
                            esMovil: esMovilMuyPequeno || esMovilGrande,
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
                            screenWidth: screenWidth,
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
