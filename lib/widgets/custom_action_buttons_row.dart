import 'package:flutter/material.dart';
import 'package:study_connect/utils/auth_utils.dart';

class CustomActionButtonsRow extends StatelessWidget {
  final VoidCallback onCalificar;
  final VoidCallback onCompartir;
  final String accion;

  const CustomActionButtonsRow({
    super.key,
    required this.onCalificar,
    required this.onCompartir,
    required this.accion,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 20,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        _buildButton(
          text:
              isUserLoggedIn()
                  ? accion
                  : 'Iniciar sesión', // Cambia el texto según el estado de inicio de sesión
          icon:
              isUserLoggedIn()
                  ? Icons.star
                  : Icons
                      .lock, // Cambia el icono según el estado de inicio de sesión
          onPressed: () {
            if (isUserLoggedIn()) {
              // Verifica si el usuario está autenticado
              onCalificar(); // Llama a la función de calificación
            } else {
              showDialog(
                context: context,
                builder:
                    (_) => AlertDialog(
                      title: const Text('Inicia sesión'),
                      content: Text('Debes iniciar sesión para $accion.'),
                      actions: [
                        TextButton(
                          onPressed:
                              () => Navigator.pushNamed(context, '/login'),
                          child: const Text('Iniciar sesión'),
                        ),
                      ],
                    ),
              );
            }
          },
          backgroundColor:
              isUserLoggedIn() ? const Color(0xFF1A1A1A) : Colors.grey,
        ),
        _buildButton(
          text: 'Compartir',
          icon: Icons.share,
          onPressed: onCompartir,
        ),
      ],
    );
  }

  Widget _buildButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    Color backgroundColor = const Color(0xFF1A1A1A),
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}
