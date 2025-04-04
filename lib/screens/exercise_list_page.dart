import 'package:flutter/material.dart';

class ExerciseListPage extends StatelessWidget {
  const ExerciseListPage({super.key});

  final List<Map<String, dynamic>> ejercicios = const [
    {
      'titulo': 'Hallar el dominio de las funciones',
      'autor': 'Jeovany',
      'calificacion': 4,
    },
    {
      'titulo': 'Averigua cual es el dominio de las funciones',
      'autor': 'Juan',
      'calificacion': 3,
    },
    {'titulo': 'Dominio de la función', 'autor': 'Hegan', 'calificacion': 5},
    {
      'titulo': 'Identifica el rango de las funciones',
      'autor': 'Jeovany',
      'calificacion': 4,
    },
    {
      'titulo': 'Halla las raíces de funciones polinómicas',
      'autor': 'Jeovany',
      'calificacion': 3,
    },
    {
      'titulo': 'Resuelve funciones racionales',
      'autor': 'Gerardo',
      'calificacion': 5,
    },
    {
      'titulo': 'Calcula el límite de la función',
      'autor': 'Abraham',
      'calificacion': 2,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF036799),
      appBar: AppBar(
        backgroundColor: const Color(0xFF048DD2),
        title: const Text('Study Connect'),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Inicio', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Ranking', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Contenidos',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {},
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
            const Text(
              'Funciones algebraicas y trascendentales',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF48C9EF),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFF48C9EF),
                    ),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Ejercicios',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Calificación',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Autor',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DataColumn(
                        label: Text('', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                    rows:
                        ejercicios.map((ej) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  ej['titulo'],
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              DataCell(_buildStars(ej['calificacion'])),
                              DataCell(
                                Text(
                                  ej['autor'],
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              DataCell(
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1A1A1A),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  onPressed: () {
                                    // Acción del botón
                                    Navigator.pushNamed(
                                      context,
                                      '/exercise_view',
                                      arguments: ej,
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStars(int count) {
    return Row(
      children: List.generate(5, (index) {
        if (index < count) {
          return const Icon(Icons.star, color: Colors.yellow, size: 20);
        } else {
          return const Icon(Icons.star_border, color: Colors.white, size: 20);
        }
      }),
    );
  }
}
