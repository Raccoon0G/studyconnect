import 'package:flutter/material.dart';

// (El código del modelo de datos y la función de formato de fecha no cambian)
class _PrivacySectionData {
  final String title;
  final IconData icon;
  final Widget content;
  final GlobalKey key = GlobalKey();
  _PrivacySectionData({
    required this.title,
    required this.icon,
    required this.content,
  });
}

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});
  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  final ScrollController _scrollController = ScrollController();
  List<_PrivacySectionData> _sections = [];

  String _formatPrivacyDate(DateTime fecha) {
    const List<String> meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    final dia = fecha.day;
    final mes = meses[fecha.month - 1];
    final anio = fecha.year;
    return '$dia de $mes de $anio';
  }

  List<_PrivacySectionData> _getPrivacySections(BuildContext context) {
    final bodyStyle = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(height: 1.5);
    final boldStyle = bodyStyle?.copyWith(fontWeight: FontWeight.bold);

    return [
      _PrivacySectionData(
        title: '1. Identidad del Responsable',
        icon: Icons.shield_outlined,
        content: RichText(
          text: TextSpan(
            style: bodyStyle,
            children: [
              const TextSpan(
                text:
                    'El responsable del tratamiento de los datos personales es el equipo de desarrollo del proyecto ',
              ),
              TextSpan(text: '“Study Connect”', style: boldStyle),
              const TextSpan(
                text:
                    ', en el marco del Trabajo Terminal 2025-A050 realizado para la Escuela Superior de Cómputo (ESCOM) del Instituto Politécnico Nacional (IPN).',
              ),
            ],
          ),
        ),
      ),
      _PrivacySectionData(
        title: '2. Datos Personales Recabados',
        icon: Icons.person_search_outlined,
        content: RichText(
          text: TextSpan(
            style: bodyStyle,
            children: [
              const TextSpan(
                text:
                    'Para el funcionamiento de la plataforma, recabamos los siguientes datos:\n\n',
              ),
              TextSpan(text: '• Datos de Identificación: ', style: boldStyle),
              const TextSpan(
                text:
                    'Nombre completo, correo electrónico institucional, número de teléfono y rol dentro de la comunidad (alumno, profesor).\n',
              ),
              TextSpan(
                text: '• Contenido Generado por el Usuario: ',
                style: boldStyle,
              ),
              const TextSpan(
                text:
                    'Ejercicios, material educativo (PDF, imágenes, videos, enlaces), comentarios, calificaciones y mensajes de chat que usted decida publicar.\n',
              ),
              TextSpan(text: '• Datos de Uso y Técnicos: ', style: boldStyle),
              const TextSpan(
                text:
                    'Información sobre su interacción con la plataforma, como puntajes de autoevaluaciones, y datos técnicos básicos para asegurar la compatibilidad y seguridad.',
              ),
            ],
          ),
        ),
      ),
      _PrivacySectionData(
        title: '3. Finalidades del Tratamiento',
        icon: Icons.check_circle_outline,
        content: RichText(
          text: TextSpan(
            style: bodyStyle,
            children: [
              const TextSpan(
                text:
                    'Sus datos personales serán utilizados para las siguientes finalidades académicas y no lucrativas:\n\n',
              ),
              const TextSpan(
                text: '• Gestionar su acceso y cuenta en la plataforma.\n',
              ),
              const TextSpan(
                text:
                    '• Permitir la publicación, visualización y calificación de contenido educativo.\n',
              ),
              const TextSpan(
                text:
                    '• Facilitar la comunicación entre usuarios a través del chat integrado.\n',
              ),
              const TextSpan(
                text:
                    '• Calcular su posición en el ranking basado en contribuciones y calificaciones.\n',
              ),
              const TextSpan(
                text:
                    '• Enviar notificaciones relevantes sobre la actividad en la plataforma.\n',
              ),
              const TextSpan(
                text:
                    '• Generar autoevaluaciones personalizadas utilizando el tema que usted seleccione.\n',
              ),
              const TextSpan(
                text:
                    '• Analizar el uso de la plataforma para realizar mejoras funcionales y de experiencia de usuario.',
              ),
            ],
          ),
        ),
      ),
      _PrivacySectionData(
        title: '4. Derechos ARCO',
        icon: Icons.gavel_outlined,
        // --- CONTENIDO ACTUALIZADO ---
        content: RichText(
          text: TextSpan(
            style: bodyStyle,
            children: [
              const TextSpan(
                text:
                    'Usted puede ejercer sus derechos de Acceso, Rectificación, Cancelación y Oposición (ARCO) directamente en la plataforma, de acuerdo al modelo de autogestión del sistema:\n\n',
              ),
              TextSpan(text: '• Acceso y Rectificación: ', style: boldStyle),
              const TextSpan(
                text:
                    'Puede acceder y modificar sus datos personales en cualquier momento desde la sección de "Editar Perfil".\n',
              ),
              TextSpan(text: '• Cancelación: ', style: boldStyle),
              const TextSpan(
                text:
                    'Puede solicitar la eliminación permanente de su cuenta y todo su contenido directamente desde la opción "Eliminar Cuenta" en su perfil. Esta acción es irreversible.\n',
              ),
              TextSpan(text: '• Oposición: ', style: boldStyle),
              const TextSpan(
                text:
                    'Si desea oponerse al tratamiento de sus datos para alguna de las finalidades, la acción correspondiente es abstenerse de utilizar dicha funcionalidad o, en última instancia, proceder con la cancelación de su cuenta.',
              ),
            ],
          ),
        ),
      ),
      _PrivacySectionData(
        title: '5. Transferencia de Datos',
        icon: Icons.sync_alt_outlined,
        content: RichText(
          text: TextSpan(
            style: bodyStyle,
            children: [
              const TextSpan(
                text:
                    'Para proveer nuestros servicios, compartimos cierta información con proveedores tecnológicos:\n\n',
              ),
              TextSpan(text: '• Google Firebase: ', style: boldStyle),
              const TextSpan(
                text:
                    'Usado como infraestructura de backend para almacenar sus datos de cuenta y contenido de forma segura.\n',
              ),
              TextSpan(text: '• OpenAI y Make/Integromat: ', style: boldStyle),
              const TextSpan(
                text:
                    'Utilizados para la generación automática de preguntas en las autoevaluaciones. Únicamente se comparte el tema de estudio seleccionado, no sus datos personales.\n\n',
              ),
              const TextSpan(
                text:
                    'Sus datos no serán vendidos ni compartidos con terceros para fines de marketing o comerciales.',
              ),
            ],
          ),
        ),
      ),
    ];
  }

  // (El resto del código del widget no cambia)

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(GlobalKey key) {
    Scrollable.ensureVisible(
      key.currentContext!,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_sections.isEmpty) {
      _sections = _getPrivacySections(context);
    }
    final theme = Theme.of(context);
    final now = DateTime.now();
    final formattedDate = _formatPrivacyDate(now);

    return Scaffold(
      appBar: AppBar(title: const Text('Aviso de Privacidad')),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AVISO DE PRIVACIDAD',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fecha de última actualización: $formattedDate',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
            const Divider(height: 48, thickness: 1),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children:
                  _sections.map((section) {
                    return ActionChip(
                      avatar: Icon(section.icon, size: 18),
                      label: Text(section.title.substring(3)),
                      onPressed: () => _scrollToSection(section.key),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 24),
            ..._sections.map((section) => _buildSection(section)).toList(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(_PrivacySectionData data) {
    return Padding(
      key: data.key,
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(data.icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: data.content,
          ),
        ],
      ),
    );
  }
}
