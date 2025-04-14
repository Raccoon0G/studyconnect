import 'package:flutter/material.dart';

class CreditsPage extends StatelessWidget {
  const CreditsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créditos')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plataforma desarrollada por:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              '• Jeovanny Martínez - Diseño y desarrollo de frontend y lógica de usuarios.',
            ),
            Text(
              '• Equipo de Firebase - Backend como servicio para autenticación y base de datos.',
            ),
            Text(
              '• Flutter - Framework de UI utilizado para la construcción de la aplicación web.',
            ),
            Text(
              '• flutter_math_fork - Paquete para renderizar notación matemática en LaTeX.',
            ),
            SizedBox(height: 20),
            Text(
              'Agradecimientos especiales a:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('• Profesores y tutores de ESCOM que apoyaron el proyecto.'),
            Text(
              '• Comunidad de estudiantes que colaboraron subiendo ejercicios.',
            ),
            Text('• ChatGPT por asistencia durante el desarrollo del sistema.'),
          ],
        ),
      ),
    );
  }
}
