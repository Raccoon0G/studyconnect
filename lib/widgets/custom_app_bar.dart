import 'package:flutter/material.dart';
import 'package:study_connect/widgets/widgets.dart'; // Asegúrate que este widget existe y la ruta es correcta
import 'package:firebase_auth/firebase_auth.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double height;
  final bool showBack;
  final String? titleText;
  final Widget? titleWidget;
  final List<String> excludeRoutes;
  final bool showMainTitleOnly; // NUEVO: Para simplificar el AppBar
  final bool
  centerTitleOverride; // NUEVO: Para forzar el centrado si es necesario

  const CustomAppBar({
    super.key,
    this.height = 56,
    this.showBack = false,
    this.titleText,
    this.titleWidget,
    this.excludeRoutes = const [],
    this.showMainTitleOnly = false, // Por defecto, mostrar todo
    this.centerTitleOverride = false,
  }) : assert(
         titleText == null || titleWidget == null,
         'Cannot provide both titleText and titleWidget. Use one or the other.',
       );

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
    final bool isMobile = screenWidth < 800;

    // --- Determinar el contenido del título ---
    Widget? effectiveTitleContent;

    if (showMainTitleOnly) {
      // Si solo queremos el título principal
      effectiveTitleContent = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Study Connect', // Título fijo en este modo
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold, // Añadido para destacar
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 16),
            Image.asset(
              'assets/images/IPN-Logo.webp',
              width: 72, // Tu tamaño original
              height: 72,
              fit: BoxFit.contain,
              errorBuilder:
                  (context, error, stackTrace) => const Icon(
                    Icons.school,
                    color: Colors.white70,
                    size: 40,
                  ), // Icono más grande como fallback
            ),
          ],
        ],
      );
    } else if (titleWidget != null) {
      effectiveTitleContent = titleWidget;
    } else if (titleText != null) {
      effectiveTitleContent = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            titleText!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22, // Consistente con tu estilo original
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 16),
            Image.asset(
              'assets/images/IPN-Logo.webp',
              width: 72,
              height: 72,
              fit: BoxFit.contain,
              errorBuilder:
                  (context, error, stackTrace) =>
                      const Icon(Icons.school, color: Colors.white70, size: 40),
            ),
          ],
        ],
      );
    } else {
      // Título por defecto si ninguno se provee y showMainTitleOnly es false
      effectiveTitleContent = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Study Connect',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 16),
            Image.asset(
              'assets/images/IPN-Logo.webp',
              width: 72,
              height: 72,
              fit: BoxFit.contain,
              errorBuilder:
                  (context, error, stackTrace) =>
                      const Icon(Icons.school, color: Colors.white70, size: 40),
            ),
          ],
        ],
      );
    }

    // --- Determinar las acciones ---
    List<Widget> actions = [];
    if (!showMainTitleOnly) {
      // Solo mostrar acciones si no estamos en modo "solo título principal"
      if (isMobile) {
        actions = [
          if (FirebaseAuth.instance.currentUser != null)
            const NotificationIconWidget(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Colors.white),
            tooltip: 'Menú',
            onSelected: (value) {
              if (value == '/user_profile') {
                _handleProfileTap(context);
              } else {
                if (ModalRoute.of(context)?.settings.name != value) {
                  Navigator.pushNamed(context, value);
                }
              }
            },
            itemBuilder: (_) => _menuItems(context),
          ),
        ];
      } else {
        actions = [
          _textButton(context, 'Inicio', '/'),
          _textButton(context, 'Ranking', '/ranking'),
          _textButton(context, 'Contenidos', '/content'),
          if (FirebaseAuth.instance.currentUser != null)
            const NotificationIconWidget(),
          _perfilButton(context),
          const SizedBox(width: 8),
          Image.asset(
            'assets/images/escudoESCOM.webp',
            width: 72,
            height: 72,
            fit: BoxFit.contain,
            errorBuilder:
                (context, error, stackTrace) =>
                    const Icon(Icons.business, color: Colors.white70, size: 40),
          ),
          const SizedBox(width: 12),
        ];
      }
    }

    return PreferredSize(
      preferredSize: Size.fromHeight(height),
      child: Container(
        // RESTAURADO EL GRADIENTE ORIGINAL
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF045C9E), Color(0xFF001F3F)],
          ),
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading:
              showBack && (ModalRoute.of(context)?.canPop ?? false)
                  ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    tooltip: 'Atrás',
                    onPressed: () => Navigator.pop(context),
                  )
                  : null,
          title: effectiveTitleContent,
          // Centrar título si es móvil Y no es el modo "solo título principal" O si centerTitleOverride es true
          centerTitle: (isMobile && !showMainTitleOnly) || centerTitleOverride,
          actions: actions, // Usar la lista de acciones determinada
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _menuItems(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    final items = <Map<String, String>>[
      {'label': 'Inicio', 'route': '/'},
      {'label': 'Ranking', 'route': '/ranking'},
      {'label': 'Contenidos', 'route': '/content'},
      {'label': 'Perfil', 'route': '/user_profile'},
    ];

    return items
        .where((item) => currentRoute != item['route'])
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
    if (currentRoute == route) {
      return const SizedBox.shrink();
    }
    return TextButton(
      onPressed: () {
        if (ModalRoute.of(context)?.settings.name != route) {
          Navigator.pushNamed(context, route);
        }
      },
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
    );
  }

  Widget _perfilButton(BuildContext context) {
    return TextButton(
      onPressed: () => _handleProfileTap(context),
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
