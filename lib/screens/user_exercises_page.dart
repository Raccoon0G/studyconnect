import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyExercisesPage extends StatelessWidget {
  const MyExercisesPage({super.key});

  Future<List<Map<String, dynamic>>> _fetchMyExercises() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final temas = ['FnAlg', 'Lim', 'Der', 'TecInteg'];
    final subcolecciones = {
      'FnAlg': 'EjerFnAlg',
      'Lim': 'EjerLim',
      'Der': 'EjerDer',
      'TecInteg': 'EjerTecInteg',
    };

    List<Map<String, dynamic>> ejercicios = [];

    for (var tema in temas) {
      final snap =
          await FirebaseFirestore.instance
              .collection('calculo')
              .doc(tema)
              .collection(subcolecciones[tema]!)
              .where('AutorId', isEqualTo: uid)
              .get();

      for (var doc in snap.docs) {
        ejercicios.add({
          'id': doc.id,
          'tema': tema,
          'subcoleccion': subcolecciones[tema],
          'titulo': doc['Titulo'],
          'descripcion': doc['DesEjercicio'],
        });
      }
    }

    return ejercicios;
  }

  Future<void> _eliminarEjercicio(
    BuildContext context,
    String tema,
    String subcoleccion,
    String docId,
  ) async {
    final versionesRef = FirebaseFirestore.instance
        .collection('calculo')
        .doc(tema)
        .collection(subcoleccion)
        .doc(docId)
        .collection('Versiones');

    final versiones = await versionesRef.get();

    if (versiones.size > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se puede eliminar un ejercicio con múltiples versiones.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('calculo')
        .doc(tema)
        .collection(subcoleccion)
        .doc(docId)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ejercicio eliminado exitosamente.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis ejercicios'),
        backgroundColor: const Color(0xFF048DD2),
      ),
      backgroundColor: const Color(0xFF036799),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchMyExercises(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No has subido ejercicios.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final ejercicios = snapshot.data!;

          return ListView.builder(
            itemCount: ejercicios.length,
            itemBuilder: (context, index) {
              final ejer = ejercicios[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: ListTile(
                  title: Text(ejer['titulo']),
                  subtitle: Text('Categoría: ${ejer['tema']}'),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/exercise_upload',
                            arguments: {
                              'modo': 'editar',
                              'tema': ejer['tema'],
                              'subcoleccion': ejer['subcoleccion'],
                              'id': ejer['id'],
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed:
                            () => _eliminarEjercicio(
                              context,
                              ejer['tema'],
                              ejer['subcoleccion'],
                              ejer['id'],
                            ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
