import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
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
    final data = <String, dynamic>{
      'id': notifRef.id,
      'tipo': tipo,
      'titulo': titulo,
      'contenido': contenido,
      'leido': false,
      'archivada': false,
      'fecha': Timestamp.now(),
      'referenciaId': referenciaId,
      'uidEmisor': uidEmisor,
      'nombreEmisor': nombreEmisor,
    };
    if ((tipo == 'comentario' || tipo == 'calificacion') && tema != null) {
      data['tema'] = tema;
    }
    await notifRef.set(data);
  }

  static Future<void> marcarComoLeida(String uid, String notifId) async {
    await FirebaseFirestore.instance
        .collection('notificaciones')
        .doc(uid)
        .collection('items')
        .doc(notifId)
        .update({'leido': true});
  }

  static Future<void> marcarTodasComoLeidas(String uid) async {
    print("--- PRUEBA DE DIAGNÓSTICO: BUSCANDO SOLO POR 'leido' ---");
    try {
      final query =
          await FirebaseFirestore.instance
              .collection('notificaciones')
              .doc(uid)
              .collection('items')
              .where('leido', isEqualTo: false)
              // .where('archivada', isEqualTo: false) // <-- HEMOS COMENTADO ESTA LÍNEA TEMPORALMENTE
              .get();

      // ESTA LÍNEA NOS DIRÁ LA VERDAD:
      print(
        "Prueba de diagnóstico encontró ${query.docs.length} notificaciones.",
      );

      if (query.docs.isEmpty) {
        print(
          "La consulta simple tampoco devolvió resultados. Esto es muy extraño.",
        );
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in query.docs) {
        batch.update(doc.reference, {'leido': true});
      }
      await batch.commit();
      print("--- PRUEBA COMPLETADA EXITOSAMENTE ---");
    } catch (e) {
      print("¡ERROR en la prueba de diagnóstico'!: $e");
    }
  }

  static Future<void> archivarNotificacion(
    String uid,
    String notifId,
    bool archivar,
  ) async {
    await FirebaseFirestore.instance
        .collection('notificaciones')
        .doc(uid)
        .collection('items')
        .doc(notifId)
        .update({'archivada': archivar, 'leido': true});
  }

  static Future<void> eliminarNotificacion(String uid, String notifId) async {
    await FirebaseFirestore.instance
        .collection('notificaciones')
        .doc(uid)
        .collection('items')
        .doc(notifId)
        .delete();
  }

  /// NUEVO: Elimina todas las notificaciones que ya fueron leídas pero no están archivadas.
  static Future<void> eliminarTodasLeidas(String uid) async {
    print("--- INTENTANDO ELIMINAR TODAS LAS LEÍDAS ---");
    try {
      final query =
          await FirebaseFirestore.instance
              .collection('notificaciones')
              .doc(uid)
              .collection('items')
              .where('leido', isEqualTo: true)
              //.where('archivada', isEqualTo: false)
              .get();

      // ESTA LÍNEA ES LA MÁS IMPORTANTE:
      print(
        "Consulta para 'Limpiar Todo' encontró ${query.docs.length} notificaciones.",
      );

      if (query.docs.isEmpty) {
        print(
          "La consulta no devolvió resultados. Causa probable: Índice incorrecto o no hay datos que coincidan.",
        );
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      print("--- BATCH 'ELIMINAR TODAS' COMPLETADO EXITOSAMENTE ---");
    } catch (e) {
      print("¡ERROR en 'eliminarTodasLeidas'!: $e");
    }
  }

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
                  'archivada': data['archivada'] ?? false,
                  'tipo': data['tipo'] ?? '',
                  'fecha': data['fecha'],
                  'referenciaId': data['referenciaId'] ?? '',
                  'tema': data['tema'],
                  'uidEmisor': data['uidEmisor'],
                  'nombreEmisor': data['nombreEmisor'],
                };
              }).toList(),
        );
  }
}
