import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final int totalContenidos;
  final String mensajeBienvenida;

  const HomePage({
    super.key,
    this.totalContenidos = 932,
    this.mensajeBienvenida =
        'Potencia tu aprendizaje y Alcanza tus objetivos académicos.',
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFF036799),
      appBar: AppBar(
        title: const Text('Study Connect'),
        backgroundColor: const Color(0xFF048DD2),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Inicio', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Ranking', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Contenidos',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/chat');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Iniciar sesión',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child:
            isWide
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLeftColumn(),
                    _buildCenterColumn(mensajeBienvenida),
                    _buildRightColumn(),
                  ],
                )
                : Column(
                  children: [
                    _buildLeftColumn(),
                    const SizedBox(height: 20),
                    _buildCenterColumn(mensajeBienvenida),
                    const SizedBox(height: 20),
                    _buildRightColumn(),
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
            height: 150,
            width: 120,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Contenidos\n$totalContenidos+',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildCenterColumn(String titulo) {
    return Flexible(
      flex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'A través de ejercicios colaborativos\ncreados por estudiantes como tú.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFB0E0FF), fontSize: 16),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sube tus propios ejercicios, estudia los de otros y compite\n'
            'por el reconocimiento en nuestro sistema de ranking.\n'
            'Únete a una comunidad de aprendizaje que recompensa\n'
            'tu esfuerzo y colaboración.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 20,
            children: [
              ElevatedButton(
                onPressed: () {},
                child: const Text('Iniciar sesión'),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.play_arrow),
                label: const Text('Ver contenidos'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRightColumn() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF48C9EF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Text('Ranking', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _avatar('assets/images/avatar1.png'),
                  _avatar('assets/images/avatar2.png'),
                  _avatar('assets/images/avatar3.png'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/images/alumno.jpg',
            height: 150,
            width: 120,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }

  Widget _avatar(String path) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: CircleAvatar(radius: 16, backgroundImage: AssetImage(path)),
    );
  }
}
