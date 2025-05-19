import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyMaterialsPage extends StatelessWidget {
  const MyMaterialsPage({super.key});

  Future<List<Map<String, dynamic>>> _fetchMyMaterials() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final temas = ['FnAlg', 'Lim', 'Der', 'TecInteg'];
    final subcolecciones = {
      'FnAlg': 'MatFnAlg',
      'Lim': 'MatLim',
      'Der': 'MatDer',
      'TecInteg': 'MatTecInteg',
    };

    List<Map<String, dynamic>> materiales = [];

    for (var tema in temas) {
      final snap =
          await FirebaseFirestore.instance
              .collection('materiales')
              .doc(tema)
              .collection(subcolecciones[tema]!)
              .where('autorId', isEqualTo: uid)
              .get();

      for (var doc in snap.docs) {
        print("doc id: ${doc.id}, data: ${doc.data()}");
        materiales.add({
          'id': doc.id,
          'tema': tema,
          'subcoleccion': subcolecciones[tema],
          'titulo': doc['titulo'] ?? '',
          'descripcion': doc['descripcion'] ?? '',
        });
      }
    }

    return materiales;
  }

  Future<void> _eliminarMaterial(
    BuildContext context,
    String tema,
    String subcoleccion,
    String docId,
  ) async {
    final versionesRef = FirebaseFirestore.instance
        .collection('materiales')
        .doc(tema)
        .collection(subcoleccion)
        .doc(docId)
        .collection('Versiones');

    final versiones = await versionesRef.get();

    if (versiones.size > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se puede eliminar un material con múltiples versiones.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('materiales')
        .doc(tema)
        .collection(subcoleccion)
        .doc(docId)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Material eliminado exitosamente.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis materiales'),
        backgroundColor: const Color(0xFF048DD2),
      ),
      backgroundColor: const Color(0xFF036799),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchMyMaterials(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No has subido materiales.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final materiales = snapshot.data!;

          return ListView.builder(
            itemCount: materiales.length,
            itemBuilder: (context, index) {
              final mat = materiales[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: ListTile(
                  title: Text(mat['titulo']),
                  subtitle: Text('Categoría: ${mat['tema']}'),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Editar material',
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/upload_material',
                            arguments: {
                              'tema': mat['tema'],
                              'materialId': mat['id'],
                              'modo': 'editar',
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed:
                            () => _eliminarMaterial(
                              context,
                              mat['tema'],
                              mat['subcoleccion'],
                              mat['id'],
                            ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.green,
                        ),
                        tooltip: 'Nueva versión',
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/upload_material',
                            arguments: {
                              'tema': mat['tema'],
                              'materialId': mat['id'],
                              'modo': 'nueva_version',
                            },
                          );
                        },
                      ),
                      // Aquí puedes agregar un PopupMenuButton para ver versiones, igual que en ejercicios si lo necesitas
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
