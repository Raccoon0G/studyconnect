import 'package:flutter/material.dart';

class ContentPage extends StatelessWidget {
  const ContentPage({super.key});

  final List<Map<String, String>> temas = const [
    {'titulo': 'Funciones algebraicas y trascendentales'},
    {'titulo': 'Límites de funciones y Continuidad'},
    {'titulo': 'Derivada y optimización'},
    {'titulo': 'Técnicas de integración'},
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFF036799),
      appBar: AppBar(
        backgroundColor: const Color(0xFF048DD2),
        title: const Text('Study Connect'),
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contenidos',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            isWide
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: temas.map((tema) => _buildCard(tema)).toList(),
                )
                : Column(
                  children:
                      temas
                          .map(
                            (tema) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildCard(tema),
                            ),
                          )
                          .toList(),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, String> tema) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF48C9EF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            tema['titulo']!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _boton('Ver contenido', Icons.arrow_forward),
          const SizedBox(height: 10),
          _boton('Agregar ejercicio', Icons.add),
        ],
      ),
    );
  }

  Widget _boton(String texto, IconData icono) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(texto, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Icon(icono, size: 18),
        ],
      ),
    );
  }
}
