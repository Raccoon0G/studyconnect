import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        child:
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
              'Sube tus propios ejercicios, estudia los de otros y compite por el\nreconocimiento en nuestro sistema de ranking. \u00danete a una comunidad\nde aprendizaje que recompensa tu esfuerzo y colaboraci\u00f3n.',
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
    return Column(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF48C9EF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                'Ranking',
                style: GoogleFonts.roboto(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 16,
                children: [
                  _avatar('assets/images/avatar1.png', 'Jeovanny'),
                  _avatar('assets/images/avatar2.png', 'Ulises'),
                  _avatar('assets/images/avatar3.png', 'Olivia'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 50),
        if (!isMobile)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/alumno.jpg',
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        if (!isMobile) const SizedBox(height: 39),
        ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/chat'),
          icon: const Icon(Icons.chat_bubble_outlined),
          label: const Text('Chat'),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/autoevaluation'),
          icon: const Icon(Icons.chat_bubble_outlined),
          label: const Text('Autoevaluación'),
        ),
      ],
    );
  }

  Widget _avatar(String path, String nombre) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 48, backgroundImage: AssetImage(path)),
        const SizedBox(height: 8),
        Text(
          nombre,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          textAlign: TextAlign.center,
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
}
