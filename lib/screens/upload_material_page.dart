import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:html' as html;
import '../services/services.dart';
import '../utils/utils.dart';
import '../widgets/widgets.dart';
import 'package:study_connect/config/secrets.dart';

class UploadMaterialPage extends StatefulWidget {
  const UploadMaterialPage({super.key});

  @override
  State<UploadMaterialPage> createState() => _UploadMaterialPageState();
}

class _UploadMaterialPageState extends State<UploadMaterialPage> {
  String? _temaSeleccionado;
  final TextEditingController _subtemaController = TextEditingController();
  final TextEditingController _notaController = TextEditingController();
  final List<Map<String, dynamic>> _archivos = [];

  final Map<String, String> temasDisponibles = {
    'FnAlg': 'Funciones algebraicas y trascendentes',
    'Lim': 'Límites de funciones y continuidad',
    'Der': 'Derivada y optimización',
    'TecInteg': 'Técnicas de integración',
    'Gnral': 'Temas en General (Cosas de aportación General)',
  };

  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  String? _nombreUsuario;
  bool _subiendo = false;
  bool _exitoAlSubir = false;

  @override
  void initState() {
    super.initState();
    _cargarNombreUsuario();
  }

  Future<void> _confirmarEliminarArchivo(int index) async {
    final archivo = _archivos[index];
    final nombre = archivo['nombre'] ?? 'archivo';

    await showCustomDialog(
      context: context,
      titulo: '¿Eliminar archivo?',
      mensaje: '¿Estás seguro de que deseas eliminar "$nombre"?',
      tipo: CustomDialogType.warning,
      botones: [
        DialogButton(texto: 'Cancelar', cierraDialogo: true),
        DialogButton(
          texto: 'Eliminar',
          onPressed: () async {
            setState(() {
              _archivos.removeAt(index);
            });
            Navigator.of(
              context,
            ).pop(); // cerrar el diálogo si no lo cierras automáticamente
            showCustomSnackbar(
              context: context,
              message: 'Archivo eliminado.',
              success: true,
            );
          },
        ),
      ],
    );
  }

  Future<void> _cargarNombreUsuario() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(uid)
              .get();
      setState(() {
        _nombreUsuario = doc['Nombre'] ?? 'Usuario';
      });
    }
  }

  Future<String?> obtenerTituloVideoYoutube(String url) async {
    final videoId =
        Uri.parse(url).queryParameters['v'] ?? Uri.parse(url).pathSegments.last;

    final apiUrl =
        'https://www.googleapis.com/youtube/v3/videos?part=snippet&id=$videoId&key=$youtubeApiKey';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final items = json['items'];
        if (items != null && items.isNotEmpty) {
          return items[0]['snippet']['title'];
        }
      }
      return null;
    } catch (e) {
      print('Error al obtener título del video: $e');
      return null;
    }
  }

  Future<void> reproducirSonidoExito() async {
    final player = AudioPlayer();
    await player.play(AssetSource('audio/successed.mp3'));
  }

  Future<void> reproducirSonidoError() async {
    final player = AudioPlayer();
    await player.play(AssetSource('audio/error.mp3'));
  }

  Future<void> _subirMaterialEducativo() async {
    if (_subiendo) return;

    if (_temaSeleccionado == null || _tituloController.text.trim().isEmpty) {
      await showCustomDialog(
        context: context,
        titulo: 'Campos obligatorios',
        mensaje:
            'Debes completar el título y seleccionar un tema para continuar.',
        tipo: CustomDialogType.warning,
      );
      return;
    }

    if (_archivos.isEmpty) {
      showCustomSnackbar(
        context: context,
        message: 'Agrega al menos un archivo o contenido.',
        success: false,
      );
      return;
    }
    if (_archivos.length > 10) {
      await showCustomDialog(
        context: context,
        titulo: 'Límite de archivos',
        mensaje:
            'Solo puedes subir hasta 10 archivos o contenidos por material.',
        tipo: CustomDialogType.warning,
      );
      return;
    }

    try {
      setState(() => _subiendo = true);

      final uid = FirebaseAuth.instance.currentUser?.uid;
      final nombreTema = temasDisponibles[_temaSeleccionado!] ?? 'Otro';
      final now = Timestamp.now();

      // Referencia a la subcolección con el patrón EjerFnAlg, EjerTecInteg, etc.
      final coleccionMateriales = FirebaseFirestore.instance
          .collection('materiales')
          .doc(_temaSeleccionado!)
          .collection('Mat$_temaSeleccionado');

      // Obtener el número de documentos para generar un ID incremental
      final snapshot = await coleccionMateriales.get();
      final materialId =
          '${_temaSeleccionado}_${(snapshot.docs.length + 1).toString().padLeft(2, '0')}';
      final versionId = 'Version_01';

      // Subida de archivos a Storage y recopilación de contenido
      final List<Map<String, dynamic>> contenido = [];
      for (var archivo in _archivos) {
        if (archivo['tipo'] == 'pdf' ||
            archivo['tipo'] == 'image' ||
            archivo['tipo'] == 'video') {
          final nombreArchivo =
              '${DateTime.now().millisecondsSinceEpoch}_${archivo['nombre']}';
          final ref = FirebaseStorage.instance
              .ref()
              .child('materiales')
              .child(_temaSeleccionado!)
              .child(uid!) // uid ya lo tienes arriba
              .child(nombreArchivo);

          await ref.putData(archivo['bytes']);
          final url = await ref.getDownloadURL();

          contenido.add({
            'tipo': archivo['tipo'],
            'nombre': archivo['nombre'],
            'url': url,
            'extension': archivo['extension'],
          });
        } else if (archivo['tipo'] == 'link' || archivo['tipo'] == 'nota') {
          contenido.add({
            'tipo': archivo['tipo'],
            'contenido': archivo['nombre'],
          });
        }
      }

      // Guardar documento principal
      final materialRef = coleccionMateriales.doc(materialId);
      await materialRef.set({
        'id': materialId,
        'autorId': uid,
        'autorNombre': _nombreUsuario ?? 'Usuario',
        'tema': _temaSeleccionado,
        'subtema': _subtemaController.text.trim(),
        'titulo': _tituloController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'archivos': contenido,
        'fecha': now,
        'FechMod': now,
        'calificacionPromedio': 0.0,
        'versionActual': versionId,
        'carpetaStorage': 'materiales/$_temaSeleccionado/$uid',
      });

      // Guardar versión inicial
      await materialRef.collection('Versiones').doc(versionId).set({
        'Descripcion': _descripcionController.text.trim(),
        'Fecha': now,
        'AutorId': uid,
        'archivos': contenido,
      });

      await NotificationService.crearNotificacion(
        uidDestino: uid!,
        tipo: 'material',
        titulo: 'Material subido correctamente',
        contenido: 'Agregaste nuevo material en $nombreTema',
        referenciaId: materialId,
        uidEmisor: uid,
        nombreEmisor: _nombreUsuario ?? 'Tú',
      );

      // ALERTA LOCAL
      await LocalNotificationService.show(
        title: 'Material subido',
        body: 'Tu material en $nombreTema fue guardado exitosamente',
      );

      await reproducirSonidoExito();

      await showFeedbackDialogAndSnackbar(
        context: context,
        titulo: '¡Éxito!',
        mensaje: 'El material se subió correctamente a la plataforma.',
        tipo: CustomDialogType.success,
        snackbarMessage: 'Material guardado con éxito',
        snackbarSuccess: true,
      );

      // Limpiar campos
      setState(() {
        _temaSeleccionado = null;
        _subtemaController.clear();
        _notaController.clear();
        _archivos.clear();
        _tituloController.clear();
        _descripcionController.clear();
      });
    } catch (e) {
      await reproducirSonidoError();
      await showFeedbackDialogAndSnackbar(
        context: context,
        titulo: 'Error al subir material',
        mensaje: e.toString(),
        tipo: CustomDialogType.error,
        snackbarMessage: '❌ Hubo un error al subir el material.',
        snackbarSuccess: false,
      );

      // Tip opcional aleatorio
      final List<String> tips = [
        'Tip: Puedes añadir enlaces de YouTube y se mostrarán como miniaturas.',
        'Tip: Puedes combinar notas y archivos en una sola publicación.',
        'Tip: No olvides agregar una descripción detallada.',
      ];

      final randomTip =
          tips[DateTime.now().millisecondsSinceEpoch % tips.length];

      // Reproduce sonido
      final player = AudioPlayer();
      await player.play(AssetSource('audio/tip.mp3'));

      // Muestra diálogo
      await showCustomDialog(
        context: context,
        titulo: '¡Consejo!',
        mensaje: randomTip,
        tipo: CustomDialogType.info,
      );
    } finally {
      setState(() => _subiendo = false);
    }
    setState(() {
      _exitoAlSubir = true;
    });

    // Esperar 1.5 segundos y luego restaurar
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _exitoAlSubir = false;
      });
    }
  }

  Future<void> _seleccionarArchivoPorExtension(
    List<String> extensiones,
    String tipo,
  ) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: extensiones,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      setState(() {
        _archivos.add({
          'nombre': file.name,
          'bytes': file.bytes,
          'extension': file.extension ?? '',
          'tipo': tipo,
        });
      });
    }
  }

  void _agregarEnlace() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Agregar enlace'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'https://...'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final enlace = controller.text.trim();
                if (enlace.isNotEmpty) {
                  final yaExiste = _archivos.any(
                    (archivo) =>
                        archivo['tipo'] == 'link' &&
                        archivo['nombre'] == enlace,
                  );

                  if (yaExiste) {
                    Navigator.pop(context);
                    showCustomSnackbar(
                      context: context,
                      message: 'Este enlace ya ha sido agregado.',
                      success: false,
                    );
                    return;
                  }

                  setState(() {
                    _archivos.add({'nombre': enlace, 'tipo': 'link'});
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  void _agregarNota() {
    final nota = _notaController.text.trim();
    if (nota.isNotEmpty) {
      final yaExiste = _archivos.any(
        (archivo) => archivo['tipo'] == 'nota' && archivo['nombre'] == nota,
      );

      if (yaExiste) {
        showCustomSnackbar(
          context: context,
          message: 'Esta nota ya ha sido agregada.',
          success: false,
        );
        return;
      }

      setState(() {
        _archivos.add({'nombre': nota, 'tipo': 'nota'});
        _notaController.clear();
      });
    }
  }

  String _extractYoutubeId(String url) {
    final uri = Uri.parse(url);
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.first;
    } else if (uri.queryParameters.containsKey('v')) {
      return uri.queryParameters['v']!;
    } else {
      return '';
    }
  }

  void _abrirEnlaceEnWeb(String url) {
    html.window.open(url, '_blank');
  }

  Widget _buildArchivoPreview(Map<String, dynamic> archivo) {
    final tipo = archivo['tipo'];
    final nombre = archivo['nombre'] ?? '';
    final extension = (archivo['extension'] ?? '').toString().toLowerCase();

    if (extension == 'pdf') {
      return ListTile(
        leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
        title: Text(nombre),
      );
    } else if (extension == 'mp3') {
      return ListTile(
        leading: const Icon(Icons.audiotrack, color: Colors.purple),
        title: Text('$nombre (Audio MP3)'),
      );
    } else if (extension == 'mp4') {
      return ListTile(
        leading: const Icon(Icons.movie, color: Colors.deepOrange),
        title: Text('$nombre (Video MP4)'),
      );
    } else if (tipo == 'image') {
      return ListTile(
        leading: const Icon(Icons.image, color: Colors.blue),
        title: Text(nombre),
      );
    } else if (tipo == 'link') {
      final link = archivo['nombre'];
      final isYoutube =
          link.contains("youtube.com") || link.contains("youtu.be");
      if (isYoutube) {
        final videoId = _extractYoutubeId(link);
        final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/0.jpg';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(thumbnailUrl, fit: BoxFit.cover),
              ListTile(
                leading: const Icon(Icons.play_circle, color: Colors.red),
                title: FutureBuilder<String?>(
                  future: obtenerTituloVideoYoutube(link),
                  builder: (context, snapshot) {
                    return Text(snapshot.data ?? 'Video de YouTube');
                  },
                ),
                subtitle: Text(link),
                trailing: ElevatedButton.icon(
                  onPressed: () => _abrirEnlaceEnWeb(link),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text("Ver video"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        return ListTile(
          leading: const Icon(Icons.link, color: Colors.green),
          title: Text(link),
          trailing: IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () => _abrirEnlaceEnWeb(link),
          ),
        );
      }
    } else if (tipo == 'nota') {
      return ListTile(
        leading: const Icon(Icons.notes, color: Colors.purple),
        title: Text(nombre),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF036799),
      appBar: AppBar(
        backgroundColor: const Color(0xFF048DD2),
        title: const Text('Subir Material Educativo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _temaSeleccionado,
                  hint: const Text('Selecciona un tema'),
                  items:
                      temasDisponibles.entries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          )
                          .toList(),
                  onChanged:
                      (value) => setState(() => _temaSeleccionado = value),
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tituloController,
                  decoration: const InputDecoration(
                    labelText: 'Título del material',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),
                TextField(
                  controller: _subtemaController,
                  decoration: const InputDecoration(
                    labelText: 'Subtema (opcional)',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 12),
                TextField(
                  controller: _descripcionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Descripción del material',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    CustomActionButton(
                      text: 'Agregar PDF',
                      icon: Icons.picture_as_pdf,
                      backgroundColor: Colors.red.shade600,
                      onPressed:
                          () => _seleccionarArchivoPorExtension(['pdf'], 'pdf'),
                    ),
                    CustomActionButton(
                      text: 'Agregar Imagen',
                      icon: Icons.image,
                      backgroundColor: Colors.blue.shade700,
                      onPressed:
                          () => _seleccionarArchivoPorExtension([
                            'jpg',
                            'jpeg',
                            'png',
                          ], 'image'),
                    ),
                    CustomActionButton(
                      text: 'Agregar Video',
                      icon: Icons.videocam,
                      backgroundColor: Colors.deepOrange.shade700,
                      onPressed:
                          () =>
                              _seleccionarArchivoPorExtension(['mp4'], 'video'),
                    ),
                    CustomActionButton(
                      text: 'Agregar Audio',
                      icon: Icons.audiotrack,
                      backgroundColor: Colors.purple.shade800,
                      onPressed:
                          () =>
                              _seleccionarArchivoPorExtension(['mp3'], 'audio'),
                    ),
                    CustomActionButton(
                      text: 'Agregar Enlace',
                      icon: Icons.link,
                      backgroundColor: Colors.green.shade700,
                      onPressed: _agregarEnlace,
                    ),
                    CustomActionButton(
                      text: 'Agregar Nota',
                      icon: Icons.notes,
                      backgroundColor: Colors.indigo.shade700,
                      onPressed: _agregarNota,
                    ),
                  ],
                ),

                // Wrap(
                //   spacing: 10,
                //   runSpacing: 10,
                //   children: [
                //     ElevatedButton.icon(
                //       onPressed: () => _seleccionarArchivo('pdf'),
                //       icon: const Icon(Icons.picture_as_pdf),
                //       label: const Text('Agregar PDF'),
                //     ),
                //     ElevatedButton.icon(
                //       onPressed: () => _seleccionarArchivo('image'),
                //       icon: const Icon(Icons.image),
                //       label: const Text('Agregar Imagen'),
                //     ),
                //     ElevatedButton.icon(
                //       onPressed: () => _seleccionarArchivo('video'),
                //       icon: const Icon(Icons.videocam),
                //       label: const Text('Agregar Video'),
                //     ),
                //     ElevatedButton.icon(
                //       onPressed: _agregarEnlace,
                //       icon: const Icon(Icons.link),
                //       label: const Text('Agregar Enlace'),
                //     ),
                //     ElevatedButton.icon(
                //       onPressed: _agregarNota,
                //       icon: const Icon(Icons.notes),
                //       label: const Text('Agregar Nota'),
                //     ),
                //   ],
                // ),
                const SizedBox(height: 20),
                // TextField(
                //   controller: _notaController,
                //   maxLines: 3,
                //   decoration: const InputDecoration(
                //     hintText: 'Escribe una nota para agregarla...',
                //     filled: true,
                //     fillColor: Colors.white,
                //     border: OutlineInputBorder(),
                //   ),
                // ),
                // const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Vista previa:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _archivos.length,
                    itemBuilder:
                        (context, index) =>
                            _buildArchivoPreview(_archivos[index]),
                  ),
                ),

                const SizedBox(height: 12),

                // ElevatedButton.icon(
                //   onPressed: _subiendo ? null : _subirMaterialEducativo,
                //   icon:
                //       _subiendo
                //           ? const SizedBox(
                //             width: 20,
                //             height: 20,
                //             child: CircularProgressIndicator(
                //               strokeWidth: 2,
                //               color: Colors.white,
                //             ),
                //           )
                //           : const Icon(Icons.upload),
                //   label: Text(_subiendo ? 'Subiendo...' : 'Subir a Firestore'),
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.black,
                //     foregroundColor: Colors.white,
                //     padding: const EdgeInsets.symmetric(
                //       horizontal: 40,
                //       vertical: 14,
                //     ),
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(30),
                //     ),
                //   ),
                // ),
                // Stack(
                //   alignment: Alignment.centerRight,
                //   children: [
                //     CustomActionButton(
                //       text: _subiendo ? 'Subiendo...' : 'Subir',
                //       icon: Icons.upload,
                //       onPressed: () {
                //         if (!_subiendo) _subirMaterialEducativo();
                //       },
                //       reserveLoaderSpace: _subiendo,
                //       animar: _subiendo,
                //       girarIcono: _subiendo,
                //       backgroundColor:
                //           _subiendo ? Colors.grey.shade800 : Colors.black,
                //     ),
                //     if (_subiendo)
                //       const Positioned(
                //         right: 20,
                //         child: SizedBox(
                //           width: 16,
                //           height: 16,
                //           child: CircularProgressIndicator(
                //             strokeWidth: 2,
                //             color: Colors.white,
                //           ),
                //         ),
                //       ),
                //   ],
                // ),
                AnimatedScale(
                  scale: _exitoAlSubir ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  child: CustomActionButton(
                    text:
                        _subiendo
                            ? 'Subiendo...'
                            : _exitoAlSubir
                            ? '¡Subido!'
                            : 'Subir',
                    icon:
                        _subiendo
                            ? Icons.hourglass_top
                            : _exitoAlSubir
                            ? Icons.check_circle_outline
                            : Icons.upload,
                    onPressed: () {
                      if (!_subiendo && !_exitoAlSubir) {
                        _subirMaterialEducativo();
                      }
                    },
                    backgroundColor:
                        _exitoAlSubir
                            ? Colors.green.shade600
                            : (_subiendo ? Colors.grey.shade800 : Colors.black),
                    reserveLoaderSpace: _subiendo,
                    animar: _subiendo,
                    girarIcono: _subiendo,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
