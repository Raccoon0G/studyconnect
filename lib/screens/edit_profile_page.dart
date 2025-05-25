import 'dart:io';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:study_connect/widgets/widgets.dart' show CustomAppBar;

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final user = FirebaseAuth.instance.currentUser;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  String photoUrl = '';
  //File? newProfileImage;
  Uint8List? newProfileImageBytes; // Compatible con Flutter Web

  bool modoOscuro = true;
  bool notificaciones = true;
  bool perfilVisible = true;

  bool isLoading = true;
  bool correoVerificado = false;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user!.uid)
            .get();

    if (doc.exists) {
      final data = doc.data()!;
      nameController.text = data['Nombre'] ?? '';
      emailController.text = data['Correo'] ?? user!.email ?? '';
      phoneController.text = data['Telefono'] ?? '';
      roleController.text = data['rol'] ?? '';
      bioController.text = data['Acerca de mi'] ?? '';
      photoUrl = data['FotoPerfil'] ?? '';
      modoOscuro = data['Config']?['ModoOscuro'] ?? true;
      notificaciones = data['Config']?['Notificaciones'] ?? true;
      perfilVisible = data['Config']?['PerfilVisible'] ?? true;
      correoVerificado = user!.emailVerified;
    }

    setState(() => isLoading = false);
  }

  Future<void> seleccionarImagen() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => newProfileImageBytes = bytes);
    }
  }

  // Future<String> subirImagen(File imageFile) async {
  //   try {
  //     // Crear referencia única para la imagen
  //     final ref = FirebaseStorage.instance
  //         .ref()
  //         .child('fotos_perfil')
  //         .child('${user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

  //     // Subir archivo a Firebase Storage
  //     final uploadTask = await ref.putFile(imageFile);

  //     // Obtener y retornar la URL de descarga
  //     return await uploadTask.ref.getDownloadURL();
  //   } catch (e) {
  //     debugPrint('Error al subir imagen: $e');
  //     rethrow;
  //   }
  // }
  Future<String> subirImagen(Uint8List imageBytes) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('fotos_perfil')
          .child(user!.uid)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = await ref.putData(imageBytes);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error al subir imagen: $e');
      rethrow;
    }
  }

  Future<void> _seleccionarYSubirImagen(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final file = uploadInput.files?.first;
      if (file == null) return;

      final reader = html.FileReader();

      reader.readAsArrayBuffer(file);

      reader.onLoadEnd.listen((e) async {
        final data = reader.result as Uint8List;
        final ref = FirebaseStorage.instance
            .ref()
            .child('fotos_perfil')
            .child(user.uid)
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        await ref.putData(data);
        final url = await ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .update({'FotoPerfil': url});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil actualizada')),
        );

        // Recargar la pantalla
        Navigator.pushReplacementNamed(context, '/user_profile');
      });
    });
  }

  Future<void> guardarCambios() async {
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

    showDialog(
      barrierDismissible: false,
      context: context,
      builder:
          (_) => const AlertDialog(
            content: SizedBox(
              height: 80,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Guardando cambios...'),
                ],
              ),
            ),
          ),
    );

    try {
      String finalPhotoUrl = photoUrl;
      // if (newProfileImage != null) {
      //   finalPhotoUrl = await subirImagen(newProfileImage!);
      // }

      if (newProfileImageBytes != null) {
        finalPhotoUrl = await subirImagen(newProfileImageBytes!);
      }

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user!.uid)
          .set({
            'Nombre': nameController.text,
            'Correo': emailController.text,
            'Telefono': phoneController.text,
            'rol': roleController.text,
            'Acerca de mi': bioController.text,
            'FotoPerfil': finalPhotoUrl,
            'id': user!.uid,
            'Config': {
              'ModoOscuro': modoOscuro,
              'Notificaciones': notificaciones,
              'PerfilVisible': perfilVisible,
            },
          }, SetOptions(merge: true));

      Navigator.pop(context); // quitar loader

      await showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text("Cambios guardados"),
              content: const Text("Tu perfil se ha actualizado correctamente."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Aceptar"),
                ),
              ],
            ),
      );

      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      Navigator.pop(context); // quitar loader en caso de error
      debugPrint('ERROR al guardar cambios: $e');

      await showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text("Error"),
              content: Text("Error al guardar cambios: $e"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Aceptar"),
                ),
              ],
            ),
      );
    }
  }

  Future<void> enviarCambioContrasena() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("¿Cambiar contraseña?"),
            content: const Text(
              "Te enviaremos un correo para restablecer tu contraseña. ¿Deseas continuar?",
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

    if (confirm != true || user == null) return;

    await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);

    await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Correo enviado"),
            content: const Text(
              "Hemos enviado un enlace para restablecer tu contraseña.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Aceptar"),
              ),
            ],
          ),
    );
  }

  Future<void> eliminarCuenta() async {
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
                child: const Text("Aceptar"),
              ),
            ],
          ),
    );

    if (confirmarEliminacion != true || user == null) return;

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
                child: const Text("Sí"),
              ),
            ],
          ),
    );

    if (eliminarAportaciones == true) {
      await _eliminarAportacionesUsuario(user!.uid);
    }

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user!.uid)
          .delete();
      await user!.delete();
    } catch (e) {
      // Reautenticación puede ser requerida
    }

    await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Cuenta eliminada"),
            content: const Text("Tu cuenta ha sido eliminada correctamente."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Aceptar"),
              ),
            ],
          ),
    );

    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  Future<void> _eliminarAportacionesUsuario(String uid) async {
    final categorias = ['FnAlg', 'Lim', 'Der', 'TecInteg'];
    final firestore = FirebaseFirestore.instance;

    for (final cat in categorias) {
      final ejerRef = firestore
          .collection('calculo')
          .doc(cat)
          .collection('Ejer$cat');

      final query = await ejerRef.where('AutorId', isEqualTo: uid).get();

      for (final doc in query.docs) {
        await doc.reference.delete();
      }
    }

    final matsRef = firestore.collection('Materiales');
    final matsQuery = await matsRef.where('AutorId', isEqualTo: uid).get();
    for (final doc in matsQuery.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF036799),
      appBar: const CustomAppBar(showBack: true),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                child: Container(
                  width: 450,
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            // CircleAvatar(
                            //   radius: 50,
                            //   backgroundImage:
                            //       newProfileImage != null
                            //           ? FileImage(newProfileImage!)
                            //           : (photoUrl.isNotEmpty
                            //               ? NetworkImage(photoUrl)
                            //               : const AssetImage(
                            //                     'assets/images/avatar1.png',
                            //                   )
                            //                   as ImageProvider),
                            // ),
                            // CircleAvatar(
                            //   radius: 50,
                            //   backgroundImage:
                            //       newProfileImageBytes != null
                            //           ? MemoryImage(newProfileImageBytes!)
                            //           : (photoUrl.isNotEmpty
                            //               ? NetworkImage(photoUrl)
                            //               : const AssetImage(
                            //                     'assets/images/avatar1.png',
                            //                   )
                            //                   as ImageProvider),
                            // ),
                            GestureDetector(
                              onTap: () => _seleccionarYSubirImagen(context),
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundImage:
                                        newProfileImageBytes != null
                                            ? MemoryImage(newProfileImageBytes!)
                                            : (photoUrl.isNotEmpty
                                                    ? NetworkImage(photoUrl)
                                                    : const AssetImage(
                                                      'assets/images/avatar1.png',
                                                    ))
                                                as ImageProvider,
                                  ),
                                  const CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: seleccionarImagen,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _inputField('Nombre completo', nameController),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _inputField(
                                'Correo institucional',
                                emailController,
                                readOnly: true,
                              ),
                            ),
                            if (correoVerificado)
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(
                                  Icons.verified,
                                  color: Colors.green,
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.number,
                          maxLength: 10,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Teléfono (opcional)',
                            border: OutlineInputBorder(),
                            counterText: '',
                          ),
                        ),

                        const SizedBox(height: 12),
                        _inputField('Carrera o Rol', roleController),
                        const SizedBox(height: 12),
                        _inputField('Sobre mí', bioController, maxLines: 3),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          value: modoOscuro,
                          title: const Text('Modo Oscuro'),
                          onChanged: (val) => setState(() => modoOscuro = val),
                        ),
                        SwitchListTile(
                          value: notificaciones,
                          title: const Text('Notificaciones'),
                          onChanged:
                              (val) => setState(() => notificaciones = val),
                        ),
                        SwitchListTile(
                          value: perfilVisible,
                          title: const Text('Perfil Visible'),
                          onChanged:
                              (val) => setState(() => perfilVisible = val),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: guardarCambios,
                                icon: const Icon(Icons.save),
                                label: const Text('Guardar cambios'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(45),
                                  backgroundColor: const Color(0xFF048DD2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: enviarCambioContrasena,
                                icon: const Icon(Icons.lock_reset),
                                label: const Text("Cambiar contraseña"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange,
                                  side: const BorderSide(color: Colors.orange),
                                  minimumSize: const Size.fromHeight(45),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: eliminarCuenta,
                                icon: const Icon(Icons.delete_forever),
                                label: const Text("Eliminar cuenta"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  minimumSize: const Size.fromHeight(45),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _inputField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
