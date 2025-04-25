import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:study_connect/services/notification_service.dart';
import 'package:study_connect/widgets/notification_icon_widget.dart';

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
  bool mostrarDetalles = false;

  @override
  void initState() {
    super.initState();
    _obtenerDatos();
    _cargarTopRanking();
  }

  List<Map<String, dynamic>> topUsuarios = [];

  Future<void> _cargarTopRanking() async {
    final query =
        await FirebaseFirestore.instance
            .collection('usuarios')
            .orderBy('EjerSubidos', descending: true) // o "Puntos"
            .limit(3)
            .get();

    setState(() {
      topUsuarios =
          query.docs.map((doc) {
            final data = doc.data();
            return {
              'nombre': data['Nombre'] ?? 'Usuario',
              'avatar':
                  data['FotoPerfil'] ??
                  'assets/images/avatar1.png', // asegúrate que exista o usa un default
            };
          }).toList();
    });
  }

  Future<List<Map<String, dynamic>>> _obtenerTop3Usuarios() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('usuarios')
            .orderBy('Puntaje', descending: true)
            .limit(3)
            .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'nombre': data['Nombre'] ?? 'Usuario',
        'avatar': data['FotoPerfil'] ?? 'assets/images/default_avatar.png',
      };
    }).toList();
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF036799),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: const Color(0xFF048DD2),
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
            height: 700,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 20),
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
            'Potencia tu aprendizaje y\nAlcanza tus objetivos académicos.',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'A través de ejercicios colaborativos\ncreados por estudiantes como tú.',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
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
              'Sube tus propios ejercicios, estudia los de otros y compite por el\nreconocimiento en nuestro sistema de ranking \u00danete a una comunidad\nde aprendizaje que recompensa tu esfuerzo y colaboraci\u00f3n',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
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
              onPressed: () => Navigator.pushNamed(context, '/login'),
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Contenidos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text('$totalEjercicios+', style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                mostrarDetalles = !mostrarDetalles;
              });
            },
            child: Text(mostrarDetalles ? 'Ocultar detalles' : 'Ver más'),
          ),
          if (mostrarDetalles)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  ejerciciosPorTema.entries
                      .map(
                        (entry) => Text(
                          '${_nombreTema(entry.key)}: ${entry.value}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      )
                      .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildRightColumn(BuildContext context, bool isMobile) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    return FutureBuilder<QuerySnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('usuarios')
              .orderBy('Calificacion', descending: true)
              .limit(3)
              .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final topUsers = snapshot.data!.docs;

        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFB3E5FC),
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
                children: [
                  Text(
                    '🏆 Top 3 Ranking',
                    style: GoogleFonts.roboto(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF01579B),
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
                          final data =
                              entry.value.data() as Map<String, dynamic>;
                          final nombre = data['Nombre'] ?? 'Usuario';
                          final puntaje = (data['Calificacion'] ?? 0)
                              .toStringAsFixed(2);
                          final ejercicios = data['EjerSubidos'] ?? 0;
                          final foto = data['FotoPerfil'];

                          // Backup en caso de error o URL inválida
                          final defaultAvatars = [
                            'assets/images/avatar1.png',
                            'assets/images/avatar2.png',
                            'assets/images/avatar3.png',
                          ];

                          final ImageProvider<Object> avatar =
                              (foto == null || foto.isEmpty)
                                  ? AssetImage(defaultAvatars[i % 3])
                                  : (foto.startsWith('http')
                                      ? NetworkImage(foto)
                                          as ImageProvider<Object>
                                      : AssetImage(defaultAvatars[i % 3]));

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
            ),
            const SizedBox(height: 40),
            if (!isMobile)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/alumno.jpg',
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 20),

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

            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/autoevaluation'),
              icon: const Icon(Icons.assignment_turned_in),
              label: const Text('Autoevaluación'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blueGrey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
            ),
          ],
        );
      },
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
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          '⭐ $puntaje pts',
          style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
        ),
        Text(
          '$ejercicios ejercicios',
          style: const TextStyle(color: Colors.black54, fontSize: 11),
        ),
      ],
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
