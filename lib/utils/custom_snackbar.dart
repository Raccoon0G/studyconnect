import 'package:flutter/material.dart';

//Este snackbar personalizado sirve para mostrar mensajes de éxito o error en la aplicación.
// Se puede utilizar en cualquier parte de la aplicación, solo se necesita pasar el contexto y el mensaje que se desea mostrar.
// El color del snackbar se determina por el parámetro success, si es true se mostrará en verde, si es false en rojo.

void showCustomSnackbar({
  required BuildContext context,
  required String message,
  required bool success,
}) {
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
