//todo Darle major presentacion, agregar imagenes, y mejorar el diseño
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui; // Asegúrate que esto es ui_web y no dart:ui
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:screenshot/screenshot.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'package:study_connect/widgets/widgets.dart';
import 'package:study_connect/utils/utils.dart';
import 'package:study_connect/config/secrets.dart';

//  Para la funcionalidad de compartir avanzada
import 'package:path_provider/path_provider.dart'; // Necesario para guardar imagen en móvil
import 'dart:io'; // Necesario para File
import 'package:flutter/foundation.dart'
    show kIsWeb; // Para diferenciar entre web y móvil

class MaterialViewPage extends StatefulWidget {
  final String tema;
  final String materialId;
  const MaterialViewPage({
    super.key,
    required this.tema,
    required this.materialId,
  });

  @override
  State<MaterialViewPage> createState() => _MaterialViewPageState();
}

class _MaterialViewPageState extends State<MaterialViewPage> {
  final ScreenshotController _screenshotController = ScreenshotController();
  Map<String, dynamic>? materialData;
  List<String> pasos = [];
  List<String> descripciones = [];
  List<Map<String, dynamic>> comentarios = [];
  final currentUser = FirebaseAuth.instance.currentUser;

  List<Map<String, dynamic>> versiones = [];
  String? versionSeleccionada;

  final Set<String> _registeredViewFactories = {};

  Map<String, List<Map<String, dynamic>>> agruparArchivosPorTipo(
    List archivos,
  ) {
    final Map<String, List<Map<String, dynamic>>> agrupados = {};
    for (final archivo in archivos) {
      final tipo = archivo['tipo'] ?? 'otro';
      if (!agrupados.containsKey(tipo)) {
        agrupados[tipo] = [];
      }
      agrupados[tipo]!.add(archivo);
    }
    return agrupados;
  }

  String obtenerNombreTema(String key) {
    final Map<String, String> nombresTemas = {
      'FnAlg': 'Funciones algebraicas y trascendentes',
      'Lim': 'Límites de funciones y continuidad',
      'Der': 'Derivada y optimización',
      'TecInteg': 'Técnicas de integración',
    };
    return nombresTemas[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarDatosDesdeFirestore() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('materiales')
              .doc(widget.tema)
              .collection('Mat${widget.tema}')
              .doc(widget.materialId)
              .get();

      if (!doc.exists) {
        throw Exception('Documento no encontrado');
      }

      final versionId = doc['versionActual'];
      final version =
          await doc.reference.collection('Versiones').doc(versionId).get();

      setState(() {
        materialData = doc.data();
        if (version.exists && version.data() != null) {
          pasos = List<String>.from(version.data()!['PasosEjer'] ?? []);
          descripciones = List<String>.from(version.data()!['DescPasos'] ?? []);
          materialData!['archivos'] = List<Map<String, dynamic>>.from(
            version.data()!['archivos'] ?? [],
          );
          materialData!['descripcion'] = version.data()!['Descripcion'] ?? '';
        } else {
          pasos = [];
          descripciones = [];
        }
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
        .collection('materiales')
        .doc(widget.tema)
        .collection('Mat${widget.tema}')
        .doc(widget.materialId);

    final versionDoc =
        await docRef.collection('Versiones').doc(versionId).get();

    if (versionDoc.exists) {
      final versionData = versionDoc.data();
      setState(() {
        materialData = {
          ...?materialData,
          'archivos': List<Map<String, dynamic>>.from(
            versionData?['archivos'] ?? [],
          ),
          'descripcion': versionData?['Descripcion'] ?? '',
          'PasosEjer': List<String>.from(versionData?['PasosEjer'] ?? []),
          'DescPasos': List<String>.from(versionData?['DescPasos'] ?? []),
        };
        pasos = List<String>.from(versionData?['PasosEjer'] ?? []);
        descripciones = List<String>.from(versionData?['DescPasos'] ?? []);
        versionSeleccionada = versionId;
      });
    }
  }

  Future<void> _cargarComentarios() async {
    try {
      final snap =
          await FirebaseFirestore.instance
              .collection('comentarios_materiales')
              .where('materialId', isEqualTo: widget.materialId)
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
              .collection('comentarios_materiales')
              .where('usuarioId', isEqualTo: comentario['usuarioId'])
              .where('comentario', isEqualTo: comentario['comentario'])
              .where('timestamp', isEqualTo: comentario['timestamp'])
              .get();

      for (final doc in query.docs) {
        await doc.reference.delete();
      }

      await _cargarTodo();

      if (mounted) {
        showFeedbackDialogAndSnackbar(
          context: context,
          titulo: '¡Éxito!',
          mensaje: 'Comentario elimnado correctamente.',
          tipo: CustomDialogType.success,
          snackbarMessage: '✅ ¡Comentario Eliminado!',
          snackbarSuccess: true,
        );
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
      }
    }
  }

  Future<void> _cargarTodo() async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('materiales')
          .doc(widget.tema)
          .collection('Mat${widget.tema}')
          .doc(widget.materialId);

      final results = await Future.wait([
        docRef.get(),
        FirebaseFirestore.instance
            .collection('comentarios_materiales')
            .where('tema', isEqualTo: widget.tema)
            .where('materialId', isEqualTo: widget.materialId)
            .orderBy('timestamp', descending: true)
            .get(),
        docRef.collection('Versiones').orderBy('Fecha', descending: true).get(),
      ]);

      final docSnap = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final comentariosSnap = results[1] as QuerySnapshot<Map<String, dynamic>>;
      final versionesSnap = results[2] as QuerySnapshot<Map<String, dynamic>>;

      if (!docSnap.exists) throw Exception('Material no encontrado');

      final String versionActualId =
          docSnap.data()?['versionActual'] ??
          (versionesSnap.docs.isNotEmpty ? versionesSnap.docs.first.id : null);

      Map<String, dynamic> versionDataActual = {};
      if (versionActualId != null) {
        final versionActualDoc =
            await docRef.collection('Versiones').doc(versionActualId).get();
        if (versionActualDoc.exists) {
          versionDataActual = versionActualDoc.data()!;
        }
      }

      setState(() {
        materialData = {
          ...docSnap.data()!,
          'archivos': List<Map<String, dynamic>>.from(
            versionDataActual['archivos'] ?? [],
          ),
          'descripcion': versionDataActual['Descripcion'] ?? '',
          'PasosEjer': List<String>.from(versionDataActual['PasosEjer'] ?? []),
          'DescPasos': List<String>.from(versionDataActual['DescPasos'] ?? []),
        };

        pasos = List<String>.from(versionDataActual['PasosEjer'] ?? []);
        descripciones = List<String>.from(versionDataActual['DescPasos'] ?? []);

        comentarios = comentariosSnap.docs.map((d) => d.data()).toList();
        versiones =
            versionesSnap.docs
                .map((d) => {'id': d.id, 'fecha': d['Fecha'] as Timestamp})
                .toList();
        versionSeleccionada = versionActualId;
      });
    } catch (e) {
      print("Error en _cargarTodo: $e");
      _mostrarError('Error al cargar datos', e.toString());
    }
  }

  void _showMaterialSharingOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            children: <Widget>[
              const ListTile(
                title: Text(
                  'Compartir Material',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.facebook, color: Color(0xFF1877F2)),
                title: const Text('Publicar en Facebook'),
                onTap: () {
                  Navigator.pop(context);
                  if (materialData != null) {
                    _compartirCapturaYFacebook(
                      materialData!['titulo'] ?? 'Material',
                      widget.tema,
                      widget.materialId,
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.image_outlined,
                  color: Colors.blueAccent,
                ),
                title: const Text('Compartir con Imagen'),
                onTap: () {
                  Navigator.pop(context);
                  _shareMaterial(withImage: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.link_outlined, color: Colors.green),
                title: const Text('Compartir solo Enlace'),
                onTap: () {
                  Navigator.pop(context);
                  _shareMaterial(withImage: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_outlined, color: Colors.grey),
                title: const Text('Copiar Enlace'),
                onTap: () {
                  Navigator.pop(context);
                  _copyMaterialLinkToClipboard();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _shareMaterial({bool withImage = false}) async {
    if (materialData == null) {
      showCustomSnackbar(
        context: context,
        message: 'Datos del material no cargados.',
        success: false,
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final titulo = materialData!['titulo'] ?? 'Material interesante';
      final nombreTema = obtenerNombreTema(widget.tema);

      final url =
          'https://study-connect.app/material/${widget.tema}/${widget.materialId}';
      final textoACompartir =
          '📚 ¡Mira este material sobre "$nombreTema" en Study Connect!\n\n$titulo\n\nEncuéntralo aquí:\n$url';

      XFile? imageFile;
      if (withImage) {
        final Uint8List? imageBytes = await _screenshotController.capture();
        if (imageBytes != null) {
          if (kIsWeb) {
            imageFile = XFile.fromData(
              imageBytes,
              name: 'material.png',
              mimeType: 'image/png',
            );
          } else {
            final tempDir = await getTemporaryDirectory();
            final file = await File(
              '${tempDir.path}/material.png',
            ).writeAsBytes(imageBytes);
            imageFile = XFile(file.path);
          }
        }
      }

      if (!mounted) return;
      Navigator.pop(context);

      if (imageFile != null) {
        await Share.shareXFiles(
          [imageFile],
          text: textoACompartir,
          subject: 'Material de Study Connect: $titulo',
        );
      } else {
        await Share.share(
          textoACompartir,
          subject: 'Material de Study Connect: $titulo',
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      showCustomSnackbar(
        context: context,
        message: 'Error al intentar compartir: $e',
        success: false,
      );
    }
  }

  void _copyMaterialLinkToClipboard() {
    if (materialData == null) return;
    final url =
        'https://study-connect.app/material/${widget.tema}/${widget.materialId}';
    Clipboard.setData(ClipboardData(text: url)).then((_) {
      showCustomSnackbar(
        context: context,
        message: '✅ Enlace del material copiado',
        success: true,
      );
    });
  }

  Future<String?> obtenerTituloVideoYoutube(String videoIdParam) async {
    final videoId = videoIdParam;

    if (videoId.isEmpty) {
      print('Error: videoId está vacío en obtenerTituloVideoYoutube.');
      return null;
    }

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

  Widget _buildVistaArchivo(Map<String, dynamic> archivo, double screenWidth) {
    final tipo = archivo['tipo'];
    final nombre = archivo['nombre'] ?? 'Archivo';
    final url =
        tipo == 'link' ? archivo['contenido'] ?? '' : archivo['url'] ?? '';
    final bool esMp3 =
        (archivo['extension'] ?? '').toString().toLowerCase() == 'mp3';
    final bool esMp4 =
        (archivo['extension'] ?? '').toString().toLowerCase() == 'mp4';

    final dimensiones = obtenerDimensionesMultimedia(screenWidth);

    if (tipo == 'pdf' || tipo == 'word' || tipo == 'excel' || tipo == 'ppt') {
      IconData icono = Icons.insert_drive_file;
      Color color = Colors.grey;

      switch (tipo) {
        case 'pdf':
          icono = Icons.picture_as_pdf;
          color = Colors.red;
          break;
        case 'word':
          icono = Icons.description;
          color = Colors.blue;
          break;
        case 'excel':
          icono = Icons.table_chart;
          color = Colors.green;
          break;
        case 'ppt':
          icono = Icons.slideshow;
          color = Colors.orange;
          break;
      }

      return ListTile(
        leading: Icon(icono, color: color),
        title: Text(nombre),
        trailing: IconButton(
          icon: const Icon(Icons.open_in_new),
          onPressed: () => html.window.open(url, '_blank'),
        ),
      );
    }

    if (tipo == 'image') {
      return Card(
        margin: EdgeInsets.symmetric(vertical: dimensiones['margen']),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(dimensiones['radio']),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(dimensiones['radio']),
              ),
              child: Center(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  height: dimensiones['altura'],
                  width: double.infinity,
                  loadingBuilder: (
                    BuildContext context,
                    Widget child,
                    ImageChunkEvent? loadingProgress,
                  ) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      height: dimensiones['altura'],
                      width: double.infinity,
                      child: Center(
                        child: CircularProgressIndicator(
                          value:
                              loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (
                    BuildContext context,
                    Object exception,
                    StackTrace? stackTrace,
                  ) {
                    return Container(
                      height: dimensiones['altura'],
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey[400],
                          size: 48,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.blue),
              title: Text(nombre, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(Icons.open_in_new),
                onPressed: () => html.window.open(url, '_blank'),
              ),
            ),
          ],
        ),
      );
    }

    if (tipo == 'video' || esMp4) {
      final viewId = 'video-${url.hashCode}';

      if (!_registeredViewFactories.contains(viewId)) {
        ui.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
          final container =
              html.DivElement()
                ..style.width = '100%'
                ..style.height = '100%'
                ..style.backgroundColor = 'black'
                ..style.display = 'flex'
                ..style.alignItems = 'center'
                ..style.justifyContent = 'center';

          final videoElement =
              html.VideoElement()
                ..src = url
                ..controls = true
                ..autoplay = false
                ..style.width = '100%'
                ..style.height = 'auto'
                ..style.maxWidth = '100%'
                ..style.maxHeight = '100%';

          container.append(videoElement);
          return container;
        });
        _registeredViewFactories.add(viewId);
      }

      return Card(
        margin: EdgeInsets.symmetric(vertical: dimensiones['margen']),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(dimensiones['radio']),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.orange),
              title: Text(nombre, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(
                  Icons.open_in_new_rounded,
                  color: Colors.blueGrey,
                ),
                tooltip: "Abrir en nueva pestaña",
                onPressed: () => html.window.open(url, '_blank'),
              ),
            ),
            Container(
              height: dimensiones['altura'],
              width: double.infinity,
              color: Colors.black,
              child: HtmlElementView(viewType: viewId),
            ),
          ],
        ),
      );
    }

    if (tipo == 'audio' || esMp3) {
      final viewId = 'audio-${url.hashCode}';

      if (!_registeredViewFactories.contains(viewId)) {
        ui.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
          final audio =
              html.AudioElement()
                ..src = url
                ..controls = true
                ..style.width = '100%';
          return audio;
        });
        _registeredViewFactories.add(viewId);
      }

      return Card(
        margin: EdgeInsets.symmetric(vertical: dimensiones['margen'] / 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(dimensiones['radio'] / 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.audiotrack, color: Colors.pink),
              title: Text(nombre, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(
                  Icons.open_in_new_rounded,
                  color: Colors.blueGrey,
                ),
                tooltip: "Abrir en nueva pestaña",
                onPressed: () => html.window.open(url, '_blank'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: SizedBox(
                height: 50,
                child: HtmlElementView(viewType: viewId),
              ),
            ),
          ],
        ),
      );
    }

    if (tipo == 'link') {
      final isYoutubeUrlPattern = RegExp(
        r'youtube\.com/watch\?v=|youtu\.be/|googleusercontent\.com/youtube\.com/\d+',
      );
      final bool isYoutube = isYoutubeUrlPattern.hasMatch(url);

      if (isYoutube) {
        String videoId = '';
        try {
          final Uri uri = Uri.parse(url);
          if (uri.host.contains('youtube.com') &&
              uri.queryParameters.containsKey('v')) {
            videoId = uri.queryParameters['v']!;
          } else if (uri.host.contains('youtu.be')) {
            videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
          } else if (uri.host.contains('googleusercontent.com') &&
              uri.path.contains('youtube.com')) {
            final potentialId = uri.pathSegments.lastWhere(
              (s) => s.length == 11 && !s.contains('.'),
              orElse: () => '',
            );
            if (potentialId.isNotEmpty) {
              videoId = potentialId;
            } else if (uri.queryParameters.containsKey('v')) {
              videoId = uri.queryParameters['v']!;
            }
          }

          if (videoId.isNotEmpty) {
            if (videoId.contains('?')) videoId = videoId.split('?').first;
            if (videoId.contains('&')) videoId = videoId.split('&').first;
            if (videoId.contains('#')) videoId = videoId.split('#').first;
          }
        } catch (e) {
          print("Error extrayendo videoId de URL ($url): $e");
          videoId = '';
        }

        final String thumbnailUrl;
        if (RegExp(r"^[a-zA-Z0-9_-]{11}$").hasMatch(videoId)) {
          thumbnailUrl = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
        } else {
          thumbnailUrl =
              'https://via.placeholder.com/480x360.png?text=Enlace+YouTube';
          if (url.isNotEmpty && videoId.isNotEmpty) {
            print(
              "Miniatura YT: videoId ('$videoId') extraído de '$url' no parece válido (no tiene 11 caracteres).",
            );
          } else if (url.isNotEmpty && videoId.isEmpty) {
            print("Miniatura YT: No se pudo extraer videoId de '$url'.");
          }
        }

        return FutureBuilder<String?>(
          future: obtenerTituloVideoYoutube(videoId),
          builder: (context, snapshot) {
            final tituloVideo =
                snapshot.data ??
                (snapshot.connectionState == ConnectionState.waiting
                    ? "Cargando título..."
                    : (videoId.isNotEmpty ? 'Video de YouTube' : 'Enlace'));

            return Card(
              margin: EdgeInsets.symmetric(vertical: dimensiones['margen']),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(dimensiones['radio']),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(
                    thumbnailUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: dimensiones['altura'] * 0.8,
                    loadingBuilder: (
                      BuildContext context,
                      Widget child,
                      ImageChunkEvent? loadingProgress,
                    ) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: dimensiones['altura'] * 0.8,
                        width: double.infinity,
                        color: Colors.grey[800],
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.white54,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (
                      BuildContext context,
                      Object exception,
                      StackTrace? stackTrace,
                    ) {
                      print(
                        "Error al cargar miniatura de YouTube para videoId '$videoId' desde '$thumbnailUrl': $exception",
                      );
                      return Container(
                        height: dimensiones['altura'] * 0.8,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: Center(
                          child: Icon(
                            Icons.ondemand_video,
                            color: Colors.grey[500],
                            size: 48,
                            semanticLabel: "Error al cargar miniatura",
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.play_circle_fill_rounded,
                      color: Colors.red,
                      size: 32,
                    ),
                    title: Text(
                      tituloVideo,
                      style: TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      url,
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: ElevatedButton.icon(
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Ver'),
                      onPressed: () => html.window.open(url, '_blank'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        textStyle: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      } else {
        return Card(
          margin: EdgeInsets.symmetric(vertical: dimensiones['margen'] / 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(dimensiones['radio'] / 1.5),
          ),
          child: ListTile(
            leading: Icon(Icons.link_rounded, color: Colors.teal, size: 30),
            title: Text(
              nombre != 'Archivo' ? nombre : url,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle:
                nombre != 'Archivo'
                    ? Text(
                      url,
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    )
                    : null,
            trailing: IconButton(
              icon: const Icon(Icons.open_in_new_rounded),
              tooltip: "Abrir enlace",
              onPressed: () => html.window.open(url, '_blank'),
            ),
          ),
        );
      }
    }

    if (tipo == 'nota') {
      return Card(
        margin: EdgeInsets.symmetric(vertical: dimensiones['margen']),
        color: const Color(0xFFFFF9C4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(dimensiones['radio']),
          side: BorderSide(color: Colors.amber[300]!, width: 1),
        ),
        child: ListTile(
          leading: Icon(
            Icons.notes_rounded,
            color: Colors.orange[700],
            size: 30,
          ),
          title: Text(nombre, style: TextStyle(fontWeight: FontWeight.w500)),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: dimensiones['margen'] / 2),
      child: ListTile(
        leading: const Icon(Icons.attach_file_rounded),
        title: Text(nombre),
        subtitle:
            url.isNotEmpty
                ? Text(
                  url,
                  style: TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                )
                : null,
        trailing:
            url.isNotEmpty
                ? IconButton(
                  icon: const Icon(Icons.open_in_new_rounded),
                  onPressed: () => html.window.open(url, '_blank'),
                )
                : null,
      ),
    );
  }

  Map<String, dynamic> obtenerDimensionesMultimedia(double width) {
    if (width <= 480) {
      return {'altura': 200.0, 'margen': 8.0, 'radio': 10.0};
    } else if (width <= 800) {
      return {'altura': 240.0, 'margen': 10.0, 'radio': 12.0};
    } else if (width <= 1200) {
      return {'altura': 280.0, 'margen': 12.0, 'radio': 14.0};
    } else if (width <= 1900) {
      return {'altura': 320.0, 'margen': 16.0, 'radio': 16.0};
    } else {
      return {'altura': 350.0, 'margen': 20.0, 'radio': 18.0};
    }
  }

  Widget _columnaIzquierda({
    required Map<String, dynamic> ejercicioData,
    required String tema,
    required String materialId,
    required List<Map<String, dynamic>> versiones,
    required String? versionSeleccionada,
    required List<Map<String, dynamic>> comentarios,
    required void Function(String) onVersionChanged,
    required bool esMovil,
  }) {
    final autor = ejercicioData['autorNombre'] ?? 'Anónimo';
    final fecha = (ejercicioData['FechMod'] as Timestamp?)?.toDate();
    final calificacion = calcularPromedioEstrellas(comentarios);
    final Map<String, String> nombresTemas = {
      'FnAlg': 'Funciones algebraicas y trascendentes',
      'Lim': 'Límites de funciones y continuidad',
      'Der': 'Derivada y optimización',
      'TecInteg': 'Técnicas de integración',
    };
    final currentUser = FirebaseAuth.instance.currentUser;
    final esAutor =
        currentUser != null &&
        ejercicioData['autorId'] != null &&
        ejercicioData['autorId'] == currentUser.uid;

    return Container(
      // margin: const EdgeInsets.only(right: 16), // Eliminado para que el SizedBox en Row controle el espacio
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF055B84),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
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
          ),
          const SizedBox(height: 8),
          InfoWithIcon(
            icon: Icons.book,
            text: 'Tema: ${nombresTemas[tema] ?? tema}',
            alignment: MainAxisAlignment.center,
            iconAlignment: Alignment.center,
            textColor: Colors.white,
            textSize: 17,
          ),
          const SizedBox(height: 8),
          InfoWithIcon(
            icon: Icons.assignment,
            text: 'Ejercicio: $materialId',
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
              child: Semantics(
                label: 'Seleccionar la versión para calificar el ejercicio',
                child: CustomDropdownVersiones(
                  versionSeleccionada: versionSeleccionada,
                  versiones: versiones,
                  onChanged: (value) {
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
            size: 30,
            color: Colors.amber,
            duration: const Duration(milliseconds: 800),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '${calificacion.toStringAsFixed(1)} / 5.0',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const Divider(color: Colors.white54, height: 20, thickness: 0.5),
          Center(
            child: Text(
              '${comentarios.length} comentario(s)',
              style: const TextStyle(color: Colors.white60),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            // Mantenido SizedBox para controlar altura explícitamente
            height: esMovil ? 180 : 230,
            width: double.infinity,
            child: const ExerciseCarousel(),
          ),
          const SizedBox(height: 16),
          if (esAutor)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Wrap(
                // Mantenido Wrap para robustez de los botones
                alignment: WrapAlignment.center,
                spacing: esMovil ? 8.0 : 12.0,
                runSpacing: 8.0,
                children: [
                  ElevatedButton.icon(
                    onPressed: _editarMaterial,
                    icon: Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: esMovil ? 20 : 24,
                    ),
                    label:
                        esMovil
                            ? const SizedBox.shrink()
                            : const Text("Editar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: EdgeInsets.symmetric(
                        horizontal: esMovil ? 10 : 16,
                        vertical: esMovil ? 8 : 10,
                      ),
                      textStyle: TextStyle(fontSize: esMovil ? 12 : 14),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _agregarNuevaVersion,
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: Colors.white,
                      size: esMovil ? 20 : 24,
                    ),
                    label:
                        esMovil
                            ? const SizedBox.shrink()
                            : const Text("Nueva versión"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      padding: EdgeInsets.symmetric(
                        horizontal: esMovil ? 10 : 16,
                        vertical: esMovil ? 8 : 10,
                      ),
                      textStyle: TextStyle(fontSize: esMovil ? 12 : 14),
                    ),
                  ),
                  Builder(
                    builder: (buttonContext) {
                      return ElevatedButton.icon(
                        onPressed: () {
                          _mostrarOpcionesEliminarMaterial(buttonContext);
                        },
                        icon: Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: esMovil ? 20 : 24,
                        ),
                        label:
                            esMovil
                                ? const SizedBox.shrink()
                                : const Text("Eliminar"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: EdgeInsets.symmetric(
                            horizontal: esMovil ? 10 : 16,
                            vertical: esMovil ? 8 : 10,
                          ),
                          textStyle: TextStyle(fontSize: esMovil ? 12 : 14),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _editarMaterial() {
    Navigator.pushNamed(
      context,
      '/upload_material',
      arguments: {
        'tema': widget.tema,
        'materialId': widget.materialId,
        'editar': true,
      },
    );
  }

  void _mostrarOpcionesEliminarMaterial(BuildContext buttonContext) {
    if (materialData == null || versionSeleccionada == null) {
      showCustomSnackbar(
        context: context,
        message: 'Datos del material no cargados completamente.',
        success: false,
      );
      return;
    }

    final RenderBox button = buttonContext.findRenderObject() as RenderBox;
    final Offset offset = button.localToGlobal(Offset.zero);

    final RelativeRect position = RelativeRect.fromLTRB(
      offset.dx,
      offset.dy + button.size.height + 5,
      offset.dx + button.size.width,
      offset.dy + button.size.height * 2,
    );

    showMenu<String>(
      context: context,
      position: position,
      color: Colors.white,
      elevation: 8.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: <PopupMenuEntry<String>>[
        if (versiones.length > 1)
          PopupMenuItem<String>(
            value: 'version',
            child: ListTile(
              leading: Icon(
                Icons.file_copy_outlined,
                color: Colors.orangeAccent[700],
              ),
              title: Text(
                'Eliminar esta versión (${versionSeleccionada ?? ""})',
                style: TextStyle(fontSize: 15),
              ),
            ),
          ),
        PopupMenuItem<String>(
          value: 'material',
          child: ListTile(
            leading: Icon(
              Icons.delete_forever_rounded,
              color: Colors.redAccent[700],
            ),
            title: Text(
              versiones.length <= 1
                  ? 'Eliminar material completo'
                  : 'Eliminar material (y todas sus versiones)',
              style: TextStyle(fontSize: 15),
            ),
          ),
        ),
      ],
    ).then((String? value) {
      if (value == null) return;

      if (value == 'version') {
        _confirmarEliminarSoloVersionMaterial();
      } else if (value == 'material') {
        _confirmarEliminarMaterialCompleto();
      }
    });
  }

  Future<void> _confirmarEliminarSoloVersionMaterial() async {
    if (versionSeleccionada == null) {
      showCustomSnackbar(
        context: context,
        message: 'No hay una versión seleccionada para eliminar.',
        success: false,
      );
      return;
    }

    final confirmar = await showCustomDialog<bool>(
      context: context,
      titulo: 'Eliminar Versión del Material',
      mensaje:
          '¿Deseas eliminar la versión seleccionada ($versionSeleccionada) de este material? Esta acción no se puede deshacer.',
      tipo: CustomDialogType.warning,
      botones: [
        DialogButton(texto: 'Cancelar', value: false),
        DialogButton(
          texto: 'Eliminar Versión',
          value: true,
          textColor: Colors.redAccent,
        ),
      ],
    );

    if (confirmar == true) {
      await _eliminarSoloVersionSeleccionadaMaterial();
    }
  }

  Future<void> _eliminarSoloVersionSeleccionadaMaterial() async {
    if (versionSeleccionada == null || materialData == null) return;

    final materialDocRef = FirebaseFirestore.instance
        .collection('materiales')
        .doc(widget.tema)
        .collection('Mat${widget.tema}')
        .doc(widget.materialId);

    final versionRef = materialDocRef
        .collection('Versiones')
        .doc(versionSeleccionada);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await versionRef.delete();

      if (materialData!['versionActual'] == versionSeleccionada) {
        final versionesRestantesSnap =
            await materialDocRef
                .collection('Versiones')
                .orderBy('Fecha', descending: true)
                .get();

        if (versionesRestantesSnap.docs.isNotEmpty) {
          final nuevaVersionActualDoc = versionesRestantesSnap.docs.first;
          await materialDocRef.update({
            'versionActual': nuevaVersionActualDoc.id,
            'FechMod': nuevaVersionActualDoc['Fecha'],
          });
        } else {
          await materialDocRef.delete();
          if (mounted) Navigator.pop(context);
          if (mounted) Navigator.pop(context, 'eliminado_completo');
          showCustomSnackbar(
            context: context,
            message: 'Material eliminado ya que no quedaban versiones.',
            success: true,
          );
          return;
        }
      }

      if (mounted) Navigator.pop(context);

      showCustomSnackbar(
        context: context,
        message: '✅ Versión eliminada correctamente.',
        success: true,
      );

      await _cargarTodo();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      print('Error al eliminar versión del material: $e');
      _mostrarError('Error al eliminar versión', e.toString());
    }
  }

  void _confirmarEliminarMaterialCompleto() async {
    final confirm = await showCustomDialog<bool>(
      context: context,
      titulo: '¿Eliminar Material Completo?',
      mensaje:
          'Esta acción eliminará permanentemente este material y TODAS sus versiones. ¿Estás seguro?',
      tipo: CustomDialogType.warning,
      botones: [
        DialogButton<bool>(texto: 'Cancelar', value: false),
        DialogButton<bool>(
          texto: 'Eliminar TODO',
          value: true,
          textColor: Colors.red,
        ),
      ],
    );
    if (confirm == true) {
      await _ejecutarEliminacionMaterialCompleto();
    }
  }

  Future<void> _ejecutarEliminacionMaterialCompleto() async {
    if (materialData == null) return;

    final materialDocRef = FirebaseFirestore.instance
        .collection('materiales')
        .doc(widget.tema)
        .collection('Mat${widget.tema}')
        .doc(widget.materialId);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final versionesSnap = await materialDocRef.collection('Versiones').get();
      for (final versionDoc in versionesSnap.docs) {
        await versionDoc.reference.delete();
      }

      await materialDocRef.delete();

      final comentariosSnap =
          await FirebaseFirestore.instance
              .collection('comentarios_materiales')
              .where('materialId', isEqualTo: widget.materialId)
              .where('tema', isEqualTo: widget.tema)
              .get();
      for (final comentarioDoc in comentariosSnap.docs) {
        await comentarioDoc.reference.delete();
      }

      final autorId = materialData!['autorId'];
      if (autorId != null && autorId.toString().isNotEmpty) {
        final usuarioRef = FirebaseFirestore.instance
            .collection('usuarios')
            .doc(autorId);
        await usuarioRef.update({
          'materialesSubidos': FieldValue.increment(-1),
        });
      }

      if (mounted) Navigator.pop(context);

      showCustomSnackbar(
        context: context,
        message: 'Material completo eliminado con éxito.',
        success: true,
      );

      if (mounted) Navigator.pop(context, 'eliminado_completo');
    } catch (e) {
      if (mounted) Navigator.pop(context);
      print('Error al eliminar material completo: $e');
      _mostrarError('Error al eliminar material', e.toString());
    }
  }

  Future<void> _eliminarMaterial() async {
    try {
      final ref = FirebaseFirestore.instance
          .collection('materiales')
          .doc(widget.tema)
          .collection('Mat${widget.tema}')
          .doc(widget.materialId);
      await ref.delete();

      final comentariosAssociated =
          await FirebaseFirestore.instance
              .collection('comentarios_materiales')
              .where('materialId', isEqualTo: widget.materialId)
              .where('tema', isEqualTo: widget.tema)
              .get();
      for (final c in comentariosAssociated.docs) {
        await c.reference.delete();
      }

      showCustomSnackbar(
        context: context,
        message: 'Material eliminado.',
        success: true,
      );

      Navigator.pop(context);
    } catch (e) {
      showCustomSnackbar(
        context: context,
        message: 'Error al eliminar: $e',
        success: false,
      );
    }
  }

  void _agregarNuevaVersion() {
    Navigator.pushNamed(
      context,
      '/upload_material',
      arguments: {
        'tema': widget.tema,
        'materialId': widget.materialId,
        'nuevaVersion': true,
      },
    );
  }

  Widget _columnaDerecha({
    required Map<String, dynamic> materialData,
    required List<Map<String, dynamic>> comentarios,
    required bool esPantallaChica,
    required double screenWidth,
  }) {
    final titulo = materialData['titulo'] ?? '';
    final descripcion = materialData['descripcion'] ?? '';
    final List archivos = materialData['archivos'] ?? [];
    final Map<String, List<Map<String, dynamic>>> agrupados =
        agruparArchivosPorTipo(archivos);
    final Map<String, IconData> iconosTipo = {
      'pdf': Icons.picture_as_pdf_rounded,
      'image': Icons.image_rounded,
      'audio': Icons.audiotrack_rounded,
      'video': Icons.videocam_rounded,
      'link': Icons.link_rounded,
      'nota': Icons.notes_rounded,
      'word': Icons.description_rounded,
      'excel': Icons.table_chart_rounded,
      'ppt': Icons.slideshow_rounded,
      'otro': Icons.attach_file_rounded,
    };
    final Map<String, String> titulosTipo = {
      'pdf': '📄 Documentos PDF',
      'image': '🖼️ Imágenes',
      'audio': '🎵 Audios',
      'video': '🎬 Videos',
      'link': '🔗 Enlaces',
      'nota': '📝 Notas',
      'word': ' W Documentos Word',
      'excel': '📊 Hojas de Cálculo',
      'ppt': '💻 Presentaciones',
      'otro': '📎 Otros Archivos',
    };

    final contenido = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Título del material:',
          style: TextStyle(
            fontSize: screenWidth < 600 ? 17 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: 8.0,
            horizontal: screenWidth < 600 ? 0 : 4,
          ),
          child: CustomLatexText(
            contenido: titulo.isNotEmpty ? titulo : "Sin título",
            fontSize: screenWidth < 600 ? 20 : 24,
            color: Colors.black87,
            prepararLatex: prepararLaTeX,
          ),
        ),
        const SizedBox(height: 16),
        const Divider(color: Colors.black54, thickness: 0.8),
        Text(
          'Descripción del material:',
          style: TextStyle(
            fontSize: screenWidth < 600 ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            dividirDescripcionEnLineas(
              descripcion.isNotEmpty ? descripcion : "Sin descripción.",
            ),
            style: TextStyle(
              fontSize: screenWidth < 600 ? 15 : 17,
              height: 1.5,
              color: Colors.black87,
            ),
            textAlign: TextAlign.justify,
          ),
        ),
        const SizedBox(height: 20),
        const Divider(color: Colors.black54, thickness: 0.8),
        Text(
          'Contenido:',
          style: TextStyle(
            fontSize: screenWidth < 600 ? 17 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        if (agrupados.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
              child: Text(
                "Este material no tiene archivos adjuntos.",
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
          )
        else
          ...agrupados.entries.map((entry) {
            final tipo = entry.key;
            final lista = entry.value;
            return ExpansionTile(
              initiallyExpanded: true,
              leading: Icon(
                iconosTipo[tipo] ?? Icons.attach_file_rounded,
                color: Colors.blueGrey[700],
                size: 28,
              ),
              title: Text(
                titulosTipo[tipo] ??
                    tipo.replaceFirst(tipo[0], tipo[0].toUpperCase()),
                style: TextStyle(
                  fontSize: screenWidth < 600 ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              childrenPadding: EdgeInsets.only(
                left: screenWidth < 600 ? 8 : 16,
                bottom: 8,
              ),
              children:
                  lista
                      .map<Widget>(
                        (archivo) => _buildVistaArchivo(archivo, screenWidth),
                      )
                      .toList(),
            );
          }).toList(),
        const SizedBox(height: 20),
        CustomExpansionTileComentarios(
          comentarios: comentarios,
          onEliminarComentario: (c) => _eliminarComentario(c),
        ),
        const SizedBox(height: 40),
        CustomFeedbackCard(
          accion: 'Calificar',
          numeroComentarios: comentarios.length,
          onCalificar: _mostrarDialogoCalificacion,
          onCompartir: _showMaterialSharingOptions,
        ),
      ],
    );

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
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: contenido,
      ),
    );
  }

  void _mostrarDialogoCalificacion() {
    final controller = TextEditingController();
    bool enviando = false;
    int rating = 0;
    bool comoAnonimo = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.all(24),
              content: _buildContenidoDialogo(
                controller,
                () => comoAnonimo,
                (v) => setStateDialog(() => comoAnonimo = v),
                () => rating,
                (v) => setStateDialog(() => rating = v),
                enviando,
                (v) => setStateDialog(() => enviando = v),
                dialogContext,
              ),
            );
          },
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
    BuildContext dialogContext,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Califica este material',
                    style: GoogleFonts.ebGaramond(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CustomRatingWidget(
              rating: getRating(),
              onRatingChanged: (v) => setRating(v),
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
              onChanged: (v) => setComoAnonimo(v ?? false),
              title: const Text('Comentar como anónimo'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
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
                              await showCustomDialog(
                                context: dialogContext,
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
                              controller.text.trim(),
                              getRating(),
                              getComoAnonimo(),
                            );
                            setEnviando(false);
                            Navigator.of(dialogContext).pop();
                            showCustomSnackbar(
                              context: context,
                              message: '✅ Comentario enviado exitosamente.',
                              success: true,
                            );
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

    final nombreUsuario = comoAnonimo ? 'Anónimo' : userData['Nombre'];
    final fotoUrl =
        (!comoAnonimo)
            ? (userData.data()?['FotoPerfil'] as String?) ?? user.photoURL
            : null;

    final comentario = {
      'usuarioId': user.uid,
      'nombre': nombreUsuario,
      'fotoUrl': fotoUrl,
      'comentario': texto,
      'estrellas': rating,
      'timestamp': Timestamp.now(),
      'tema': widget.tema,
      'materialId': widget.materialId,
      'modificado': false,
    };

    await FirebaseFirestore.instance
        .collection('comentarios_materiales')
        .add(comentario);

    final calSnap =
        await FirebaseFirestore.instance
            .collection('comentarios_materiales')
            .where('materialId', isEqualTo: widget.materialId)
            .where('tema', isEqualTo: widget.tema)
            .get();

    final ratings = calSnap.docs.map((d) => d['estrellas'] as int).toList();

    double promedio = 0.0;
    if (ratings.isNotEmpty) {
      promedio = ratings.reduce((a, b) => a + b) / ratings.length;
    }

    await FirebaseFirestore.instance
        .collection('materiales')
        .doc(widget.tema)
        .collection('Mat${widget.tema}')
        .doc(widget.materialId)
        .update({'calificacionPromedio': promedio});

    final materialDoc =
        await FirebaseFirestore.instance
            .collection('materiales')
            .doc(widget.tema)
            .collection('Mat${widget.tema}')
            .doc(widget.materialId)
            .get();

    final autorId = materialDoc.data()?['autorId'];

    if (autorId != null && autorId is String && autorId.trim().isNotEmpty) {
      await actualizarTodoCalculoDeUsuario(uid: autorId);
    }

    await _cargarComentarios();
    await _cargarDatosDesdeFirestore();

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
      final blob = html.Blob([image]);
      final urlBlob = html.Url.createObjectUrlFromBlob(blob);

      final link =
          html.AnchorElement(href: urlBlob)
            ..setAttribute('download', 'captura_material.png')
            ..click();

      html.Url.revokeObjectUrl(urlBlob);

      final urlEjercicio = Uri.encodeComponent(
        'https://study-connect.app/material/$tema/$ejercicioId',
      );
      final quote = Uri.encodeComponent('¡Revisa este material: $titulo!');
      final facebookUrl =
          'https://www.facebook.com/sharer/sharer.php?u=$urlEjercicio&quote=$quote';

      html.window.open(facebookUrl, '_blank');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (materialData == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF036799),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final bool esMovil = screenWidth <= 800;

    return Scaffold(
      backgroundColor: const Color(0xFF036799),
      appBar: const CustomAppBar(showBack: true),
      body: Screenshot(
        controller: _screenshotController,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1920, // Ajustado para un ancho máximo razonable
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (esMovil) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      12, // Reducido padding para móviles
                      12,
                      12,
                      0,
                    ),
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: _columnaIzquierda(
                            ejercicioData: materialData ?? {},
                            tema: widget.tema,
                            materialId: widget.materialId,
                            versiones: versiones,
                            versionSeleccionada: versionSeleccionada,
                            comentarios: comentarios,
                            onVersionChanged: (newVersion) {
                              _cargarVersionSeleccionada(newVersion);
                            },
                            esMovil: true,
                          ),
                        ),
                        const SliverPadding(padding: EdgeInsets.only(top: 16)),
                        SliverToBoxAdapter(
                          child: _columnaDerecha(
                            materialData: materialData ?? {},
                            comentarios: comentarios,
                            esPantallaChica:
                                true, // Indicador para _columnaDerecha
                            screenWidth: screenWidth,
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.only(
                            bottom: 16,
                          ), // Espacio al final
                        ),
                      ],
                    ),
                  );
                } else {
                  // Layout para pantallas más grandes (tablets en horizontal, laptops, desktops)
                  return Padding(
                    padding: const EdgeInsets.all(
                      24,
                    ), // Padding general para desktop
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1, // Columna izquierda toma 1 parte del espacio
                          child: SingleChildScrollView(
                            // Permite scroll si el contenido es alto
                            child: _columnaIzquierda(
                              ejercicioData: materialData ?? {},
                              tema: widget.tema,
                              materialId: widget.materialId,
                              versiones: versiones,
                              versionSeleccionada: versionSeleccionada,
                              comentarios: comentarios,
                              onVersionChanged: (newVersion) {
                                _cargarVersionSeleccionada(newVersion);
                              },
                              esMovil: false, // No es móvil en este layout
                            ),
                          ),
                        ),
                        const SizedBox(width: 24), // Espacio entre columnas
                        Expanded(
                          flex: 3, // Columna derecha toma 3 partes del espacio
                          child: _columnaDerecha(
                            materialData: materialData ?? {},
                            comentarios: comentarios,
                            esPantallaChica: false, // No es pantalla chica
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
