//todo Darle major presentacion, agregar imagenes, y mejorar el diseño
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui;
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

//  Para la integración con Facebook
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

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

  // bool get esAutor {
  //   if (materialData == null) return false;
  //   final autorId = materialData!['autorId'];
  //   final currentUser = FirebaseAuth.instance.currentUser;
  //   return autorId != null && currentUser != null && autorId == currentUser.uid;
  // }

  String obtenerNombreTema(String key) {
    // Usamos el mapa definido en la columna izquierda.
    // Lo ideal sería tener este mapa en un lugar central (utils) para no repetirlo.
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
        .collection('materiales')
        .doc(widget.tema)
        .collection('Mat${widget.tema}')
        .doc(widget.materialId);

    final versionDoc =
        await docRef.collection('Versiones').doc(versionId).get();

    if (versionDoc.exists) {
      final versionData = versionDoc.data();
      setState(() {
        // Aquí se actualizan solo los archivos y la descripción
        materialData = {
          ...?materialData, // Mantén los demás datos (titulo, autor, etc.)
          'archivos': List<Map<String, dynamic>>.from(
            versionData?['archivos'] ?? [],
          ),
          'descripcion': versionData?['Descripcion'] ?? '',
        };
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

      await _cargarTodo(); // recarga TODO (material + comentarios)

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

      setState(() {
        // datos
        materialData = docSnap.data()!;

        // comentarios
        comentarios = comentariosSnap.docs.map((d) => d.data()).toList();

        // versiones  mapeamos id + fecha
        versiones =
            versionesSnap.docs
                .map((d) => {'id': d.id, 'fecha': d['Fecha'] as Timestamp})
                .toList();

        // valor inicial del dropdown
        versionSeleccionada =
            versiones.isNotEmpty ? versiones.first['id'] : null;
      });
    } catch (e) {
      _mostrarError('Error al cargar datos', e.toString());
    }
  }

  ///  Muestra menú modal con opciones para compartir
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
                title: const Text('Publicar en mi Página de Facebook'),
                onTap: () {
                  Navigator.pop(context);
                  _postMaterialDirectlyToFacebook();
                },
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

  ///  Función central para compartir
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
      final nombreTema = obtenerNombreTema(
        widget.tema,
      ); // ✅ Usando la función corregida

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
      Navigator.pop(context); // Cierra diálogo de carga

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

  ///  Función para copiar enlace
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

  ///  Función para conectar con Facebook
  Future<void> _connectToFacebook() async {
    if (!mounted) return;
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      showCustomSnackbar(
        context: context,
        message: 'Debes iniciar sesión primero.',
        success: false,
      );
      return;
    }

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
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(firebaseUser.uid)
          .update({'facebookAccessToken': accessToken.tokenString});
      if (!mounted) return;
      showCustomSnackbar(
        context: context,
        message: '¡Cuenta de Facebook conectada!',
        success: true,
      );
    } else {
      if (!mounted) return;
      showCustomSnackbar(
        context: context,
        message: 'No se pudo conectar con Facebook.',
        success: false,
      );
    }
  }

  ///  Función para publicar directamente en Facebook
  Future<void> _postMaterialDirectlyToFacebook() async {
    if (!mounted) return;
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      showCustomSnackbar(
        context: context,
        message: 'Debes iniciar sesión primero.',
        success: false,
      );
      return;
    }
    if (materialData == null) {
      showCustomSnackbar(
        context: context,
        message: 'Datos del material no cargados.',
        success: false,
      );
      return;
    }

    final userDoc =
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(firebaseUser.uid)
            .get();
    final String? userToken = userDoc.data()?['facebookAccessToken'];

    if (userToken == null) {
      if (!mounted) return;
      //  Corregido: sin 'duration' ni 'action'
      showCustomSnackbar(
        context: context,
        message:
            'Conecta tu cuenta de Facebook en tu perfil para publicar directamente.',
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
      if (kIsWeb) {
        if (!mounted) return;
        Navigator.pop(context);
        showCustomSnackbar(
          context: context,
          message: 'La publicación directa no está soportada en web por ahora.',
          success: false,
        );
        return;
      }

      final Uint8List? imageBytes = await _screenshotController.capture();
      if (imageBytes == null) {
        if (!mounted) return;
        Navigator.pop(context);
        showCustomSnackbar(
          context: context,
          message: 'No se pudo capturar la imagen.',
          success: false,
        );
        return;
      }
      //TODO Checar implementacion con api
      final String pageId =
          "ID_DE_LA_PAGINA_FACEBOOK_DEL_USUARIO"; // Reemplazar
      if (pageId == "ID_DE_LA_PAGINA_FACEBOOK_DEL_USUARIO") {
        if (!mounted) return;
        Navigator.pop(context);
        showCustomSnackbar(
          context: context,
          message: "Configuración de Page ID pendiente.",
          success: false,
        );
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://graph.facebook.com/$pageId/photos'),
      );
      final tituloMaterial = materialData!['titulo'] ?? 'Material de Estudio';
      final texto =
          '¡Nuevo material en Study Connect! "$tituloMaterial" sobre ${obtenerNombreTema(widget.tema)}. #StudyConnectMaterial'; // ✅ Usando la función corregida

      request.fields['caption'] = texto;
      request.fields['access_token'] = userToken;
      request.files.add(
        http.MultipartFile.fromBytes(
          'source',
          imageBytes,
          filename: 'material_screenshot.png',
        ),
      );

      final response = await request.send();

      if (!mounted) return;
      Navigator.pop(context);

      if (response.statusCode == 200) {
        showCustomSnackbar(
          context: context,
          message: '¡Material publicado en Facebook con éxito!',
          success: true,
        );
      } else {
        final responseData = await response.stream.bytesToString();
        print('Error al publicar: ${response.statusCode}, $responseData');
        showCustomSnackbar(
          context: context,
          message: 'Error al publicar en Facebook.',
          success: false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      print('Error excepcional al publicar: $e');
      showCustomSnackbar(
        context: context,
        message: 'Error inesperado al publicar.',
        success: false,
      );
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

  Widget _buildVistaArchivo(Map<String, dynamic> archivo, double screenWidth) {
    final tipo = archivo['tipo'];
    final nombre = archivo['nombre'] ?? 'Archivo';
    final url =
        tipo == 'link' ? archivo['contenido'] ?? '' : archivo['url'] ?? '';

    final extension = (archivo['extension'] ?? '').toString().toLowerCase();
    final bool esPdf = extension == 'pdf';
    final bool esMp3 = extension == 'mp3';
    final bool esMp4 = extension == 'mp4';

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
              borderRadius: BorderRadius.circular(12),
              child: Center(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  height: obtenerDimensionesMultimedia(screenWidth)['altura'],
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.image, color: Colors.blue),
              title: Text(nombre),
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
      ui.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
        final video =
            html.VideoElement()
              ..src = url
              ..controls = true
              ..style.width = '100%';
        return video;
      });

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.videocam, color: Colors.orange),
            title: Text(nombre),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: dimensiones['altura'],
            child: HtmlElementView(viewType: viewId),
          ),
        ],
      );
    }

    if (tipo == 'audio' || esMp3) {
      final viewId = 'audio-${url.hashCode}';
      ui.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
        final audio =
            html.AudioElement()
              ..src = url
              ..controls = true
              ..style.width = '100%';
        return audio;
      });

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.audiotrack, color: Colors.pink),
            title: Text(nombre),
          ),
          const SizedBox(height: 8),
          HtmlElementView(viewType: viewId),
        ],
      );
    }

    if (tipo == 'link') {
      final isYoutube = url.contains('youtube.com') || url.contains('youtu.be');
      if (isYoutube) {
        final videoId =
            Uri.parse(url).queryParameters['v'] ??
            Uri.parse(url).pathSegments.last;
        final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/0.jpg';
        return FutureBuilder<String?>(
          future: obtenerTituloVideoYoutube(url),
          builder: (context, snapshot) {
            final tituloVideo = snapshot.data ?? 'Video de YouTube';
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
                    child: Image.network(
                      thumbnailUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: dimensiones['altura'],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.play_circle_fill,
                      color: Colors.red,
                    ),
                    title: Text(tituloVideo),
                    subtitle: Text(url),
                    trailing: ElevatedButton.icon(
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Ver video'),
                      onPressed: () => html.window.open(url, '_blank'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      } else {
        return ListTile(
          leading: const Icon(Icons.link, color: Colors.green),
          title: Text(url),
          trailing: IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () => html.window.open(url, '_blank'),
          ),
        );
      }
    }

    if (tipo == 'nota') {
      return Card(
        margin: EdgeInsets.symmetric(vertical: dimensiones['margen']),
        color: const Color(0xFFF1F8E9),
        child: ListTile(
          leading: const Icon(Icons.notes, color: Colors.purple),
          title: Text(nombre),
        ),
      );
    }

    return ListTile(
      leading: const Icon(Icons.insert_drive_file, color: Colors.grey),
      title: Text(nombre),
      trailing: IconButton(
        icon: const Icon(Icons.open_in_new),
        onPressed: () => html.window.open(url, '_blank'),
      ),
    );
  }

  Map<String, dynamic> obtenerDimensionesMultimedia(double width) {
    if (width <= 480) {
      return {'altura': 180.0, 'margen': 8.0, 'radio': 12.0};
    } else if (width <= 800) {
      return {'altura': 220.0, 'margen': 10.0, 'radio': 14.0};
    } else if (width <= 1200) {
      return {'altura': 260.0, 'margen': 12.0, 'radio': 16.0};
    } else if (width <= 1900) {
      return {'altura': 220.0, 'margen': 16.0, 'radio': 16.0};
    } else {
      return {'altura': 200.0, 'margen': 20.0, 'radio': 20.0};
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
            constraints: const BoxConstraints(maxHeight: 260, minHeight: 120),
            child: const ExerciseCarousel(),
          ),
          const SizedBox(height: 16),

          // dentro de _columnaIzquierda, usando el booleano 'esMovil' de la Solución 2
          if (esAutor)
            Row(
              // O Wrap, como en la Solución 1
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _editarMaterial,
                  icon: const Icon(Icons.edit, color: Colors.white),
                  // Si es móvil, no muestra texto. Si es grande, sí.
                  label:
                      esMovil ? const SizedBox.shrink() : const Text("Editar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    // Agregamos padding para que el botón no sea tan pequeño sin texto
                    padding: EdgeInsets.symmetric(
                      horizontal: esMovil ? 12 : 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _agregarNuevaVersion,
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.white,
                  ),
                  label:
                      esMovil
                          ? const SizedBox.shrink()
                          : const Text("Nueva versión"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    padding: EdgeInsets.symmetric(
                      horizontal: esMovil ? 12 : 16,
                    ),
                  ),
                ),

                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _confirmarEliminarMaterial,
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label:
                      esMovil
                          ? const SizedBox.shrink()
                          : const Text("Eliminar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: EdgeInsets.symmetric(
                      horizontal: esMovil ? 12 : 16,
                    ),
                  ),
                ),
              ],
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

  void _confirmarEliminarMaterial() async {
    final confirm = await showCustomDialog<bool>(
      context: context,
      titulo: '¿Eliminar material?',
      mensaje:
          'Esta acción eliminará permanentemente este material y todas sus versiones. ¿Estás seguro?',
      tipo: CustomDialogType.warning,
      botones: [
        DialogButton<bool>(texto: 'Cancelar', value: false),
        DialogButton<bool>(texto: 'Eliminar', value: true),
      ],
    );
    if (confirm == true) {
      await _eliminarMaterial();
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

      // Elimina también los comentarios relacionados (opcional)
      final comentarios =
          await FirebaseFirestore.instance
              .collection('comentarios_materiales')
              .where('materialId', isEqualTo: widget.materialId)
              .get();
      for (final c in comentarios.docs) {
        await c.reference.delete();
      }

      showCustomSnackbar(
        context: context,
        message: 'Material eliminado.',
        success: true,
      );

      Navigator.pop(context); // Regresa a la lista de materiales
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
      'pdf': Icons.picture_as_pdf,
      'image': Icons.image,
      'audio': Icons.audiotrack,
      'video': Icons.videocam,
      'link': Icons.link,
      'nota': Icons.notes,
    };
    final Map<String, String> titulosTipo = {
      'pdf': '📄 Documentos PDF',
      'image': '🖼️ Imágenes',
      'audio': '🎵 Audios',
      'video': '🎬 Videos',
      'link': '🔗 Enlaces',
      'nota': '📝 Notas',
    };

    final contenido = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Título del material:',
          style: TextStyle(
            fontSize: screenWidth < 600 ? 16 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          color: const Color(0xFFF6F3FA),
          child: Padding(
            padding: EdgeInsets.all(screenWidth < 600 ? 10 : 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: CustomLatexText(
                contenido: titulo,
                fontSize: screenWidth < 600 ? 18 : 22,
                color: Colors.black,
                prepararLatex: prepararLaTeX,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Divider(color: Colors.black87),
        const Text('Descripción del material:', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F3FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            dividirDescripcionEnLineas(descripcion),
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.justify,
          ),
        ),
        const SizedBox(height: 20),
        const Divider(color: Colors.black87),
        const Text('Contenido:', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 10),
        ...agrupados.entries.map((entry) {
          final tipo = entry.key;
          final lista = entry.value;
          return ExpansionTile(
            initiallyExpanded: true,
            leading: Icon(iconosTipo[tipo], color: Colors.black),
            title: Text(
              titulosTipo[tipo] ?? tipo,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
          onEliminarComentario:
              (c) => _eliminarComentario(
                c,
              ), // Asegúrate de que esta llamada sea correcta
        ),
        const SizedBox(height: 40),

        // ================== ✅ ESTA ES LA PARTE CORREGIDA ==================
        CustomFeedbackCard(
          accion: 'Calificar',
          numeroComentarios: comentarios.length,
          onCalificar: _mostrarDialogoCalificacion,
          onCompartir:
              _showMaterialSharingOptions, // Se llama a la función principal del BottomSheet
        ),

        // ===================================================================
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
          ),
          child: contenido,
        ),
      );
    } else {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [contenido],
          ),
        ),
      );
    }
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
    BuildContext dialogContext, // <-- recibirlo aquí
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabecera
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

            // Rating
            CustomRatingWidget(
              rating: getRating(),
              onRatingChanged: (v) => setRating(v),
              enableHoverEffect: true,
            ),
            const SizedBox(height: 12),

            // Comentario
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Comentario',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // Anónimo
            CheckboxListTile(
              value: getComoAnonimo(),
              onChanged: (v) => setComoAnonimo(v ?? false),
              title: const Text('Comentar como anónimo'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),

            // Botones
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
                            // 1) Validación: si faltan campos, muestro el diálogo y salgo:
                            if (controller.text.trim().isEmpty ||
                                getRating() == 0) {
                              await showCustomDialog(
                                context: dialogContext, // contexto del diálogo
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
                              return; // 2) aquí terminamos el onPressed sin seguir adelante
                            }

                            // 3) Si pasa la validación, enviamos el comentario:
                            setEnviando(true);
                            await _enviarComentario(
                              controller.text.trim(),
                              getRating(),
                              getComoAnonimo(),
                            );
                            setEnviando(false);

                            // 4) Cerramos el diálogo de calificación:
                            Navigator.of(dialogContext).pop();

                            // 5) Y finalmente mostramos el snackbar de éxito:
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
    // Aquí obtenemos la URL de la foto (o null si no hay)
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

    // 🔽 Obtener el UID del autor del material
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
            ..setAttribute('download', 'captura_material.png')
            ..click();

      html.Url.revokeObjectUrl(urlBlob);

      // Después, compartir en Facebook
      final urlEjercicio = Uri.encodeComponent(
        'https://study-connect.app/material/$tema/$ejercicioId',
      ); // CAMBIA aquí tu dominio real
      final quote = Uri.encodeComponent('¡Revisa este material: $titulo!');
      final facebookUrl =
          'https://www.facebook.com/sharer/sharer.php?u=$urlEjercicio&quote=$quote';

      html.window.open(facebookUrl, '_blank');
    }
  }

  // Future<void> _compartirCapturaYSharePlus(
  //   String titulo,
  //   String tema,
  //   String ejercicioId,
  // ) async {
  //   final Uint8List? image = await _screenshotController.capture();
  //   if (image != null) {
  //     final blob = html.Blob([image]);
  //     final urlBlob = html.Url.createObjectUrlFromBlob(blob);

  //     // Descargar la imagen
  //     final link =
  //         html.AnchorElement(href: urlBlob)
  //           ..setAttribute('download', 'captura_material.png')
  //           ..click();

  //     html.Url.revokeObjectUrl(urlBlob);
  //   }

  //   final urlEjercicio =
  //       'https://tuapp.com/$tema/$ejercicioId'; // CAMBIA por tu dominio real
  //   await Share.share('📘 $titulo\n$urlEjercicio');
  // }

  // void compartirEnFacebook(String titulo, String tema, String ejercicioId) {
  //   final url = Uri.encodeComponent(
  //     'https://tuapp.com/$tema/$ejercicioId',
  //   ); // <-- CAMBIA por tu dominio real
  //   final quote = Uri.encodeComponent('¡Revisa este material: $titulo!');
  //   final facebookUrl =
  //       'https://www.facebook.com/sharer/sharer.php?u=$url&quote=$quote';
  //   html.window.open(facebookUrl, '_blank');
  // }

  // void compartirGenerico(String titulo, String tema, String ejercicioId) {
  //   final url =
  //       'https://tuapp.com/$tema/$ejercicioId'; // <-- CAMBIA por tu dominio real
  //   Share.share('$titulo\n$url');
  // }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // 👇 NUEVA LÍNEA para validar que los datos ya se cargaron
    if (materialData == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF036799),
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                            ejercicioData: materialData ?? {},
                            tema: widget.tema,
                            materialId: widget.materialId,
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
                            materialData: materialData ?? {},
                            comentarios: comentarios,
                            esPantallaChica: false,
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
                            ejercicioData: materialData ?? {},
                            tema: widget.tema,
                            materialId: widget.materialId,
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
                            materialData: materialData ?? {},
                            comentarios: comentarios,
                            esPantallaChica: true,
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
