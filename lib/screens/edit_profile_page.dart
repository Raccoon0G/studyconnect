import 'dart:io'; // Para File (móvil)
import 'dart:typed_data'; // Para Uint8List
import 'package:flutter/foundation.dart' show kIsWeb; // Para kIsWeb

// Importaciones de Firebase
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Flutter y UI
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Selectores de Imágenes
import 'package:image_picker/image_picker.dart'; // Para móvil/otras plataformas
import 'dart:html' as html; // Para web

// Tus importaciones (asegúrate que la ruta sea correcta)
import 'package:study_connect/widgets/custom_app_bar.dart'; // TU CUSTOM APP BAR MODIFICADO
import 'package:study_connect/models/usuario_model.dart'; // Importa tu clase Usuario

// --- CONSTANTES ---
const String routeUserProfile = '/user_profile';
const String routeHome = '/';
const String usersCollection = 'usuarios';
const String profilePhotosStoragePath = 'fotos_perfil';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final User? firebaseAuthUser = FirebaseAuth.instance.currentUser;

  Usuario? _usuarioActual;
  Usuario? _usuarioOriginalParaComparar;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  Uint8List? _newProfileImageBytes;

  bool isLoading = true;
  bool isSaving = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario().then((_) {
      if (_usuarioActual != null) {
        _addListenersToDetectChanges();
      }
    });
  }

  void _addListenersToDetectChanges() {
    nameController.addListener(_checkForUnsavedChanges);
    phoneController.addListener(_checkForUnsavedChanges);
    roleController.addListener(_checkForUnsavedChanges);
    bioController.addListener(_checkForUnsavedChanges);
  }

  void _removeListeners() {
    nameController.removeListener(_checkForUnsavedChanges);
    phoneController.removeListener(_checkForUnsavedChanges);
    roleController.removeListener(_checkForUnsavedChanges);
    bioController.removeListener(_checkForUnsavedChanges);
  }

  void _checkForUnsavedChanges() {
    if (_usuarioOriginalParaComparar == null || _usuarioActual == null) return;
    bool changed = false;
    if (nameController.text.trim() != _usuarioOriginalParaComparar!.nombre)
      changed = true;
    if ((phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim()) !=
        _usuarioOriginalParaComparar!.telefono)
      changed = true;
    if ((roleController.text.trim().isEmpty
            ? null
            : roleController.text.trim()) !=
        _usuarioOriginalParaComparar!.rol)
      changed = true;
    if ((bioController.text.trim().isEmpty
            ? null
            : bioController.text.trim()) !=
        _usuarioOriginalParaComparar!.acercaDeMi)
      changed = true;
    if (_newProfileImageBytes != null) changed = true;
    if (_usuarioActual!.fotoPerfilUrl !=
        _usuarioOriginalParaComparar!.fotoPerfilUrl)
      changed = true;

    // if (_usuarioActual!.config['ModoOscuro'] !=
    //     _usuarioOriginalParaComparar!.config['ModoOscuro'])
    //   changed = true;
    if (_usuarioActual!.config['Notificaciones'] !=
        _usuarioOriginalParaComparar!.config['Notificaciones'])
      changed = true;
    if (_usuarioActual!.config['PerfilVisible'] !=
        _usuarioOriginalParaComparar!.config['PerfilVisible'])
      changed = true;

    if (mounted && _hasUnsavedChanges != changed) {
      setState(() {
        _hasUnsavedChanges = changed;
      });
    }
  }

  Future<bool> _handlePopNavigation() async {
    _checkForUnsavedChanges();
    if (_hasUnsavedChanges) {
      final bool? shouldPop = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Cambios sin guardar'),
              content: const Text(
                'Tienes cambios sin guardar. ¿Estás seguro de que quieres salir?',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Salir'),
                ),
              ],
            ),
      );
      return shouldPop ?? false;
    }
    return true;
  }

  @override
  void dispose() {
    _removeListeners();
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    roleController.dispose();
    bioController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosUsuario() async {
    setState(() => isLoading = true);
    if (firebaseAuthUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no autenticado.')),
        );
        setState(() => isLoading = false);
      }
      return;
    }

    try {
      final docSnap =
          await FirebaseFirestore.instance
              .collection(usersCollection)
              .doc(firebaseAuthUser!.uid)
              .get();

      if (docSnap.exists && mounted) {
        _usuarioActual = Usuario.fromFirestore(docSnap);
        _usuarioOriginalParaComparar = Usuario(
          id: _usuarioActual!.id,
          nombre: _usuarioActual!.nombre,
          correo: _usuarioActual!.correo,
          telefono: _usuarioActual!.telefono,
          rol: _usuarioActual!.rol,
          acercaDeMi: _usuarioActual!.acercaDeMi,
          fotoPerfilUrl: _usuarioActual!.fotoPerfilUrl,
          config: Map<String, bool>.from(_usuarioActual!.config),
        );

        nameController.text = _usuarioActual!.nombre;
        emailController.text = _usuarioActual!.correo;
        phoneController.text = _usuarioActual!.telefono ?? '';
        roleController.text = _usuarioActual!.rol ?? '';
        bioController.text = _usuarioActual!.acercaDeMi ?? '';
      } else if (mounted) {
        _usuarioActual = Usuario(
          id: firebaseAuthUser!.uid,
          nombre: firebaseAuthUser!.displayName ?? '',
          correo: firebaseAuthUser!.email ?? '',
          fotoPerfilUrl: firebaseAuthUser!.photoURL,
        );
        _usuarioOriginalParaComparar = Usuario(
          id: _usuarioActual!.id,
          nombre: _usuarioActual!.nombre,
          correo: _usuarioActual!.correo,
          fotoPerfilUrl: _usuarioActual!.fotoPerfilUrl,
          config: Map<String, bool>.from(_usuarioActual!.config),
        );
        nameController.text = _usuarioActual!.nombre;
        emailController.text = _usuarioActual!.correo;
        phoneController.text = '';
        roleController.text = '';
        bioController.text = '';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil no encontrado, se muestran datos base.'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al cargar datos del usuario: $e');
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar perfil: ${e.toString()}')),
        );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _seleccionarImagen() async {
    if (isSaving) return;
    try {
      if (kIsWeb) {
        final uploadInput =
            html.FileUploadInputElement()
              ..accept = 'image/*,image/jpeg,image/png,image/webp';
        uploadInput.click();
        uploadInput.onChange.listen((e) {
          final files = uploadInput.files;
          if (files != null && files.isNotEmpty) {
            final file = files.first;
            if (file.size > 5 * 1024 * 1024) {
              if (mounted)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Imagen muy grande (max 5MB).')),
                );
              return;
            }
            final reader = html.FileReader();
            reader.readAsArrayBuffer(file);
            reader.onLoadEnd.listen((event) {
              if (mounted)
                setState(() {
                  _newProfileImageBytes = reader.result as Uint8List?;
                  _checkForUnsavedChanges();
                });
            });
          }
        });
      } else {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 70,
          maxHeight: 1024,
          maxWidth: 1024,
        );
        if (pickedFile != null && mounted) {
          final bytes = await pickedFile.readAsBytes();
          if (bytes.lengthInBytes > 5 * 1024 * 1024) {
            if (mounted)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Imagen muy grande (max 5MB).')),
              );
            return;
          }
          setState(() {
            _newProfileImageBytes = bytes;
            _checkForUnsavedChanges();
          });
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: ${e.toString()}'),
          ),
        );
      debugPrint("Error al seleccionar imagen: $e");
    }
  }

  Future<void> _quitarFotoPerfil() async {
    if (_usuarioActual == null || isSaving) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Quitar foto de perfil'),
            content: const Text(
              '¿Estás seguro de que quieres quitar tu foto de perfil actual?',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Quitar'),
              ),
            ],
          ),
    );
    if (confirm == true && mounted) {
      setState(() {
        _usuarioActual!.fotoPerfilUrl = null;
        _newProfileImageBytes = null;
        _checkForUnsavedChanges();
      });
    }
  }

  Future<String?> _subirNuevaImagenSiExiste() async {
    if (firebaseAuthUser == null) return _usuarioActual?.fotoPerfilUrl;
    if (_newProfileImageBytes == null && _usuarioActual?.fotoPerfilUrl != null)
      return _usuarioActual!.fotoPerfilUrl;
    if (_newProfileImageBytes == null && _usuarioActual?.fotoPerfilUrl == null)
      return null;

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child(profilePhotosStoragePath)
          .child(firebaseAuthUser!.uid)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = await ref.putData(_newProfileImageBytes!, metadata);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error al subir imagen: $e');
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir imagen: ${e.toString()}')),
        );
      return _usuarioActual?.fotoPerfilUrl;
    }
  }

  Future<void> _guardarCambios() async {
    if (firebaseAuthUser == null || _usuarioActual == null) return;
    if (!_formKey.currentState!.validate()) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("¿Guardar cambios?"),
            content: const Text("¿Deseas guardar los cambios realizados?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancelar"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Aceptar"),
              ),
            ],
          ),
    );
    if (confirm != true) return;

    setState(() => isSaving = true);

    try {
      final String? nuevaFotoUrl = await _subirNuevaImagenSiExiste();

      _usuarioActual!.nombre = nameController.text.trim();
      _usuarioActual!.telefono =
          phoneController.text.trim().isEmpty
              ? null
              : phoneController.text.trim();
      _usuarioActual!.rol =
          roleController.text.trim().isEmpty
              ? null
              : roleController.text.trim();
      _usuarioActual!.acercaDeMi =
          bioController.text.trim().isEmpty ? null : bioController.text.trim();
      _usuarioActual!.fotoPerfilUrl = nuevaFotoUrl;

      await FirebaseFirestore.instance
          .collection(usersCollection)
          .doc(_usuarioActual!.id)
          .set(_usuarioActual!.toMap(), SetOptions(merge: true));

      if (mounted) {
        _newProfileImageBytes = null;
        final updatedDocSnap =
            await FirebaseFirestore.instance
                .collection(usersCollection)
                .doc(_usuarioActual!.id)
                .get();
        if (updatedDocSnap.exists) {
          _usuarioOriginalParaComparar = Usuario.fromFirestore(updatedDocSnap);
        }
        setState(() {
          _hasUnsavedChanges = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente')),
        );
        Navigator.pushReplacementNamed(context, routeUserProfile);
      }
    } catch (e) {
      debugPrint('ERROR al guardar cambios: $e');
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar cambios: ${e.toString()}')),
        );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> _reenviarEmailVerificacion() async {
    if (firebaseAuthUser == null || isSaving) return;
    setState(() => isSaving = true);
    try {
      await firebaseAuthUser?.sendEmailVerification();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Correo de verificación enviado.')),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar correo: ${e.toString()}')),
        );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> _enviarCambioContrasena() async {
    if (firebaseAuthUser == null || firebaseAuthUser!.email == null || isSaving)
      return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("¿Cambiar contraseña?"),
            content: Text(
              "Te enviaremos un correo a ${firebaseAuthUser!.email} para restablecer tu contraseña. ¿Deseas continuar?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancelar"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Aceptar"),
              ),
            ],
          ),
    );
    if (confirm != true) return;

    setState(() => isSaving = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: firebaseAuthUser!.email!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Correo de restablecimiento enviado a ${firebaseAuthUser!.email!}',
            ),
          ),
        );
        Navigator.pushReplacementNamed(context, routeUserProfile);
      }
    } catch (e) {
      debugPrint("Error al enviar correo de restablecimiento: $e");
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar correo: ${e.toString()}')),
        );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  // En _EditProfilePageState

  Future<void> _eliminarCuenta() async {
    if (firebaseAuthUser == null || _usuarioActual == null || isSaving) return;

    final confirmarEliminacion = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("¿Eliminar cuenta?"),
            content: const Text(
              "Esta acción es irreversible. ¿Estás seguro de que deseas eliminar tu cuenta?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancelar"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Eliminar",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
    if (confirmarEliminacion != true) return;

    final eliminarAportaciones = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("¿Eliminar tus ejercicios también?"),
            content: const Text(
              "¿Deseas que también se borren tus ejercicios o materiales subidos?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("No"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Sí, eliminar todo"),
              ),
            ],
          ),
    );
    // Si el usuario cierra este diálogo, no continuamos.
    if (eliminarAportaciones == null) return;

    setState(() => isSaving = true);
    try {
      // --- INICIO DE LA LÓGICA DE BORRADO ---
      // 1. Eliminar datos de Firestore (como ya lo hacías)
      if (eliminarAportaciones == true) {
        await _eliminarAportacionesUsuario(_usuarioActual!.id);
      }
      await FirebaseFirestore.instance
          .collection(usersCollection)
          .doc(_usuarioActual!.id)
          .delete();

      // 2. Eliminar el usuario de Firebase Auth
      await firebaseAuthUser!.delete();

      // 3. Si todo sale bien, navegar fuera
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta eliminada correctamente.')),
        );
        Navigator.pushNamedAndRemoveUntil(context, routeHome, (route) => false);
      }
      // --- FIN DE LA LÓGICA DE BORRADO ---
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // --- INICIO DE LA NUEVA LÓGICA DE REAUTENTICACIÓN ---
        if (!mounted) return;
        setState(
          () => isSaving = false,
        ); // Desactivar el loading para mostrar el diálogo

        final passwordController = TextEditingController();
        final bool? reautenticado = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text("Confirmación requerida"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Por seguridad, ingresa tu contraseña para continuar con la eliminación.",
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancelar"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (passwordController.text.trim().isEmpty) return;

                      setState(
                        () => isSaving = true,
                      ); // Activar loading de nuevo

                      final credencial = EmailAuthProvider.credential(
                        email: firebaseAuthUser!.email!,
                        password: passwordController.text.trim(),
                      );

                      try {
                        await firebaseAuthUser!.reauthenticateWithCredential(
                          credencial,
                        );
                        Navigator.pop(
                          context,
                          true,
                        ); // Contraseña correcta, cerrar diálogo y proceder
                      } on FirebaseAuthException catch (reauthError) {
                        Navigator.pop(context); // Cerrar diálogo de contraseña
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Contraseña incorrecta. Intenta de nuevo. Error: ${reauthError.code}",
                            ),
                          ),
                        );
                      } finally {
                        if (mounted) setState(() => isSaving = false);
                      }
                    },
                    child: const Text("Confirmar"),
                  ),
                ],
              ),
        );

        // Si la reautenticación fue exitosa, reintentamos la eliminación
        if (reautenticado == true) {
          await _eliminarCuenta(); // Vuelve a llamar a la función entera para reintentar
        }
        // --- FIN DE LA NUEVA LÓGICA ---
      } else {
        // Manejar otros errores de FirebaseAuth
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error al eliminar cuenta: ${e.message ?? e.code}"),
              duration: const Duration(seconds: 6),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error al eliminar cuenta: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error desconocido al eliminar cuenta: ${e.toString()}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> _eliminarAportacionesUsuario(String uid) async {
    final categorias = ['FnAlg', 'Lim', 'Der', 'TecInteg'];
    final firestore = FirebaseFirestore.instance;
    WriteBatch batch = firestore.batch();
    try {
      for (final cat in categorias) {
        final ejerQuery =
            await firestore
                .collection('calculo')
                .doc(cat)
                .collection('Ejer$cat')
                .where('AutorId', isEqualTo: uid)
                .get();
        for (final doc in ejerQuery.docs) {
          batch.delete(doc.reference);
        }
      }
      final matsQuery =
          await firestore
              .collection('Materiales')
              .where('AutorId', isEqualTo: uid)
              .get();
      for (final doc in matsQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint("Error al eliminar aportaciones: $e");
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error al eliminar algunas aportaciones."),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool emailEstaVerificado = firebaseAuthUser?.emailVerified ?? false;

    // Define las reglas de color para la pista del interruptor
    final MaterialStateProperty<Color?> trackColor =
        MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
          // Si el estado es "seleccionado" (encendido), usa el color primario
          if (states.contains(MaterialState.selected)) {
            return theme.colorScheme.primary.withOpacity(0.6);
          }
          // Si no, para el estado "apagado", usa un gris claro
          return Colors.grey.shade300;
        });

    // Define las reglas de color para el círculo del interruptor
    final MaterialStateProperty<Color?> thumbColor =
        MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            return theme.colorScheme.primary;
          }
          // Si está "apagado", usa un gris sólido y visible
          return Colors.grey.shade500;
        });

    return PopScope(
      canPop: false, // Siempre interceptar
      // USANDO onPopInvokedWithResult SEGÚN SUGERENCIA DEL LINTER
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        _handlePopNavigation().then((bool shouldPop) {
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        });
      },
      child: Scaffold(
        // backgroundColor: theme.colorScheme.surface,
        backgroundColor: const Color(0xFF036799),
        appBar: CustomAppBar(
          showBack: true,
          // AHORA USAMOS titleWidget en lugar de titleContent
          // PARA PODER PERSONALIZAR EL TÍTULO CON UN WIDGET
          titleWidget:
              _hasUnsavedChanges
                  ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Editar Perfil',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.edit_notifications_outlined,
                        size: 20,
                        color: Colors.amberAccent,
                      ),
                    ],
                  )
                  : Text(
                    'Editar Perfil',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 20,
                    ),
                  ),
        ),
        body:
            isLoading || _usuarioActual == null
                ? Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                )
                : Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 550),
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: theme.canvasColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Tooltip(
                                  message: "Cambiar foto de perfil",
                                  child: GestureDetector(
                                    onTap: isSaving ? null : _seleccionarImagen,
                                    child: Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        CircleAvatar(
                                          radius: 60,
                                          backgroundColor:
                                              theme
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                          backgroundImage:
                                              _newProfileImageBytes != null
                                                  ? MemoryImage(
                                                    _newProfileImageBytes!,
                                                  )
                                                  : (_usuarioActual!.fotoPerfilUrl !=
                                                                  null &&
                                                              _usuarioActual!
                                                                  .fotoPerfilUrl!
                                                                  .isNotEmpty
                                                          ? NetworkImage(
                                                            _usuarioActual!
                                                                .fotoPerfilUrl!,
                                                          )
                                                          : null)
                                                      as ImageProvider?,
                                          child:
                                              (_newProfileImageBytes == null &&
                                                      (_usuarioActual!
                                                                  .fotoPerfilUrl ==
                                                              null ||
                                                          _usuarioActual!
                                                              .fotoPerfilUrl!
                                                              .isEmpty))
                                                  ? Icon(
                                                    Icons.add_a_photo_outlined,
                                                    size: 50,
                                                    color:
                                                        theme
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                  )
                                                  : null,
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: theme.canvasColor,
                                              width: 2,
                                            ),
                                          ),
                                          padding: const EdgeInsets.all(6),
                                          child: Icon(
                                            Icons.edit,
                                            size: 20,
                                            color: theme.colorScheme.onPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_usuarioActual!.fotoPerfilUrl != null &&
                                    _usuarioActual!.fotoPerfilUrl!.isNotEmpty &&
                                    _newProfileImageBytes == null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 8.0,
                                      bottom: 0,
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: theme.colorScheme.error,
                                        size: 28,
                                      ),
                                      tooltip: 'Quitar foto de perfil',
                                      onPressed:
                                          isSaving ? null : _quitarFotoPerfil,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: nameController,
                              enabled: !isSaving,
                              decoration: const InputDecoration(
                                labelText: 'Nombre completo *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty)
                                  return 'El nombre completo es obligatorio';
                                if (value.trim().length < 3)
                                  return 'El nombre debe tener al menos 3 caracteres';
                                return null;
                              },
                              textInputAction: TextInputAction.next,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: emailController,
                                    readOnly: true,
                                    enabled: !isSaving,
                                    decoration: InputDecoration(
                                      labelText: 'Correo institucional',
                                      border: const OutlineInputBorder(),
                                      prefixIcon: const Icon(
                                        Icons.email_outlined,
                                      ),
                                      filled: true,
                                      fillColor: theme.colorScheme.onSurface
                                          .withOpacity(0.05),
                                    ),
                                  ),
                                ),
                                if (emailEstaVerificado)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Tooltip(
                                      message: "Correo verificado",
                                      child: Icon(
                                        Icons.verified_user_rounded,
                                        color: Colors.green.shade600,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                if (!emailEstaVerificado &&
                                    firebaseAuthUser != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4.0),
                                    child: TextButton(
                                      onPressed:
                                          isSaving
                                              ? null
                                              : _reenviarEmailVerificacion,
                                      child: const Text(
                                        "Reenviar email",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: phoneController,
                              enabled: !isSaving,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Teléfono',
                                hintText: 'Opcional',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.phone_outlined),
                                counterText: '',
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: roleController,
                              enabled: !isSaving,
                              decoration: const InputDecoration(
                                labelText: 'Carrera o Rol',
                                hintText: 'Ej: Ing. en Sistemas',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.school_outlined),
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: bioController,
                              enabled: !isSaving,
                              maxLines: 3,
                              maxLength: 200,
                              decoration: const InputDecoration(
                                labelText: 'Sobre mí',
                                hintText: 'Cuéntanos algo sobre ti (opcional)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.info_outline),
                              ),
                              textInputAction: TextInputAction.done,
                            ),
                            const SizedBox(height: 16),
                            _buildSectionTitle("Configuración", theme),
                            SwitchListTile.adaptive(
                              value:
                                  _usuarioActual!.config['Notificaciones'] ??
                                  true,
                              title: Text(
                                'Notificaciones',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              onChanged:
                                  isSaving
                                      ? null
                                      : (val) {
                                        setState(
                                          () =>
                                              _usuarioActual!
                                                      .config['Notificaciones'] =
                                                  val,
                                        );
                                        _checkForUnsavedChanges();
                                      },
                              secondary: Icon(
                                Icons.notifications_active_outlined,
                                color: theme.colorScheme.secondary,
                              ),
                              thumbColor: thumbColor,
                              trackColor: trackColor,
                              trackOutlineColor: MaterialStateProperty.all(
                                Colors.transparent,
                              ), // Para quitar un borde extra
                              activeColor: theme.colorScheme.primary,
                            ),
                            SwitchListTile.adaptive(
                              value:
                                  _usuarioActual!.config['PerfilVisible'] ??
                                  true,
                              title: Text(
                                'Perfil Visible Públicamente',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              onChanged:
                                  isSaving
                                      ? null
                                      : (val) {
                                        setState(
                                          () =>
                                              _usuarioActual!
                                                      .config['PerfilVisible'] =
                                                  val,
                                        );
                                        _checkForUnsavedChanges();
                                      },
                              secondary: Icon(
                                Icons.visibility_outlined,
                                color: theme.colorScheme.secondary,
                              ),
                              thumbColor: thumbColor,
                              trackColor: trackColor,
                              trackOutlineColor: MaterialStateProperty.all(
                                Colors.transparent,
                              ), // Para quitar un borde extra
                              activeColor: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed:
                                  isSaving || !_hasUnsavedChanges
                                      ? null
                                      : _guardarCambios,
                              icon:
                                  isSaving
                                      ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: theme.colorScheme.onPrimary,
                                        ),
                                      )
                                      : const Icon(Icons.save_alt_outlined),
                              label: Text(
                                isSaving ? 'Guardando...' : 'Guardar Cambios',
                              ),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildSectionTitle("Seguridad", theme),
                            OutlinedButton.icon(
                              onPressed:
                                  isSaving ? null : _enviarCambioContrasena,
                              icon: const Icon(Icons.lock_reset_outlined),
                              label: const Text("Cambiar contraseña"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.secondary,
                                side: BorderSide(
                                  color: theme.colorScheme.secondary,
                                  width: 1.5,
                                ),
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: const TextStyle(fontSize: 16),
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: isSaving ? null : _eliminarCuenta,
                              icon: const Icon(Icons.delete_forever_outlined),
                              label: const Text("Eliminar cuenta"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.error,
                                side: BorderSide(
                                  color: theme.colorScheme.error,
                                  width: 1.5,
                                ),
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: const TextStyle(fontSize: 16),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
