import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  // Crea notificacion para el usuario
  static Future<void> crearNotificacion({
    required String uidDestino,
    required String tipo, // ej. 'mensaje', 'mensaje_grupo', 'agregado_grupo'
    required String titulo,
    required String contenido,
    required String referenciaId, // Este es el chatId
    String? tema,
    String? uidEmisor,
    String? nombreEmisor,
  }) async {
    // --- INICIO DE MODIFICACIÓN PARA CHATS SILENCIADOS ---
    // Solo aplicamos la lógica de silencio para notificaciones de tipo 'mensaje' o 'mensaje_grupo'
    // y si referenciaId (chatId) está presente.
    // También podrías incluir 'agregado_grupo' si no quieres notificar si el chat donde te agregaron está silenciado,
    // pero usualmente las notificaciones de "te agregaron a un grupo" se quieren recibir siempre.
    if ((tipo == 'mensaje' || tipo == 'mensaje_grupo') &&
        referenciaId.isNotEmpty) {
      try {
        final DocumentSnapshot chatDoc =
            await FirebaseFirestore.instance
                .collection('Chats')
                .doc(referenciaId) // referenciaId es el chatId
                .get();

        if (chatDoc.exists) {
          final Map<String, dynamic> chatData =
              chatDoc.data() as Map<String, dynamic>;
          // Manejo seguro del campo 'silenciadoPor', asumiendo que puede no existir o ser null.
          final List<dynamic> silenciadoPorDinamico =
              chatData['silenciadoPor'] as List<dynamic>? ?? [];
          final List<String> silenciadoPorLista =
              silenciadoPorDinamico.map((item) => item.toString()).toList();

          if (silenciadoPorLista.contains(uidDestino)) {
            // El usuario destino ha silenciado este chat, así que no creamos la notificación.
            print(
              'Notificación NO creada para $uidDestino del chat $referenciaId porque está silenciado.',
            );
            return; // Salimos de la función temprano
          }
        }
      } catch (e) {
        // Si hay un error al leer el chat (ej. no existe, problema de permisos),
        // podríamos optar por enviar la notificación de todas formas o registrar el error.
        // Por ahora, imprimimos el error y continuamos para crear la notificación.
        print(
          'Error al verificar estado de silencio para chat $referenciaId: $e. Se procederá a notificar.',
        );
      }
    }
    // --- FIN DE MODIFICACIÓN ---

    // Si llegamos aquí, o no es un tipo de mensaje que se pueda silenciar,
    // o el chat no está silenciado por el destinatario, o hubo un error al verificar.

    final notifRef =
        FirebaseFirestore.instance
            .collection('notificaciones')
            .doc(uidDestino)
            .collection('items')
            .doc(); // Firestore genera un ID automáticamente

    final data = <String, dynamic>{
      // Especificar el tipo del mapa es buena práctica
      'id': notifRef.id, // Guardamos el ID autogenerado
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
    print('Notificación creada para $uidDestino (referencia: $referenciaId).');
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
                  'fecha': data['fecha'], // Timestamp, se formateará en la UI
                  'referenciaId': data['referenciaId'] ?? '',
                  'tema': data['tema'],
                  'uidEmisor': data['uidEmisor'],
                  'nombreEmisor': data['nombreEmisor'],
                };
              }).toList(),
        );
  }
}
