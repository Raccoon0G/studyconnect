import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_connect/services/notification_service.dart';
import 'package:study_connect/widgets/notification_icon_widget.dart';
import 'package:study_connect/widgets/widgets.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> ranking = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _cargarRankingPorTipo(_tabController.index);
    });
    _cargarRankingPorTipo(0); // Carga inicial
  }

  Future<void> _cargarRankingPorTipo(int index) async {
    setState(() => loading = true);
    final tipo = ['ejercicios', 'materiales', 'combinado'][index];
    final usuariosSnap =
        await FirebaseFirestore.instance.collection('usuarios').get();

    final List<Map<String, dynamic>> ranking = [];

    for (var doc in usuariosSnap.docs) {
      final data = doc.data();
      final uid = doc.id;

      final nombre = data['Nombre'] ?? 'Anónimo';
      final foto = data['FotoPerfil'] ?? '';
      final califEj = (data['CalificacionEjercicios'] ?? 0.0).toDouble();
      final califMat = (data['CalificacionMateriales'] ?? 0.0).toDouble();
      final ejer = int.tryParse('${data['EjerSubidos']}') ?? 0;
      final mat = int.tryParse('${data['MaterialesSubidos']}') ?? 0;

      int aportaciones = 0;
      double puntaje = 0.0;

      switch (tipo) {
        case 'ejercicios':
          puntaje = califEj;
          aportaciones = ejer;
          break;
        case 'materiales':
          puntaje = califMat;
          aportaciones = mat;
          break;
        case 'combinado':
          aportaciones = ejer + mat;
          puntaje = ((califEj * ejer) + (califMat * mat)) / (aportaciones + 1);
          break;
      }

      if (aportaciones == 0 && puntaje == 0) continue;

      ranking.add({
        'uid': uid,
        'nombre': nombre,
        'foto': foto,
        'aportaciones': aportaciones,
        'prom': double.parse(puntaje.toStringAsFixed(2)),
      });
    }

    ranking.sort((a, b) {
      final cmp = b['prom'].compareTo(a['prom']);
      if (cmp != 0) return cmp;
      return b['aportaciones'].compareTo(a['aportaciones']);
    });

    setState(() {
      this.ranking = ranking;
      loading = false;
    });

    // Notificar a top 3 si aún no han sido notificados hoy
    final hoy = DateTime.now();
    final hoyStr =
        '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';

    for (int i = 0; i < ranking.length && i < 3; i++) {
      final user = ranking[i];
      final uidDestino = user['uid'];
      final nombre = user['nombre'];
      final referenciaId = uidDestino;
      final posicion = i + 1;

      final usuarioDoc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(uidDestino)
              .get();
      final notificado =
          (usuarioDoc.data()?['rankingNotificado'] ?? {})
              as Map<String, dynamic>;

      if (notificado[tipo] == hoyStr) continue;

      await NotificationService.crearNotificacion(
        uidDestino: uidDestino,
        tipo: 'ranking',
        titulo: '¡Felicidades $nombre!',
        contenido:
            'Estás en el top $posicion del ranking de ${tipo.toUpperCase()} 🎉',
        referenciaId: referenciaId,
      );

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uidDestino)
          .update({'rankingNotificado.$tipo': hoyStr});
    }
  }

  Widget _buildPodioSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF015C8B),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min, // <- Importante para no expandirse de más
              children: [
                const Text(
                  '🏅 Líderes del Aprendizaje',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                PodiumWidget(top3: ranking.take(3).toList()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRankingListView() {
    return ListView.builder(
      itemCount: ranking.length,
      itemBuilder: (context, index) {
        final r = ranking[index];
        final badge = ['🥇', '🥈', '🥉'];
        final nombre = r['nombre'] ?? 'Desconocido';
        final foto = r['foto'] ?? '';
        final puntos = r['prom'] ?? 0.0;
        final aportaciones = r['aportaciones'] ?? 0;
        final isTop3 = index < 3;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade800.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              CircleAvatar(
                backgroundImage: foto.isNotEmpty ? NetworkImage(foto) : null,
                radius: 20,
                child: foto.isEmpty ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$nombre ${isTop3 ? badge[index] : ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Aportaciones: $aportaciones',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'Puntaje: ${puntos.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              CustomStarRating(
                valor: puntos,
                size: 20,
                duration: const Duration(milliseconds: 600),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListaSection({required bool esMovil}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF015C8B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Tabla de Posiciones',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: Colors.white54),
          const SizedBox(height: 8),
          // Aquí cambia: si es móvil, NO uses Expanded. Usa un SizedBox con altura calculada.
          esMovil
              ? SizedBox(
                height:
                    350, // O calcula el height según MediaQuery si prefieres
                child: _buildRankingListView(),
              )
              : Expanded(child: _buildRankingListView()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF036799),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CustomAppBar(title: 'Ranking'),
            Material(
              color: const Color(0xFF048DD2),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Ejercicios'),
                  Tab(text: 'Materiales'),
                  Tab(text: 'Combinado'),
                ],
                labelColor: Colors.white,
                indicatorColor: Colors.purpleAccent,
              ),
            ),
          ],
        ),
      ),

      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                builder: (context, constraints) {
                  final esMovil = constraints.maxWidth < 800;
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child:
                        esMovil
                            ? Column(
                              children: [
                                Flexible(child: _buildPodioSection()),

                                const SizedBox(height: 20),
                                _buildListaSection(esMovil: true), // <= aquí
                              ],
                            )
                            : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 4, child: _buildPodioSection()),
                                const SizedBox(width: 20),
                                Expanded(
                                  flex: 6,
                                  child: _buildListaSection(esMovil: false),
                                ), // <= aquí
                              ],
                            ),
                  );
                },
              ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
