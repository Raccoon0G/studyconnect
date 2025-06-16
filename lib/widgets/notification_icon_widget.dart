// widgets/notification_icon_widget.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import '../services/notification_service.dart';
import '../services/services.dart';
import '../services/navigation_service.dart';

// La función de formato de fecha no cambia
String formatFechaPersonalizada(DateTime fecha) {
  const List<String> mesesAbreviados = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  final dia = fecha.day;
  final mes = mesesAbreviados[fecha.month - 1];
  final anio = fecha.year;
  final esAm = fecha.hour < 12;
  final ampm = esAm ? 'AM' : 'PM';
  int hora12 = fecha.hour % 12;
  if (hora12 == 0) {
    hora12 = 12;
  }
  final minuto = fecha.minute.toString().padLeft(2, '0');
  return '$dia de $mes. de $anio $hora12:$minuto $ampm';
}

// El widget principal no necesita cambios
class NotificationIconWidget extends StatefulWidget {
  const NotificationIconWidget({super.key});
  @override
  State<NotificationIconWidget> createState() => _NotificationIconWidgetState();
}

class _NotificationIconWidgetState extends State<NotificationIconWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _previousUnreadCount = 0;

  void _playNotificationSound() async {
    await _audioPlayer.play(AssetSource('audio/notification.mp3'));
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200);
    }
  }

  OverlayEntry? _overlayEntry;
  final GlobalKey _notificationIconKey = GlobalKey();

  @override
  void dispose() {
    _audioPlayer.dispose();
    _cerrarPopup();
    super.dispose();
  }

  void _cerrarPopup() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showNotifications(
    BuildContext context,
    List<Map<String, dynamic>> notifications,
  ) {
    if (_overlayEntry != null) {
      _cerrarPopup();
      return;
    }
    const double mobileBreakpoint = 768.0;
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < mobileBreakpoint) {
      _showPanelForMobile(context, notifications);
    } else {
      _showPopupForDesktop(context, notifications);
    }
  }

  void _showPanelForMobile(
    BuildContext context,
    List<Map<String, dynamic>> notifications,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            builder:
                (_, controller) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: _NotificationsContent(
                    notifications: notifications,
                    scrollController: controller,
                    onClose: () => Navigator.of(context).pop(),
                  ),
                ),
          ),
    );
  }

  void _showPopupForDesktop(
    BuildContext context,
    List<Map<String, dynamic>> notifications,
  ) {
    final overlay = Overlay.of(context);
    final renderBox =
        _notificationIconKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    _overlayEntry = OverlayEntry(
      builder:
          (context) => GestureDetector(
            onTap: _cerrarPopup,
            behavior: HitTestBehavior.translucent,
            child: Stack(
              children: [
                Positioned(
                  top: offset.dy + renderBox.size.height + 10,
                  right: 20,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 420,
                        maxHeight: 550,
                      ),
                      child: _NotificationsContent(
                        notifications: notifications,
                        onClose: _cerrarPopup,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
    overlay.insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    // 1. PRIMER STREAMBUILDER: Para obtener la configuración del usuario en tiempo real.
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .snapshots(),
      builder: (context, userConfigSnapshot) {
        // 2. EXTRAER EL VALOR BOOLEANO:
        // Por defecto, las notificaciones están activadas si no se encuentra el valor.
        bool notificacionesActivas = true;

        if (userConfigSnapshot.hasData && userConfigSnapshot.data!.exists) {
          final userData =
              userConfigSnapshot.data!.data() as Map<String, dynamic>?;

          // Accedemos de forma segura a Config -> Notificaciones.
          if (userData != null && userData.containsKey('Config')) {
            notificacionesActivas =
                userData['Config']['Notificaciones'] ?? true;
          }
        }

        // 3. SEGUNDO STREAMBUILDER: Para obtener las notificaciones.
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: NotificationService.obtenerNotificaciones(user.uid),
          builder: (context, notificationsSnapshot) {
            final notificaciones = notificationsSnapshot.data ?? [];
            final noLeidas =
                notificaciones
                    .where(
                      (n) => n['leido'] == false && n['archivada'] == false,
                    )
                    .length;

            // 4. LÓGICA CONDICIONAL: Comprueba si hay nuevas notificaciones Y si están activadas.
            if (notificationsSnapshot.hasData &&
                noLeidas > _previousUnreadCount &&
                notificacionesActivas) {
              _playNotificationSound();
            }

            _previousUnreadCount = noLeidas;

            // El resto de la UI no cambia
            return GestureDetector(
              key: _notificationIconKey,
              onTap: () => _showNotifications(context, notificaciones),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.notifications,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  if (noLeidas > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Center(
                          child: Text(
                            '$noLeidas',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// El resto del código no necesita modificaciones
enum _NotifView { nuevas, leidas, archivadas }

class _NotificationsContent extends StatefulWidget {
  final List<Map<String, dynamic>> notifications;
  final ScrollController? scrollController;
  final VoidCallback onClose;
  const _NotificationsContent({
    required this.notifications,
    required this.onClose,
    this.scrollController,
  });
  @override
  __NotificationsContentState createState() => __NotificationsContentState();
}

class __NotificationsContentState extends State<_NotificationsContent> {
  _NotifView _currentView = _NotifView.nuevas;
  late List<Map<String, dynamic>> _localNotifications;
  @override
  void initState() {
    super.initState();
    _localNotifications = List.from(widget.notifications);
  }

  @override
  void didUpdateWidget(covariant _NotificationsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.notifications != oldWidget.notifications) {
      setState(() {
        _localNotifications = List.from(widget.notifications);
      });
    }
  }

  void _handleAction({
    required String uid,
    String? notifId,
    required String action,
  }) {
    setState(() {
      switch (action) {
        case 'marcarLeida':
          final index = _localNotifications.indexWhere(
            (n) => n['id'] == notifId,
          );
          if (index != -1) _localNotifications[index]['leido'] = true;
          break;
        case 'archivar':
          final index = _localNotifications.indexWhere(
            (n) => n['id'] == notifId,
          );
          if (index != -1) {
            _localNotifications[index]['archivada'] = true;
            _localNotifications[index]['leido'] = true;
          }
          break;
        case 'desarchivar':
          final index = _localNotifications.indexWhere(
            (n) => n['id'] == notifId,
          );
          if (index != -1) _localNotifications[index]['archivada'] = false;
          break;
        case 'eliminar':
          _localNotifications.removeWhere((n) => n['id'] == notifId);
          break;
        case 'marcarTodasLeidas':
          for (var notif in _localNotifications) {
            if (notif['leido'] == false && notif['archivada'] == false) {
              notif['leido'] = true;
            }
          }
          break;
        case 'eliminarTodasLeidas':
          _localNotifications.removeWhere(
            (n) => n['leido'] == true && n['archivada'] == false,
          );
          break;
      }
    });
    switch (action) {
      case 'marcarLeida':
        NotificationService.marcarComoLeida(uid, notifId!);
        break;
      case 'archivar':
        NotificationService.archivarNotificacion(uid, notifId!, true);
        break;
      case 'desarchivar':
        NotificationService.archivarNotificacion(uid, notifId!, false);
        break;
      case 'eliminar':
        NotificationService.eliminarNotificacion(uid, notifId!);
        break;
      case 'marcarTodasLeidas':
        NotificationService.marcarTodasComoLeidas(uid);
        break;
      case 'eliminarTodasLeidas':
        NotificationService.eliminarTodasLeidas(uid);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final nuevas =
        _localNotifications
            .where((n) => n['leido'] == false && n['archivada'] == false)
            .toList();
    final leidas =
        _localNotifications
            .where((n) => n['leido'] == true && n['archivada'] == false)
            .toList();
    final archivadas =
        _localNotifications.where((n) => n['archivada'] == true).toList();
    List<Map<String, dynamic>> visibleNotifications;
    String title;
    switch (_currentView) {
      case _NotifView.nuevas:
        visibleNotifications = nuevas;
        title = 'Notificaciones';
        break;
      case _NotifView.leidas:
        visibleNotifications = leidas;
        title = 'Leídas';
        break;
      case _NotifView.archivadas:
        visibleNotifications = archivadas;
        title = 'Archivadas';
        break;
    }
    final isMobile = MediaQuery.of(context).size.width < 768.0;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _currentView == _NotifView.archivadas
                      ? Icons.notifications
                      : Icons.archive_outlined,
                  color: Colors.black54,
                ),
                tooltip:
                    _currentView == _NotifView.archivadas
                        ? 'Ver nuevas'
                        : 'Ver archivadas',
                onPressed:
                    () => setState(
                      () =>
                          _currentView =
                              _currentView == _NotifView.archivadas
                                  ? _NotifView.nuevas
                                  : _NotifView.archivadas,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.black54),
                tooltip: 'Cerrar',
                onPressed: widget.onClose,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              ToggleButtons(
                isSelected: [
                  _currentView == _NotifView.nuevas,
                  _currentView == _NotifView.leidas,
                  _currentView == _NotifView.archivadas,
                ],
                onPressed: (index) {
                  setState(() {
                    _currentView = _NotifView.values[index];
                  });
                },
                borderRadius: BorderRadius.circular(8),
                constraints: const BoxConstraints(minHeight: 32, minWidth: 80),
                children: const [
                  Text('Nuevas'),
                  Text('Leídas'),
                  Text('Archivadas'),
                ],
              ),
              const Spacer(),
              if (_currentView == _NotifView.nuevas &&
                  nuevas.isNotEmpty &&
                  uid != null)
                TextButton(
                  onPressed:
                      () =>
                          _handleAction(uid: uid, action: 'marcarTodasLeidas'),
                  child: const Text('Marcar todo'),
                ),
              if (_currentView == _NotifView.leidas &&
                  leidas.isNotEmpty &&
                  uid != null)
                TextButton(
                  onPressed:
                      () => _handleAction(
                        uid: uid,
                        action: 'eliminarTodasLeidas',
                      ),
                  child: const Text(
                    'Limpiar todo',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child:
              visibleNotifications.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay notificaciones en esta sección',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    controller: widget.scrollController,
                    padding: EdgeInsets.zero,
                    itemCount: visibleNotifications.length,
                    itemBuilder: (context, index) {
                      return _NotificationTile(
                        notification: visibleNotifications[index],
                        isMobile: isMobile,
                        currentView: _currentView,
                        onAction:
                            (action) => _handleAction(
                              uid: uid!,
                              notifId: visibleNotifications[index]['id'],
                              action: action,
                            ),
                        onClosePanel: widget.onClose,
                      );
                    },
                  ),
        ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final bool isMobile;
  final _NotifView currentView;
  final Function(String action) onAction;
  final VoidCallback onClosePanel;

  const _NotificationTile({
    required this.notification,
    required this.isMobile,
    required this.currentView,
    required this.onAction,
    required this.onClosePanel,
  });

  IconData _getIconForType(String tipo) {
    // Puedes personalizar esto según los tipos de notificaciones que tengas
    switch (tipo) {
      case 'nuevo_mensaje':
        return Icons.message;
      case 'nuevo_seguidor':
        return Icons.person_add;
      case 'anuncio':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }

  Widget _buildTrailingButtons(BuildContext context) {
    switch (currentView) {
      case _NotifView.nuevas:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.archive_outlined, color: Colors.blueGrey),
              tooltip: 'Archivar',
              onPressed: () => onAction('archivar'),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
              tooltip: 'Marcar como leído',
              onPressed: () => onAction('marcarLeida'),
            ),
          ],
        );
      case _NotifView.leidas:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.archive_outlined, color: Colors.blueGrey),
              tooltip: 'Archivar',
              onPressed: () => onAction('archivar'),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Eliminar',
              onPressed: () => onAction('eliminar'),
            ),
          ],
        );
      case _NotifView.archivadas:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.unarchive_outlined,
                color: Colors.blueGrey,
              ),
              tooltip: 'Desarchivar',
              onPressed: () => onAction('desarchivar'),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_forever_outlined,
                color: Colors.redAccent,
              ),
              tooltip: 'Eliminar permanentemente',
              onPressed: () => onAction('eliminar'),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isUnread = currentView == _NotifView.nuevas;

    final tile = ListTile(
      leading: CircleAvatar(
        backgroundColor:
            isUnread ? Colors.blue.withOpacity(0.1) : Colors.grey.shade200,
        child: Icon(
          _getIconForType(notification['tipo'] ?? ''),
          color: isUnread ? Colors.blue.shade700 : Colors.grey.shade600,
        ),
      ),
      title: Text(
        notification['titulo'] ?? '',
        style: TextStyle(
          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        '${notification['contenido'] ?? ''}\n${formatFechaPersonalizada((notification['fecha'] as Timestamp).toDate())}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey.shade600),
      ),
      trailing: _buildTrailingButtons(context),
    );

    return Material(
      color: isUnread ? Colors.blue.withOpacity(0.08) : Colors.transparent,
      child: InkWell(
        onTap: () {
          // 1. Cierra el panel
          onClosePanel();
          // 2. Si es nueva, la marca como leída
          if (isUnread) {
            onAction('marcarLeida');
          }
          // 3. Navega al contenido
          NavigationService.navigateToNotificationContent(
            context,
            notification,
          );
        },
        child: tile,
      ),
    );
  }
}
