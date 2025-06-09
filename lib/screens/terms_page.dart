import 'package:flutter/material.dart';

// Modelo para estructurar los datos del contenido
class _TermSectionData {
  final String title;
  final IconData icon;
  final Widget content; // Usamos Widget para permitir RichText y listas
  final GlobalKey key = GlobalKey();

  _TermSectionData({
    required this.title,
    required this.icon,
    required this.content,
  });
}

class TermsPage extends StatefulWidget {
  const TermsPage({super.key});

  @override
  State<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> {
  final ScrollController _scrollController = ScrollController();
  List<_TermSectionData> _sections = [];

  String _formatDate(DateTime fecha) {
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
    return '${fecha.day} de ${meses[fecha.month - 1]} de ${fecha.year}';
  }

  List<_TermSectionData> _getTermSections(BuildContext context) {
    final bodyStyle = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(height: 1.5);
    final boldStyle = bodyStyle?.copyWith(fontWeight: FontWeight.bold);

    Widget buildPointList(List<String> points) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            points.map((point) => _buildListItem(point, context)).toList(),
      );
    }

    return [
      _TermSectionData(
        title: '1. Aceptación de los Términos',
        icon: Icons.check_box_outlined,
        content: RichText(
          text: TextSpan(
            style: bodyStyle,
            children: [
              const TextSpan(
                text:
                    'Estos Términos y Condiciones ("Términos") rigen el uso de la plataforma ',
              ),
              TextSpan(text: '“Study Connect”', style: boldStyle),
              const TextSpan(
                text:
                    ' (la "Plataforma"). Al registrarse o utilizar la Plataforma, usted acepta cumplir con estos Términos en su totalidad. Si no está de acuerdo, debe abstenerse de usarla.',
              ),
            ],
          ),
        ),
      ),
      _TermSectionData(
        title: '2. Objeto de la Plataforma',
        icon: Icons.school_outlined,
        content: buildPointList([
          'La Plataforma es un prototipo de sistema web diseñado como una herramienta académica complementaria y de reforzamiento para la Unidad de Aprendizaje de Cálculo en la ESCOM-IPN. ',
          'Su enfoque principal es el trabajo colaborativo ("coworking"), donde los propios usuarios (alumnos, tutores y profesores) aportan, corrigen y enriquecen el contenido. ',
          'La Plataforma no pretende de ninguna manera sustituir la labor del docente titular de la materia. ',
        ]),
      ),
      _TermSectionData(
        title: '3. Cuenta de Usuario',
        icon: Icons.person_add_alt_1_outlined,
        content: buildPointList([
          'Para el registro, es necesario proporcionar un correo electrónico único y válido, así como una contraseña que cumpla con los formatos de seguridad establecidos. ',
          'Usted es el único responsable de mantener la confidencialidad de su contraseña y de todas las actividades que ocurran en su cuenta.',
          'El registro requiere una verificación por correo electrónico que debe completarse en un plazo de 24 horas, de lo contrario, la solicitud de registro será eliminada. ',
        ]),
      ),
      _TermSectionData(
        title: '4. Contenido y Conducta del Usuario',
        icon: Icons.lightbulb_outline,
        content: buildPointList([
          'Usted es el único responsable del contenido que publica, incluyendo ejercicios, comentarios y materiales.',
          'Se compromete a utilizar la Plataforma únicamente con fines académicos y a no publicar material ofensivo, difamatorio, comercial o que infrinja derechos de autor. ',
          'La comunidad, mediante un sistema de calificaciones y comentarios, es la principal encargada de validar la calidad y corrección del contenido. Los usuarios pueden crear nuevas versiones de los ejercicios para corregirlos o mejorarlos. ',
        ]),
      ),
      _TermSectionData(
        title: '5. Propiedad Intelectual',
        icon: Icons.copyright,
        content: buildPointList([
          'El código fuente, diseño, logotipos y la marca "Study Connect" son propiedad intelectual de sus desarrolladores y del Instituto Politécnico Nacional. No pueden ser copiados o modificados sin autorización explícita. ',
          'Usted retiene los derechos sobre el contenido que genera. Sin embargo, al publicarlo, otorga a la Plataforma una licencia para mostrar, adaptar y distribuir dicho contenido dentro del ecosistema de "Study Connect" con fines educativos.',
        ]),
      ),
      // --- NUEVAS SECCIONES AÑADIDAS ---
      _TermSectionData(
        title: '6. Sistema de Ranking y Recompensas',
        icon: Icons.emoji_events_outlined,
        content: buildPointList([
          'La Plataforma incluye un sistema de recompensas y ranking para incentivar la participación y reconocer a los colaboradores más activos. ',
          'La posición en el ranking se basa en la calidad y cantidad de las contribuciones, según las calificaciones otorgadas por la comunidad. ',
          'Las recompensas y reconocimientos son de carácter simbólico y solo tienen validez dentro de la Plataforma, sin ningún valor monetario o académico oficial.',
        ]),
      ),
      _TermSectionData(
        title: '7. Comunicación y Chat',
        icon: Icons.chat_bubble_outline,
        content: buildPointList([
          'La Plataforma incluye un sistema de chat para facilitar la comunicación y colaboración entre los usuarios. ',
          'Está prohibido el uso del chat para fines de acoso, envío de spam, o cualquier actividad ilícita.',
          'Todas las interacciones deben mantenerse en un tono respetuoso y enfocado en la colaboración académica.',
        ]),
      ),
      _TermSectionData(
        title: '8. Compartición en Redes Sociales',
        icon: Icons.share_outlined,
        content: buildPointList([
          'La Plataforma permite compartir contenido educativo en redes sociales como Facebook para mejorar su visibilidad y difusión. ',
          'Al utilizar esta función, usted está sujeto a los Términos y Condiciones y a las Políticas de Privacidad de la red social correspondiente (Facebook).',
          'Study Connect no se hace responsable del tratamiento de los datos o las interacciones que ocurran fuera de la propia Plataforma.',
        ]),
      ),
      _TermSectionData(
        title: '9. Limitación de Responsabilidad',
        icon: Icons.warning_amber_rounded,
        content: buildPointList([
          'La Plataforma se ofrece "tal cual" y como un "prototipo funcional".  No se garantiza una disponibilidad ininterrumpida del sistema ni la corrección absoluta de todo el contenido generado por los usuarios. ',
          'El equipo desarrollador y la institución no se hacen responsables de las decisiones académicas que los usuarios tomen basándose en el contenido de la Plataforma.',
        ]),
      ),
      _TermSectionData(
        title: '10. Terminación de la Cuenta',
        icon: Icons.no_accounts_outlined,
        content: buildPointList([
          'Usted puede eliminar su cuenta de forma permanente en cualquier momento desde su perfil. ',
          'Nos reservamos el derecho de suspender o eliminar cualquier cuenta que incumpla grave o reiteradamente estos Términos y Condiciones.',
        ]),
      ),
      _TermSectionData(
        title: '11. Ley Aplicable y Contacto',
        icon: Icons.gavel_rounded,
        content: RichText(
          text: TextSpan(
            style: bodyStyle,
            children: [
              const TextSpan(
                text:
                    'Estos Términos se regirán e interpretarán de acuerdo con las leyes de México. Cualquier disputa será resuelta en los tribunales competentes de la Ciudad de México.\n\nPara información adicional sobre este proyecto, puede contactar a la: ',
              ),
              TextSpan(
                text:
                    'Subdirección Académica de la Escuela Superior de Cómputo del Instituto Politécnico Nacional, Av. Juan de Dios Bátiz s/n, Teléfono: 57296000 extensión 52000.',
                style: boldStyle,
              ),
              const TextSpan(text: ' '),
            ],
          ),
        ),
      ),
    ];
  }

  // (El resto del código del widget no necesita cambios)
  @override
  void initState() {
    super.initState();
  }

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
      _sections = _getTermSections(context);
    }

    final theme = Theme.of(context);
    final now = DateTime.now();
    final formattedDate = _formatDate(now);

    return Scaffold(
      appBar: AppBar(title: const Text('Términos y Condiciones')),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TÉRMINOS Y CONDICIONES',
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

  Widget _buildSection(_TermSectionData data) {
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

  Widget _buildListItem(String text, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6.0, right: 12.0, left: 8.0),
            child: Icon(Icons.circle, size: 8, color: Colors.grey.shade600),
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
