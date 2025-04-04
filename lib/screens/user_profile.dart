import 'package:flutter/material.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF036799),
      appBar: AppBar(
        backgroundColor: const Color(0xFF048DD2),
        title: const Text('Perfil de Usuario'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Regresar
            },
            child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Center(
        child: Container(
          width: 400,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              const CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/images/avatar1.png'),
              ),
              const SizedBox(height: 16),
              // Nombre y correo
              const Text(
                'Jonathan Patterson',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'jonathan@escom.ipn.mx',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 4),
              const Text(
                'Estudiante de ISC',
                style: TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 20),

              // Botones
              ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Editar perfil'),
                onPressed: () {
                  Navigator.pushNamed(context, '/edit_profile');
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(45),
                  backgroundColor: const Color(0xFF048DD2),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.list_alt),
                label: const Text('Ver ejercicios aportados'),
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(45),
                  backgroundColor: const Color.fromARGB(255, 52, 44, 65),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                onPressed: () {
                  // FirebaseAuth.instance.signOut(); // si usas auth
                  Navigator.pushReplacementNamed(context, '/login');
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(45),
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
