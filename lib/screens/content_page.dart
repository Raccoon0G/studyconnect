import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ContentPage extends StatelessWidget {
  const ContentPage({super.key});

  final List<Map<String, String>> temas = const [
    {
      'titulo': 'Funciones algebraicas y trascendentes',
      'imagen': 'funciones.png',
    },
    {'titulo': 'Límites de funciones y Continuidad', 'imagen': 'limites.png'},
    {'titulo': 'Derivada y optimización', 'imagen': 'derivadas3.png'},
    {'titulo': 'Técnicas de integración', 'imagen': 'tecnicas2.png'},
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
            onPressed: () {
              Navigator.pushNamed(context, '/');
            },
            child: const Text('Inicio', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/ranking');
            },
            child: const Text('Ranking', style: TextStyle(color: Colors.white)),
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
                  children:
                      temas.map((tema) => _buildCard(context, tema)).toList(),
                )
                : Column(
                  children:
                      temas
                          .map(
                            (tema) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildCard(context, tema),
                            ),
                          )
                          .toList(),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, Map<String, String> tema) {
    return Container(
      height: 750,
      width: 450,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Colors.blueAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            tema['titulo']!,
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 30),
          _boton(context, 'Ver contenido', Icons.arrow_forward),
          const SizedBox(height: 30),
          _boton(context, 'Agregar ejercicio', Icons.add),
          const SizedBox(height: 30),
          _boton(context, 'Agregar Material', Icons.add),
          SizedBox(height: 50),
          _imagenIlustrativa(ancho: 450, alto: 379, assetName: tema['imagen']!),
        ],
      ),
    );
  }

  //TODO Arreglar botones
  Widget _boton(BuildContext context, String texto, IconData icono) {
    return ElevatedButton(
      onPressed: () {
        // Acción del botón
        if (texto == 'Ver contenido') {
          // Navegar a la página de contenido
          Navigator.pushNamed(context, '/exercise_list');
        } else if (texto == 'Agregar ejercicio') {
          // Navegar a la página de agregar ejercicio
          Navigator.pushNamed(context, '/exercise_upload');
        }
      },
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

  Widget _imagenIlustrativa({
    required double ancho,
    required double alto,
    required String assetName,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/images/$assetName',
          width: ancho,
          height: alto,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
