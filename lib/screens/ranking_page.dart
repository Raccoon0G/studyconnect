import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:study_connect/widgets/notification_icon_widget.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  List<Map<String, dynamic>> ranking = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _cargarRanking();
  }

  Future<void> _cargarRanking() async {
    final comentariosSnap =
        await FirebaseFirestore.instance
            .collection('comentarios_ejercicios')
            .get();

    final Map<String, List<int>> calificacionesPorUsuario = {};

    for (var doc in comentariosSnap.docs) {
      final data = doc.data();
      final uid = data['usuarioId'] ?? 'anon';
      final estrellas = (data['estrellas'] ?? 0) as int;

      if (!calificacionesPorUsuario.containsKey(uid)) {
        calificacionesPorUsuario[uid] = [];
      }
      calificacionesPorUsuario[uid]!.add(estrellas);
    }

    final usuariosSnap =
        await FirebaseFirestore.instance.collection('usuarios').get();

    final nombrePorUid = {
      for (var doc in usuariosSnap.docs)
        doc.id: doc.data()['Nombre'] ?? 'Anónimo',
    };

    final List<Map<String, dynamic>> resultado =
        calificacionesPorUsuario.entries.map((entry) {
            final uid = entry.key;
            final califs = entry.value;
            final promedio = califs.reduce((a, b) => a + b) / califs.length;

            // Actualiza o crea el campo Calificacion en la colección usuarios
            FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
              'Calificacion': promedio,
              'EjerSubidos': califs.length,
            }, SetOptions(merge: true));

            return {
              'uid': uid,
              'nombre': nombrePorUid[uid] ?? 'Anónimo',
              'ej': califs.length,
              'prom': promedio,
            };
          }).toList()
          ..sort((a, b) => b['prom'].compareTo(a['prom']));

    setState(() {
      ranking = resultado;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: () => Navigator.pushNamed(context, '/content'),
            child: const Text(
              'Contenidos',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const NotificationIconWidget(),
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
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: List.generate(3, (i) {
                                      if (i >= ranking.length)
                                        return const SizedBox();
                                      final datos = ranking[i];
                                      final medal = ['🥇', '🥈', '🥉'][i];
                                      final color =
                                          [
                                            Colors.amber,
                                            Colors.blue,
                                            Colors.red,
                                          ][i];
                                      return _PodiumPlace(
                                        nombre: datos['nombre'],
                                        puntos: datos['prom'].toInt(),
                                        color: color,
                                        medal: medal,
                                      );
                                    }),
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
                          // Tabla
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
                                    label: Icon(
                                      Icons.star,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                                rows: List.generate(ranking.length, (index) {
                                  final r = ranking[index];
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          r['nombre'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '${r['ej']}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '${r['prom'].toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
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
