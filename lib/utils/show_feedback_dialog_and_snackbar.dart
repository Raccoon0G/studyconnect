import 'package:flutter/material.dart';
import 'package:study_connect/utils/custom_snackbar.dart';
import 'package:study_connect/utils/show_custom_dialog.dart';

/// Muestra un diálogo y luego un snackbar personalizado, según el resultado
Future<void> showFeedbackDialogAndSnackbar({
  required BuildContext context,
  required String titulo,
  required String mensaje,
  CustomDialogType tipo = CustomDialogType.info,
  String? snackbarMessage,
  bool snackbarSuccess = true,
}) async {
  await showCustomDialog(
    context: context,
    titulo: titulo,
    mensaje: mensaje,
    tipo: tipo,
  );

  // Cuando el usuario cierre el diálogo, mostramos un snackbar
  if (snackbarMessage != null && snackbarMessage.isNotEmpty) {
    showCustomSnackbar(
      context: context,
      message: snackbarMessage,
      success: snackbarSuccess,
    );
  }
}
