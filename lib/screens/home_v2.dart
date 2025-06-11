import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Asegúrate que la ruta a widgets.dart sea correcta si CustomAppBar y HomeCarousel están ahí.
// import 'package:study_connect/widgets/widgets.dart'; // Descomenta si es necesario
import 'package:study_connect/widgets/custom_app_bar.dart'; // Asumiendo que CustomAppBar está aquí
import 'package:study_connect/widgets/home_carousel.dart'; // Asumiendo que HomeCarousel está aquí

// 🎨 Colores personalizados
const Color azulPrimario = Color(0xFF0D47A1);
const Color azulSecundario = Color(0xFF1976D2);
const Color moradoPrimario = Color(0xFF7E57C2);
const Color fondoOscuro = Color(0xFF0A192F);
const Color blancoSuave = Color(0xFFE3F2FD);
const Color tarjetaFondoOscuro = Color(
  0xFF0E2038,
); // Un poco más claro que fondoOscuro
const Color textoClaroPrincipal = Colors.white;
const Color textoClaroSecundario = Colors.white70;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _auth = FirebaseAuth.instance;

  String? nombreUsuario;
  Map<String, int> ejerciciosPorTema = {};
  int totalEjercicios = 0;
  bool mostrarDetallesEjercicios = false;
  bool mostrarDetallesPreguntas = false;
  List<Map<String, dynamic>>? _rankingCache;
  bool _primeraCarga = true;

  @override
  void initState() {
    super.initState();
    _obtenerDatos();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_primeraCarga) {
      _primeraCarga = false;
    } else {
      recargarRanking();
    }
  }

  Future<void> _obtenerDatos() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc =
            await FirebaseFirestore.instance
                .collection('usuarios')
                .doc(user.uid)
                .get();
        if (mounted) {
          setState(() {
            nombreUsuario = doc.data()?['Nombre'] ?? '';
          });
        }
      } catch (e) {
        debugPrint("Error obteniendo nombre de usuario: $e");
        if (mounted) {
          setState(() {
            nombreUsuario = ''; // Evitar null
          });
        }
      }
    }

    final temas = {
      'FnAlg': 'EjerFnAlg',
      'Lim': 'EjerLim',
      'TecInteg': 'EjerTecInteg',
      'Der': 'EjerDer',
    };
    int total = 0;
    Map<String, int> conteo = {};
    for (final entry in temas.entries) {
      try {
        // Usar .count() para obtener solo el número de documentos de forma eficiente
        final snapshot =
            await FirebaseFirestore.instance
                .collection('calculo')
                .doc(entry.key)
                .collection(entry.value)
                .count()
                .get();
        conteo[entry.key] = snapshot.count ?? 0;
        total += snapshot.count ?? 0;
      } catch (e) {
        debugPrint("Error contando ejercicios para ${entry.key}: $e");
        conteo[entry.key] = 0; // Asignar 0 en caso de error
      }
    }
    if (mounted) {
      setState(() {
        ejerciciosPorTema = conteo;
        totalEjercicios = total;
      });
    }
  }

  Future<void> recargarRanking() async {
    if (mounted) {
      setState(() {
        _rankingCache = null;
      });
    }
  }

  // IMPORTANTE: Esta función es muy ineficiente para muchos usuarios/ejercicios.
  // Considera desnormalizar datos (ej. totalEjercicios, calificacionPromedio) en los documentos
  // de usuario y actualizarlos con Cloud Functions para un ranking performante.
  Future<List<Map<String, dynamic>>> obtenerRanking() async {
    if (_rankingCache != null) return _rankingCache!;

    final usersSnapshot =
        await FirebaseFirestore.instance.collection('usuarios').get();
    // final temas = ['FnAlg', 'Lim', 'Der', 'TecInteg']; // No es necesario si se usa 'EjerSubidos'
    List<Map<String, dynamic>> ranking = [];

    for (final userDoc in usersSnapshot.docs) {
      final data = userDoc.data();
      // Priorizar el campo desnormalizado 'EjerSubidos' si existe.
      int totalEjer = (data['EjerSubidos'] as num?)?.toInt() ?? 0;

      ranking.add({
        'uid': userDoc.id,
        'nombre': data['Nombre'] ?? 'Usuario Anónimo',
        'foto': data['FotoPerfil'], // Puede ser null
        'calificacion':
            (data['CalificacionEjercicios'] as num?)?.toDouble() ?? 0.0,
        'ejercicios': totalEjer,
      });
    }

    ranking.sort((a, b) {
      final promA = a['calificacion'] as double;
      final promB = b['calificacion'] as double;
      if (promA != promB)
        return promB.compareTo(promA); // Mayor calificación primero
      return (b['ejercicios'] as int).compareTo(
        a['ejercicios'] as int,
      ); // Luego más ejercicios
    });

    _rankingCache = ranking.take(5).toList(); // Top 5 usuarios
    return _rankingCache!;
  }

  Future<Map<String, int>> obtenerConteoPreguntasPorTema() async {
    Map<String, int> conteo = {};
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('preguntas_por_tema')
              .get();
      for (final doc in snapshot.docs) {
        final tema = doc.data()['tema'] as String? ?? 'Tema desconocido';
        conteo[tema] = (conteo[tema] ?? 0) + 1;
      }
    } catch (e) {
      debugPrint("Error obteniendo conteo de preguntas: $e");
    }
    return conteo;
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required String countText,
    required IconData icon,
    required Color iconColor,
    required List<Widget> detailsChildren,
    required bool showDetails,
    required VoidCallback onToggleDetails,
    required String buttonText,
    required VoidCallback onButtonPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tarjetaFondoOscuro, // Color sólido para estas tarjetas
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: textoClaroPrincipal,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            countText,
            style: GoogleFonts.poppins(
              color: textoClaroPrincipal,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onToggleDetails,
            style: TextButton.styleFrom(
              foregroundColor: moradoPrimario.withOpacity(0.9),
            ),
            child: Text(
              showDetails ? 'Ocultar detalles' : 'Ver desglose por tema',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
          if (showDetails) ...[
            const Divider(color: Colors.white24, height: 20, thickness: 0.5),
            ...detailsChildren,
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onButtonPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  iconColor, // Usar el color del icono para el botón
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            label: Text(buttonText),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile =
        screenWidth <
        850; // Ajusta este breakpoint según necesites para 3 columnas
    final user = _auth.currentUser;
    final isLoggedIn = user != null;

    return Scaffold(
      backgroundColor: fondoOscuro,
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 32,
                    vertical: 24,
                  ),
                  child: Column(
                    children: [
                      _preloadIcons(), // Para precargar iconos si es necesario
                      isMobile
                          ? Column(
                            // Layout Móvil
                            children: [
                              _buildBienvenida(context, user, isMobile),
                              const SizedBox(height: 30),
                              _buildContenidosCard(
                                context,
                              ), // Tarjeta de Contenidos
                              const SizedBox(height: 30),
                              _buildRightColumnContent(
                                context,
                                isMobile,
                                isLoggedIn,
                              ), // Ranking y Autoevaluación
                            ],
                          )
                          : Row(
                            // Layout Desktop
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildLeftColumn(context, isMobile),
                              ), // Columna Izquierda: Carousel y Contenidos
                              const SizedBox(width: 30),
                              Expanded(
                                flex: 3,
                                child: _buildBienvenida(
                                  context,
                                  user,
                                  isMobile,
                                ),
                              ), // Columna Central: Bienvenida
                              const SizedBox(width: 30),
                              Expanded(
                                flex: 2,
                                child: _buildRightColumnContent(
                                  context,
                                  isMobile,
                                  isLoggedIn,
                                ),
                              ), // Columna Derecha: Ranking, Imagen, Autoevaluación
                            ],
                          ),
                      const SizedBox(height: 120), // Espacio para footer y chat
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 20,
                  child: _buildChatButton(context, isLoggedIn),
                ),
              ],
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildLeftColumn(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HomeCarousel(), // Asumiendo que HomeCarousel es un widget existente
        const SizedBox(height: 30),
        _buildContenidosCard(
          context,
        ), // Tarjeta de contenidos aquí para desktop
      ],
    );
  }

  Widget _buildBienvenida(BuildContext context, User? user, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (nombreUsuario != null && nombreUsuario!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Hola, $nombreUsuario 👋',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: textoClaroPrincipal,
                fontSize: isMobile ? 30 : 36, // Más grande
                fontWeight: FontWeight.bold, // Más destacado
              ),
            ),
          ),
        Text(
          'Potencia tu aprendizaje y\nAlcanza tus objetivos académicos',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: blancoSuave,
            fontSize: isMobile ? 26 : 38,
            fontWeight: FontWeight.bold,
            height: 1.3,
            shadows: [
              Shadow(
                blurRadius: 10,
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(2, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'A través de ejercicios colaborativos creados por estudiantes como tú',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: const Color(0xFFB0E0FF).withOpacity(0.95),
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 40),
        ConstrainedBox(
          // Para limitar el ancho de las featurettes en desktop
          constraints: const BoxConstraints(
            maxWidth: 550,
          ), // Ligeramente más ancho
          child: Column(
            children: const [
              _Featurette(
                icon: Icons.group_add_outlined,
                text: 'Únete a una comunidad de aprendizaje activa y solidaria',
              ),
              _Featurette(
                icon: Icons.lightbulb_outline,
                text:
                    'Sube, comparte y aprende de una gran variedad de ejercicios',
              ),
              _Featurette(
                icon: Icons.military_tech_outlined,
                text:
                    'Compite sanamente y gana reconocimiento en nuestro ranking',
              ),
              _Featurette(
                icon: Icons.model_training_outlined,
                text:
                    'Pon a prueba tus conocimientos con autoevaluaciones por tema',
              ),
            ],
          ),
        ),
        const SizedBox(height: 50),
        if (user == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              style: ElevatedButton.styleFrom(
                backgroundColor: moradoPrimario,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 18,
                ), // Botón más grande
                textStyle: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Crear Cuenta Ahora'),
            ),
          ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/content'),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                user == null
                    ? azulSecundario.withOpacity(0.8)
                    : moradoPrimario.withOpacity(0.9),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 16),
            textStyle: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            side:
                user != null
                    ? null
                    : BorderSide(color: Colors.white.withOpacity(0.5)),
          ),
          icon: const Icon(Icons.dashboard_customize_outlined, size: 20),
          label: const Text('Explorar Contenidos'),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildContenidosCard(BuildContext context) {
    return _buildInfoCard(
      context: context,
      title: 'Contenidos Disponibles',
      countText: '$totalEjercicios+ ejercicios',
      icon: Icons.auto_stories_outlined,
      iconColor: azulSecundario,
      detailsChildren:
          ejerciciosPorTema.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                '• ${_nombreTema(entry.key)}: ${entry.value}',
                style: const TextStyle(
                  color: textoClaroSecundario,
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
      showDetails: mostrarDetallesEjercicios,
      onToggleDetails:
          () => setState(
            () => mostrarDetallesEjercicios = !mostrarDetallesEjercicios,
          ),
      buttonText: 'Ver Todos los Ejercicios', // Texto más explícito
      onButtonPressed: () => Navigator.pushNamed(context, '/content'),
    );
  }

  Widget _buildAutoevaluacionCard(
    BuildContext context,
    Map<String, int> preguntasPorTema,
    bool isLoggedIn,
  ) {
    final totalPreguntas = preguntasPorTema.values.fold(
      0,
      (sum, item) => sum + item,
    );
    return _buildInfoCard(
      context: context,
      title: 'Autoevaluación',
      countText: '$totalPreguntas+ preguntas',
      icon: Icons.quiz_outlined,
      iconColor: moradoPrimario,
      detailsChildren:
          preguntasPorTema.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                '• ${entry.key}: ${entry.value}',
                style: const TextStyle(
                  color: textoClaroSecundario,
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
      showDetails: mostrarDetallesPreguntas,
      onToggleDetails:
          () => setState(
            () => mostrarDetallesPreguntas = !mostrarDetallesPreguntas,
          ),
      buttonText: 'Iniciar Autoevaluación',
      onButtonPressed: () {
        if (!isLoggedIn) {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  backgroundColor: tarjetaFondoOscuro,
                  title: Text(
                    'Inicio de sesión requerido',
                    style: GoogleFonts.poppins(color: textoClaroPrincipal),
                  ),
                  content: Text(
                    'Para acceder a la autoevaluación necesitas iniciar sesión.',
                    style: GoogleFonts.poppins(color: textoClaroSecundario),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancelar',
                        style: GoogleFonts.poppins(color: moradoPrimario),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: moradoPrimario,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/login');
                      },
                      child: Text(
                        'Iniciar sesión',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ],
                ),
          );
        } else {
          Navigator.pushNamed(context, '/autoevaluation');
        }
      },
    );
  }

  Widget _buildRightColumnContent(
    BuildContext context,
    bool isMobile,
    bool isLoggedIn,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FutureBuilder<List<Map<String, dynamic>>>(
          future: obtenerRanking(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                _rankingCache == null) {
              return _buildSkeletonCard(height: 250); // Ajustar altura
            }
            if (snapshot.hasError)
              return Center(
                child: Text(
                  'Error cargando ranking: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            if (!snapshot.hasData || snapshot.data!.isEmpty)
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Aún no hay usuarios en el ranking.',
                    style: TextStyle(
                      color: textoClaroSecundario,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              );

            return _buildRankingCardDesdeMapa(snapshot.data!);
          },
        ),
        const SizedBox(height: 30),
        if (!isMobile) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/alumno.webp',
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 30),
        ],
        FutureBuilder<Map<String, int>>(
          future: obtenerConteoPreguntasPorTema(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return _buildSkeletonCard(height: 280); // Ajustar altura
            if (snapshot.hasError)
              return Center(
                child: Text(
                  'Error cargando preguntas: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            if (!snapshot.hasData || snapshot.data!.isEmpty)
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'No hay preguntas para autoevaluación.',
                    style: TextStyle(
                      color: textoClaroSecundario,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              );

            return _buildAutoevaluacionCard(
              context,
              snapshot.data!,
              isLoggedIn,
            );
          },
        ),
        const SizedBox(height: 20), // Espacio antes del final de la columna
      ],
    );
  }

  Widget _buildSkeletonCard({double height = 220}) {
    // Renombrado y parametrizado
    return Container(
      height: height,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tarjetaFondoOscuro.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          CircularProgressIndicator(color: Colors.white70),
          SizedBox(height: 16),
          Text(
            'Cargando datos...',
            style: TextStyle(color: textoClaroSecundario, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _avatarMiniRanking(
    ImageProvider avatar,
    String nombre,
    String puntaje,
    int ejercicios,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 32,
          backgroundImage: avatar,
          backgroundColor: Colors.white24,
        ),
        const SizedBox(height: 8),
        Tooltip(
          message: nombre,
          child: SizedBox(
            width: 80,
            child: Text(
              nombre.length > 10 ? '${nombre.substring(0, 8)}…' : nombre,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: GoogleFonts.poppins(
                color: textoClaroPrincipal,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star_rounded,
              color: Colors.amber,
              size: 16,
            ), // Icono más relleno
            const SizedBox(width: 3),
            Text(
              '$puntaje pts',
              style: GoogleFonts.poppins(
                color: textoClaroPrincipal,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          '$ejercicios ejer.',
          style: GoogleFonts.poppins(
            color: textoClaroSecundario.withOpacity(0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildRankingCardDesdeMapa(List<Map<String, dynamic>> topUsers) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          // Mantenemos el gradiente distintivo para el ranking
          colors: [
            azulPrimario.withOpacity(0.9),
            azulSecundario.withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ], // Sombra más pronunciada
      ),
      child: Column(
        children: [
          Text(
            '🏅 Top 5 - Comunidad Destacada',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.spaceAround,
            spacing: 10,
            runSpacing: 16, // Ajustar spacing si es necesario
            children:
                topUsers.map((data) {
                  final nombre = data['nombre'] as String? ?? 'Usuario';
                  final puntaje = (data['calificacion'] as double? ?? 0.0)
                      .toStringAsFixed(2);
                  final ejercicios = data['ejercicios'] as int? ?? 0;
                  final foto = data['foto'] as String?;
                  final ImageProvider avatar =
                      (foto != null &&
                              foto.isNotEmpty &&
                              foto.startsWith('http'))
                          ? NetworkImage(foto)
                          : const AssetImage(
                            'assets/images/avatar1.webp',
                          ); // Asegúrate de tener esta imagen

                  return _avatarMiniRanking(
                    avatar,
                    nombre,
                    puntaje,
                    ejercicios,
                  );
                }).toList(),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            icon: const Icon(Icons.leaderboard_outlined, color: blancoSuave),
            label: Text(
              'Ver Ranking Completo',
              style: GoogleFonts.poppins(
                color: blancoSuave,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () {
              // TODO: Implementar navegación a la página de ranking completo
              Navigator.pushNamed(
                context,
                '/ranking',
              ); // Asumiendo que tienes una ruta '/ranking'
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: blancoSuave.withOpacity(0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _nombreTema(String clave) {
    switch (clave) {
      case 'FnAlg':
        return 'Funciones algebraicas y trascendentes';
      case 'Lim':
        return 'Límites de funciones y continuidad';
      case 'TecInteg':
        return 'Técnicas de integración';
      case 'Der':
        return 'Derivada y optimización';
      default:
        return clave;
    }
  }

  Widget _preloadIcons() {
    return Offstage(
      child: Row(
        children: const [
          Icon(Icons.emoji_events),
          Icon(Icons.star),
          Icon(Icons.star_border),
          Icon(Icons.star_half),
          Icon(Icons.assignment_turned_in),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      color:
          fondoOscuro, // Para asegurar que el footer no contraste si el SingleChildScrollView no llega al final
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 32,
        runSpacing: 16,
        children: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/credits'),
            child: const Text(
              'Créditos',
              style: TextStyle(color: textoClaroSecundario),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/faq'),
            child: const Text(
              'Preguntas frecuentes',
              style: TextStyle(color: textoClaroSecundario),
            ),
          ),
          const Text(
            '© 2025 Study Connect | ESCOM IPN',
            style: TextStyle(color: Colors.white38),
          ), // Año actualizado
        ],
      ),
    );
  }

  Widget _buildChatButton(BuildContext context, bool isLoggedIn) {
    return FloatingActionButton.extended(
      onPressed: () {
        if (!isLoggedIn) {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  backgroundColor: tarjetaFondoOscuro,
                  title: Text(
                    'Inicio de sesión requerido',
                    style: GoogleFonts.poppins(color: textoClaroPrincipal),
                  ),
                  content: Text(
                    'Para usar el chat necesitas iniciar sesión.',
                    style: GoogleFonts.poppins(color: textoClaroSecundario),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancelar',
                        style: GoogleFonts.poppins(color: moradoPrimario),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: moradoPrimario,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/login');
                      },
                      child: Text(
                        'Iniciar sesión',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ],
                ),
          );
        } else {
          Navigator.pushNamed(context, '/chat');
        }
      },
      label: Text(
        isLoggedIn ? 'Chat Comunitario' : 'Chat (Inicia Sesión)',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      icon: Icon(isLoggedIn ? Icons.chat_bubble_outline : Icons.lock_outline),
      backgroundColor: moradoPrimario,
      foregroundColor: Colors.white,
      elevation: 6,
    );
  }
}

class _Featurette extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Featurette({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 8.0 : 12.0,
      ), // Más espacio vertical
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment:
            CrossAxisAlignment.center, // Mejor alineación vertical
        children: [
          Icon(
            icon,
            color: moradoPrimario,
            size: isMobile ? 24 : 30,
          ), // Iconos un poco más grandes
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: textoClaroSecundario,
                fontSize: isMobile ? 15 : 17,
                height: 1.55,
              ), // Mejor interlineado
            ),
          ),
        ],
      ),
    );
  }
}
