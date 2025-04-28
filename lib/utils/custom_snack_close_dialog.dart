import 'package:flutter/material.dart';

/// Cierra cualquier diálogo abierto y luego muestra un snackbar bonito.
/// Este método es útil para mostrar mensajes de éxito o error después de una acción,
/// como el registro o inicio de sesión de un usuario.
///
Future<void> closeDialogAndShowSnackbar({
  required BuildContext context,
  required String message,
  required bool success,
}) async {
  final navigator = Navigator.of(
    context,
    rootNavigator: true,
  ); // 👈 Guardar antes

  // 1. Cerrar cualquier diálogo abierto
  if (navigator.canPop()) {
    navigator.pop();
    await Future.delayed(const Duration(milliseconds: 250));
  }

  // 2. Mostrar snackbar bonito
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: success ? Colors.green.shade600 : Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
