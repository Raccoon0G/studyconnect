import 'package:flutter/material.dart';
import 'package:study_connect/utils/custom_dialog_type.dart';

//Esta función muestra un diálogo personalizado con un título, un mensaje y un icono opcional.
// El título y el mensaje se pueden personalizar con colores específicos.
// El diálogo se puede cerrar al hacer clic en el botón "Aceptar".
// También se pueden agregar botones personalizados con acciones específicas.
/// Muestra un diálogo personalizado con un título, mensaje y botones opcionales.
/// y ya se puede cerrar al hacer clic en el botón "Aceptar".

/// Función para mostrar un diálogo bonito y dinámico
Future<void> showCustomDialog({
  required BuildContext context,
  required String titulo,
  required String mensaje,
  CustomDialogType tipo = CustomDialogType.info,
  List<DialogButton> botones = const [],
}) async {
  // Definir ícono y color dinámico basado en el tipo
  IconData icono;
  Color color;

  switch (tipo) {
    case CustomDialogType.success:
      icono = Icons.check_circle_outline;
      color = Colors.green;
      break;
    case CustomDialogType.error:
      icono = Icons.error_outline;
      color = Colors.redAccent;
      break;
    case CustomDialogType.warning:
      icono = Icons.warning_amber_outlined;
      color = Colors.amber;
      break;
    case CustomDialogType.info:
    default:
      icono = Icons.info_outline;
      color = Colors.blueAccent;
      break;
  }

  return showDialog(
    context: context,
    barrierDismissible: true,
    builder:
        (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(icono, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          content: SelectableText(
            mensaje,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          actions:
              botones.isEmpty
                  ? [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Aceptar'),
                    ),
                  ]
                  : botones.map((boton) {
                    return TextButton(
                      onPressed: () async {
                        if (boton.cierraDialogo) {
                          Navigator.of(context).pop();
                        }
                        if (boton.onPressed != null) {
                          await boton.onPressed!();
                        }
                      },
                      child: Text(boton.texto),
                    );
                  }).toList(),
        ),
  );
}

/// Modelo para definir botones del diálogo
class DialogButton {
  final String texto;
  final Future<void> Function()? onPressed;
  final bool cierraDialogo;

  const DialogButton({
    required this.texto,
    this.onPressed,
    this.cierraDialogo = true,
  });
}
