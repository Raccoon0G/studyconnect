// lib/services/navigation_service.dart
import 'package:flutter/material.dart';

class NavigationService {
  static void navigateToNotificationContent(
    BuildContext context,
    Map<String, dynamic> notification,
  ) {
    final String tipo = notification['tipo'] ?? '';
    final String referenciaId = notification['referenciaId'] ?? '';
    final String? tema = notification['tema'];

    switch (tipo) {
      case 'mensaje':
      case 'mensaje_grupo':
      case 'grupo':
        // NAVEGACIÓN A CHATS
        // NOTA: Tu 'main.dart' tiene la ruta '/chat' que parece ser una lista de chats.
        // Para ir a un chat específico, probablemente necesites una ruta dinámica.
        // Si tu página de chat puede recibir el ID, puedes pasar a esa página.
        // Si no, simplemente abrimos la lista de chats.
        Navigator.pushNamed(context, '/chat');
        break;

      case 'comentario':
      case 'calificacion':
      case 'ejercicio':
        // NAVEGACIÓN A EJERCICIOS
        // Esto coincide con tu ruta '/exercise_view' en onGenerateRoute.
        if (referenciaId.isNotEmpty && tema != null) {
          Navigator.pushNamed(
            context,
            '/exercise_view',
            arguments: {'ejercicioId': referenciaId, 'tema': tema},
          );
        }
        break;

      case 'material':
        // NAVEGACIÓN A MATERIALES
        // Esto coincide con tu ruta '/material_view' en onGenerateRoute.
        if (referenciaId.isNotEmpty && tema != null) {
          Navigator.pushNamed(
            context,
            '/material_view',
            arguments: {'materialId': referenciaId, 'tema': tema},
          );
        }
        break;

      case 'ranking':
        Navigator.pushNamed(context, '/ranking');
        break;

      default:
        print('Navegación no implementada para el tipo: $tipo');
        break;
    }
  }
}
