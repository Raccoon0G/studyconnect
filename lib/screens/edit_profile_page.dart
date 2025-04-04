import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController nameController = TextEditingController(
    text: 'Jonathan Patterson',
  );
  final TextEditingController emailController = TextEditingController(
    text: 'jonathan@escom.ipn.mx',
  );
  final TextEditingController careerController = TextEditingController(
    text: 'Estudiante de ISC',
  );
  final TextEditingController bioController = TextEditingController(
    text: 'Me gusta colaborar en ejercicios de Cálculo.',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF036799),
      appBar: AppBar(
        backgroundColor: const Color(0xFF048DD2),
        title: const Text('Editar Perfil'),
      ),
      body: Center(
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
                // Imagen de perfil
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage('assets/images/avatar1.png'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        // implementar carga de imagen
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Campo Nombre
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                // Campo Correo (solo lectura)
                TextField(
                  controller: emailController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Correo institucional',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                // Campo Carrera
                TextField(
                  controller: careerController,
                  decoration: const InputDecoration(
                    labelText: 'Carrera o Rol',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                // Campo Bio
                TextField(
                  controller: bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Sobre mí',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    // Aquí iría el guardado (puedes usar Firebase)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cambios guardados')),
                    );
                    Navigator.pop(context); // volver al perfil
                  },
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
}
