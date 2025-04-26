import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CardTema extends StatefulWidget {
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
  State<CardTema> createState() => _CardTemaState();
}

class _CardTemaState extends State<CardTema> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 1000;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/exercise_list',
            arguments: {'tema': widget.clave, 'titulo': widget.titulo},
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform:
              isHovered
                  ? (Matrix4.identity()..scale(1.03))
                  : Matrix4.identity(),

          decoration: BoxDecoration(
            boxShadow:
                isHovered
                    ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ]
                    : [],
            borderRadius: BorderRadius.circular(16),
          ),
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
                      widget.titulo,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildButton(context, 'Ver contenido', Icons.arrow_forward),
                    const SizedBox(height: 16),
                    _buildButton(context, 'Ver material', Icons.book),
                    const SizedBox(height: 16),
                    _buildButton(
                      context,
                      'Agregar ejercicio',
                      Icons.add_box_outlined,
                    ),
                  ],
                ),
                _buildImage(widget.imagen),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String texto, IconData icono) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: ElevatedButton.icon(
        onPressed: () {
          if (texto == 'Ver contenido') {
            Navigator.pushNamed(
              context,
              '/exercise_list',
              arguments: {'tema': widget.clave, 'titulo': widget.titulo},
            );
          } else if (texto == 'Ver material') {
            Navigator.pushNamed(
              context,
              '/material_list',
              arguments: {'tema': widget.clave, 'titulo': widget.titulo},
            );
          } else if (texto == 'Agregar ejercicio') {
            Navigator.pushNamed(context, '/exercise_upload');
          }
        },
        icon: Icon(icono, size: 18),
        label: Text(texto, style: const TextStyle(fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 2,
          minimumSize: const Size.fromHeight(42),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String assetName) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.only(top: 30),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/images/$assetName',
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
            width: double.infinity,
          ),
        ),
      ),
    );
  }
}
