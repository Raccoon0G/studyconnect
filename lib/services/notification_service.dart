import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  // Crea notificacion para el usuario
  static Future<void> crearNotificacion({
    required String uidDestino,
    required String tipo,
    required String titulo,
    required String contenido,
    required String referenciaId,
    String? tema,
    String? uidEmisor,
    String? nombreEmisor,
  }) async {
    final notifRef =
        FirebaseFirestore.instance
            .collection('notificaciones')
            .doc(uidDestino)
            .collection('items')
            .doc();

    final data = {
      'id': notifRef.id,
      'tipo': tipo,
      'titulo': titulo,
      'contenido': contenido,
      'leido': false,
      'fecha': Timestamp.now(),
      'referenciaId': referenciaId,
      'uidEmisor': uidEmisor,
      'nombreEmisor': nombreEmisor,
    };

    // Solo agrega el campo 'tema' si el tipo lo requiere y tema no es nulo
    if ((tipo == 'comentario' || tipo == 'calificacion') && tema != null) {
      data['tema'] = tema;
    }

    await notifRef.set(data);
  }

  /// Cuenta el total de notificaciones no leídas para un usuario.
  static Future<int> contarNoLeidas(String uid) async {
    final snap =
        await FirebaseFirestore.instance
            .collection('notificaciones')
            .doc(uid)
            .collection('items')
            .where('leido', isEqualTo: false)
            .get();
    return snap.docs.length;
  }

  /// Marca todas las notificaciones como leídas para un usuario.
  static Future<void> marcarTodasComoLeidas(String uid) async {
    final batch = FirebaseFirestore.instance.batch();
    final query =
        await FirebaseFirestore.instance
            .collection('notificaciones')
            .doc(uid)
            .collection('items')
            .where('leido', isEqualTo: false)
            .get();

    for (final doc in query.docs) {
      batch.update(doc.reference, {'leido': true});
    }
    await batch.commit();
  }

  /// Stream en tiempo real de notificaciones para mostrar en una lista.
  static Stream<List<Map<String, dynamic>>> obtenerNotificaciones(String uid) {
    return FirebaseFirestore.instance
        .collection('notificaciones')
        .doc(uid)
        .collection('items')
        .orderBy('fecha', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data();
                return {
                  'id': doc.id,
                  'titulo': data['titulo'] ?? '',
                  'contenido': data['contenido'] ?? '',
                  'leido': data['leido'] ?? false,
                  'tipo': data['tipo'] ?? '',
                  'fecha': data['fecha'],
                  'referenciaId': data['referenciaId'] ?? '',
                  'tema': data['tema'], // nuevo
                  'uidEmisor': data['uidEmisor'], // nuevo
                  'nombreEmisor': data['nombreEmisor'], // nuevo
                };
              }).toList(),
        );
  }
}
