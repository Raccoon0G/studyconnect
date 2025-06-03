import 'package:flutter/material.dart';
import 'package:study_connect/utils/custom_dialog_type.dart';

//Esta función muestra un diálogo personalizado con un título, un mensaje y un icono opcional.
// El título y el mensaje se pueden personalizar con colores específicos.
// El diálogo se puede cerrar al hacer clic en el botón "Aceptar".
// También se pueden agregar botones personalizados con acciones específicas.
/// Muestra un diálogo personalizado con un título, mensaje y botones opcionales.
/// y ya se puede cerrar al hacer clic en el botón "Aceptar".

// --- Clase DialogButton con soporte para value
class DialogButton<T> {
  final String texto;
  final Future<void> Function()? onPressed;
  final bool cierraDialogo;
  final T? value;
  final Color? textColor; // Parámetro para el color del texto del botón

  const DialogButton({
    required this.texto,
    this.onPressed,
    this.cierraDialogo = true,
    this.value,
    this.textColor, // Añadido al constructor
  });
}

// --- Función showCustomDialog mejorada ---
Future<T?> showCustomDialog<T>({
  required BuildContext context,
  required String titulo,
  required String mensaje,
  CustomDialogType tipo = CustomDialogType.info,
  List<DialogButton<T>> botones = const [],
}) {
  // Definir ícono y color dinámico basado en el tipo (para el título del diálogo)
  IconData iconoDialogo;
  Color colorDialogo;

  switch (tipo) {
    case CustomDialogType.success:
      iconoDialogo = Icons.check_circle_outline;
      colorDialogo = Colors.green;
      break;
    case CustomDialogType.error:
      iconoDialogo = Icons.error_outline;
      colorDialogo = Colors.redAccent;
      break;
    case CustomDialogType.warning:
      iconoDialogo = Icons.warning_amber_outlined;
      colorDialogo =
          Colors
              .orange; // Cambiado de amber a orange para mejor contraste con texto oscuro
      break;
    case CustomDialogType.info:
    default:
      iconoDialogo = Icons.info_outline;
      colorDialogo =
          Theme.of(context).colorScheme.primary; // Usar color primario del tema
      break;
  }

  return showDialog<T>(
    context: context,
    barrierDismissible:
        true, // El usuario puede cerrar tocando fuera del diálogo
    builder:
        (BuildContext dialogContext) => AlertDialog(
          // Renombrado context a dialogContext para evitar shadowing
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                iconoDialogo,
                color: colorDialogo,
                size: 28,
              ), // Icono un poco más grande
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorDialogo, // Color del título igual al del icono
                  ),
                ),
              ),
            ],
          ),
          content: SelectableText(
            mensaje,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
          actions:
              botones.isEmpty
                  ? [
                    // Botón por defecto si la lista de botones está vacía
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop(); // Usar dialogContext
                      },
                      child: Text(
                        'Aceptar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(dialogContext)
                                  .colorScheme
                                  .primary, // Usar color primario del tema
                        ),
                      ),
                    ),
                  ]
                  : botones.map((boton) {
                    return TextButton(
                      onPressed: () async {
                        bool shouldPop = boton.cierraDialogo;
                        T? returnValue = boton.value;

                        // Ejecutar onPressed si existe
                        if (boton.onPressed != null) {
                          await boton.onPressed!();
                        }

                        // Cerrar el diálogo si corresponde, después de que onPressed haya tenido la oportunidad de ejecutarse
                        if (shouldPop && dialogContext.mounted) {
                          // Verificar si el contexto sigue montado
                          Navigator.of(dialogContext).pop(returnValue);
                        }
                      },
                      child: Text(
                        boton.texto,
                        style: TextStyle(
                          color:
                              boton.textColor ??
                              Theme.of(dialogContext)
                                  .colorScheme
                                  .primary, // Usa el textColor o el primario del tema
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
        ),
  );
}
