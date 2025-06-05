import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data'; // Necesario para Uint8List
import 'dart:html' as html; // Para html.window.open
import '../services/services.dart'; // Asegúrate que NotificationService y LocalNotificationService estén aquí
import '../utils/utils.dart';
import '../widgets/widgets.dart';
import 'package:study_connect/config/secrets.dart'; // Asegúrate que esta ruta es correcta

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
  };

  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  String? _nombreUsuario;
  bool _subiendo = false;
  bool _exitoAlSubir = false;

  String?
  _materialId; // ID del material si se está editando o creando nueva versión
  bool _modoEdicion = false;
  bool _modoNuevaVersion = false;
  String?
  _versionActualIdParaEditar; // ID de la versión específica que se edita
  bool _argumentosCargados = false;

  @override
  void initState() {
    super.initState();
    _cargarNombreUsuario();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argumentosCargados) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _temaSeleccionado = args['tema'] as String?;
        _materialId = args['materialId'] as String?;
        _modoEdicion = args['editar'] == true;
        _modoNuevaVersion = args['nuevaVersion'] == true;

        if ((_modoEdicion || _modoNuevaVersion) &&
            _materialId != null &&
            _temaSeleccionado != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _cargarMaterialParaEditar();
          });
        }
      }
      _argumentosCargados = true;
    }
  }

  Future<void> _cargarMaterialParaEditar() async {
    if (!mounted || _temaSeleccionado == null || _materialId == null) return;

    final materialDocRef = FirebaseFirestore.instance
        .collection('materiales')
        .doc(_temaSeleccionado)
        .collection('Mat$_temaSeleccionado')
        .doc(_materialId);

    try {
      final materialDoc = await materialDocRef.get();
      if (!mounted) return;

      if (!materialDoc.exists) {
        showCustomSnackbar(
          context: context,
          message: 'Error: El material a editar no fue encontrado.',
          success: false,
        );
        return;
      }

      final data = materialDoc.data()!;
      _tituloController.text = data['titulo'] ?? '';
      _subtemaController.text = data['subtema'] ?? '';
      _versionActualIdParaEditar = data['versionActual'] as String?;

      if (_versionActualIdParaEditar == null) {
        showCustomSnackbar(
          context: context,
          message:
              'Error: No se encontró el ID de la versión actual del material.',
          success: false,
        );
        return;
      }

      final versionDoc =
          await materialDocRef
              .collection('Versiones')
              .doc(_versionActualIdParaEditar)
              .get();

      if (!mounted) return;

      if (versionDoc.exists) {
        final vData = versionDoc.data()!;
        _descripcionController.text = vData['Descripcion'] ?? '';

        final archivosDeVersion = List<Map<String, dynamic>>.from(
          vData['archivos'] ?? [],
        );

        setState(() {
          _archivos.clear();
          _archivos.addAll(
            archivosDeVersion.map((a) => Map<String, dynamic>.from(a)),
          );
        });
      } else {
        showCustomSnackbar(
          context: context,
          message: 'Error: No se pudo cargar la versión actual del material.',
          success: false,
        );
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackbar(
          context: context,
          message: 'Error al cargar datos para edición: ${e.toString()}',
          success: false,
        );
      }
    }
  }

  Future<void> _confirmarEliminarArchivo(int index) async {
    if (!mounted) return;
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
            if (mounted) {
              setState(() {
                _archivos.removeAt(index);
              });
              Navigator.of(context).pop();
              showCustomSnackbar(
                context: context,
                message: 'Archivo eliminado.',
                success: true,
              );
            }
          },
        ),
      ],
    );
  }

  Future<void> _cargarNombreUsuario() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final doc =
            await FirebaseFirestore.instance
                .collection('usuarios')
                .doc(uid)
                .get();
        if (mounted) {
          setState(() {
            _nombreUsuario = doc.data()?['Nombre'] ?? 'Usuario Anónimo';
          });
        }
      } catch (e) {
        print("Error al cargar nombre de usuario: $e");
        if (mounted) {
          setState(() {
            _nombreUsuario = 'Usuario (Error)';
          });
        }
      }
    }
  }

  Future<String?> obtenerTituloVideoYoutube(String url) async {
    final videoIdMatch = RegExp(
      r"(?:youtube(?:-nocookie)?\.com/(?:[^/\n\s]+/\S+/|(?:v|e(?:mbed)?)/|\S*?[?&]v=)|youtu\.be/)([a-zA-Z0-9_-]{11})",
    ).firstMatch(url);
    final videoId = videoIdMatch?.group(1);

    if (videoId == null)
      return Future.value('Enlace de YouTube (ID no encontrado)');

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
      return 'Video de YouTube (Título no disponible)';
    } catch (e) {
      print('Error al obtener título del video: $e');
      return 'Video de YouTube (Error al cargar título)';
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
    } else if (total % 10 == 0 && total > 0) {
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

  Future<String> _generarNuevoMaterialId(
    CollectionReference materialesSubcoleccionRef,
    String temaKey,
  ) async {
    final docs = await materialesSubcoleccionRef.get();
    final idsExistentes = docs.docs.map((d) => d.id).toSet();
    int i = 1;
    String nuevoId;
    do {
      nuevoId = '${temaKey}_${i.toString().padLeft(2, '0')}';
      i++;
    } while (idsExistentes.contains(nuevoId));
    return nuevoId;
  }

  Future<void> _subirMaterialEducativo() async {
    if (!mounted || _subiendo) return;

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

    setState(() => _subiendo = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        setState(() => _subiendo = false);
        await showCustomDialog(
          context: context,
          titulo: 'Error',
          mensaje: 'Usuario no autenticado.',
          tipo: CustomDialogType.error,
        );
      }
      return;
    }

    final nombreTema = temasDisponibles[_temaSeleccionado!] ?? 'Otro';
    final now = Timestamp.now();
    final coleccionMateriales = FirebaseFirestore.instance
        .collection('materiales')
        .doc(_temaSeleccionado!)
        .collection('Mat$_temaSeleccionado');

    final List<Map<String, dynamic>> contenidoParaFirestore = [];
    try {
      for (var archivo in _archivos) {
        if ((archivo['tipo'] == 'pdf' ||
                archivo['tipo'] == 'image' ||
                archivo['tipo'] == 'video' ||
                archivo['tipo'] == 'audio') &&
            archivo['bytes'] != null) {
          final nombreArchivoStorage =
              '${DateTime.now().millisecondsSinceEpoch}_${archivo['nombre']}';
          final ref = FirebaseStorage.instance
              .ref()
              .child('materiales')
              .child(_temaSeleccionado!)
              .child(uid)
              .child(nombreArchivoStorage);
          await ref.putData(archivo['bytes'] as Uint8List);
          final url = await ref.getDownloadURL();
          contenidoParaFirestore.add({
            'tipo': archivo['tipo'],
            'nombre': archivo['nombre'],
            'url': url,
            'extension': archivo['extension'],
          });
        } else if ((archivo['tipo'] == 'pdf' ||
                archivo['tipo'] == 'image' ||
                archivo['tipo'] == 'video' ||
                archivo['tipo'] == 'audio') &&
            archivo['url'] != null &&
            archivo['url'].toString().isNotEmpty) {
          // Archivo existente con URL
          contenidoParaFirestore.add({
            'tipo': archivo['tipo'],
            'nombre': archivo['nombre'],
            'url': archivo['url'],
            'extension': archivo['extension'],
          });
        } else if (archivo['tipo'] == 'link' || archivo['tipo'] == 'nota') {
          contenidoParaFirestore.add({
            'tipo': archivo['tipo'],
            // Para links y notas, 'nombre' es el contenido (URL del link o texto de la nota)
            // Y la clave para el contenido es 'contenido'
            'contenido': archivo['nombre'],
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _subiendo = false);
        await showCustomDialog(
          context: context,
          titulo: 'Error al procesar archivos',
          mensaje: 'Ocurrió un error al preparar los archivos: ${e.toString()}',
          tipo: CustomDialogType.error,
        );
      }
      return;
    }

    if (contenidoParaFirestore.isEmpty && _archivos.isNotEmpty) {
      if (mounted) {
        setState(() => _subiendo = false);
        await showCustomDialog(
          context: context,
          titulo: 'Error de Archivos',
          mensaje:
              'No se pudieron procesar los archivos para subir. Asegúrate de que sean válidos y no estén vacíos.',
          tipo: CustomDialogType.error,
        );
      }
      return;
    }

    String materialDocId;
    String versionDocId;

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      if (_modoEdicion &&
          _materialId != null &&
          _versionActualIdParaEditar != null) {
        materialDocId = _materialId!;
        versionDocId = _versionActualIdParaEditar!;

        final materialRef = coleccionMateriales.doc(materialDocId);
        final versionRef = materialRef
            .collection('Versiones')
            .doc(versionDocId);

        batch.update(versionRef, {
          'Descripcion': _descripcionController.text.trim(),
          'Fecha': now,
          'archivos': contenidoParaFirestore,
        });
        batch.update(materialRef, {
          'titulo': _tituloController.text.trim(),
          'subtema': _subtemaController.text.trim(),
          'descripcion': _descripcionController.text.trim(),
          'FechMod': now,
          'archivos':
              contenidoParaFirestore, // Actualizar archivos en el doc principal también
        });

        await batch.commit();
        if (!mounted) return;

        await NotificationService.crearNotificacion(
          uidDestino: uid,
          tipo: 'material_editado',
          titulo: '¡Material Editado!',
          contenido:
              'Has editado tu material: "${_tituloController.text.trim()}".',
          referenciaId: materialDocId,
          tema: _temaSeleccionado!,
          uidEmisor: uid,
          nombreEmisor: _nombreUsuario ?? 'Sistema',
        );
        await LocalNotificationService.show(
          title: 'Material Editado',
          body:
              'Tu material "${_tituloController.text.trim()}" fue editado exitosamente.',
        );
        await reproducirSonidoExito();
        if (mounted) {
          await showFeedbackDialogAndSnackbar(
            context: context,
            titulo: '¡Editado!',
            mensaje: 'El material fue editado correctamente.',
            tipo: CustomDialogType.success,
            snackbarMessage: 'Material editado',
            snackbarSuccess: true,
          );
          Navigator.pushReplacementNamed(
            context,
            '/material_view',
            arguments: {
              'tema': _temaSeleccionado!,
              'materialId': materialDocId,
              'tituloTema':
                  temasDisponibles[_temaSeleccionado!] ?? _temaSeleccionado!,
            },
          );
        }
      } else if (_modoNuevaVersion && _materialId != null) {
        materialDocId = _materialId!;
        final materialRef = coleccionMateriales.doc(materialDocId);

        final versionesSnap =
            await materialRef
                .collection('Versiones')
                .orderBy('Fecha', descending: true)
                .get();
        final versionNum = versionesSnap.docs.length + 1;
        versionDocId = 'Version_${versionNum.toString().padLeft(2, '0')}';

        batch.set(materialRef.collection('Versiones').doc(versionDocId), {
          'Descripcion': _descripcionController.text.trim(),
          'Fecha': now,
          'AutorId': uid,
          'archivos': contenidoParaFirestore,
        });
        batch.update(materialRef, {
          'titulo': _tituloController.text.trim(),
          'subtema': _subtemaController.text.trim(),
          'descripcion': _descripcionController.text.trim(),
          'FechMod': now,
          'versionActual': versionDocId,
          'archivos':
              contenidoParaFirestore, // Actualizar archivos en el doc principal también
        });

        await batch.commit();
        if (!mounted) return;

        await NotificationService.crearNotificacion(
          uidDestino: uid,
          tipo: 'material_nueva_version',
          titulo: '¡Nueva Versión de Material!',
          contenido:
              'Se añadió una nueva versión a tu material: "${_tituloController.text.trim()}".',
          referenciaId: materialDocId,
          tema: _temaSeleccionado!,
          uidEmisor: uid,
          nombreEmisor: _nombreUsuario ?? 'Sistema',
        );
        await LocalNotificationService.show(
          title: 'Nueva Versión Guardada',
          body:
              'Se guardó una nueva versión para "${_tituloController.text.trim()}".',
        );
        await reproducirSonidoExito();
        if (mounted) {
          await showFeedbackDialogAndSnackbar(
            context: context,
            titulo: '¡Nueva Versión!',
            mensaje: 'Nueva versión del material agregada exitosamente.',
            tipo: CustomDialogType.success,
            snackbarMessage: 'Nueva versión guardada',
            snackbarSuccess: true,
          );
          Navigator.pushReplacementNamed(
            context,
            '/material_view',
            arguments: {
              'tema': _temaSeleccionado!,
              'materialId': materialDocId,
              'tituloTema':
                  temasDisponibles[_temaSeleccionado!] ?? _temaSeleccionado!,
            },
          );
        }
      } else {
        // ---- NUEVO MATERIAL ----
        materialDocId = await _generarNuevoMaterialId(
          coleccionMateriales,
          _temaSeleccionado!,
        );
        versionDocId = 'Version_01';

        final materialRef = coleccionMateriales.doc(materialDocId);

        batch.set(materialRef, {
          'id': materialDocId,
          'autorId': uid,
          'autorNombre': _nombreUsuario ?? 'Usuario Anónimo',
          'tema': _temaSeleccionado,
          'subtema': _subtemaController.text.trim(),
          'titulo': _tituloController.text.trim(),
          'descripcion': _descripcionController.text.trim(),
          'archivos': contenidoParaFirestore, // Guardar archivos aquí también
          'fechaCreacion': now,
          'FechMod': now,
          'calificacionPromedio': 0.0,
          'versionActual': versionDocId,
          'carpetaStorage': 'materiales/$_temaSeleccionado/$uid',
        });
        batch.set(materialRef.collection('Versiones').doc(versionDocId), {
          'Descripcion': _descripcionController.text.trim(),
          'Fecha': now,
          'AutorId': uid,
          'archivos': contenidoParaFirestore,
        });

        await batch.commit();
        if (!mounted) return;

        final userRef = FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid);
        final userSnap = await userRef.get();
        final datosUsuario = userSnap.data() ?? {};
        final materialesSubidos =
            (datosUsuario['MaterialesSubidos'] ?? 0) as int;
        final totalSubidos = materialesSubidos + 1;
        await userRef.update({'MaterialesSubidos': totalSubidos});
        await actualizarTodoCalculoDeUsuario(uid: uid);

        await NotificationService.crearNotificacion(
          uidDestino: uid,
          tipo: 'material_nuevo',
          titulo: '¡Material Subido!',
          contenido: obtenerMensajeLogroMaterial(totalSubidos),
          referenciaId: materialDocId,
          tema: _temaSeleccionado!,
          uidEmisor: uid,
          nombreEmisor: _nombreUsuario ?? 'Tú',
        );
        await LocalNotificationService.show(
          title: 'Material Subido',
          body: 'Tu material en $nombreTema fue guardado exitosamente.',
        );
        await reproducirSonidoExito();
        if (mounted) {
          await showFeedbackDialogAndSnackbar(
            context: context,
            titulo: '¡Éxito!',
            mensaje: 'El material se subió correctamente a la plataforma.',
            tipo: CustomDialogType.success,
            snackbarMessage: 'Material guardado con éxito',
            snackbarSuccess: true,
          );
          setState(() {
            _temaSeleccionado = null;
            _subtemaController.clear();
            _notaController.clear();
            _archivos.clear();
            _tituloController.clear();
            _descripcionController.clear();
            _exitoAlSubir = true;
            _modoEdicion = false;
            _modoNuevaVersion = false;
            _materialId = null;
            _versionActualIdParaEditar = null;
          });
        }
      }

      if (mounted) {
        setState(() => _subiendo = false);
        if (_exitoAlSubir && !(_modoEdicion || _modoNuevaVersion)) {
          await Future.delayed(const Duration(milliseconds: 1500));
          if (mounted) setState(() => _exitoAlSubir = false);
        }
      }
    } catch (e) {
      if (mounted) {
        await reproducirSonidoError();
        setState(() => _subiendo = false);
        await showFeedbackDialogAndSnackbar(
          context: context,
          titulo: 'Error al subir material',
          mensaje: 'Ocurrió un error: ${e.toString()}',
          tipo: CustomDialogType.error,
          snackbarMessage: '❌ Hubo un error al subir el material.',
          snackbarSuccess: false,
        );

        final List<String> tips = [
          'Tip: Revisa tu conexión a internet.',
          'Tip: Asegúrate que los archivos no sean demasiado grandes.',
          'Tip: Contacta a soporte si el problema persiste.',
        ];
        final randomTip =
            tips[DateTime.now().millisecondsSinceEpoch % tips.length];
        if (mounted) {
          //Chequeo adicional antes de reproducir sonido y mostrar diálogo
          final player = AudioPlayer();
          await player.play(AssetSource('audio/tip.mp3'));
          await showCustomDialog(
            context: context,
            titulo: '¡Consejo!',
            mensaje: randomTip,
            tipo: CustomDialogType.info,
          );
        }
      }
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
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes != null) {
        if (mounted) {
          setState(() {
            _archivos.add({
              'nombre': file.name,
              'bytes': file.bytes,
              'extension': file.extension ?? '',
              'tipo': tipo,
            });
          });
        }
      } else {
        if (mounted) {
          showCustomSnackbar(
            context: context,
            message: "El archivo seleccionado está vacío o no se pudo leer.",
            success: false,
          );
        }
      }
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
            decoration: const InputDecoration(
              hintText: 'https://ejemplo.com/video_o_pagina',
            ),
            keyboardType: TextInputType.url,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final enlace = controller.text.trim();
                if (enlace.isNotEmpty &&
                    Uri.tryParse(enlace)?.hasAbsolutePath == true) {
                  final yaExiste = _archivos.any(
                    (archivo) =>
                        archivo['tipo'] == 'link' &&
                        archivo['nombre'] == enlace,
                  );

                  if (yaExiste) {
                    Navigator.pop(context);
                    if (mounted) {
                      showCustomSnackbar(
                        context: context,
                        message: 'Este enlace ya ha sido agregado.',
                        success: false,
                      );
                    }
                    return;
                  }

                  String tituloYoutube = enlace;
                  if (enlace.toLowerCase().contains("youtube.com") ||
                      enlace.toLowerCase().contains("youtu.be")) {
                    tituloYoutube =
                        await obtenerTituloVideoYoutube(enlace) ?? enlace;
                  }

                  if (mounted) {
                    setState(() {
                      _archivos.add({
                        'nombre': enlace,
                        'tipo': 'link',
                        'tituloMostrado': tituloYoutube, // Para la UI
                      });
                    });
                  }
                } else {
                  if (mounted) {
                    showCustomSnackbar(
                      context: context,
                      message: 'Por favor, ingresa un enlace válido.',
                      success: false,
                    );
                  }
                  return;
                }
                if (mounted) Navigator.pop(context);
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
      if (mounted) {
        setState(() {
          _archivos.add({'nombre': nota, 'tipo': 'nota'});
          _notaController.clear();
        });
      }
    }
  }

  String _extractYoutubeId(String url) {
    RegExp regExp = RegExp(
      r'.*(?:youtu.be/|v/|u/\w/|embed/|watch\?v=|\&v=)([^#\&\?]*).*', // Ajusta esta RegExp si es necesario para tus URLs de YT
      caseSensitive: false,
      multiLine: false,
    );
    Match? match = regExp.firstMatch(url);
    return (match != null &&
            match.group(1) != null &&
            match.group(1)!.length == 11)
        ? match.group(1)!
        : '';
  }

  void _abrirEnlaceEnWeb(String url) {
    html.window.open(url, '_blank');
  }

  Widget _buildArchivoPreview(Map<String, dynamic> archivo, int index) {
    final tipo = archivo['tipo'];
    final nombreOriginal = archivo['nombre'] ?? '';
    final tituloMostrado = archivo['tituloMostrado'] ?? nombreOriginal;

    Widget? leadingWidget;
    String tituloParaMostrarEnListTile = nombreOriginal;
    String? subtituloParaMostrarEnListTile;

    if (tipo == 'link') {
      tituloParaMostrarEnListTile = tituloMostrado;
      subtituloParaMostrarEnListTile = nombreOriginal;
      if (nombreOriginal.toLowerCase().contains("youtube.com") ||
          nombreOriginal.toLowerCase().contains("youtu.be")) {
        final videoId = _extractYoutubeId(nombreOriginal);
        if (videoId.isNotEmpty) {
          final thumbnailUrl =
              'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
          leadingWidget = SizedBox(
            width: 80,
            height: 60,
            child: Image.network(
              thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) => const Icon(
                    Icons.play_circle_fill,
                    color: Colors.red,
                    size: 40,
                  ),
            ),
          );
        } else {
          leadingWidget = const Icon(
            Icons.play_circle_outline,
            color: Colors.red,
            size: 40,
          );
        }
      } else {
        leadingWidget = const Icon(
          Icons.link,
          color: Colors.blueGrey,
          size: 40,
        );
      }
    } else if (tipo == 'nota') {
      tituloParaMostrarEnListTile = 'Nota';
      subtituloParaMostrarEnListTile =
          nombreOriginal.length > 50
              ? '${nombreOriginal.substring(0, 50)}...'
              : nombreOriginal;
      leadingWidget = const Icon(Icons.notes, color: Colors.indigo, size: 40);
    } else if (tipo == 'pdf') {
      tituloParaMostrarEnListTile =
          nombreOriginal; // Mostrar nombre del archivo PDF
      leadingWidget = const Icon(
        Icons.picture_as_pdf,
        color: Colors.redAccent,
        size: 40,
      );
    } else if (tipo == 'image') {
      tituloParaMostrarEnListTile =
          nombreOriginal; // Mostrar nombre del archivo de imagen
      if (archivo['bytes'] != null) {
        leadingWidget = SizedBox(
          width: 60,
          height: 60,
          child: Image.memory(archivo['bytes'] as Uint8List, fit: BoxFit.cover),
        );
      } else if (archivo['url'] != null) {
        leadingWidget = SizedBox(
          width: 60,
          height: 60,
          child: Image.network(
            archivo['url'],
            fit: BoxFit.cover,
            errorBuilder:
                (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 40),
          ),
        );
      } else {
        leadingWidget = const Icon(Icons.image_outlined, size: 40);
      }
    } else if (tipo == 'video') {
      tituloParaMostrarEnListTile =
          nombreOriginal; // Mostrar nombre del archivo de video
      leadingWidget = const Icon(
        Icons.movie,
        color: Colors.deepOrange,
        size: 40,
      );
    } else if (tipo == 'audio') {
      tituloParaMostrarEnListTile =
          nombreOriginal; // Mostrar nombre del archivo de audio
      leadingWidget = const Icon(
        Icons.audiotrack,
        color: Colors.purple,
        size: 40,
      );
    } else {
      tituloParaMostrarEnListTile = nombreOriginal;
      leadingWidget = const Icon(Icons.attach_file, size: 40);
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      elevation: 2,
      child: ListTile(
        leading: leadingWidget,
        title: Text(
          tituloParaMostrarEnListTile,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle:
            subtituloParaMostrarEnListTile != null
                ? Text(
                  subtituloParaMostrarEnListTile,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
                : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tipo == 'link')
              IconButton(
                icon: const Icon(Icons.open_in_new, color: Colors.blue),
                tooltip: 'Abrir enlace',
                onPressed: () => _abrirEnlaceEnWeb(nombreOriginal),
              ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.red.shade700),
              tooltip: 'Eliminar',
              onPressed: () => _confirmarEliminarArchivo(index),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF036799),
      appBar: CustomAppBar(
        showBack: true,
        titleText:
            _modoEdicion
                ? 'Editar Material'
                : _modoNuevaVersion
                ? 'Nueva Versión de Material'
                : 'Subir Nuevo Material',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _temaSeleccionado,
                  hint: const Text('Selecciona un tema *'),
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
                      (_modoEdicion || _modoNuevaVersion)
                          ? null
                          : (value) =>
                              setState(() => _temaSeleccionado = value),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor:
                        (_modoEdicion || _modoNuevaVersion)
                            ? Colors.grey.shade200
                            : Colors.white,
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (_modoEdicion && _materialId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Editando material: $_materialId\nVersión: ${_versionActualIdParaEditar ?? "..."}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                if (_modoNuevaVersion && _materialId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.lightBlue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Creando nueva versión para: $_materialId',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                const SizedBox(height: 12),
                TextField(
                  controller: _tituloController,
                  decoration: const InputDecoration(
                    labelText: 'Título del material *',
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
                const SizedBox(height: 12),
                TextField(
                  controller: _descripcionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción del material/versión *',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    CustomActionButton(
                      // Asumo que tu CustomActionButton no usa isSmall o ya lo adaptaste
                      text: 'PDF',
                      icon: Icons.picture_as_pdf,
                      backgroundColor: Colors.red.shade600,
                      onPressed:
                          () => _seleccionarArchivoPorExtension(['pdf'], 'pdf'),
                    ),
                    CustomActionButton(
                      text: 'Imagen',
                      icon: Icons.image,
                      backgroundColor: Colors.blue.shade700,
                      onPressed:
                          () => _seleccionarArchivoPorExtension([
                            'jpg',
                            'jpeg',
                            'png',
                            'gif',
                            'webp',
                            'bmp',
                          ], 'image'),
                    ),
                    CustomActionButton(
                      text: 'Video',
                      icon: Icons.videocam,
                      backgroundColor: Colors.deepOrange.shade700,
                      onPressed:
                          () => _seleccionarArchivoPorExtension([
                            'mp4',
                            'mov',
                            'avi',
                            'mkv',
                          ], 'video'),
                    ),
                    CustomActionButton(
                      text: 'Audio',
                      icon: Icons.audiotrack,
                      backgroundColor: Colors.purple.shade800,
                      onPressed:
                          () => _seleccionarArchivoPorExtension([
                            'mp3',
                            'wav',
                            'aac',
                          ], 'audio'),
                    ),
                    CustomActionButton(
                      text: 'Enlace',
                      icon: Icons.link,
                      backgroundColor: Colors.green.shade700,
                      onPressed: _agregarEnlace,
                    ),
                    CustomActionButton(
                      text: 'Nota',
                      icon: Icons.notes,
                      backgroundColor: Colors.indigo.shade700,
                      onPressed: _agregarNota,
                    ),
                  ],
                ),
                if (_archivos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Archivos y contenido adjunto:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF036799),
                      ),
                    ),
                  ),
                ],
                Expanded(
                  child:
                      _archivos.isEmpty
                          ? const Center(
                            child: Text(
                              'Aún no has agregado archivos o contenido.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                          : ListView.builder(
                            itemCount: _archivos.length,
                            itemBuilder:
                                (context, index) => _buildArchivoPreview(
                                  _archivos[index],
                                  index,
                                ),
                          ),
                ),

                const SizedBox(height: 12),
                AnimatedScale(
                  scale: _exitoAlSubir ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  child: CustomActionButton(
                    text:
                        _subiendo
                            ? 'Procesando...'
                            : _exitoAlSubir
                            ? '¡Listo!'
                            : (_modoEdicion
                                ? 'Guardar Cambios'
                                : (_modoNuevaVersion
                                    ? 'Guardar Nueva Versión'
                                    : 'Subir Material')),
                    icon:
                        _subiendo
                            ? Icons.hourglass_top
                            : _exitoAlSubir
                            ? Icons.check_circle_outline
                            : Icons.upload_file,
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
