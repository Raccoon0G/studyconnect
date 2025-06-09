import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CreditsPage extends StatelessWidget {
  const CreditsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créditos y Detalles del Proyecto'),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          const breakpoint = 850.0;
          if (constraints.maxWidth > breakpoint) {
            return _buildWideLayout(context);
          } else {
            return _buildNarrowLayout(context);
          }
        },
      ),
    );
  }

  // --- DISEÑO PARA PANTALLAS ANCHAS ---
  Widget _buildWideLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProjectInfoSection(context),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: _buildTeamSection(context)),
              const SizedBox(width: 24),
              Expanded(flex: 1, child: _buildDirectorsSection(context)),
            ],
          ),
          const SizedBox(height: 24),
          _buildSynodalsSection(context),
          const SizedBox(height: 24),
          _buildPhilosophySection(context),
          const SizedBox(height: 24),
          // Stack tecnológico separado
          _buildSectionTitle(context, 'Stack Tecnológico Principal'),
          _buildTechnologyTile(
            icon: Icons.code,
            iconColor: Colors.teal,
            title: 'Flutter Web & Dart',
            subtitle: 'Framework principal para el desarrollo de la interfaz.',
            onTap: () => _launchURL('https://flutter.dev'),
          ),
          _buildTechnologyTile(
            icon: Icons.local_fire_department_outlined,
            iconColor: Colors.orange,
            title: 'Firebase Suite',
            subtitle:
                'Backend: Auth, Firestore, Storage, Functions y Messaging.',
            onTap: () => _launchURL('https://firebase.google.com'),
          ),
          _buildTechnologyTile(
            icon: Icons.g_mobiledata_rounded,
            iconColor: Colors.black,
            title: 'Github',
            subtitle: 'Repositorio del proyecto y control de versiones.',
            onTap:
                () => _launchURL('https://github.com/Raccoon0G/studyconnect'),
          ),
          _buildTechnologyTile(
            icon: Icons.change_circle_outlined,
            iconColor: Colors.red,
            title: 'Git',
            subtitle: 'Control de versiones distribuido para el código fuente.',
            onTap: () => _launchURL('https://git-scm.com/'),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'APIs y Servicios Externos'),
          _buildTechnologyTile(
            icon: Icons.smart_toy_outlined,
            iconColor: Colors.green.shade600,
            title: 'OpenAI API',
            subtitle: 'Generación de preguntas para el banco de reactivos.',
            onTap: () => _launchURL('https://openai.com'),
          ),
          _buildTechnologyTile(
            icon: Icons.play_circle_outline,
            iconColor: Colors.red,
            title: 'YouTube API',
            subtitle: 'Obtención de metadatos y vistas previas de videos.',
            onTap: () => _launchURL('https://developers.google.com/youtube'),
          ),
          _buildTechnologyTile(
            icon: Icons.bolt_outlined,
            iconColor: Colors.purple,
            title: 'Make (Integromat)',
            subtitle: 'Automatización del workflow de generación de contenido.',
            onTap: () => _launchURL('https://www.make.com/en'),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Librerías Clave'),
          _buildTechnologyTile(
            icon: Icons.functions_outlined,
            iconColor: Colors.blueGrey,
            title: 'flutter_math_fork',
            subtitle: 'Renderizado de expresiones matemáticas en LaTeX.',
            onTap:
                () => _launchURL('https://pub.dev/packages/flutter_math_fork'),
          ),
          _buildTechnologyTile(
            icon: Icons.font_download_outlined,
            iconColor: Colors.indigo,
            title: 'Google Fonts',
            subtitle: 'Fuentes utilizadas para la paleta visual institucional.',
            onTap: () => _launchURL('https://fonts.google.com'),
          ),
        ],
      ),
    );
  }

  // --- DISEÑO PARA PANTALLAS ESTRECHAS ---
  Widget _buildNarrowLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProjectInfoSection(context),
          const SizedBox(height: 24),
          _buildTeamSection(context),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Agradecimientos Especiales'),
          _buildDirectorsSection(context, withTitle: false),
          const SizedBox(height: 16),
          _buildSynodalsSection(context, withTitle: false),
          const SizedBox(height: 24),
          _buildPhilosophySection(context),
          const SizedBox(height: 24),
          // Stack tecnológico separado
          _buildSectionTitle(context, 'Stack Tecnológico Principal'),
          _buildTechnologyTile(
            icon: Icons.code,
            iconColor: Colors.teal,
            title: 'Flutter Web & Dart',
            subtitle: 'Framework principal para el desarrollo de la interfaz.',
            onTap: () => _launchURL('https://flutter.dev'),
          ),
          _buildTechnologyTile(
            icon: Icons.local_fire_department_outlined,
            iconColor: Colors.orange,
            title: 'Firebase Suite',
            subtitle:
                'Backend: Auth, Firestore, Storage, Functions y Messaging.',
            onTap: () => _launchURL('https://firebase.google.com'),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'APIs y Servicios Externos'),
          _buildTechnologyTile(
            icon: Icons.smart_toy_outlined,
            iconColor: Colors.green.shade600,
            title: 'OpenAI API',
            subtitle: 'Generación de preguntas para el banco de reactivos.',
            onTap: () => _launchURL('https://openai.com'),
          ),
          _buildTechnologyTile(
            icon: Icons.play_circle_outline,
            iconColor: Colors.red,
            title: 'YouTube API',
            subtitle: 'Obtención de metadatos y vistas previas de videos.',
            onTap: () => _launchURL('https://developers.google.com/youtube'),
          ),
          _buildTechnologyTile(
            icon: Icons.bolt_outlined,
            iconColor: Colors.purple,
            title: 'Make (Integromat)',
            subtitle: 'Automatización del workflow de generación de contenido.',
            onTap: () => _launchURL('https://www.make.com/en'),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Librerías Clave'),
          _buildTechnologyTile(
            icon: Icons.functions_outlined,
            iconColor: Colors.blueGrey,
            title: 'flutter_math_fork',
            subtitle: 'Renderizado de expresiones matemáticas en LaTeX.',
            onTap:
                () => _launchURL('https://pub.dev/packages/flutter_math_fork'),
          ),
          _buildTechnologyTile(
            icon: Icons.font_download_outlined,
            iconColor: Colors.indigo,
            title: 'Google Fonts',
            subtitle: 'Fuentes utilizadas para la paleta visual institucional.',
            onTap: () => _launchURL('https://fonts.google.com'),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectorsSection(BuildContext context, {bool withTitle = true}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (withTitle) _buildSectionTitle(context, 'Directores de TT'),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!withTitle)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      'Directores de TT',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                _buildAcknowledgementPersonTile(
                  name: 'M. en C. Verónica Agustín Domínguez',
                  role:
                      'Por su invaluable guía, paciencia y sabiduría a lo largo de este viaje.',
                  icon: Icons.school_outlined,
                ),
                _buildAcknowledgementPersonTile(
                  name: 'Dr. Miguel Santiago Suárez Castañón',
                  role:
                      'Por su visión estratégica y por impulsar la calidad académica del proyecto.',
                  icon: Icons.school_outlined,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSynodalsSection(BuildContext context, {bool withTitle = true}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (withTitle)
          _buildSectionTitle(context, 'Sinodales'), // TÍTULO CAMBIADO
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!withTitle)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      'Sinodales',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ), // TÍTULO CAMBIADO
                  ),
                _buildAcknowledgementPersonTile(
                  name: 'M. en C. Elena Fabiola Ruíz Ledesma',
                  role:
                      'Por su amable disposición para guiarnos y por sus acertadas observaciones, que fueron de gran ayuda en momentos clave.',
                  icon: Icons.reviews_outlined,
                ),
                _buildAcknowledgementPersonTile(
                  name: 'Mtra. Karina Viveros Vela',
                  role:
                      'Por su gran amabilidad y por recibirnos siempre con una puerta abierta; su entusiasmo fue un gran impulso para nosotros.',
                  icon: Icons.reviews_outlined,
                ),
                _buildAcknowledgementPersonTile(
                  name: 'M. en C. Rubén Peredo Valderrama',
                  role:
                      'Un agradecimiento profundo por su infinita paciencia y por recibirnos siempre con la mejor disposición. Su visión para el futuro del proyecto y nuestra formación fue la brújula que guio nuestro trabajo.',
                  icon: Icons.military_tech_outlined,
                  iconColor: Colors.amber.shade800,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Equipo del Proyecto'),
        _buildCreditCard(
          context: context,
          title: 'Brayam Jeovanny Torres Martínez',
          subtitle: 'Arquitecto y Desarrollador Full-Stack',
          icon: Icons.person_outline,
          iconColor: Colors.blueAccent,
          imageUrl: 'assets/images/jeovanny.webp',
          onTap: () => _launchURL('https://github.com/Raccoon0G'),
        ),
        const SizedBox(height: 16),
        _buildCreditCard(
          context: context,
          title: 'Hegan David Sagastegui Vazquez',
          subtitle: 'Aseguramiento de Calidad y Pruebas (QA Tester)',
          icon: Icons.checklist_rtl_outlined,
          iconColor: Colors.teal,
          imageUrl: 'assets/images/hegan.webp',
          onTap: () => _launchURL('https://github.com/HeganS'),
        ),
      ],
    );
  }

  // --- WIDGETS AUXILIARES ---

  // TARJETA DE CRÉDITO MODIFICADA PARA ACEPTAR IMÁGENES
  Widget _buildCreditCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    Color iconColor = Colors.grey,
    String? imageUrl, // Parámetro opcional para la imagen
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                // Si hay una imagen, la usa. Si no, muestra el ícono.
                backgroundImage: imageUrl != null ? AssetImage(imageUrl) : null,
                backgroundColor: iconColor.withOpacity(0.1),
                child:
                    imageUrl == null
                        ? Icon(icon, size: 30, color: iconColor)
                        : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- El resto de widgets y funciones no necesitan cambios ---
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {}
  }

  Widget _buildProjectInfoSection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Información del Proyecto'),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trabajo Terminal 2025-A050',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '“Prototipo de sistema web para enseñanza con recursos digitales y compartición en Facebook: caso UA Cálculo”',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhilosophySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Filosofía de Desarrollo y Calidad'),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                _buildDetailTile(
                  icon: Icons.architecture,
                  color: Colors.amber.shade700,
                  title: 'Arquitectura MVC',
                  subtitle:
                      'Diseño basado en el patrón Modelo-Vista-Controlador y separación de responsabilidades.',
                ),
                _buildDetailTile(
                  icon: Icons.design_services_outlined,
                  color: Colors.lightBlue,
                  title: 'Enfoque en la Experiencia de Usuario (UX)',
                  subtitle:
                      'Animaciones suaves, diseño responsive y confirmaciones visuales con diálogos.',
                ),
                _buildDetailTile(
                  icon: Icons.speed_outlined,
                  color: Colors.green,
                  title: 'Optimización de Rendimiento',
                  subtitle:
                      'Uso de FutureBuilder y StreamBuilder para una carga eficiente en la web.',
                ),
                _buildDetailTile(
                  icon: Icons.checklist_rtl_outlined,
                  color: Colors.deepPurple,
                  title: 'Pruebas y Validación',
                  subtitle:
                      'Pruebas funcionales por módulo, validación de flujos y corrección de bugs visuales.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    /* ... */
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAcknowledgementPersonTile({
    required String name,
    required String role,
    required IconData icon,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.grey.shade600, size: 28),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(role, style: TextStyle(color: Colors.grey.shade700)),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 4.0,
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 28),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
    );
  }

  Widget _buildTechnologyTile({
    required IconData icon,
    Color iconColor = Colors.grey,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    /* ... */
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.transparent,
        child: Icon(icon, color: iconColor, size: 32),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 4.0,
        horizontal: 8.0,
      ),
    );
  }
}
