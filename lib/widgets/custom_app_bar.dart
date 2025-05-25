import 'package:flutter/material.dart';
import 'package:study_connect/widgets/notification_icon_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double height;
  final bool showBack;
  final String? title;
  final List<String> excludeRoutes;

  const CustomAppBar({
    super.key,
    this.height = 80,
    this.showBack = false,
    this.title,
    this.excludeRoutes = const [],
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (excludeRoutes.contains(currentRoute)) {
      return const SizedBox.shrink(); // no mostrar el AppBar
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;

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
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              if (showBack)
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              const Text(
                'Study Connect',
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    'assets/images/IPN-Logo.png',
                    width: 72,
                    height: 72,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ],
          ),

          actions:
              isMobile
                  ? [
                    const NotificationIconWidget(),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onSelected:
                          (value) => Navigator.pushNamed(context, '/$value'),
                      itemBuilder: (_) => _menuItems(context),
                    ),
                  ]
                  : [
                    _textButton(context, 'Inicio', '/'),
                    _textButton(context, 'Ranking', '/ranking'),
                    _textButton(context, 'Contenidos', '/content'),
                    if (FirebaseAuth.instance.currentUser != null)
                      const NotificationIconWidget(),
                    _perfilButton(context),
                    const SizedBox(width: 8),
                    if (!isMobile) ...[
                      const SizedBox(width: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.asset(
                          'assets/images/escudoESCOM.png',
                          width: 72,
                          height: 72,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],

                    const SizedBox(width: 12),
                  ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String label, String route) {
    return PopupMenuItem(
      value: route,
      child: Builder(
        builder: (context) {
          final currentRoute = ModalRoute.of(context)?.settings.name;
          if (currentRoute == '/$route' ||
              (route == '' && currentRoute == '/')) {
            return const SizedBox.shrink(); // No mostrar el ítem
          }
          return ListTile(
            leading: const Icon(Icons.arrow_right),
            title: Text(label),
          );
        },
      ),
    );
  }

  List<PopupMenuEntry<String>> _menuItems(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    final items = <Map<String, String>>[
      {'label': 'Inicio', 'route': ''},
      {'label': 'Ranking', 'route': 'ranking'},
      {'label': 'Contenidos', 'route': 'content'},
      {'label': 'Perfil', 'route': 'user_profile'},
    ];

    return items
        .where(
          (item) =>
              currentRoute != '/${item['route']}' &&
              !(item['route'] == '' && currentRoute == '/'),
        )
        .map(
          (item) => PopupMenuItem<String>(
            value: item['route']!,
            child: ListTile(
              leading: const Icon(Icons.arrow_right),
              title: Text(item['label']!),
            ),
          ),
        )
        .toList();
  }

  Widget _textButton(BuildContext context, String label, String route) {
    final currentRoute = ModalRoute.of(context)?.settings.name;

    if (currentRoute == route || (route == '/' && currentRoute == '/')) {
      return const SizedBox.shrink(); // Oculta el botón si ya estamos en la ruta
    }

    return TextButton(
      onPressed: () => Navigator.pushNamed(context, route),
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _perfilButton(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.pushNamed(context, '/user_profile'),
      style: TextButton.styleFrom(
        side: const BorderSide(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      child: const Row(
        children: [
          Text('Perfil', style: TextStyle(color: Colors.white)),
          SizedBox(width: 6),
          Icon(Icons.person_outline, color: Colors.white, size: 20),
        ],
      ),
    );
  }
}
