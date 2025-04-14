import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  File? newProfileImage;

  bool modoOscuro = true;
  bool notificaciones = true;
  bool perfilVisible = true;

  bool isLoading = true;

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
    }

    setState(() => isLoading = false);
  }

  Future<void> seleccionarImagen() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => newProfileImage = File(pickedFile.path));
    }
  }

  Future<String> subirImagen(File imageFile) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('fotos_perfil')
        .child('${user!.uid}.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<void> guardarCambios() async {
    if (user == null) return;

    String finalPhotoUrl = photoUrl;

    if (newProfileImage != null) {
      finalPhotoUrl = await subirImagen(newProfileImage!);
    }

    await FirebaseFirestore.instance.collection('usuarios').doc(user!.uid).set({
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cambios guardados')));
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF036799),
      appBar: AppBar(
        backgroundColor: const Color(0xFF048DD2),
        title: const Text('Editar Perfil'),
      ),
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
                            CircleAvatar(
                              radius: 50,
                              backgroundImage:
                                  newProfileImage != null
                                      ? FileImage(newProfileImage!)
                                      : (photoUrl.isNotEmpty
                                          ? NetworkImage(photoUrl)
                                          : const AssetImage(
                                                'assets/images/avatar1.png',
                                              )
                                              as ImageProvider),
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
                        _inputField(
                          'Correo institucional',
                          emailController,
                          readOnly: true,
                        ),
                        const SizedBox(height: 12),
                        _inputField('Teléfono (opcional)', phoneController),
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
                        ElevatedButton.icon(
                          onPressed: guardarCambios,
                          icon: const Icon(Icons.save),
                          label: const Text('Guardar cambios'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(45),
                            backgroundColor: const Color(0xFF048DD2),
                          ),
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
