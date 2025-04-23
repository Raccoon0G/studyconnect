import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExerciseListPage extends StatelessWidget {
  const ExerciseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final String temaKey = args?['tema'] ?? 'FnAlg';
    final String tituloTema =
        args?['titulo'] ?? 'Funciones algebraicas y trascendentes';

    final CollectionReference ejerciciosRef = FirebaseFirestore.instance
        .collection('calculo')
        .doc(temaKey)
        .collection('Ejer$temaKey');

    return Scaffold(
      backgroundColor: const Color(0xFF036799),
      appBar: AppBar(
        backgroundColor: const Color(0xFF048DD2),
        title: const Text('Study Connect'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/'),
            child: const Text('Inicio', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/ranking'),
            child: const Text('Ranking', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/content'),
            child: const Text(
              'Contenidos',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/user_profile'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Perfil',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tituloTema,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Colors.blueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(16),
                child: StreamBuilder<QuerySnapshot>(
                  stream: ejerciciosRef.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final ejercicios = snapshot.data?.docs ?? [];

                    if (ejercicios.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hay ejercicios disponibles.',
                          style: TextStyle(color: Colors.black),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        columnSpacing: 20,
                        headingRowColor: WidgetStateProperty.all(
                          const Color(0xFF48C9EF),
                        ),
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Ejercicios',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Calificación',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Autor',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                              ),
                            ),
                          ),
                          DataColumn(label: Text('')),
                        ],
                        rows:
                            ejercicios.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return DataRow(
                                cells: [
                                  DataCell(Text(data['Titulo'] ?? '')),
                                  DataCell(
                                    _buildStars(
                                      (data['CalPromedio'] ?? '0').toString(),
                                    ),
                                  ),
                                  DataCell(Text(data['Autor'] ?? '')),
                                  DataCell(
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF1A1A1A,
                                        ),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/exercise_view',
                                          arguments: {
                                            'tema': temaKey,
                                            'ejercicioId': doc.id,
                                          },
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.arrow_forward,
                                        size: 16,
                                      ),
                                      label: const Text('Ver ejercicio'),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStars(String calificacionStr) {
    final int calificacion =
        int.tryParse(calificacionStr.split('.').first) ?? 0;
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < calificacion ? Icons.star : Icons.star_border,
          color: index < calificacion ? Colors.yellow : Colors.white,
          size: 20,
        );
      }),
    );
  }
}
