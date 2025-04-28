import 'package:flutter/material.dart';
import 'package:study_connect/utils/custom_snackbar.dart'; // Asegúrate que esté bien importado
import 'package:study_connect/utils/custom_dialog_type.dart';

/// Enum para definir el tipo de diálogo

/// Función para mostrar un diálogo + snackbar de retroalimentación
Future<void> showFeedbackDialogAndSnackbar({
  required BuildContext context,
  required String titulo,
  required String mensaje,
  required CustomDialogType tipo,
  required String snackbarMessage,
  required bool snackbarSuccess,
}) async {
  IconData icono;
  Color iconColor;

  // 🛠️ Elegir icono y color dinámicamente
  switch (tipo) {
    case CustomDialogType.success:
      icono = Icons.check_circle_outline;
      iconColor = Colors.green;
      break;
    case CustomDialogType.warning:
      icono = Icons.warning_amber_outlined;
      iconColor = Colors.amber;
      break;
    case CustomDialogType.error:
      icono = Icons.error_outline;
      iconColor = Colors.redAccent;
      break;
    case CustomDialogType.info:
      icono = Icons.info_outline;
      iconColor = Colors.blueAccent;
      break;
    default:
      icono = Icons.info_outline;
      iconColor = Colors.blueAccent;
      break;
  }

  // 📋 Mostrar el diálogo primero
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icono, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                titulo,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          mensaje,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      );
    },
  );

  // ✅ Luego mostrar el snackbar
  if (context.mounted) {
    showCustomSnackbar(
      context: context,
      message: snackbarMessage,
      success: snackbarSuccess,
    );
  }
}
