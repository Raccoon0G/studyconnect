import 'package:flutter/material.dart';
import 'package:study_connect/widgets/notification_icon_widget.dart'; // Asegúrate que este widget existe y la ruta es correcta
import 'package:firebase_auth/firebase_auth.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double height;
  final bool showBack;
  final Widget?
  titleContent; // MODIFICADO: Acepta un Widget para el contenido del título
  final List<String> excludeRoutes;

  const CustomAppBar({
    super.key,
    this.height =
        kToolbarHeight, // Usar kToolbarHeight como alto estándar para AppBar
    this.showBack = false,
    this.titleContent, // MODIFICADO
    this.excludeRoutes = const [],
  });

  void _handleProfileTap(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Inicio de sesión requerido'),
              content: const Text(
                'Para acceder a tu perfil necesitas iniciar sesión.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/login');
                  },
                  child: const Text('Iniciar sesión'),
                ),
              ],
            ),
      );
    } else {
      // Evitar push si ya estamos en user_profile para no apilar la misma pantalla
      if (ModalRoute.of(context)?.settings.name != '/user_profile') {
        Navigator.pushNamed(context, '/user_profile');
      }
    }
  }

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (excludeRoutes.contains(currentRoute)) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800; // Puedes ajustar este breakpoint

    // Título por defecto si titleContent es null
    Widget defaultTitle = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Study Connect',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20, // Ajustado para consistencia
            fontWeight: FontWeight.bold,
          ),
        ),
        if (!isMobile) ...[
          const SizedBox(width: 16),
          // Asegúrate que la imagen del logo existe en la ruta especificada
          // Si no, puedes comentarla o reemplazarla
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset(
              'assets/images/IPN-Logo.webp',
              width: 36, // Reducido para mejor proporción
              height: 36,
              fit: BoxFit.contain,
              errorBuilder:
                  (context, error, stackTrace) => const Icon(
                    Icons.school,
                    color: Colors.white70,
                    size: 30,
                  ), // Fallback
            ),
          ),
        ],
      ],
    );

    return PreferredSize(
      preferredSize: Size.fromHeight(height),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF045C9E), // Azul más vivo
              Color(0xFF001F3F), // Navy más oscuro
            ],
          ),
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          // El botón de atrás se maneja explícitamente por el leading
          automaticallyImplyLeading: false,
          leading:
              showBack && (ModalRoute.of(context)?.canPop ?? false)
                  ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    tooltip: 'Atrás',
                    onPressed: () => Navigator.pop(context),
                  )
                  : null,
          title:
              titleContent ??
              defaultTitle, // Usa titleContent o el defaultTitle
          centerTitle: isMobile, // Centrar título en móvil puede ser buena idea
          actions:
              isMobile
                  ? [
                    // Si NotificationIconWidget es null, no se mostrará error.
                    if (FirebaseAuth.instance.currentUser != null)
                      const NotificationIconWidget(),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      tooltip: 'Menú',
                      onSelected: (value) {
                        if (value == 'user_profile') {
                          _handleProfileTap(context);
                        } else if (value == '/') {
                          // Ruta raíz
                          if (ModalRoute.of(context)?.settings.name != '/') {
                            Navigator.pushNamed(context, '/');
                          }
                        } else {
                          if (ModalRoute.of(context)?.settings.name !=
                              '/$value') {
                            Navigator.pushNamed(context, '/$value');
                          }
                        }
                      },
                      itemBuilder: (_) => _menuItems(context),
                    ),
                  ]
                  : [
                    _textButton(context, 'Inicio', '/'),
                    _textButton(context, 'Ranking', '/ranking'),
                    _textButton(
                      context,
                      'Contenidos',
                      '/content',
                    ), // Asumiendo que esta ruta existe
                    if (FirebaseAuth.instance.currentUser != null)
                      const NotificationIconWidget(),
                    _perfilButton(context),
                    const SizedBox(width: 8),
                    // Asegúrate que la imagen del logo existe en la ruta especificada
                    // Si no, puedes comentarla o reemplazarla
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.asset(
                        'assets/images/escudoESCOM.webp',
                        width: 36, // Reducido
                        height: 36,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (context, error, stackTrace) => const Icon(
                              Icons.business,
                              color: Colors.white70,
                              size: 30,
                            ), // Fallback
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _menuItems(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    // Definición de las rutas y sus etiquetas
    // Asegúrate que 'user_profile' y otras rutas sean manejadas correctamente o existan.
    final items = <Map<String, String>>[
      {'label': 'Inicio', 'route': '/'}, // Usar '/' para la ruta raíz
      {'label': 'Ranking', 'route': '/ranking'},
      {'label': 'Contenidos', 'route': '/content'},
      {'label': 'Perfil', 'route': '/user_profile'},
    ];

    // Filtrar el ítem de la ruta actual
    return items
        .where((item) => currentRoute != item['route'])
        .map(
          (item) => PopupMenuItem<String>(
            value: item['route']!, // El valor será la ruta completa
            child: Text(item['label']!),
          ),
        )
        .toList();
  }

  Widget _textButton(BuildContext context, String label, String route) {
    final currentRoute = ModalRoute.of(context)?.settings.name;

    // No mostrar el botón si ya estamos en esa ruta
    if (currentRoute == route) {
      return const SizedBox.shrink();
    }

    return TextButton(
      onPressed: () {
        // Evitar push si ya estamos en la ruta (doble chequeo)
        if (ModalRoute.of(context)?.settings.name != route) {
          Navigator.pushNamed(context, route);
        }
      },
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }

  Widget _perfilButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: TextButton.icon(
        onPressed: () => _handleProfileTap(context),
        icon: const Icon(Icons.person_outline, color: Colors.white, size: 22),
        label: const Text(
          'Perfil',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          // Opcional: añadir un borde sutil o fondo al pasar el mouse (si es web)
          // side: BorderSide(color: Colors.white.withOpacity(0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
