import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:study_connect/widgets/card_tema.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_connect/widgets/widgets.dart' show CustomAppBar;

class ContentPage extends StatelessWidget {
  const ContentPage({super.key});

  final List<Map<String, String>> temas = const [
    {
      'clave': 'FnAlg',
      'titulo': 'Funciones algebraicas y trascendentes',
      'imagen': 'assets/images/funciones.webp',
    },
    {
      'clave': 'Lim',
      'titulo': 'Límites de funciones y Continuidad',
      'imagen': 'assets/images/limites3.webp',
    },
    {
      'clave': 'Der',
      'titulo': 'Derivada y optimización',
      'imagen': 'assets/images/derivadas5.webp',
    },
    {
      'clave': 'TecInteg',
      'titulo': 'Técnicas de integración',
      'imagen': 'assets/images/tecnicas2.webp',
    },
  ];

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

  Widget _botonProtegido(
    BuildContext context, {
    required IconData icono,
    required String texto,
    required String ruta,
  }) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    return ElevatedButton.icon(
      onPressed: () {
        if (!isLoggedIn) {
          _showLoginRequiredDialog(context);
        } else {
          Navigator.pushNamed(context, ruta);
        }
      },
      icon: Icon(icono, size: 16),
      label: Text(texto, style: GoogleFonts.poppins(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: isLoggedIn ? Colors.black87 : Colors.grey.shade600,
        elevation: isLoggedIn ? 3 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount;
    double childAspectRatio;
    double mainAxisSpacing = 16.0;
    double crossAxisSpacing = 16.0;
    EdgeInsets gridPadding = const EdgeInsets.symmetric(
      horizontal: 16.0,
      vertical: 20.0,
    );

    if (screenWidth > 1150) {
      crossAxisCount = 4;
      childAspectRatio =
          0.72; // Ajusta este valor para que la imagen tenga buen tamaño
      mainAxisSpacing = 20.0;
      crossAxisSpacing = 20.0;
      gridPadding = const EdgeInsets.symmetric(
        horizontal: 24.0,
        vertical: 20.0,
      );
    } else if (screenWidth > 850) {
      crossAxisCount = 3;
      childAspectRatio = 0.7;
      mainAxisSpacing = 18.0;
      crossAxisSpacing = 18.0;
    } else if (screenWidth > 550) {
      crossAxisCount = 2;
      childAspectRatio = 0.75;
    } else {
      crossAxisCount = 1;
      childAspectRatio = 0.7;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF036799),
      appBar: const CustomAppBar(titleText: "Study Connect", showBack: true),
      body: SingleChildScrollView(
        padding: gridPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
              child: Text(
                'Contenidos',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: crossAxisSpacing,
                mainAxisSpacing: mainAxisSpacing,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: temas.length,
              itemBuilder: (context, index) {
                final tema = temas[index];
                // CardTema ahora maneja su propio onTap principal
                return CardTema(
                  titulo: tema['titulo']!,
                  clave: tema['clave']!,
                  imagen: tema['imagen']!,
                );
              },
            ),
            const SizedBox(height: 32),

            Center(
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _botonProtegido(
                    context,
                    icono: Icons.add_circle_outline,
                    texto: 'Agregar ejercicio',
                    ruta: '/exercise_upload',
                  ),
                  _botonProtegido(
                    context,
                    icono: Icons.post_add_outlined,
                    texto: 'Agregar material',
                    ruta: '/upload_material',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
