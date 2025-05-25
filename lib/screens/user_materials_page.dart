import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyMaterialsPage extends StatefulWidget {
  const MyMaterialsPage({super.key});

  @override
  State<MyMaterialsPage> createState() => _MyMaterialsPageState();
}

class _MyMaterialsPageState extends State<MyMaterialsPage> {
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

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

    // 🔄 Decrementar MaterialesSubidos del usuario
    final userRef = FirebaseFirestore.instance.collection('usuarios').doc(uid);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      final actual = snapshot.data()?['MaterialesSubidos'] ?? 0;
      transaction.update(userRef, {
        'MaterialesSubidos': (actual - 1).clamp(0, actual),
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Material eliminado exitosamente.'),
        backgroundColor: Colors.green,
      ),
    );

    // 🔄 Recargar lista
    setState(() {
      _futureMateriales = _fetchMyMaterials();
    });
  }

  late Future<List<Map<String, dynamic>>> _futureMateriales;

  @override
  void initState() {
    super.initState();
    _futureMateriales = _fetchMyMaterials();
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
        future: _futureMateriales,
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
              bool isHovered = false;

              return StatefulBuilder(
                builder: (context, setStateCard) {
                  return MouseRegion(
                    onEnter: (_) => setStateCard(() => isHovered = true),
                    onExit: (_) => setStateCard(() => isHovered = false),
                    child: InkWell(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/material_view',
                          arguments: {
                            'tema': mat['tema'],
                            'materialId': mat['id'],
                          },
                        );
                      },
                      child: Card(
                        elevation: isHovered ? 8 : 2,
                        shadowColor: Colors.black54,
                        color: isHovered ? Colors.blue.shade50 : Colors.white,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: ListTile(
                          title: Text(mat['titulo']),
                          subtitle: Text('Categoría: ${mat['tema']}'),
                          trailing: PopupMenuButton<String>(
                            tooltip: 'Opciones',
                            onSelected: (value) {
                              if (value == 'editar') {
                                Navigator.pushNamed(
                                  context,
                                  '/upload_material',
                                  arguments: {
                                    'tema': mat['tema'],
                                    'materialId': mat['id'],
                                    'editar': true, // ✅ CORRECTO
                                  },
                                );
                              } else if (value == 'nueva') {
                                Navigator.pushNamed(
                                  context,
                                  '/upload_material',
                                  arguments: {
                                    'tema': mat['tema'],
                                    'materialId': mat['id'],
                                    'nuevaVersion': true, // ✅ CORRECTO
                                  },
                                );
                              } else if (value == 'eliminar') {
                                _eliminarMaterial(
                                  context,
                                  mat['tema'],
                                  mat['subcoleccion'],
                                  mat['id'],
                                );
                              }
                            },
                            itemBuilder:
                                (context) => const [
                                  PopupMenuItem(
                                    value: 'editar',
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      title: Text('Editar material'),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'nueva',
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.add_circle_outline,
                                        color: Colors.green,
                                      ),
                                      title: Text('Nueva versión'),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'eliminar',
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.delete_forever,
                                        color: Colors.red,
                                      ),
                                      title: Text('Eliminar'),
                                    ),
                                  ),
                                ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
