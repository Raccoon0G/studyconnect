import 'package:flutter/material.dart';

class RankingPage extends StatelessWidget {
  const RankingPage({super.key});

  final List<Map<String, dynamic>> ranking = const [
    {'nombre': 'Jeovanny Torres', 'ej': 13, 'prom': 5.0},
    {'nombre': 'Hegan Sagastegui', 'ej': 15, 'prom': 4.9},
    {'nombre': 'Ulises Veles', 'ej': 11, 'prom': 4.9},
    {'nombre': 'Fer Torres', 'ej': 20, 'prom': 4.9},
    {'nombre': 'Alan Juarez', 'ej': 12, 'prom': 4.8},
    {'nombre': 'Olivia Martinez', 'ej': 9, 'prom': 4.8},
    {'nombre': 'Jonathan Patterson', 'ej': 10, 'prom': 4.7},
    {'nombre': 'Juaan Hernandez', 'ej': 6, 'prom': 4.6},
    {'nombre': 'Abraham Vazquez', 'ej': 5, 'prom': 4.5},
    {'nombre': 'Diana Diaz', 'ej': 5, 'prom': 4.5},
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
            onPressed: () {
              Navigator.pushNamed(context, '/');
            },
            child: const Text('Inicio', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/content');
            },
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
              'Ranking',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Row(
                children: [
                  // Podio
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Líderes del Aprendizaje',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: const [
                              _PodiumPlace(
                                nombre: 'Nombre 2',
                                puntos: 90,
                                color: Colors.blue,
                                medal: '🥈',
                              ),
                              _PodiumPlace(
                                nombre: 'Nombre 1',
                                puntos: 97,
                                color: Colors.amber,
                                medal: '🥇',
                              ),
                              _PodiumPlace(
                                nombre: 'Nombre 3',
                                puntos: 89,
                                color: Colors.red,
                                medal: '🥉',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '¡Contribuye más y escala en el ranking!',
                            style: TextStyle(
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Tabla de ranking
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF48C9EF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          const Color(0xFF48C9EF),
                        ),
                        columnSpacing: 12,
                        columns: const [
                          DataColumn(
                            label: Text(
                              'NO',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'APORTADOR',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Ej',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DataColumn(
                            label: Icon(Icons.star, color: Colors.white),
                          ),
                        ],
                        rows: List.generate(ranking.length, (index) {
                          final r = ranking[index];
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              DataCell(
                                Text(
                                  r['nombre'],
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '${r['ej']}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '${r['prom']}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PodiumPlace extends StatelessWidget {
  final String nombre;
  final int puntos;
  final Color color;
  final String medal;

  const _PodiumPlace({
    required this.nombre,
    required this.puntos,
    required this.color,
    required this.medal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.white,
          child: Text(medal),
        ),
        const SizedBox(height: 8),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              '$nombre\n$puntos puntos',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
