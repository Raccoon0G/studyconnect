import 'package:flutter/material.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preguntas Frecuentes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ExpansionTile(
            title: Text('¿Cómo puedo registrarme?'),
            children: [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Para registrarte, ve a la pantalla principal y haz clic en "Registrarse". Llena el formulario y acepta los términos.',
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: Text('¿Dónde puedo subir ejercicios?'),
            children: [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Una vez que hayas iniciado sesión, navega a la sección "Contenidos" y selecciona "Agregar ejercicio".',
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: Text('¿Puedo editar mis ejercicios después de subirlos?'),
            children: [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Sí, puedes modificar tus ejercicios desde tu perfil, siempre que no estén bloqueados por revisión.',
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: Text('¿Cómo funciona el sistema de ranking?'),
            children: [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Los usuarios reciben puntos cuando comparten contenido útil y reciben buenas calificaciones por parte de otros.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
