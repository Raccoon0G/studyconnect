import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatefulWidget {
  final int totalContenidos;

  const HomePage({super.key, this.totalContenidos = 932});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(51),
                      blurRadius: 4,
                      offset: const Offset(1, 2),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/logo_ipn.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
          actions:
              isMobile
                  ? [
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.menu,
                        color: Colors.white,
                        size: 28,
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'Inicio':
                            Navigator.pushNamed(context, '/');
                            break;
                          case 'Ranking':
                            Navigator.pushNamed(context, '/ranking');
                            break;
                          case 'Contenidos':
                            Navigator.pushNamed(context, '/content');
                            break;
                          case 'Perfil':
                            Navigator.pushNamed(context, '/user_profile');
                            break;
                        }
                      },
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: 'Inicio',
                              child: ListTile(
                                leading: Icon(Icons.home),
                                title: Text('Inicio'),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'Ranking',
                              child: ListTile(
                                leading: Icon(Icons.emoji_events),
                                title: Text('Ranking'),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'Contenidos',
                              child: ListTile(
                                leading: Icon(Icons.book),
                                title: Text('Contenidos'),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'Perfil',
                              child: ListTile(
                                leading: Icon(Icons.person_outline),
                                title: Text('Perfil'),
                              ),
                            ),
                          ],
                    ),
                  ]
                  : [
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/'),
                      child: const Text(
                        'Inicio',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/ranking'),
                      child: const Text(
                        'Ranking',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/content'),
                      child: const Text(
                        'Contenidos',
                        style: TextStyle(color: Colors.white),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
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
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(51),
                            blurRadius: 4,
                            offset: const Offset(1, 2),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/logo_escom.png',
                          fit: BoxFit.contain,
                        ),
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
                    _buildCenterColumn(context),
                    const SizedBox(height: 20),
                    _buildRightColumn(context, isMobile),
                  ],
                )
                : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildLeftColumn()),
                    const SizedBox(width: 20),
                    Expanded(child: _buildCenterColumn(context)),
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
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Contenidos\n${widget.totalContenidos}+',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildCenterColumn(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Potencia tu aprendizaje y Alcanza\ntus objetivos acad\u00e9micos.',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontSize: 45,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 80),
            Text(
              'A trav\u00e9s de ejercicios colaborativos\ncreados por estudiantes como t\u00fa.',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                color: const Color(0xFFB0E0FF),
                fontSize: 28,
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
            const SizedBox(height: 130),
            Wrap(
              spacing: 20,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Registrarse',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/content'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 1.5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Ver contenidos'),
                ),
              ],
            ),
          ],
        ),
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
}
