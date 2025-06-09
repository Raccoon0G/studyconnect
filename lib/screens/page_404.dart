import 'package:flutter/material.dart';

class Page404 extends StatelessWidget {
  const Page404({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. La Imagen
              Image.asset(
                'assets/images/404.webp', // Asegúrate que el nombre coincida con tu archivo
                width: 300,
                // Opcional: un texto alternativo si la imagen no carga
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.error_outline,
                    size: 100,
                    color: Colors.red,
                  );
                },
              ),
              const SizedBox(height: 32),

              // 2. El Mensaje Principal
              Text(
                '¡Ups! Página no encontrada',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // 3. El Texto de Ayuda
              Text(
                'Parece que el enlace que seguiste está roto o la página ha sido eliminada.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 40),

              // 4. El Botón de Acción
              ElevatedButton.icon(
                icon: const Icon(Icons.home_outlined),
                label: const Text('Volver al Inicio'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // Esta línea navega a la ruta principal ('/') y elimina todas las rutas anteriores.
                  // Es la forma más segura de "resetear" la navegación y volver al inicio.
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                    (Route<dynamic> route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
