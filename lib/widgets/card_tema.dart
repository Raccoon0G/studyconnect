import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CardTema extends StatelessWidget {
  final String titulo;
  final String clave;
  final String imagen;

  const CardTema({
    super.key,
    required this.titulo,
    required this.clave,
    required this.imagen,
  });

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 1000;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/exercise_list',
          arguments: {'tema': clave, 'titulo': titulo},
        );
      },
      child: Container(
        height: 650,
        width: isWide ? 400 : double.infinity,
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 30),
                _boton(context, 'Ver contenido', Icons.arrow_forward),
                const SizedBox(height: 16),
                _boton(context, 'Ver material', Icons.book),
                const SizedBox(height: 16),
              ],
            ),
            _imagenIlustrativa(ancho: 450, alto: 400, assetName: imagen),
          ],
        ),
      ),
    );
  }

  Widget _boton(BuildContext context, String texto, IconData icono) {
    return ElevatedButton.icon(
      onPressed: () {
        if (texto == 'Ver contenido') {
          Navigator.pushNamed(
            context,
            '/exercise_list',
            arguments: {'tema': clave, 'titulo': titulo},
          );
        } else if (texto == 'Ver material') {
          Navigator.pushNamed(
            context,
            '/material_list',
            arguments: {'tema': clave, 'titulo': titulo},
          );
        } else if (texto == 'Agregar ejercicio') {
          Navigator.pushNamed(context, '/exercise_upload');
        }
      },
      icon: Icon(icono, size: 18),
      label: Text(texto, style: const TextStyle(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
