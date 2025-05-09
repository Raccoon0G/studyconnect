import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:study_connect/widgets/notification_icon_widget.dart';
import 'package:study_connect/widgets/widgets.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  List<Map<String, dynamic>> ranking = [];
  bool loading = true;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

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

    final Map<String, Map<String, dynamic>> datosUsuarioPorUid = {
      for (var doc in usuariosSnap.docs)
        doc.id: {
          'nombre': doc.data()['Nombre'] ?? 'Anónimo',
          'foto': doc.data()['FotoPerfil'] ?? '', // Puede estar vacío
        },
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
              'nombre': datosUsuarioPorUid[uid]?['nombre'] ?? 'Anónimo',
              'foto': datosUsuarioPorUid[uid]?['foto'] ?? '',

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
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFF0D47A1), // Azul profundo
                                  Color(0xFF002B60), // Azul oscuro tipo navy
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black45,
                                  blurRadius: 8,
                                  offset: Offset(2, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Líderes del Aprendizaje',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                PodiumWidget(top3: ranking.take(3).toList()),
                              ],
                            ),
                          ),

                          const SizedBox(width: 20),
                          // Tabla
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF005B96),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black38,
                                    blurRadius: 6,
                                    offset: Offset(2, 4),
                                  ),
                                ],
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: SizedBox(
                                      width: constraints.maxWidth,
                                      height: constraints.maxHeight,
                                      child: DataTable(
                                        sortColumnIndex: _sortColumnIndex,
                                        sortAscending: _sortAscending,
                                        headingRowHeight: 56,
                                        dataRowMinHeight: 64,
                                        dataRowMaxHeight: 72,
                                        horizontalMargin: 16,
                                        columnSpacing: 28,
                                        headingRowColor:
                                            WidgetStateProperty.all(
                                              const Color(0xFF0288D1),
                                            ),
                                        dividerThickness: 0.5,
                                        border: TableBorder(
                                          horizontalInside: BorderSide(
                                            color: Colors.white30,
                                            width: 0.5,
                                          ),
                                        ),
                                        columns: [
                                          DataColumn(
                                            label: const Text(
                                              'Posición',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            onSort: (columnIndex, ascending) {
                                              setState(() {
                                                _sortColumnIndex = columnIndex;
                                                _sortAscending = ascending;
                                                ranking.sort(
                                                  (a, b) =>
                                                      ascending
                                                          ? a['uid'].compareTo(
                                                            b['uid'],
                                                          )
                                                          : b['uid'].compareTo(
                                                            a['uid'],
                                                          ),
                                                );
                                              });
                                            },
                                          ),
                                          DataColumn(
                                            label: const Text(
                                              'Nombre',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: const Text(
                                              'Ejercicios',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            numeric: true,
                                            onSort: (columnIndex, ascending) {
                                              setState(() {
                                                _sortColumnIndex = columnIndex;
                                                _sortAscending = ascending;
                                                ranking.sort(
                                                  (a, b) =>
                                                      ascending
                                                          ? a['ej'].compareTo(
                                                            b['ej'],
                                                          )
                                                          : b['ej'].compareTo(
                                                            a['ej'],
                                                          ),
                                                );
                                              });
                                            },
                                          ),
                                          DataColumn(
                                            label: const Icon(
                                              Icons.star,
                                              color: Colors.amberAccent,
                                            ),
                                            onSort: (columnIndex, ascending) {
                                              setState(() {
                                                _sortColumnIndex = columnIndex;
                                                _sortAscending = ascending;
                                                ranking.sort(
                                                  (a, b) =>
                                                      ascending
                                                          ? a['prom'].compareTo(
                                                            b['prom'],
                                                          )
                                                          : b['prom'].compareTo(
                                                            a['prom'],
                                                          ),
                                                );
                                              });
                                            },
                                          ),
                                        ],

                                        rows: List.generate(ranking.length, (
                                          index,
                                        ) {
                                          final r = ranking[index];
                                          final nombre =
                                              r['nombre'] ?? 'Desconocido';
                                          final foto = r['foto'] ?? '';
                                          final prom = r['prom'] ?? 0.0;
                                          final isTop3 = index < 3;
                                          final badge = ['🥇', '🥈', '🥉'];

                                          return DataRow(
                                            cells: [
                                              DataCell(
                                                SizedBox(
                                                  width: 60,
                                                  child: Text(
                                                    '${index + 1}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                SizedBox(
                                                  width: 200,
                                                  child: Row(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 18,
                                                        backgroundImage:
                                                            foto.isNotEmpty
                                                                ? NetworkImage(
                                                                  foto,
                                                                )
                                                                : null,
                                                        child:
                                                            foto.isEmpty
                                                                ? const Icon(
                                                                  Icons.person,
                                                                  size: 16,
                                                                )
                                                                : null,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Flexible(
                                                        child: Text(
                                                          '$nombre ${isTop3 ? badge[index] : ''}',
                                                          style:
                                                              const TextStyle(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                SizedBox(
                                                  width: 100,
                                                  child: Text(
                                                    '${r['ej']}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                SizedBox(
                                                  width: 140,
                                                  child: Center(
                                                    child: CustomStarRating(
                                                      valor: prom,
                                                      size: 20,
                                                      geometryAlignment:
                                                          Alignment.center,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }),
                                      ),
                                    ),
                                  );
                                },
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
  final String foto;

  const _PodiumPlace({
    required this.nombre,
    required this.puntos,
    required this.color,
    required this.medal,
    required this.foto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: foto.isNotEmpty ? NetworkImage(foto) : null,
          child:
              foto.isEmpty
                  ? Text(medal, style: const TextStyle(fontSize: 20))
                  : null,
          backgroundColor: Colors.white,
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
              '$nombre\n$puntos pts',
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
