import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_connect/services/notification_service.dart';

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
  final double _tabBarHeight = 48.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cargarRankingPorTipo(0);
    });
  }

  void _handleTabSelection() {
    if (mounted &&
        !_tabController.indexIsChanging &&
        _tabController.index != _tabController.previousIndex) {
      _cargarRankingPorTipo(_tabController.index);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarRankingPorTipo(int index) async {
    // ... (Tu lógica de _cargarRankingPorTipo sin cambios en la obtención de datos) ...
    if (!mounted) return;
    setState(() => loading = true);

    final tipo = ['ejercicios', 'materiales', 'combinado'][index];

    try {
      final usuariosSnap =
          await FirebaseFirestore.instance.collection('usuarios').get();

      final List<Map<String, dynamic>> rankingData = [];

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
            puntaje =
                (aportaciones > 0)
                    ? ((califEj * ejer) + (califMat * mat)) / aportaciones
                    : 0.0;
            if (puntaje.isNaN || puntaje.isInfinite) puntaje = 0.0;
            break;
        }

        if (aportaciones == 0 && puntaje == 0.0) continue;

        rankingData.add({
          'uid': uid,
          'nombre': nombre,
          'foto': foto,
          'aportaciones': aportaciones,
          'prom': double.parse(puntaje.toStringAsFixed(2)),
        });
      }

      rankingData.sort((a, b) {
        final cmp = b['prom'].compareTo(a['prom']);
        if (cmp != 0) return cmp;
        return b['aportaciones'].compareTo(a['aportaciones']);
      });

      if (mounted) {
        setState(() {
          ranking = rankingData;
          loading = false;
        });
      }
      _notificarTop3(tipo, rankingData);
    } catch (e) {
      debugPrint("Error al cargar ranking: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al cargar el ranking: ${e.toString()}"),
          ),
        );
        setState(() => loading = false);
      }
    }
  }

  Future<void> _notificarTop3(
    String tipoRanking,
    List<Map<String, dynamic>> currentRanking,
  ) async {
    // ... (Tu lógica de _notificarTop3 sin cambios) ...
    final hoy = DateTime.now();
    final hoyStr =
        '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';

    for (int i = 0; i < currentRanking.length && i < 3; i++) {
      final userRankData = currentRanking[i];
      final uidDestino = userRankData['uid'];
      final nombre = userRankData['nombre'];
      final posicion = i + 1;

      try {
        final usuarioDoc =
            await FirebaseFirestore.instance
                .collection('usuarios')
                .doc(uidDestino)
                .get();
        if (!usuarioDoc.exists) continue;

        final notificadoMap = usuarioDoc.data()?['rankingNotificado'];
        final Map<String, dynamic> notificado =
            notificadoMap is Map
                ? Map<String, dynamic>.from(notificadoMap)
                : {};

        if (notificado[tipoRanking] == hoyStr) continue;

        await NotificationService.crearNotificacion(
          uidDestino: uidDestino,
          tipo: 'ranking',
          titulo: '¡Felicidades $nombre!',
          contenido:
              'Estás en el top $posicion del ranking de ${tipoRanking.replaceFirstMapped(RegExp(r'^[a-z]'), (match) => match.group(0)!.toUpperCase())} 🎉',
          referenciaId: uidDestino,
        );

        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uidDestino)
            .update({'rankingNotificado.$tipoRanking': hoyStr});
      } catch (e) {
        debugPrint(
          "Error al procesar notificación para $nombre (UID: $uidDestino): $e",
        );
      }
    }
  }

  Widget _buildPodioSection() {
    // Envolver en SingleChildScrollView si el contenido INTERNO del podio puede ser muy alto
    // pero el podio como tal, usualmente tiene una altura más o menos fija o predecible.
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF015C8B), // Tu color original
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
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🏅 Líderes del Aprendizaje',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          if (ranking.isNotEmpty)
            PodiumWidget(top3: ranking.take(3).toList())
          else if (!loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                "Aún no hay suficientes datos para el podio.",
                style: TextStyle(color: Colors.white70),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildRankingListItems() {
    // Renombrado para claridad
    if (ranking.isEmpty && !loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "No hay datos en el ranking para mostrar.",
            style: TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    // Este ListView.builder SÍ necesita shrinkWrap y NeverScrollableScrollPhysics
    // porque estará dentro de la Column de _buildListaSection, que a su vez estará
    // en un SingleChildScrollView (móvil) o Expanded (web).
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
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
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 16),
              CircleAvatar(
                backgroundImage: foto.isNotEmpty ? NetworkImage(foto) : null,
                radius: 20,
                backgroundColor: Colors.white24,
                child:
                    foto.isEmpty
                        ? const Icon(Icons.person, color: Colors.white70)
                        : null,
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
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (aportaciones > 0)
                      Text(
                        'Aportaciones: $aportaciones',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    Text(
                      'Puntaje: ${puntos.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (puntos > 0) CustomStarRating(valor: puntos, size: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListaSection() {
    // Quitado esMovil, el contenido es el mismo
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF015C8B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize:
            MainAxisSize
                .min, // Para que la columna no intente ser infinita si está en un SingleChildScrollView
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Text(
              '📊 Tabla de Posiciones',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: Colors.white54, height: 1, thickness: 1),
          const SizedBox(height: 8),
          // El ListView ahora está en _buildRankingListItems y tiene shrinkWrap.
          // Si esta sección (_buildListaSection) está dentro de un Expanded (para web)
          // o un SingleChildScrollView (para móvil), este ListView se adaptará.
          _buildRankingListItems(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double customAppBarActualHeight = kToolbarHeight;

    return Scaffold(
      backgroundColor: const Color(0xFF036799),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          customAppBarActualHeight + _tabBarHeight,
        ),
        child: Column(
          children: [
            CustomAppBar(
              titleText: 'Ranking',
              showBack: true,
              height: customAppBarActualHeight,
            ),
            Material(
              color: const Color(0xFF048DD2),
              child: TabBar(
                controller: _tabController,
                // isScrollable: true, // QUITARLO si quieres que las pestañas se distribuyan
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.7),
                indicatorColor: Colors.blue.shade900,
                indicatorWeight: 2.0,
                indicatorSize:
                    TabBarIndicatorSize
                        .label, // O .tab para que ocupe todo el tab
                tabs: const [
                  Tab(text: 'Ejercicios'),
                  Tab(text: 'Materiales'),
                  Tab(text: 'Combinado'),
                ],
                overlayColor: WidgetStateProperty.all(
                  Colors.purpleAccent.withOpacity(0.1),
                ),
              ),
            ),
          ],
        ),
      ),
      body:
          loading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
              : LayoutBuilder(
                builder: (context, constraints) {
                  final esMovil = constraints.maxWidth < 700;

                  if (esMovil) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize:
                            MainAxisSize
                                .min, // Para que la columna se ajuste al contenido
                        children: [
                          _buildPodioSection(),
                          const SizedBox(height: 16),
                          _buildListaSection(), // _buildListaSection es una Column con un ListView (con shrinkWrap)
                        ],
                      ),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildPodioSection()),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 5,
                            child: SingleChildScrollView(
                              child: _buildListaSection(),
                            ),
                          ), // Envolver _buildListaSection en SingleChildScrollView
                        ],
                      ),
                    );
                  }
                },
              ),
    );
  }
}
