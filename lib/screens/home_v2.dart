import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:study_connect/widgets/notification_icon_widget.dart';
import 'package:study_connect/widgets/widgets.dart';

// 🎨 Colores personalizados
const Color azulPrimario = Color(0xFF0D47A1); // Azul profundo
const Color azulSecundario = Color(0xFF1976D2); // Azul claro
const Color moradoPrimario = Color(0xFF7E57C2); // Púrpura educativo
const Color fondoOscuro = Color(0xFF0A192F); // Azul oscuro tipo navy
const Color blancoSuave = Color(0xFFE3F2FD); // Blanco azulado

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

  @override
  void initState() {
    super.initState();
    _obtenerDatos();
  }

  Future<void> _obtenerDatos() async {
    final user = _auth.currentUser;

    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .get();

      setState(() {
        nombreUsuario = doc.data()?['Nombre'] ?? '';
      });
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
      final snapshot =
          await FirebaseFirestore.instance
              .collection('calculo')
              .doc(entry.key)
              .collection(entry.value)
              .get();

      conteo[entry.key] = snapshot.docs.length;
      total += snapshot.docs.length;
    }

    setState(() {
      ejerciciosPorTema = conteo;
      totalEjercicios = total;
    });
  }

  Future<List<Map<String, dynamic>>> obtenerRanking() async {
    if (_rankingCache != null) return _rankingCache!;

    final usersSnapshot =
        await FirebaseFirestore.instance
            .collection('usuarios')
            .get(); // No usamos orderBy porque calcularemos el total nosotros

    final temas = ['FnAlg', 'Lim', 'Der', 'TecInteg'];
    List<Map<String, dynamic>> ranking = [];

    for (final userDoc in usersSnapshot.docs) {
      final userId = userDoc.id;
      int totalEjer = 0;

      for (final tema in temas) {
        final ejerciciosSnapshot =
            await FirebaseFirestore.instance
                .collection('calculo')
                .doc(tema)
                .collection('Ejer$tema')
                .where('AutorId', isEqualTo: userId)
                .get();

        totalEjer += ejerciciosSnapshot.size;
      }

      final data = userDoc.data();
      ranking.add({
        'uid': userId,
        'nombre': data['Nombre'] ?? 'Usuario',
        'foto': data['FotoPerfil'],
        'calificacion': data['Calificacion'] ?? 0.0,
        'ejercicios': totalEjer,
      });
    }

    // Ordenar por número de ejercicios (de mayor a menor)
    ranking.sort((a, b) => b['ejercicios'].compareTo(a['ejercicios']));

    _rankingCache = ranking.take(5).toList(); // Top 5 usuarios
    return _rankingCache!;
  }

  Future<Map<String, int>> obtenerConteoPreguntasPorTema() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('preguntas_por_tema').get();

    Map<String, int> conteo = {};

    for (final doc in snapshot.docs) {
      final tema = doc.data()['tema'] ?? 'Tema desconocido';
      conteo[tema] = (conteo[tema] ?? 0) + 1;
    }

    return conteo;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: fondoOscuro,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: azulPrimario,
          foregroundColor: Colors.white,

          elevation: 6,
          shadowColor: Colors.black.withAlpha(76),
          title: Row(
            children: [
              const Text(
                'Study Connect',
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
              const SizedBox(width: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/logo_ipn.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
          actions:
              isMobile
                  ? [
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onSelected: (value) {
                        Navigator.pushNamed(context, '/$value');
                      },
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: '',
                              child: ListTile(
                                leading: Icon(Icons.home),
                                title: Text('Inicio'),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'ranking',
                              child: ListTile(
                                leading: Icon(Icons.emoji_events),
                                title: Text('Ranking'),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'content',
                              child: ListTile(
                                leading: Icon(Icons.book),
                                title: Text('Contenidos'),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'user_profile',
                              child: ListTile(
                                leading: Icon(Icons.person_outline),
                                title: Text('Perfil'),
                              ),
                            ),
                          ],
                    ),
                  ]
                  : [
                    for (final item in [
                      ['Inicio', '/'],
                      ['Ranking', '/ranking'],
                      ['Contenidos', '/content'],
                    ])
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, item[1]),
                        child: Text(
                          item[0],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    if (_auth.currentUser != null)
                      NotificationIconWidget(), //  AQUI el widget
                    TextButton(
                      onPressed:
                          () => Navigator.pushNamed(context, '/user_profile'),
                      style: TextButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: Row(
                        children: const [
                          Text('Perfil', style: TextStyle(color: Colors.white)),
                          SizedBox(width: 6),
                          Icon(
                            Icons.person_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/logo_escom.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _preloadIcons(), // <- Forzamos precarga de íconos
            isMobile
                ? Column(
                  children: [
                    _buildBienvenida(user),
                    const SizedBox(height: 20),
                    _buildContenidosCard(),
                    const SizedBox(height: 20),
                    _buildRightColumn(context, isMobile),
                  ],
                )
                : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildLeftColumn()),
                    const SizedBox(width: 20),
                    Expanded(child: _buildBienvenida(user)),
                    const SizedBox(width: 20),
                    Expanded(child: _buildRightColumn(context, isMobile)),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftColumn() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/images/profe.jpg',
            width: double.infinity,
            height: 600,
            fit: BoxFit.cover,
          ),
        ),

        //NoticiasCarouselApi(),
        const SizedBox(height: 10),
        _buildContenidosCard(),
      ],
    );
  }

  Widget _buildBienvenida(User? user) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Column(
        children: [
          if (nombreUsuario != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Hola, $nombreUsuario 👋',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Text(
            'Potencia tu aprendizaje y\nAlcanza tus objetivos académicos',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: blancoSuave,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'A través de ejercicios colaborativos\ncreados por estudiantes como tú',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: const Color(0xFFB0E0FF),
              fontSize: 24,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 120),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Sube tus propios ejercicios, estudia los de otros y compite por el\nreconocimiento en nuestro sistema de ranking únete a una comunidad\nde aprendizaje que recompensa tu esfuerzo y colaboración',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 60),
          if (user == null)
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: const Text('Registrarse'),
            ),
          const SizedBox(height: 120),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/content'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
            ),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Ver contenidos'),
          ),
        ],
      ),
    );
  }

  Widget _buildContenidosCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              '📚 Contenidos disponibles',
              style: GoogleFonts.poppins(
                color: blancoSuave,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '$totalEjercicios+ ejercicios',
              style: GoogleFonts.poppins(
                color: blancoSuave,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                mostrarDetallesEjercicios = !mostrarDetallesEjercicios;
              });
            },
            child: Center(
              child: Text(
                mostrarDetallesEjercicios ? 'Ocultar detalles' : 'Ver más',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (mostrarDetallesEjercicios)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  ejerciciosPorTema.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Center(
                        child: Text(
                          '• ${_nombreTema(entry.key)}: ${entry.value}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildRightColumn(BuildContext context, bool isMobile) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;

    return Column(
      children: [
        FutureBuilder<List<Map<String, dynamic>>>(
          future: obtenerRanking(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return _buildSkeletonRanking();
            }

            final topUsers = snapshot.data!;

            if (topUsers.isEmpty) {
              return const Text(
                'No hay usuarios en el ranking',
                style: TextStyle(color: Colors.white),
              );
            }

            return _buildRankingCardDesdeMapa(topUsers);
          },
        ),

        const SizedBox(height: 40),
        if (!isMobile)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/alumno.jpg',
              height: 260,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

        const SizedBox(height: 40),
        FutureBuilder<Map<String, int>>(
          future: obtenerConteoPreguntasPorTema(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return _buildSkeletonRanking(); // Reutiliza skeleton
            return _buildAutoevaluacionCard(snapshot.data!);
          },
        ),
        const SizedBox(height: 20),
        // Botón de chat (sin cambios)
        GestureDetector(
          onTap: () {
            if (!isLoggedIn) {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Inicio de sesión requerido'),
                      content: const Text(
                        'Para usar el chat necesitas iniciar sesión.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/login');
                          },
                          child: const Text('Iniciar sesión'),
                        ),
                      ],
                    ),
              );
            } else {
              Navigator.pushNamed(context, '/chat');
            }
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  if (isLoggedIn)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLoggedIn
                          ? Icons.chat_bubble_outline
                          : Icons.lock_outline,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isLoggedIn ? 'Chat' : 'Inicia sesión',
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSkeletonRanking() {
    return Container(
      height: 200,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          SizedBox(height: 16),
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 12),
          Text('Cargando ...', style: TextStyle(color: Colors.white70)),
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
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: CircleAvatar(radius: 32, backgroundImage: avatar),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          nombre,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            shadows: [
              Shadow(
                blurRadius: 2,
                color: Colors.black26,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text(
              '$puntaje pts',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                    blurRadius: 2,
                    color: Colors.black26,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$ejercicios ejercicios',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildRankingCardDesdeMapa(List<Map<String, dynamic>> topUsers) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      width: double.infinity, // <-- AÑADE ESTO
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '🏅 Top 5 - Comunidad destacada',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children:
                topUsers.asMap().entries.map((entry) {
                  final i = entry.key;
                  final data = entry.value;
                  final nombre = data['nombre'] ?? 'Usuario';
                  final puntaje = (data['calificacion'] ?? 0.0).toStringAsFixed(
                    2,
                  );
                  final ejercicios = data['ejercicios'] ?? 0;
                  final foto = data['foto'];

                  final defaultAvatars = [
                    'assets/images/avatar1.png',
                    'assets/images/avatar2.png',
                    'assets/images/avatar3.png',
                  ];

                  final ImageProvider avatar =
                      (foto != null && foto.startsWith('http'))
                          ? NetworkImage(foto)
                          : AssetImage(defaultAvatars[i % 3]);

                  return _avatarMiniRanking(
                    avatar,
                    nombre,
                    puntaje,
                    ejercicios,
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoevaluacionCard(Map<String, int> preguntasPorTema) {
    final totalPreguntas = preguntasPorTema.values.fold(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              '📝 Autoevaluación disponible',
              style: GoogleFonts.poppins(
                color: blancoSuave,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '$totalPreguntas+ preguntas',
              style: GoogleFonts.poppins(
                color: blancoSuave,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                mostrarDetallesPreguntas = !mostrarDetallesPreguntas;
              });
            },
            child: Center(
              child: Text(
                mostrarDetallesPreguntas ? 'Ocultar temas' : 'Ver más',
                style: GoogleFonts.poppins(
                  color: blancoSuave,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (mostrarDetallesPreguntas)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  preguntasPorTema.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Center(
                        child: Text(
                          '• ${entry.key}: ${entry.value}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/autoevaluation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF6A11CB),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),

              icon: const Icon(Icons.assignment_turned_in),
              label: const Text('Ir a autoevaluación'),
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
}
