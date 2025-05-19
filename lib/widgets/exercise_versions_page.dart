import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ExerciseVersionsPage extends StatelessWidget {
  final String tema;
  final String subcoleccion;
  final String id;

  const ExerciseVersionsPage({
    super.key,
    required this.tema,
    required this.subcoleccion,
    required this.id,
  });

  Future<List<Map<String, dynamic>>> _fetchVersions() async {
    final versionesSnap =
        await FirebaseFirestore.instance
            .collection('calculo')
            .doc(tema)
            .collection(subcoleccion)
            .doc(id)
            .collection('Versiones')
            .orderBy('FechCreacion', descending: true)
            .get();

    return versionesSnap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Versiones del ejercicio'),
        backgroundColor: const Color(0xFF048DD2),
      ),
      backgroundColor: const Color(0xFF036799),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchVersions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No hay versiones registradas.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          final versiones = snapshot.data!;
          return ListView.builder(
            itemCount: versiones.length,
            itemBuilder: (context, index) {
              final version = versiones[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    'Versión ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Fecha: ${version['FechCreacion'] ?? ''}\n'
                    'Descripción: ${version['Descripcion'] ?? ''}',
                  ),
                  // Puedes agregar más acciones aquí como exportar o comparar
                  onTap: () {
                    // Mostrar detalles completos de la versión
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
