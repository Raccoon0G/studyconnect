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

  String? _materialId;
  bool _modoEdicion = false;
  bool _modoNuevaVersion = false;
  String? _versionActualIdParaEditar;
  bool _argumentosCargados = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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

  @override
  void dispose() {
    _tituloController.dispose();
    _subtemaController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _cargarMaterialParaEditar() async {
    if (!mounted || _temaSeleccionado == null || _materialId == null) return;
    if (mounted) setState(() => _subiendo = true);

    final materialDocRef = FirebaseFirestore.instance
        .collection('materiales')
        .doc(_temaSeleccionado)
        .collection('Mat$_temaSeleccionado')
        .doc(_materialId);

    try {
      final materialDoc = await materialDocRef.get();
      if (!mounted) return;

      if (!materialDoc.exists) {
        if (mounted) {
          showCustomSnackbar(
            context: context,
            message: 'Error: El material a editar no fue encontrado.',
            success: false,
          );
        }
        return;
      }

      final data = materialDoc.data()!;
      _tituloController.text = data['titulo'] ?? '';
      _subtemaController.text = data['subtema'] ?? '';
      _versionActualIdParaEditar = data['versionActual'] as String?;

      if (_versionActualIdParaEditar == null && _modoEdicion) {
        if (mounted) {
          showCustomSnackbar(
            context: context,
            message:
                'Advertencia: No se encontró un ID de versión específica. Editando datos generales del material.',
            success: false,
          );
        }
        _descripcionController.text = data['descripcion'] ?? '';
        final archivosDelMaterialPrincipal = List<Map<String, dynamic>>.from(
          data['archivos'] ?? [],
        );
        if (mounted) {
          setState(() {
            _archivos.clear();
            _archivos.addAll(
              archivosDelMaterialPrincipal.map((a) {
                final Map<String, dynamic> archivoProcesado =
                    Map<String, dynamic>.from(a);
                if (archivoProcesado['tipo'] == 'link' &&
                    (archivoProcesado['nombre'] as String)
                        .toLowerCase()
                        .contains('youtu')) {
                  if (archivoProcesado['tituloMostrado'] == null ||
                      (archivoProcesado['tituloMostrado'] as String).isEmpty) {
                    archivoProcesado['tituloMostrado'] =
                        archivoProcesado['nombre'];
                  }
                }
                return archivoProcesado;
              }),
            );
          });
        }
      }

      if (_versionActualIdParaEditar != null) {
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

          if (mounted) {
            setState(() {
              _archivos.clear();
              _archivos.addAll(
                archivosDeVersion.map((a) {
                  final Map<String, dynamic> archivoProcesado =
                      Map<String, dynamic>.from(a);
                  if (archivoProcesado['tipo'] == 'link' &&
                      (archivoProcesado['nombre'] as String)
                          .toLowerCase()
                          .contains('youtu')) {
                    if (archivoProcesado['tituloMostrado'] == null ||
                        (archivoProcesado['tituloMostrado'] as String)
                            .isEmpty) {
                      archivoProcesado['tituloMostrado'] =
                          archivoProcesado['nombre'];
                    }
                  }
                  return archivoProcesado;
                }),
              );
            });
          }
        } else if (_modoEdicion) {
          if (mounted) {
            showCustomSnackbar(
              context: context,
              message:
                  'Error: No se pudo cargar la versión específica "$_versionActualIdParaEditar". Cargando datos generales.',
              success: false,
            );
          }
          _descripcionController.text = data['descripcion'] ?? '';
          final archivosDelMaterialPrincipal = List<Map<String, dynamic>>.from(
            data['archivos'] ?? [],
          );
          if (mounted) {
            setState(() {
              _archivos.clear();
              _archivos.addAll(
                archivosDelMaterialPrincipal.map((a) {
                  final Map<String, dynamic> archivoProcesado =
                      Map<String, dynamic>.from(a);
                  if (archivoProcesado['tipo'] == 'link' &&
                      (archivoProcesado['nombre'] as String)
                          .toLowerCase()
                          .contains('youtu')) {
                    if (archivoProcesado['tituloMostrado'] == null ||
                        (archivoProcesado['tituloMostrado'] as String)
                            .isEmpty) {
                      archivoProcesado['tituloMostrado'] =
                          archivoProcesado['nombre'];
                    }
                  }
                  return archivoProcesado;
                }),
              );
            });
          }
        }
      } else if (!_modoEdicion && _modoNuevaVersion) {
        _descripcionController.text = data['descripcion'] ?? '';
        final archivosDelMaterialPrincipal = List<Map<String, dynamic>>.from(
          data['archivos'] ?? [],
        );
        if (mounted) {
          setState(() {
            _archivos.clear();
            _archivos.addAll(
              archivosDelMaterialPrincipal.map((a) {
                final Map<String, dynamic> archivoProcesado =
                    Map<String, dynamic>.from(a);
                if (archivoProcesado['tipo'] == 'link' &&
                    (archivoProcesado['nombre'] as String)
                        .toLowerCase()
                        .contains('youtu')) {
                  if (archivoProcesado['tituloMostrado'] == null ||
                      (archivoProcesado['tituloMostrado'] as String).isEmpty) {
                    archivoProcesado['tituloMostrado'] =
                        archivoProcesado['nombre'];
                  }
                }
                return archivoProcesado;
              }),
            );
          });
        }
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackbar(
          context: context,
          message: 'Error al cargar datos para edición: ${e.toString()}',
          success: false,
        );
      }
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  Future<void> _confirmarEliminarArchivo(int index) async {
    if (!mounted) return;
    final archivo = _archivos[index];
    final nombre =
        archivo['tituloMostrado'] ?? archivo['nombre'] ?? 'este archivo';

    await showCustomDialog<bool>(
      context: context,
      titulo: '¿Eliminar Contenido?',
      mensaje:
          '¿Estás seguro de que deseas eliminar "${nombre.length > 50 ? "${nombre.substring(0, 50)}..." : nombre}"?',
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
              showCustomSnackbar(
                context: context,
                message: 'Contenido eliminado.',
                success: true,
              );
            }
          },
          cierraDialogo: true,
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
    String? videoId;
    if (url.contains("youtu.be/")) {
      videoId = Uri.parse(
        url,
      ).pathSegments.lastWhere((e) => e.isNotEmpty, orElse: () => '');
    } else if (url.contains("youtube.com/watch")) {
      videoId = Uri.parse(url).queryParameters['v'];
    } else if (url.contains("youtube.com/embed/")) {
      videoId = Uri.parse(
        url,
      ).pathSegments.lastWhere((e) => e.isNotEmpty, orElse: () => '');
    } else {
      final videoIdMatch = RegExp(
        r"(?:youtube(?:-nocookie)?\.com/(?:[^/\n\s]+/\S+/|(?:v|e(?:mbed)?)/|\S*?[?&]v=)|youtu\.be/)([a-zA-Z0-9_-]{11})",
      ).firstMatch(url);
      videoId = videoIdMatch?.group(1);
    }

    if (videoId == null || videoId.isEmpty) {
      print('No se pudo extraer el Video ID de: $url');
      return Future.value(url);
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
      return url;
    } catch (e) {
      print('Error al obtener título del video de YouTube: $e');
      return url;
    }
  }

  Future<void> reproducirSonidoExito() async {
    final player = AudioPlayer();
    try {
      await player.play(AssetSource('audio/successed.mp3'));
    } catch (e) {
      print("Error al reproducir sonido de éxito: $e");
    }
  }

  Future<void> reproducirSonidoError() async {
    final player = AudioPlayer();
    try {
      await player.play(AssetSource('audio/error.mp3'));
    } catch (e) {
      print("Error al reproducir sonido de error: $e");
    }
  }

  String obtenerMensajeLogroMaterial(int total) {
    if (total == 1)
      return "¡Subiste tu primer material! 📚 Bienvenido a la comunidad de colaboradores.";
    if (total == 5)
      return "¡5 materiales subidos! 🥈 Logro: Compartidor Activo. ¡Sigue inspirando!";
    if (total == 10)
      return "¡10 materiales! 🥇 Logro: Colaborador Avanzado. ¡Tus aportes son clave para todos!";
    if (total == 20)
      return "¡20 materiales! 🏆 Logro: Master Resource Giver. ¡Eres un pilar en la comunidad!";
    if (total % 10 == 0 && total > 0)
      return "¡$total materiales! ⭐ ¡Nivel leyenda en recursos! Sigue sumando éxitos.";
    if (total >= 3 && total < 5)
      return "¡Gran avance! Ya llevas $total materiales subidos.";
    if (total > 20 && total % 5 == 0)
      return "¡Wow! $total materiales subidos. ¡Inspiras a todos! 👏";

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
    if (!_formKey.currentState!.validate()) {
      await showCustomDialog(
        context: context,
        titulo: 'Campos Incompletos',
        mensaje:
            'Por favor, completa todos los campos marcados con un asterisco (*).',
        tipo: CustomDialogType.warning,
      );
      return;
    }

    if (_archivos.isEmpty) {
      showCustomSnackbar(
        context: context,
        message: 'Debes agregar al menos un archivo, enlace o nota.',
        success: false,
      );
      return;
    }

    final titulo = _tituloController.text.trim();
    final subtema = _subtemaController.text.trim();
    final descripcion = _descripcionController.text.trim();

    // 1. Revisar título, subtítulo y descripción principal
    if (ProfanityFilter.esProfano(titulo) ||
        ProfanityFilter.esProfano(subtema) ||
        ProfanityFilter.esProfano(descripcion)) {
      await showCustomDialog(
        context: context,
        titulo: 'Contenido no permitido',
        mensaje:
            'Hemos detectado lenguaje inapropiado en el título o la descripción. Por favor, revísalos.',
        tipo: CustomDialogType.error,
      );
      return; // Detiene la subida
    }

    // 2. Revisar el contenido de las notas adjuntas
    for (final archivo in _archivos) {
      if (archivo['tipo'] == 'nota') {
        final contenidoNota = archivo['nombre'] as String?;
        if (contenidoNota != null && ProfanityFilter.esProfano(contenidoNota)) {
          await showCustomDialog(
            context: context,
            titulo: 'Contenido no permitido',
            mensaje:
                'Hemos detectado lenguaje inapropiado en el contenido de una de las notas. Por favor, revísala.',
            tipo: CustomDialogType.error,
          );
          return; // Detiene la subida
        }
      }
    }

    setState(() => _subiendo = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        setState(() => _subiendo = false);
        await showCustomDialog(
          context: context,
          titulo: 'Error de Autenticación',
          mensaje:
              'No se pudo verificar tu identidad. Por favor, inicia sesión de nuevo.',
          tipo: CustomDialogType.error,
        );
      }
      return;
    }

    final nombreTema =
        temasDisponibles[_temaSeleccionado!] ?? 'Tema Desconocido';
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
          contenidoParaFirestore.add({
            'tipo': archivo['tipo'],
            'nombre': archivo['nombre'],
            'url': archivo['url'],
            'extension': archivo['extension'],
          });
        } else if (archivo['tipo'] == 'link') {
          contenidoParaFirestore.add({
            'tipo': archivo['tipo'],
            'nombre': archivo['nombre'],
            'tituloMostrado': archivo['tituloMostrado'],
            'contenido': archivo['nombre'],
          });
        } else if (archivo['tipo'] == 'nota') {
          contenidoParaFirestore.add({
            'tipo': archivo['tipo'],
            'nombre': archivo['nombre'],
            'contenido': archivo['nombre'],
            'tituloMostrado': archivo['tituloMostrado'],
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _subiendo = false);
        await showCustomDialog(
          context: context,
          titulo: 'Error al Procesar Archivos',
          mensaje:
              'Ocurrió un error al preparar los archivos para subir: ${e.toString()}.\nIntenta de nuevo.',
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
          titulo: 'Error de Contenido',
          mensaje:
              'No se pudo procesar el contenido adjunto. Asegúrate de que los archivos sean válidos.',
          tipo: CustomDialogType.error,
        );
      }
      return;
    }

    String materialDocId;
    String versionDocId;

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      if (_modoEdicion && _materialId != null) {
        materialDocId = _materialId!;

        if (_versionActualIdParaEditar != null) {
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
            'archivos': contenidoParaFirestore,
          });
        } else {
          final materialRef = coleccionMateriales.doc(materialDocId);
          batch.update(materialRef, {
            'titulo': _tituloController.text.trim(),
            'subtema': _subtemaController.text.trim(),
            'descripcion': _descripcionController.text.trim(),
            'FechMod': now,
            'archivos': contenidoParaFirestore,
          });
        }
        await batch.commit();
        if (!mounted) return;
        await _handleUploadSuccess(
          uid: uid,
          materialDocId: materialDocId,
          tituloMaterial: _tituloController.text.trim(),
          isEdit: true,
          isNewVersion: false,
          nombreTema: nombreTema,
        );
      } else if (_modoNuevaVersion && _materialId != null) {
        materialDocId = _materialId!;
        final materialRef = coleccionMateriales.doc(materialDocId);

        final versionesSnap =
            await materialRef
                .collection('Versiones')
                .orderBy('Fecha', descending: true)
                .limit(1)
                .get();

        int versionNum;
        if (versionesSnap.docs.isEmpty) {
          versionNum = 1;
        } else {
          final ultimoIdVersion = versionesSnap.docs.first.id;
          final match = RegExp(r'Version_(\d+)').firstMatch(ultimoIdVersion);
          versionNum =
              (match != null ? int.tryParse(match.group(1)!) ?? 0 : 0) + 1;
        }
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
          'archivos': contenidoParaFirestore,
        });

        await batch.commit();
        if (!mounted) return;
        await _handleUploadSuccess(
          uid: uid,
          materialDocId: materialDocId,
          tituloMaterial: _tituloController.text.trim(),
          isEdit: false,
          isNewVersion: true,
          nombreTema: nombreTema,
        );
      } else {
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
          'archivos': contenidoParaFirestore,
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

        await _handleUploadSuccess(
          uid: uid,
          materialDocId: materialDocId,
          tituloMaterial: _tituloController.text.trim(),
          isEdit: false,
          isNewVersion: false,
          totalSubidos: totalSubidos,
          nombreTema: nombreTema,
        );
        if (mounted) {
          setState(() {
            _formKey.currentState?.reset();
            _temaSeleccionado = null;
            _subtemaController.clear();
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
          await Future.delayed(const Duration(milliseconds: 1800));
          if (mounted) setState(() => _exitoAlSubir = false);
        }
      }
    } catch (e) {
      if (mounted) {
        await reproducirSonidoError();
        setState(() => _subiendo = false);
        await showFeedbackDialogAndSnackbar(
          context: context,
          titulo: 'Error al Guardar Material',
          mensaje:
              'Ocurrió un error inesperado: ${e.toString()}.\nPor favor, inténtalo de nuevo.',
          tipo: CustomDialogType.error,
          snackbarMessage: '❌ Hubo un error al guardar el material.',
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
          final player = AudioPlayer();
          try {
            await player.play(AssetSource('audio/tip.mp3'));
          } catch (_) {}
          await showCustomDialog(
            context: context,
            titulo: '¡Consejo Útil!',
            mensaje: randomTip,
            tipo: CustomDialogType.info,
          );
        }
      }
    }
  }

  Future<void> _handleUploadSuccess({
    required String uid,
    required String materialDocId,
    required String tituloMaterial,
    required bool isEdit,
    required bool isNewVersion,
    int? totalSubidos,
    required String nombreTema,
  }) async {
    if (!mounted) return;

    String notificationTitle = '';
    String notificationBody = '';
    String notificationType = '';
    String dialogTitle = '';
    String dialogMessage = '';
    String snackbarMessage = '';

    if (isEdit) {
      notificationTitle = '¡Material Editado!';
      notificationBody = 'Has editado tu material: "$tituloMaterial".';
      notificationType = 'material_editado';
      dialogTitle = '¡Editado Correctamente!';
      dialogMessage = 'El material "$tituloMaterial" fue editado exitosamente.';
      snackbarMessage = 'Material editado y guardado.';
    } else if (isNewVersion) {
      notificationTitle = '¡Nueva Versión de Material!';
      notificationBody =
          'Se añadió una nueva versión a tu material: "$tituloMaterial".';
      notificationType = 'material_nueva_version';
      dialogTitle = '¡Nueva Versión Guardada!';
      dialogMessage =
          'La nueva versión de "$tituloMaterial" se agregó exitosamente.';
      snackbarMessage = 'Nueva versión guardada.';
    } else {
      notificationTitle = '¡Material Subido!';
      notificationBody = obtenerMensajeLogroMaterial(totalSubidos!);
      notificationType = 'material_nuevo';
      dialogTitle = '¡Éxito Total!';
      dialogMessage =
          'El material "$tituloMaterial" se subió correctamente a la plataforma.';
      snackbarMessage = 'Material guardado con éxito.';
    }

    await NotificationService.crearNotificacion(
      uidDestino: uid,
      tipo: notificationType,
      titulo: notificationTitle,
      contenido: notificationBody,
      referenciaId: materialDocId,
      tema: _temaSeleccionado!,
      uidEmisor: uid,
      nombreEmisor:
          _nombreUsuario ?? (isEdit || isNewVersion ? 'Sistema' : 'Tú'),
    );

    await LocalNotificationService.show(
      title: notificationTitle,
      body:
          isEdit || isNewVersion
              ? notificationBody
              : 'Tu material en "$nombreTema" fue guardado exitosamente.',
    );

    await reproducirSonidoExito();

    if (mounted) {
      if (isEdit || isNewVersion) {
        await showFeedbackDialogAndSnackbar(
          context: context,
          titulo: dialogTitle,
          mensaje: dialogMessage,
          tipo: CustomDialogType.success,
          snackbarMessage: snackbarMessage,
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
      } else {
        await showFeedbackDialogAndSnackbar(
          context: context,
          titulo: dialogTitle,
          mensaje: dialogMessage,
          tipo: CustomDialogType.success,
          snackbarMessage: snackbarMessage,
          snackbarSuccess: true,
        );
      }
    }
  }

  Future<void> _seleccionarArchivoPorExtension(
    List<String> extensiones,
    String tipo,
  ) async {
    if (_archivos.length >= 10) {
      showCustomSnackbar(
        context: context,
        message: "Has alcanzado el límite de 10 contenidos.",
        success: false,
      );
      return;
    }
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: extensiones,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes != null && file.bytes!.isNotEmpty) {
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
            message: "El archivo '${file.name}' está vacío o no se pudo leer.",
            success: false,
          );
        }
      }
    }
  }

  void _agregarEnlace() {
    if (_archivos.length >= 10) {
      showCustomSnackbar(
        context: context,
        message: "Has alcanzado el límite de 10 contenidos.",
        success: false,
      );
      return;
    }

    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoadingTitle = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (stfContext, stfSetState) {
            return AlertDialog(
              title: const Text('Agregar Enlace Externo'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText:
                            'https://www.youtube.com/... o https://ejemplo.com',
                        labelText: 'URL del Enlace *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, ingresa un enlace.';
                        }
                        final uri = Uri.tryParse(value.trim());
                        if (uri == null ||
                            !uri.hasAbsolutePath ||
                            !uri.hasScheme) {
                          return 'Por favor, ingresa un enlace válido (ej. https://...)';
                        }
                        return null;
                      },
                    ),
                    if (isLoadingTitle)
                      const Padding(
                        padding: EdgeInsets.only(top: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text("Obteniendo título..."),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed:
                      isLoadingTitle
                          ? null
                          : () async {
                            if (formKey.currentState!.validate()) {
                              final enlace = controller.text.trim();
                              final yaExiste = _archivos.any(
                                (archivo) =>
                                    archivo['tipo'] == 'link' &&
                                    archivo['nombre'] == enlace,
                              );

                              if (yaExiste) {
                                Navigator.pop(dialogContext);
                                if (mounted) {
                                  showCustomSnackbar(
                                    context: context,
                                    message: 'Este enlace ya ha sido agregado.',
                                    success: false,
                                  );
                                }
                                return;
                              }

                              stfSetState(() => isLoadingTitle = true);

                              String tituloMostrado = enlace;
                              if (enlace.toLowerCase().contains(
                                    "youtube.com",
                                  ) ||
                                  enlace.toLowerCase().contains("youtu.be")) {
                                tituloMostrado =
                                    await obtenerTituloVideoYoutube(enlace) ??
                                    enlace;
                              }

                              stfSetState(() => isLoadingTitle = false);

                              if (mounted) {
                                setState(() {
                                  _archivos.add({
                                    'nombre': enlace,
                                    'tipo': 'link',
                                    'tituloMostrado': tituloMostrado,
                                  });
                                });
                              }
                              Navigator.pop(dialogContext);
                            }
                          },
                  child: const Text('Agregar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _agregarNota() {
    if (_archivos.length >= 10) {
      showCustomSnackbar(
        context: context,
        message: "Has alcanzado el límite de 10 contenidos.",
        success: false,
      );
      return;
    }
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Agregar Nueva Nota'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Contenido de la nota *',
                hintText: 'Escribe tu nota aquí...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              minLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La nota no puede estar vacía.';
                }
                if (value.trim().length < 5) {
                  return 'La nota debe tener al menos 5 caracteres.';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final nota = controller.text.trim();
                  final yaExiste = _archivos.any(
                    (archivo) =>
                        archivo['tipo'] == 'nota' && archivo['nombre'] == nota,
                  );

                  if (yaExiste) {
                    Navigator.pop(dialogContext);
                    if (mounted) {
                      showCustomSnackbar(
                        context: context,
                        message:
                            'Esta nota (o una idéntica) ya ha sido agregada.',
                        success: false,
                      );
                    }
                    return;
                  }
                  if (mounted) {
                    setState(() {
                      _archivos.add({
                        'nombre': nota,
                        'tipo': 'nota',
                        'tituloMostrado':
                            'Nota: ${nota.substring(0, nota.length > 20 ? 20 : nota.length)}${nota.length > 20 ? "..." : ""}',
                      });
                    });
                  }
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Agregar Nota'),
            ),
          ],
        );
      },
    );
  }

  String _extractYoutubeIdFromUrl(String url) {
    if (url.isEmpty) return '';
    RegExp regExp = RegExp(
      r"^.*(?:(?:youtu\.be\/|v\/|vi\/|u\/\w\/|embed\/|shorts\/)|(?:(?:watch)?\?v(?:i)?=|\&v(?:i)?=))([^#\&\?]*).*",
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
    final uri = Uri.tryParse(url);
    if (uri != null && (uri.isScheme("http") || uri.isScheme("https"))) {
      html.window.open(url, '_blank');
    } else {
      if (mounted) {
        showCustomSnackbar(
          context: context,
          message: "El enlace no es válido para abrir.",
          success: false,
        );
      }
    }
  }

  Widget _buildArchivoPreview(Map<String, dynamic> archivo, int index) {
    final tipo = archivo['tipo'] as String?;
    final nombreOriginal =
        archivo['nombre'] as String? ?? 'Contenido sin nombre';
    final tituloParaMostrarEnUI =
        archivo['tituloMostrado'] as String? ?? nombreOriginal;

    final theme = Theme.of(context);

    Widget leadingWidget;
    String subtituloParaMostrarEnUI = '';

    IconData defaultIcon;
    Color defaultIconColor;

    switch (tipo) {
      case 'pdf':
        leadingWidget = Icon(
          Icons.picture_as_pdf_rounded,
          color: Colors.red.shade700,
          size: 40,
        );
        subtituloParaMostrarEnUI = "Documento PDF";
        break;
      case 'image':
        defaultIcon = Icons.broken_image_rounded;
        defaultIconColor = Colors.grey;
        if (archivo['bytes'] != null) {
          leadingWidget = SizedBox(
            width: 60,
            height: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                archivo['bytes'] as Uint8List,
                fit: BoxFit.cover,
                errorBuilder:
                    (ctx, err, st) =>
                        Icon(defaultIcon, color: defaultIconColor, size: 40),
              ),
            ),
          );
        } else if (archivo['url'] != null) {
          leadingWidget = SizedBox(
            width: 60,
            height: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                archivo['url'] as String,
                fit: BoxFit.cover,
                errorBuilder:
                    (ctx, err, st) =>
                        Icon(defaultIcon, color: defaultIconColor, size: 40),
                loadingBuilder: (
                  BuildContext context,
                  Widget child,
                  ImageChunkEvent? loadingProgress,
                ) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                      strokeWidth: 2,
                    ),
                  );
                },
              ),
            ),
          );
        } else {
          leadingWidget = Icon(
            Icons.image_rounded,
            color: Colors.blue.shade700,
            size: 40,
          );
        }
        subtituloParaMostrarEnUI = "Archivo de Imagen";
        break;
      case 'video':
        leadingWidget = Icon(
          Icons.movie_creation_rounded,
          color: Colors.orange.shade700,
          size: 40,
        );
        subtituloParaMostrarEnUI = "Archivo de Video";
        break;
      case 'audio':
        leadingWidget = Icon(
          Icons.audiotrack_rounded,
          color: Colors.purple.shade700,
          size: 40,
        );
        subtituloParaMostrarEnUI = "Archivo de Audio";
        break;
      case 'link':
        final videoId = _extractYoutubeIdFromUrl(nombreOriginal);
        if (videoId.isNotEmpty) {
          final thumbnailUrl =
              'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
          leadingWidget = SizedBox(
            width: 80,
            height: 50,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder:
                    (ctx, err, st) => Icon(
                      Icons.play_circle_outline_rounded,
                      color: Colors.red.shade700,
                      size: 40,
                    ),
                loadingBuilder: (
                  BuildContext context,
                  Widget child,
                  ImageChunkEvent? loadingProgress,
                ) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              ),
            ),
          );
          subtituloParaMostrarEnUI = nombreOriginal;
        } else {
          leadingWidget = Icon(
            Icons.link_rounded,
            color: Colors.green.shade700,
            size: 40,
          );
          subtituloParaMostrarEnUI = "Enlace Web";
        }
        break;
      case 'nota':
        leadingWidget = Icon(
          Icons.note_alt_rounded,
          color: Colors.amber.shade800,
          size: 40,
        );
        subtituloParaMostrarEnUI = "Nota Personal";
        break;
      default:
        leadingWidget = Icon(
          Icons.attach_file_rounded,
          color: Colors.grey.shade700,
          size: 40,
        );
        subtituloParaMostrarEnUI = "Archivo adjunto";
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Padding(
          padding: const EdgeInsets.all(4.0),
          child: leadingWidget,
        ),
        title: Text(
          tituloParaMostrarEnUI,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          subtituloParaMostrarEnUI,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tipo == 'link')
              IconButton(
                icon: Icon(
                  Icons.open_in_new_rounded,
                  color: theme.colorScheme.secondary,
                  size: 22,
                ),
                tooltip: 'Abrir enlace',
                onPressed: () => _abrirEnlaceEnWeb(nombreOriginal),
              ),
            IconButton(
              icon: Icon(
                Icons.delete_forever_rounded,
                color: theme.colorScheme.error,
                size: 22,
              ),
              tooltip: 'Eliminar',
              onPressed: () => _confirmarEliminarArchivo(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool isContentCounter = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        top: isContentCounter ? 12.0 : 20.0,
        bottom: 8.0,
      ),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAddContentButtons() {
    final theme = Theme.of(context);

    final pdfStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.red.shade100,
      foregroundColor: Colors.red.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      elevation: 1,
    );
    final imageStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.blue.shade100,
      foregroundColor: Colors.blue.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      elevation: 1,
    );
    final videoStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.orange.shade100,
      foregroundColor: Colors.orange.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      elevation: 1,
    );
    final audioStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.purple.shade100,
      foregroundColor: Colors.purple.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      elevation: 1,
    );
    final linkStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.green.shade100,
      foregroundColor: Colors.green.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      elevation: 1,
    );
    final noteStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.indigo.shade100,
      foregroundColor: Colors.indigo.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      elevation: 1,
    );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.start,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
          label: const Text('PDF'),
          style: pdfStyle,
          onPressed: () => _seleccionarArchivoPorExtension(['pdf'], 'pdf'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.image_rounded, size: 18),
          label: const Text('Imagen'),
          style: imageStyle,
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
        ElevatedButton.icon(
          icon: const Icon(Icons.movie_filter_rounded, size: 18),
          label: const Text('Video'),
          style: videoStyle,
          onPressed:
              () => _seleccionarArchivoPorExtension([
                'mp4',
                'mov',
                'avi',
                'mkv',
                'webm',
              ], 'video'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.graphic_eq_rounded, size: 18),
          label: const Text('Audio'),
          style: audioStyle,
          onPressed:
              () => _seleccionarArchivoPorExtension([
                'mp3',
                'wav',
                'aac',
                'ogg',
                'm4a',
              ], 'audio'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.add_link_rounded, size: 18),
          label: const Text('Enlace'),
          style: linkStyle,
          onPressed: _agregarEnlace,
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.note_add_rounded, size: 18),
          label: const Text('Nota'),
          style: noteStyle,
          onPressed: _agregarNota,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isEditingOrNewVersion = _modoEdicion || _modoNuevaVersion;

    String appBarTitle = 'Subir Nuevo Material';
    String mainActionButtonText = 'Subir Material';

    if (_modoEdicion) {
      appBarTitle = 'Editar Material Existente';
      mainActionButtonText = 'Guardar Cambios';
    } else if (_modoNuevaVersion) {
      appBarTitle = 'Crear Nueva Versión';
      mainActionButtonText = 'Guardar Nueva Versión';
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(showBack: true, titleText: appBarTitle),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: theme.cardColor,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isEditingOrNewVersion)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color:
                            _modoEdicion
                                ? theme.colorScheme.tertiaryContainer
                                : theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (_modoEdicion
                                  ? theme.colorScheme.tertiary
                                  : theme.colorScheme.secondary)
                              .withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        _modoEdicion
                            ? 'Modo Edición: Estás modificando "${_tituloController.text.isNotEmpty ? _tituloController.text : (_materialId ?? "Material")}" (Versión: ${_versionActualIdParaEditar ?? "Principal"})'
                            : 'Nueva Versión para: "${_tituloController.text.isNotEmpty ? _tituloController.text : (_materialId ?? "Material")}"',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color:
                              _modoEdicion
                                  ? theme.colorScheme.onTertiaryContainer
                                  : theme.colorScheme.onSecondaryContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  DropdownButtonFormField<String>(
                    value: _temaSeleccionado,
                    hint: const Text('Selecciona un tema *'),
                    items:
                        temasDisponibles.entries
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(
                                  e.value,
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged:
                        isEditingOrNewVersion
                            ? null
                            : (value) =>
                                setState(() => _temaSeleccionado = value),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor:
                          isEditingOrNewVersion
                              ? theme.disabledColor.withOpacity(0.1)
                              : theme.inputDecorationTheme.fillColor,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.school_rounded,
                        color: theme.hintColor,
                      ),
                    ),
                    validator:
                        (value) =>
                            value == null ? 'El tema es obligatorio.' : null,
                    disabledHint:
                        _temaSeleccionado != null
                            ? Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10.0,
                              ),
                              child: Text(
                                temasDisponibles[_temaSeleccionado!] ??
                                    'Tema actual',
                                style: TextStyle(
                                  color: theme.textTheme.bodyLarge?.color
                                      ?.withOpacity(0.7),
                                ),
                              ),
                            )
                            : const Text("El tema no se puede cambiar"),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _tituloController,
                    decoration: InputDecoration(
                      labelText: 'Título del material *',
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      prefixIcon: Icon(
                        Icons.title_rounded,
                        color: theme.hintColor,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'El título es obligatorio.';
                      if (value.trim().length < 5)
                        return 'El título debe tener al menos 5 caracteres.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _subtemaController,
                    decoration: InputDecoration(
                      labelText: 'Subtema (opcional)',
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      prefixIcon: Icon(
                        Icons.subject_rounded,
                        color: theme.hintColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descripcionController,
                    maxLines: 4,
                    minLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Descripción del material/versión *',
                      hintText:
                          'Detalla el contenido, propósito, o cambios en esta versión...',
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      alignLabelWithHint: true,
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(bottom: 40.0),
                        child: Icon(
                          Icons.description_rounded,
                          color: theme.hintColor,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'La descripción es obligatoria.';
                      if (value.trim().length < 10)
                        return 'La descripción debe tener al menos 10 caracteres.';
                      return null;
                    },
                  ),

                  _buildSectionTitle('Agregar Contenido (Máx. 10)'),
                  _buildAddContentButtons(),
                  const SizedBox(height: 10),

                  if (_archivos.isNotEmpty)
                    _buildSectionTitle(
                      'Contenido Adjunto (${_archivos.length}/10):',
                      isContentCounter: true,
                    ),

                  _archivos.isEmpty
                      ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.cloud_off_rounded,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Aún no has agregado contenido.\n¡Usa los botones de arriba!',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14.5,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _archivos.length,
                        itemBuilder:
                            (context, index) =>
                                _buildArchivoPreview(_archivos[index], index),
                      ),
                  const SizedBox(height: 24),

                  AnimatedScale(
                    scale: _exitoAlSubir ? 1.03 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    child: CustomActionButton(
                      text:
                          _subiendo
                              ? 'Procesando...'
                              : _exitoAlSubir
                              ? '¡Guardado!'
                              : mainActionButtonText,
                      icon:
                          _subiendo
                              ? Icons.sync_rounded
                              : _exitoAlSubir
                              ? Icons.check_circle_rounded
                              : (isEditingOrNewVersion
                                  ? Icons.save_alt_rounded
                                  : Icons.cloud_upload_rounded),
                      // En el código antiguo:
                      onPressed: () {
                        if (!_subiendo && !_exitoAlSubir) {
                          // La condición para ejecutar estaba DENTRO de la función síncrona
                          _subirMaterialEducativo(); // Llamada a la función async, pero la función onPressed en sí era síncrona
                        }
                      },
                      backgroundColor:
                          _exitoAlSubir
                              ? Colors.green.shade700
                              : (_subiendo
                                  ? Colors.grey.shade600
                                  : theme.colorScheme.primary),
                      animar: _subiendo,
                      girarIcono: _subiendo,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
