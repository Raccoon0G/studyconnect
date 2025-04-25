import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';

class NotificationIconWidget extends StatefulWidget {
  const NotificationIconWidget({super.key});

  @override
  State<NotificationIconWidget> createState() => _NotificationIconWidgetState();
}

class _NotificationIconWidgetState extends State<NotificationIconWidget> {
  OverlayEntry? _overlayEntry;
  List<String> _ocultadas = [];
  bool _verArchivadas = false;

  void _mostrarPopup(
    BuildContext context,
    List<Map<String, dynamic>> notificaciones,
  ) {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;

    _overlayEntry = OverlayEntry(
      builder:
          (context) => GestureDetector(
            onTap: _cerrarPopup,
            behavior: HitTestBehavior.translucent,
            child: Stack(
              children: [
                Positioned(
                  top: offset.dy + 40,
                  right: 20,
                  child: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    child: Container(
                      width: 420,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      constraints: const BoxConstraints(maxHeight: 340),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  final uid =
                                      FirebaseAuth.instance.currentUser?.uid;
                                  if (uid != null) {
                                    await NotificationService.marcarTodasComoLeidas(
                                      uid,
                                    );
                                    setState(() {
                                      _ocultadas =
                                          notificaciones
                                              .map((n) => n['id'] as String)
                                              .toList();
                                    });
                                    _cerrarPopup();
                                  }
                                },
                                child: const Text('Marcar todo como leído'),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _ocultadas =
                                        notificaciones
                                            .map((n) => n['id'] as String)
                                            .toList();
                                  });
                                  _cerrarPopup();
                                },
                                child: const Text('Ocultar todo'),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _verArchivadas = !_verArchivadas;
                                  });
                                },
                                child: Text(
                                  _verArchivadas
                                      ? 'Ver nuevas'
                                      : 'Ver archivadas',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          Builder(
                            builder: (context) {
                              final visibles =
                                  notificaciones
                                      .where((notif) {
                                        final esOculta = _ocultadas.contains(
                                          notif['id'],
                                        );
                                        final esLeida = notif['leido'] == true;
                                        return _verArchivadas
                                            ? (esLeida && esOculta)
                                            : (!esLeida && !esOculta);
                                      })
                                      .take(8)
                                      .toList();

                              if (visibles.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('No tienes notificaciones'),
                                );
                              }

                              return Expanded(
                                child: ListView(
                                  children:
                                      visibles.map((notif) {
                                        final timestamp =
                                            (notif['fecha'] as Timestamp)
                                                .toDate();
                                        final hora = DateFormat(
                                          'HH:mm',
                                        ).format(timestamp);
                                        final uid =
                                            FirebaseAuth
                                                .instance
                                                .currentUser
                                                ?.uid;
                                        final notifId = notif['id']?.toString();

                                        final contenido =
                                            '${notif['contenido']} · $hora';

                                        return ListTile(
                                          leading: Icon(
                                            _iconoParaTipo(notif['tipo']),
                                          ),
                                          title: Text(
                                            notif['titulo'] ?? '',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),

                                          subtitle: Text(
                                            contenido,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (notif['leido'] == false)
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.check_circle_outline,
                                                  ),
                                                  onPressed: () async {
                                                    if (uid != null &&
                                                        notifId != null) {
                                                      final docRef =
                                                          FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                'notificaciones',
                                                              )
                                                              .doc(uid)
                                                              .collection(
                                                                'items',
                                                              )
                                                              .doc(notifId);
                                                      await docRef.update({
                                                        'leido': true,
                                                      });
                                                      setState(() {
                                                        // Esto forza a que se vuelva a renderizar sin necesidad de cerrar
                                                      });
                                                    }
                                                  },
                                                ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.archive_outlined,
                                                ),
                                                onPressed: () async {
                                                  if (uid != null &&
                                                      notifId != null) {
                                                    final docRef =
                                                        FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                              'notificaciones',
                                                            )
                                                            .doc(uid)
                                                            .collection('items')
                                                            .doc(notifId);
                                                    await docRef.update({
                                                      'leido': true,
                                                    });
                                                    setState(() {
                                                      _ocultadas.add(notifId);
                                                    });
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                          onTap: () {},
                                        );
                                      }).toList(),
                                ),
                              );
                            },
                          ),
                        ],
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

  IconData _iconoParaTipo(String tipo) {
    switch (tipo) {
      case 'mensaje':
        return Icons.message;
      case 'comentario':
        return Icons.comment;
      case 'calificacion':
        return Icons.star;
      case 'ranking':
        return Icons.emoji_events;
      default:
        return Icons.notifications;
    }
  }

  void _cerrarPopup() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: NotificationService.obtenerNotificaciones(user.uid),
      builder: (context, snapshot) {
        final notificaciones = snapshot.data ?? [];
        final noLeidas =
            notificaciones
                .where(
                  (n) => n['leido'] == false && !_ocultadas.contains(n['id']),
                )
                .length;

        return GestureDetector(
          onTap: () {
            if (_overlayEntry != null) {
              _cerrarPopup();
            } else {
              _mostrarPopup(context, notificaciones);
            }
          },
          child: Stack(
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.notifications, color: Colors.white),
              ),
              if (noLeidas > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$noLeidas',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
