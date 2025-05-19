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
    //'Gnral': 'Temas en General (Cosas de aportación General)',
  };

  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  String? _nombreUsuario;
  bool _subiendo = false;
  bool _exitoAlSubir = false;

  String? _materialId;
  bool _modoEdicion = false;
  bool _modoNuevaVersion = false;

  @override
  void initState() {
    super.initState();
    _cargarNombreUsuario();
  }

  Future<void> _cargarMaterialParaEditar() async {
    if (_temaSeleccionado == null || _materialId == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('materiales')
            .doc(_temaSeleccionado)
            .collection('Mat$_temaSeleccionado')
            .doc(_materialId)
            .get();

    if (!doc.exists) return;

    final data = doc.data()!;
    // Carga los datos generales
    _tituloController.text = data['titulo'] ?? '';
    _descripcionController.text = data['descripcion'] ?? '';
    _subtemaController.text = data['subtema'] ?? '';

    // Siempre obtén la versión actual (o la que se va a editar)
    final versionId = data['versionActual'];
    final versionDoc =
        await doc.reference.collection('Versiones').doc(versionId).get();

    if (versionDoc.exists) {
      final vData = versionDoc.data()!;
      _descripcionController.text = vData['Descripcion'] ?? '';
      // Para edición o nueva versión, carga los archivos de la versión actual
      final archivos = List<Map<String, dynamic>>.from(vData['archivos'] ?? []);
      setState(() {
        _archivos.clear();
        _archivos.addAll(archivos);
      });
    }

    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      _temaSeleccionado ??= args['tema'];
      _materialId = args['materialId'];
      _modoEdicion = args['editar'] == true;
      _modoNuevaVersion = args['nuevaVersion'] == true;
      if (_modoEdicion || _modoNuevaVersion) {
        _cargarMaterialParaEditar();
      }
    }
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

  String obtenerMensajeLogroMaterial(int total) {
    if (total == 1) {
      return "¡Subiste tu primer material! 📚 Bienvenido a la comunidad de colaboradores.";
    } else if (total == 5) {
      return "¡5 materiales subidos! 🥈 Logro: Compartidor Activo. ¡Sigue inspirando!";
    } else if (total == 10) {
      return "¡10 materiales! 🥇 Logro: Colaborador Avanzado. ¡Tus aportes son clave para todos!";
    } else if (total == 20) {
      return "¡20 materiales! 🏆 Logro: Master Resource Giver. ¡Eres un pilar en la comunidad!";
    } else if (total % 10 == 0) {
      return "¡$total materiales! ⭐ ¡Nivel leyenda en recursos! Sigue sumando éxitos.";
    } else if (total >= 3 && total < 5) {
      return "¡Gran avance! Ya llevas $total materiales subidos.";
    } else if (total > 20 && total % 5 == 0) {
      return "¡Wow! $total materiales subidos. ¡Inspiras a todos! 👏";
    } else {
      final frases = [
        "¡Cada recurso suma! Gracias por tu apoyo.",
        "¡Aporta más, crecemos juntos!",
        "¡Tus materiales marcan la diferencia!",
        "¡Eres parte importante de la comunidad!",
        "¡Sigue compartiendo! 👏",
        "¡Buen trabajo! Cada recurso ayuda a todos.",
        "¡Sigue así, tu aporte es valioso!",
        "¡Tu material facilita el aprendizaje de muchos!",
        "¡Uno más para la comunidad! 🚀",
        "¡Aportar te acerca al top del ranking!",
        "¡No pares de compartir!",
      ];
      return frases[DateTime.now().millisecondsSinceEpoch % frases.length];
    }
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

      final coleccionMateriales = FirebaseFirestore.instance
          .collection('materiales')
          .doc(_temaSeleccionado!)
          .collection('Mat$_temaSeleccionado');

      // Limpia archivos inválidos que NO tienen bytes ni url (solo si no son link/nota)
      _archivos.removeWhere(
        (a) =>
            (a['tipo'] == 'pdf' ||
                a['tipo'] == 'image' ||
                a['tipo'] == 'video' ||
                a['tipo'] == 'audio') &&
            a['bytes'] == null &&
            (a['url'] == null || a['url'].toString().isEmpty),
      );

      // Subida de archivos a Storage y recopilación de contenido
      final List<Map<String, dynamic>> contenido = [];
      for (var archivo in _archivos) {
        // Para archivos NUEVOS: tienen 'bytes' y NO tienen 'url'
        if ((archivo['tipo'] == 'pdf' ||
                archivo['tipo'] == 'image' ||
                archivo['tipo'] == 'video' ||
                archivo['tipo'] == 'audio') &&
            archivo['bytes'] != null) {
          final nombreArchivo =
              '${DateTime.now().millisecondsSinceEpoch}_${archivo['nombre']}';
          final ref = FirebaseStorage.instance
              .ref()
              .child('materiales')
              .child(_temaSeleccionado!)
              .child(uid!)
              .child(nombreArchivo);

          await ref.putData(archivo['bytes']);
          final url = await ref.getDownloadURL();

          contenido.add({
            'tipo': archivo['tipo'],
            'nombre': archivo['nombre'],
            'url': url,
            'extension': archivo['extension'],
          });
        }
        // Para archivos YA EXISTENTES en la nube: tienen 'url' y NO tienen 'bytes'
        else if ((archivo['tipo'] == 'pdf' ||
                archivo['tipo'] == 'image' ||
                archivo['tipo'] == 'video' ||
                archivo['tipo'] == 'audio') &&
            archivo['url'] != null) {
          contenido.add({
            'tipo': archivo['tipo'],
            'nombre': archivo['nombre'],
            'url': archivo['url'],
            'extension': archivo['extension'],
          });
        }
        // Links o notas (no se suben a storage, solo se guardan como texto)
        else if (archivo['tipo'] == 'link' || archivo['tipo'] == 'nota') {
          contenido.add({
            'tipo': archivo['tipo'],
            'contenido': archivo['nombre'],
          });
        }
      }

      // --------- Determinación de modo: edición, nueva versión, nuevo ----------
      String materialId;
      String versionId;

      if (_modoEdicion || _modoNuevaVersion) {
        materialId = _materialId!;
        if (_modoNuevaVersion) {
          // ---- NUEVA VERSIÓN ----
          final doc = await coleccionMateriales.doc(materialId).get();
          final versionesSnap =
              await doc.reference.collection('Versiones').get();
          final versionNum = versionesSnap.docs.length + 1;
          final nuevaVersionId =
              'Version_${versionNum.toString().padLeft(2, '0')}';

          // 1. Crear nueva versión (nuevo doc)
          await doc.reference.collection('Versiones').doc(nuevaVersionId).set({
            'Descripcion': _descripcionController.text.trim(),
            'Fecha': now,
            'AutorId': uid,
            'archivos': contenido, // SOLO aquí guardas archivos
          });

          // 2. Actualizar SOLO metadatos generales y el versionActual
          await doc.reference.update({
            'titulo': _tituloController.text.trim(),
            'descripcion': _descripcionController.text.trim(),
            'subtema': _subtemaController.text.trim(),
            // NO actualices el campo 'archivos' aquí (ni lo pongas)
            'FechMod': now,
            'versionActual': nuevaVersionId, // <--- Muy importante
          });

          await NotificationService.crearNotificacion(
            uidDestino: uid!,
            tipo: 'material',
            titulo: '¡Nueva versión de material!',
            contenido: 'Se subió una nueva versión de tu material.',
            referenciaId: materialId,
            uidEmisor: uid,
            nombreEmisor: _nombreUsuario ?? 'Tú',
            tema: _temaSeleccionado,
          );

          await LocalNotificationService.show(
            title: 'Material actualizado',
            body: '¡Tu material fue actualizado con una nueva versión!',
          );

          await reproducirSonidoExito();

          await showFeedbackDialogAndSnackbar(
            context: context,
            titulo: '¡Nueva versión!',
            mensaje: 'Nueva versión del material agregada exitosamente.',
            tipo: CustomDialogType.success,
            snackbarMessage: 'Nueva versión guardada',
            snackbarSuccess: true,
          );

          setState(() {
            _exitoAlSubir = true;
            _subiendo = false;
          });
          return;
        } else {
          // ---- EDICIÓN NORMAL ----
          final doc = await coleccionMateriales.doc(materialId).get();
          final versionActualId = doc['versionActual'];

          // Actualiza doc principal
          await doc.reference.update({
            'titulo': _tituloController.text.trim(),
            'descripcion': _descripcionController.text.trim(),
            'subtema': _subtemaController.text.trim(),
            'archivos': contenido,
            'FechMod': now,
          });

          // Actualiza versión actual
          await doc.reference
              .collection('Versiones')
              .doc(versionActualId)
              .update({
                'Descripcion': _descripcionController.text.trim(),
                'Fecha': now,
                'AutorId': uid,
                'archivos': contenido,
              });

          await NotificationService.crearNotificacion(
            uidDestino: uid!,
            tipo: 'material',
            titulo: '¡Material editado!',
            contenido: 'Se editaron los datos de tu material.',
            referenciaId: materialId,
            uidEmisor: uid,
            nombreEmisor: _nombreUsuario ?? 'Tú',
            tema: _temaSeleccionado,
          );

          await LocalNotificationService.show(
            title: 'Material editado',
            body: '¡Tu material fue editado exitosamente!',
          );

          await reproducirSonidoExito();

          await showFeedbackDialogAndSnackbar(
            context: context,
            titulo: '¡Editado!',
            mensaje: 'El material fue editado correctamente.',
            tipo: CustomDialogType.success,
            snackbarMessage: 'Material editado',
            snackbarSuccess: true,
          );

          setState(() {
            _exitoAlSubir = true;
            _subiendo = false;
          });
          return;
        }
      } else {
        // ---- NUEVO MATERIAL ----
        final snapshot = await coleccionMateriales.get();
        materialId =
            '${_temaSeleccionado}_${(snapshot.docs.length + 1).toString().padLeft(2, '0')}';
        versionId = 'Version_01';

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

        // --- GAMIFICACIÓN: Contador de materiales subidos
        final userRef = FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid);
        final userSnap = await userRef.get();
        final datosUsuario = userSnap.data() ?? {};
        final materialesSubidos =
            (datosUsuario['MaterialesSubidos'] ?? 0) as int;
        final totalSubidos = materialesSubidos + 1;
        await userRef.update({'MaterialesSubidos': totalSubidos});

        // Actualizar ranking, etc.
        if (uid != null) {
          await actualizarTodoCalculoDeUsuario(uid: uid);
        }

        // --- Notificación motivacional
        await NotificationService.crearNotificacion(
          uidDestino: uid!,
          tipo: 'material',
          titulo: '¡Material subido correctamente!',
          contenido: obtenerMensajeLogroMaterial(totalSubidos),
          referenciaId: materialId,
          uidEmisor: uid,
          nombreEmisor: _nombreUsuario ?? 'Tú',
          tema: _temaSeleccionado,
        );

        // --- Notificación local
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
      }
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

  Widget _buildArchivoPreview(Map<String, dynamic> archivo, int index) {
    final tipo = archivo['tipo'];
    final nombre = archivo['nombre'] ?? '';
    final extension = (archivo['extension'] ?? '').toString().toLowerCase();

    Widget? leading;
    String? subtitle;
    IconData? icon;

    // Iconos y subtítulos según tipo
    if (extension == 'pdf') {
      icon = Icons.picture_as_pdf;
    } else if (extension == 'mp3') {
      icon = Icons.audiotrack;
      subtitle = 'Audio MP3';
    } else if (extension == 'mp4') {
      icon = Icons.movie;
      subtitle = 'Video MP4';
    } else if (tipo == 'image') {
      icon = Icons.image;
    } else if (tipo == 'link') {
      icon = Icons.link;
      subtitle = archivo['nombre'];
    } else if (tipo == 'nota') {
      icon = Icons.notes;
      subtitle = archivo['nombre'];
    }

    // Para enlaces de YouTube muestra la miniatura y el botón eliminar
    if (tipo == 'link' &&
        (nombre.contains("youtube.com") || nombre.contains("youtu.be"))) {
      final videoId = _extractYoutubeId(nombre);
      final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/0.jpg';

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(thumbnailUrl, fit: BoxFit.cover),
                ListTile(
                  leading: Icon(Icons.play_circle, color: Colors.red),
                  title: FutureBuilder<String?>(
                    future: obtenerTituloVideoYoutube(nombre),
                    builder: (context, snapshot) {
                      return Text(snapshot.data ?? 'Video de YouTube');
                    },
                  ),
                  subtitle: Text(nombre),
                  trailing: ElevatedButton.icon(
                    onPressed: () => _abrirEnlaceEnWeb(nombre),
                    icon: Icon(Icons.open_in_new),
                    label: Text("Ver video"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            // --- Botón X (arriba a la derecha) ---
            Positioned(
              right: 0,
              top: 0,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.red.shade700, size: 24),
                onPressed: () async {
                  final confirm = await showCustomDialog<bool>(
                    context: context,
                    titulo: '¿Eliminar archivo?',
                    mensaje: '¿Estás seguro de eliminar este archivo?',
                    tipo: CustomDialogType.warning,
                    botones: [
                      DialogButton<bool>(texto: 'Cancelar', value: false),
                      DialogButton<bool>(texto: 'Eliminar', value: true),
                    ],
                  );
                  if (confirm == true) {
                    setState(() {
                      _archivos.removeAt(index);
                    });
                    showCustomSnackbar(
                      context: context,
                      message: 'Archivo eliminado.',
                      success: true,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      );
    }

    // Otros tipos (PDF, imagen, audio, nota, etc.)
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueGrey),
        title: Text(nombre),
        subtitle: subtitle != null ? Text(subtitle) : null,
        // --- Botón X ---
        trailing: IconButton(
          icon: Icon(Icons.close, color: Colors.red.shade700, size: 24),
          onPressed: () async {
            final confirm = await showCustomDialog<bool>(
              context: context,
              titulo: '¿Eliminar archivo?',
              mensaje: '¿Estás seguro de eliminar este archivo?',
              tipo: CustomDialogType.warning,
              botones: [
                DialogButton<bool>(texto: 'Cancelar', value: false),
                DialogButton<bool>(texto: 'Eliminar', value: true),
              ],
            );
            if (confirm == true) {
              setState(() {
                _archivos.removeAt(index);
              });
              showCustomSnackbar(
                context: context,
                message: 'Archivo eliminado.',
                success: true,
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF036799),
      appBar: AppBar(
        backgroundColor: const Color(0xFF048DD2),
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 8),
            Image.asset('assets/images/logo_ipn.png', height: 32),
            const SizedBox(width: 8),
            const Text(
              'Study Connect',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/'),
            child: const Text('Inicio', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/ranking'),
            child: const Text('Ranking', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/content'),
            child: const Text(
              'Contenidos',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const NotificationIconWidget(),
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/user_profile'),
            icon: const Icon(Icons.person, color: Colors.white),
            label: const Text('Perfil', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 10),
        ],
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
                            _buildArchivoPreview(_archivos[index], index),
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
