import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:study_connect/widgets/card_tema.dart';
import 'package:study_connect/widgets/notification_icon_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ContentPage extends StatelessWidget {
  const ContentPage({super.key});

  final List<Map<String, String>> temas = const [
    {
      'clave': 'FnAlg',
      'titulo': 'Funciones algebraicas y trascendentes',
      'imagen': 'funciones.png',
    },
    {
      'clave': 'Lim',
      'titulo': 'Límites de funciones y Continuidad',
      'imagen': 'limites.png',
    },
    {
      'clave': 'Der',
      'titulo': 'Derivada y optimización',
      'imagen': 'derivadas3.png',
    },
    {
      'clave': 'TecInteg',
      'titulo': 'Técnicas de integración',
      'imagen': 'tecnicas2.png',
    },
  ];

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
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Inicio de sesión requerido'),
                  content: const Text(
                    'Para realizar esta acción necesitas iniciar sesión.',
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
          Navigator.pushNamed(context, ruta);
        }
      },
      icon: Icon(icono),
      label: Text(texto),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: isLoggedIn ? Colors.black : Colors.grey.shade600,
        elevation: isLoggedIn ? 4 : 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //final isWide = MediaQuery.of(context).size.width > 800;

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
          const NotificationIconWidget(),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/user_profile');
            },
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: const Text(
                'Contenidos',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Center(
              child: Wrap(
                spacing: 24,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: [
                  CardTema(
                    titulo: 'Funciones algebraicas y trascendentes',
                    clave: 'FnAlg',
                    imagen: 'funciones.png',
                  ),
                  CardTema(
                    titulo: 'Límites de funciones y Continuidad',
                    clave: 'Lim',
                    imagen: 'limites3.png',
                  ),
                  CardTema(
                    titulo: 'Derivada y optimización',
                    clave: 'Der',
                    imagen: 'derivadas5.png',
                  ),
                  CardTema(
                    titulo: 'Técnicas de integración',
                    clave: 'TecInteg',
                    imagen: 'tecnicas2.png',
                  ),
                ],
              ),
            ),
            //OTRA VISTA DE LAS TARJETAS
            //isWide
            //    ? Center(
            //      child: SizedBox(
            //        width:
            //            MediaQuery.of(context).size.width *
            //            0.94, // margen lateral
            //        child: SingleChildScrollView(
            //          scrollDirection: Axis.horizontal,
            //          child: Row(
            //            mainAxisAlignment: MainAxisAlignment.center,
            //            children:
            //                temas.map((tema) {
            //                  return Padding(
            //                    padding: const EdgeInsets.symmetric(
            //                      horizontal: 12,
            //                    ),
            //                    child: _buildCard(context, tema),
            //                  );
            //                }).toList(),
            //          ),
            //        ),
            //      ),
            //    )
            //    : Column(
            //      children:
            //          temas
            //              .map(
            //                (tema) => Padding(
            //                  padding: const EdgeInsets.only(bottom: 16),
            //                  child: _buildCard(context, tema),
            //                ),
            //              )
            //              .toList(),
            //    ),
            const SizedBox(height: 30),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   children: [
            //     ElevatedButton.icon(
            //       onPressed:
            //           () => Navigator.pushNamed(context, '/exercise_upload'),
            //       icon: const Icon(Icons.add),
            //       label: const Text('Agregar ejercicio'),
            //       style: ElevatedButton.styleFrom(
            //         backgroundColor: Colors.white,
            //         foregroundColor: Colors.black,
            //       ),
            //     ),
            //     const SizedBox(width: 16),
            //     ElevatedButton.icon(
            //       onPressed:
            //           () => Navigator.pushNamed(context, '/upload_material'),
            //       icon: const Icon(Icons.add),
            //       label: const Text('Agregar material'),
            //       style: ElevatedButton.styleFrom(
            //         backgroundColor: Colors.white,
            //         foregroundColor: Colors.black,
            //       ),
            //     ),
            //   ],
            // ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _botonProtegido(
                  context,
                  icono: Icons.add,
                  texto: 'Agregar ejercicio',
                  ruta: '/exercise_upload',
                ),
                const SizedBox(width: 16),
                _botonProtegido(
                  context,
                  icono: Icons.add,
                  texto: 'Agregar material',
                  ruta: '/upload_material',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
