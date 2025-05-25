import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyExercisesPage extends StatefulWidget {
  const MyExercisesPage({super.key});

  @override
  State<MyExercisesPage> createState() => _MyExercisesPageState();
}

class _MyExercisesPageState extends State<MyExercisesPage> {
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

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

    final docRef = FirebaseFirestore.instance
        .collection('calculo')
        .doc(tema)
        .collection(subcoleccion)
        .doc(docId);

    await docRef.delete();

    // 🔄 Decrementar contador de ejercicios subidos
    final userRef = FirebaseFirestore.instance.collection('usuarios').doc(uid);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      final actual = snapshot.data()?['EjerSubidos'] ?? 0;
      transaction.update(userRef, {
        'EjerSubidos': (actual - 1).clamp(0, actual),
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ejercicio eliminado exitosamente.'),
        backgroundColor: Colors.green,
      ),
    );

    setState(() {
      _futureEjercicios = _fetchMyExercises();
    });
  }

  late Future<List<Map<String, dynamic>>> _futureEjercicios;

  @override
  void initState() {
    super.initState();
    _futureEjercicios = _fetchMyExercises();
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
        future: _futureEjercicios,
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
                          '/exercise_view',
                          arguments: {
                            'tema': ejer['tema'],
                            'ejercicioId': ejer['id'],
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
                          title: Text(ejer['titulo']),
                          subtitle: Text('Categoría: ${ejer['tema']}'),
                          trailing: PopupMenuButton<String>(
                            tooltip: 'Opciones',
                            onSelected: (value) {
                              if (value == 'editar') {
                                Navigator.pushNamed(
                                  context,
                                  '/exercise_upload',
                                  arguments: {
                                    'tema': ejer['tema'],
                                    'ejercicioId': ejer['id'],
                                    'modo': 'editar',
                                  },
                                );
                              } else if (value == 'nueva') {
                                Navigator.pushNamed(
                                  context,
                                  '/exercise_upload',
                                  arguments: {
                                    'tema': ejer['tema'],
                                    'ejercicioId': ejer['id'],
                                    'modo': 'nueva_version',
                                  },
                                );
                              } else if (value == 'eliminar') {
                                _eliminarEjercicio(
                                  context,
                                  ejer['tema'],
                                  ejer['subcoleccion'],
                                  ejer['id'],
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
                                      title: Text('Editar ejercicio'),
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
