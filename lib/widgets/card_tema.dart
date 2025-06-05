import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (BuildContext dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Text(
              'Inicio de Sesión Requerido',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Para realizar esta acción, necesitas iniciar sesión.',
              style: GoogleFonts.poppins(),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.poppins(
                    color: Theme.of(dialogContext).colorScheme.secondary,
                  ),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.primary,
                  foregroundColor:
                      Theme.of(dialogContext).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('Iniciar Sesión', style: GoogleFonts.poppins()),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.pushNamed(context, '/login');
                },
              ),
            ],
          ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String texto,
    IconData icono,
    VoidCallback onPressedCallback,
  ) {
    // Mantenemos el estilo de tus botones internos originales
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ElevatedButton.icon(
        onPressed: onPressedCallback,
        icon: Icon(icono, size: 18, color: Colors.black54),
        label: Text(
          texto,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.95),
          elevation: 1,
          minimumSize: const Size.fromHeight(40),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        // <--- GESTURE DETECTOR PRINCIPAL PARA TODA LA TARJETA
        onTap: () {
          // Acción por defecto al tocar la tarjeta (navegar a lista de ejercicios)
          print(
            'Card Tapped: Navigating to /exercise_list with clave: ${widget.clave}, titulo: ${widget.titulo}',
          );
          Navigator.pushNamed(
            context,
            '/exercise_list',
            arguments: {
              'tema': widget.clave,
              'titulo': widget.titulo,
            }, // Usar 'tema' como clave para los argumentos
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform:
              isHovered
                  ? (Matrix4.identity()..scale(1.02))
                  : Matrix4.identity(),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isHovered ? 0.12 : 0.06),
                blurRadius: isHovered ? 18 : 10,
                spreadRadius: isHovered ? 1 : 0,
                offset: Offset(0, isHovered ? 6 : 3),
              ),
            ],
          ),
          child: Container(
            // La altura se manejará por el contenido y cómo se coloque en ContentPage
            // width: isWide ? 400 : double.infinity, // El Wrap en ContentPage controlará el ancho
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF63A4FF).withOpacity(0.85),
                  const Color(0xFF3A7BD5).withOpacity(0.95),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.4, 0.6],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.titulo,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 2.0,
                              color: Colors.black.withOpacity(0.35),
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 18),
                      _buildButton(
                        context,
                        'Ver contenido',
                        Icons.arrow_forward,
                        () {
                          // Icono original
                          print(
                            'Button "Ver contenido" Tapped: Navigating to /exercise_list with clave: ${widget.clave}, titulo: ${widget.titulo}',
                          );
                          Navigator.pushNamed(
                            context,
                            '/exercise_list', // Ruta original del CardTema para "Ver contenido"
                            arguments: {
                              'tema': widget.clave,
                              'titulo': widget.titulo,
                            },
                          );
                        },
                      ),
                      _buildButton(context, 'Ver material', Icons.book, () {
                        // Icono original
                        print(
                          'Button "Ver material" Tapped: Navigating to /material_list with clave: ${widget.clave}, titulo: ${widget.titulo}',
                        );
                        Navigator.pushNamed(
                          context,
                          '/material_list',
                          arguments: {
                            'tema': widget.clave,
                            'titulo': widget.titulo,
                          }, // Usar 'tema'
                        );
                      }),
                      _buildButton(
                        context,
                        'Agregar ejercicio',
                        Icons.add_box_outlined,
                        () {
                          // Icono original
                          final isLoggedIn =
                              FirebaseAuth.instance.currentUser != null;
                          if (!isLoggedIn) {
                            _showLoginRequiredDialog(context);
                          } else {
                            print(
                              'Button "Agregar ejercicio" Tapped: Navigating to /exercise_upload',
                            );
                            // En tu ContentPage original, _botonProtegido para 'Agregar ejercicio' no pasaba argumentos.
                            // Si necesitas pasar argumentos para esta ruta DESDE CardTema, añádelos aquí.
                            // Ejemplo: arguments: {'temaClave': widget.clave}
                            Navigator.pushNamed(context, '/exercise_upload');
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.asset(
                        widget
                            .imagen, // Asegúrate que esta ruta ya incluya 'assets/images/'
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
