import 'dart:typed_data';
import 'dart:html' as html;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:study_connect/services/services.dart';
import 'package:study_connect/widgets/widgets.dart';

class ChatHomePage extends StatefulWidget {
  const ChatHomePage({super.key});

  @override
  State<ChatHomePage> createState() => _ChatHomePageState();
}

class _ChatHomePageState extends State<ChatHomePage> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  String? chatIdSeleccionado;
  String? otroUid;
  String mensaje = '';
  final TextEditingController _mensajeController = TextEditingController();
  final TextEditingController _busquedaController = TextEditingController();
  List<DocumentSnapshot> _usuarios = [];
  Map<String, Map<String, String>> cacheUsuarios = {};

  String? nombreUsuario;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey listViewKey = GlobalKey();
  final ValueNotifier<String?> hoveredChatId = ValueNotifier<String?>(null);
  final TextEditingController _groupNameController = TextEditingController();
  String filtro = '';
  String? hoveredUserId;
  List<String> _selectedForGroup = [];
  Uint8List? _imagenGrupo;
  bool _showList = true;
  bool _isTyping = false;
  bool _isSearchingGlobalUsers = false;

  @override
  void initState() {
    super.initState();

    _cargarUsuarios();
    _obtenerNombreUsuario();
  }

  Future<void> _obtenerNombreUsuario() async {
    final doc =
        await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();

    final nombreEmisor = doc['Nombre'] ?? 'Usuario';
    final fotoEmisor = doc['FotoPerfil'] ?? ''; // si guardas foto

    // Agregamos el usuario al cache
    cacheUsuarios[uid] = {'nombre': nombreEmisor, 'foto': fotoEmisor};

    setState(() {
      nombreUsuario = nombreEmisor;
    });
  }

  Future<void> _cargarUsuarios() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('usuarios').get();
    setState(() {
      _usuarios = snapshot.docs.where((doc) => doc.id != uid).toList();
      // Aquí llenas el cacheUsuarios con todos para que no haya nulls nunca
      for (final doc in snapshot.docs) {
        cacheUsuarios[doc.id] = {
          'nombre': (doc['Nombre'] ?? 'Usuario') as String,
          'foto': (doc['FotoPerfil'] ?? '') as String,
        };
      }
    });
  }

  String _formatearHora(Timestamp timestamp) {
    final dt = timestamp.toDate();
    return DateFormat.Hm().format(dt);
  }

  Future<void> _obtenerUsuario(String usuarioId) async {
    if (cacheUsuarios.containsKey(usuarioId)) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(usuarioId)
            .get();
    final nombre = doc['Nombre'] ?? 'Usuario';
    final foto = doc['FotoPerfil'] ?? '';
    // aquí reemplazamos la simple asignación por un setState:
    setState(() {
      cacheUsuarios[usuarioId] = {'nombre': nombre, 'foto': foto};
    });
  }

  // void _iniciarChat(String otroId) async {
  //   // 1) Creamos el chatId ordenado
  //   final nuevoChatId =
  //       uid.compareTo(otroId) < 0 ? '${uid}_$otroId' : '${otroId}_$uid';
  //   // 2) Precargamos datos del otro usuario en caché
  //   await _obtenerUsuario(otroId);

  //   // ── creamos/mergeamos el documento Chats/{chatId}
  //   await FirebaseFirestore.instance.collection('Chats').doc(nuevoChatId).set({
  //     'ids': [uid, otroId],
  //     'UltimaAct': FieldValue.serverTimestamp(),
  //     'typing': {uid: false, otroId: false},
  //   }, SetOptions(merge: true));

  //   // 3) Disparamos el cambio de chat
  //   setState(() {
  //     filtro = ''; // reset del filtro
  //     _busquedaController.clear(); // limpiamos la caja de texto
  //     _showList = false;
  //     chatIdSeleccionado = nuevoChatId;
  //     otroUid = otroId;
  //   });
  // }

  // void _enviarMensaje() async {
  //   if (chatIdSeleccionado == null || mensaje.trim().isEmpty) return;

  //   // 1) Creamos un timestamp único para usarlo en mensaje y chat
  //   final now = Timestamp.now();

  //   // 2) Añadimos el mensaje con esa fecha
  //   await FirebaseFirestore.instance
  //       .collection('Chats')
  //       .doc(chatIdSeleccionado)
  //       .collection('Mensajes')
  //       .add({
  //         'AutorID': uid,
  //         'Contenido': mensaje.trim(),
  //         'Fecha': now, // <-- usamos now aquí
  //         'reacciones': {},
  //         'editado': false,
  //         'eliminado': false,
  //         'leidoPor': [uid],
  //       });

  //   // 3) Actualizamos el documento de chat con lastMessageAt
  //   await FirebaseFirestore.instance
  //       .collection('Chats')
  //       .doc(chatIdSeleccionado)
  //       .update({
  //         'typing.$uid': false,
  //         'lastMessageAt': now,
  //         'lastMessage': mensaje.trim(),
  //       });

  //   // Crear notificación para el receptor
  //   if (otroUid != null && otroUid != uid) {
  //     await NotificationService.crearNotificacion(
  //       uidDestino: otroUid!,
  //       tipo: 'mensaje',
  //       titulo: 'Nuevo mensaje de $nombreUsuario',
  //       contenido:
  //           mensaje.trim().length > 40
  //               ? '${mensaje.trim().substring(0, 40)}...'
  //               : mensaje.trim(),
  //       referenciaId: chatIdSeleccionado!,
  //       uidEmisor: uid,
  //       nombreEmisor: nombreUsuario ?? 'Usuario',
  //     );
  //   }

  //   _mensajeController.clear();
  //   setState(() => mensaje = '');

  //   // ── AUTO‐SCROLL TRAS ENVÍO ──
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     if (_scrollController.hasClients) {
  //       _scrollController.animateTo(
  //         0.0,
  //         duration: const Duration(milliseconds: 300),
  //         curve: Curves.easeOut,
  //       );
  //     }
  //   });
  // }

  // Reemplaza tu función _iniciarChat actual con esta versión:
  void _iniciarChat(String otroId) async {
    // 1) Creamos el chatId ordenado para chats 1 a 1.
    final nuevoChatId =
        uid.compareTo(otroId) < 0 ? '${uid}_$otroId' : '${otroId}_$uid';

    // 2) Precargamos datos del otro usuario en caché si es necesario.
    await _obtenerUsuario(otroId);

    // 3) Referencia al documento y obtenemos el snapshot para ver si existe.
    final DocumentReference chatDocRef = FirebaseFirestore.instance
        .collection('Chats')
        .doc(nuevoChatId);
    final DocumentSnapshot chatDocSnapshot = await chatDocRef.get();

    if (!chatDocSnapshot.exists) {
      // El chat NO EXISTE: lo creamos con todos los campos iniciales,
      // incluyendo unreadCounts para ambos usuarios a 0.
      await chatDocRef.set(
        {
          'ids': [uid, otroId],
          'isGroup': false,
          'groupName': null,
          'groupPhoto': null,
          'createdBy': null,
          'lastActivityAt': FieldValue.serverTimestamp(),
          'lastMessage': '', // Sin mensaje inicial
          'typing': {uid: false, otroId: false},
          'unreadCounts': {
            // Para un chat NUEVO, ambos empiezan con 0.
            uid: 0,
            otroId: 0,
          },
        },
      ); // No se necesita SetOptions(merge: true) si estamos seguros que no existe.
    } else {
      // El chat YA EXISTE.
      // El onTap en _chatListStream ya se encargó de hacer update({'unreadCounts.$uid': 0}).
      // Aquí solo actualizamos campos que podrían cambiar al "reabrir" un chat, como la última actividad.
      // NO incluimos 'unreadCounts' aquí para no sobrescribir el contador del otroId.
      await chatDocRef.set({
        // Aseguramos que estos campos estén presentes o se "toquen"
        'ids': [
          uid,
          otroId,
        ], // Redundante si ya existe, pero no daña con merge.
        'isGroup': false, // Redundante si ya existe.
        'lastActivityAt': FieldValue.serverTimestamp(),
        // No tocamos lastMessage, lastMessageAt, typing, ni unreadCounts aquí.
      }, SetOptions(merge: true));
    }

    // 4) Actualizamos el estado de la UI para mostrar el chat seleccionado.
    setState(() {
      filtro = '';
      _busquedaController.clear();
      _showList = false;
      chatIdSeleccionado = nuevoChatId;
      otroUid = otroId;
    });
  }

  void _enviarMensaje() async {
    // 0. Verificaciones iniciales
    if (chatIdSeleccionado == null || mensaje.trim().isEmpty) return;

    final now = Timestamp.now();
    final String mensajeActual = mensaje.trim();

    _mensajeController.clear();
    setState(() {
      mensaje = '';
    });

    // 1. Añadir el nuevo mensaje
    final DocumentReference mensajeDocRef = await FirebaseFirestore.instance
        .collection('Chats')
        .doc(chatIdSeleccionado)
        .collection('Mensajes')
        .add({
          'AutorID': uid,
          'Contenido': mensajeActual,
          'Fecha': now,
          'reacciones': {},
          'editado': false,
          'eliminado': false,
          'leidoPor': [uid],
        });

    // 2. Actualizar el documento principal del Chat
    final DocumentReference chatDocRef = FirebaseFirestore.instance
        .collection('Chats')
        .doc(chatIdSeleccionado!);
    final DocumentSnapshot chatSnapshot = await chatDocRef.get();

    Map<String, dynamic> chatUpdateData = {
      'typing.$uid': false,
      'lastMessageAt': now,
      'lastMessage': mensajeActual,
    };

    // Variables para la lógica de notificaciones
    List<String> uidsDestinatariosNotificacion = [];
    bool esNotificacionDeGrupo = false;
    String nombreGrupoParaNotificacion = '';

    if (chatSnapshot.exists) {
      final Map<String, dynamic> chatData =
          chatSnapshot.data() as Map<String, dynamic>;
      final List<String> memberIds = List<String>.from(chatData['ids'] ?? []);
      Map<String, dynamic> currentUnreadCounts = Map<String, dynamic>.from(
        chatData['unreadCounts'] ?? {},
      );

      for (String memberId in memberIds) {
        if (memberId != uid) {
          currentUnreadCounts[memberId] =
              (currentUnreadCounts[memberId] as int? ?? 0) + 1;
          // Añadir a destinatarios para notificación
          if (!uidsDestinatariosNotificacion.contains(memberId)) {
            uidsDestinatariosNotificacion.add(memberId);
          }
        }
      }
      chatUpdateData['unreadCounts'] = currentUnreadCounts;

      // Determinar si es grupo para la notificación
      esNotificacionDeGrupo = (chatData['isGroup'] as bool?) ?? false;
      if (esNotificacionDeGrupo) {
        nombreGrupoParaNotificacion = chatData['groupName'] ?? 'el grupo';
      }
    } else {
      // El documento del chat NO existe. Esto es menos común si _iniciarChat o la creación de grupos funciona bien.
      // Creamos una estructura básica.
      print(
        "Advertencia: El documento del chat '$chatIdSeleccionado' no existía. Se creará con datos básicos.",
      );
      if (otroUid != null && otroUid != uid) {
        // Asumimos que es un chat 1 a 1 porque otroUid está presente
        chatUpdateData['ids'] = [uid, otroUid!];
        chatUpdateData['isGroup'] = false;
        chatUpdateData['unreadCounts'] = {
          otroUid!: 1,
        }; // El otro usuario tiene 1 mensaje no leído
        if (!uidsDestinatariosNotificacion.contains(otroUid!)) {
          uidsDestinatariosNotificacion.add(otroUid!);
        }
        esNotificacionDeGrupo = false;
      } else {
        // No hay otroUid, podría ser un intento de enviar a un grupo que no existe.
        // No podemos saber los miembros, así que unreadCounts para otros no se puede establecer aquí.
        // 'ids' tampoco se puede determinar aquí de forma fiable para un grupo.
        // El creador del grupo (o _iniciarChat) es responsable de la estructura inicial.
        chatUpdateData['isGroup'] =
            true; // Asumimos que la intención era un grupo
        // No se pueden agregar destinatarios específicos para notificación sin la lista de miembros.
        // Se podría enviar una notificación genérica si tuvieras un topic de FCM para "nuevos grupos" o similar.
      }
    }

    // Usamos .set con merge:true para crear el documento si no existe, o actualizarlo si existe.
    await chatDocRef.set(chatUpdateData, SetOptions(merge: true));

    // 3. Crear notificaciones
    if (nombreUsuario != null && uidsDestinatariosNotificacion.isNotEmpty) {
      for (String destinatarioId in uidsDestinatariosNotificacion) {
        String tituloNotificacion;
        if (esNotificacionDeGrupo) {
          tituloNotificacion = '$nombreUsuario @ $nombreGrupoParaNotificacion';
        } else {
          tituloNotificacion = 'Nuevo mensaje de $nombreUsuario';
        }

        await NotificationService.crearNotificacion(
          uidDestino: destinatarioId,
          tipo: esNotificacionDeGrupo ? 'mensaje_grupo' : 'mensaje',
          titulo: tituloNotificacion,
          contenido:
              mensajeActual.length > 40
                  ? '${mensajeActual.substring(0, 40)}...'
                  : mensajeActual,
          referenciaId: chatIdSeleccionado!,
          uidEmisor: uid,
          nombreEmisor:
              nombreUsuario!, // nombreUsuario no debería ser null aquí
        );
      }
    } else if (nombreUsuario == null) {
      print(
        "Advertencia: nombreUsuario es null, no se pueden enviar notificaciones personalizadas.",
      );
    }

    // 4. Auto-scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _editarMensaje(String mensajeId, String contenido, Timestamp fecha) {
    final diferencia = DateTime.now().difference(fecha.toDate());
    if (diferencia.inMinutes > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya no puedes editar este mensaje.')),
      );
      return;
    }
    final controller = TextEditingController(text: contenido);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Editar mensaje'),
            content: TextField(controller: controller),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final nuevo = controller.text.trim();
                  if (nuevo.isNotEmpty) {
                    await FirebaseFirestore.instance
                        .collection('Chats')
                        .doc(chatIdSeleccionado)
                        .collection('Mensajes')
                        .doc(mensajeId)
                        .update({'Contenido': nuevo, 'editado': true});
                  }
                  Navigator.pop(context);
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  void _eliminarMensaje(String mensajeId) async {
    await FirebaseFirestore.instance
        .collection('Chats')
        .doc(chatIdSeleccionado)
        .collection('Mensajes')
        .doc(mensajeId)
        .update({'eliminado': true});
  }

  void _reaccionarMensaje(String mensajeId) {
    final emojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
    showModalBottomSheet(
      context: context,
      builder:
          (_) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:
                emojis
                    .map(
                      (e) => IconButton(
                        icon: Text(e, style: const TextStyle(fontSize: 24)),
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection('Chats')
                              .doc(chatIdSeleccionado)
                              .collection('Mensajes')
                              .doc(mensajeId)
                              .update({
                                'reacciones.$e': FieldValue.increment(1),
                              });
                          Navigator.pop(context);
                        },
                      ),
                    )
                    .toList(),
          ),
    );
  }

  Future<String> subirImagenGrupo(Uint8List imagenBytes, String chatId) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('grupos')
        .child('$chatId.jpg');

    await ref.putData(imagenBytes);
    return await ref.getDownloadURL();
  }

  // En _ChatHomePageState
  // Reemplaza el contenido de _ejecutarSalirDelGrupo con esto:
  Future<void> _ejecutarSalirDelGrupo(String groupId) async {
    final DocumentReference chatDocRef = FirebaseFirestore.instance
        .collection('Chats')
        .doc(groupId);

    print(
      'Intentando salir del grupo: $groupId con UID: $uid',
    ); // Log para confirmar IDs

    try {
      // Crear un WriteBatch
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // 1. Quitar el UID del usuario de la lista 'ids'
      batch.update(chatDocRef, {
        'ids': FieldValue.arrayRemove([uid]),
      });

      // 2. Quitar las entradas del usuario de 'unreadCounts' y 'typing'
      batch.update(chatDocRef, {
        'unreadCounts.$uid': FieldValue.delete(),
        'typing.$uid': FieldValue.delete(),
      });

      // Ejecutar todas las operaciones del batch
      await batch.commit();
      print('Batch commit exitoso para salir del grupo.');

      // Volver a la lista de chats y deseleccionar el chat actual
      if (mounted) {
        setState(() {
          _showList = true;
          chatIdSeleccionado = null;
          otroUid = null;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Has salido del grupo.')));
      }
    } catch (e, s) {
      // Usamos el mismo bloque catch detallado de antes
      print('--- ERROR CAPTURADO AL SALIR DEL GRUPO (CON WRITEBATCH) ---');
      print('1. Tipo de Excepción (e.runtimeType): ${e.runtimeType}');
      print('2. Error (e.toString()): ${e.toString()}');
      print('3. Stack Trace (s.toString()):\n$s');

      dynamic nestedError;
      String nestedErrorMessage = '';
      String nestedErrorCode = '';
      String nestedErrorStackTrace = '';

      if (e.toString().contains(
        "Use the properties 'error' to fetch the boxed error",
      )) {
        try {
          nestedError = (e as dynamic).error;
          if (nestedError != null) {
            print('4. Error "Boxeado" (e.error): ${nestedError.toString()}');
            print(
              '5. Tipo de Error "Boxeado" (e.error.runtimeType): ${nestedError.runtimeType}',
            );
            if (nestedError is FirebaseException) {
              print(
                '6. "Boxeado" es FirebaseException - Código: ${nestedError.code}',
              );
              print(
                '7. "Boxeado" es FirebaseException - Mensaje: ${nestedError.message}',
              );
              nestedErrorCode = nestedError.code;
              nestedErrorMessage =
                  nestedError.message ?? 'Mensaje de Firebase no disponible.';
            }
            try {
              nestedErrorStackTrace =
                  (nestedError as dynamic).stackTrace?.toString() ??
                  'No hay stack trace para el error anidado.';
              print(
                '8. StackTrace del Error "Boxeado":\n$nestedErrorStackTrace',
              );
            } catch (_) {
              print('8. No se pudo acceder al stackTrace del error anidado.');
            }
          } else {
            print('4. La propiedad "e.error" es null.');
          }
        } catch (accessError) {
          print(
            '4. Fallo al intentar acceder a "e.error": ${accessError.toString()}',
          );
        }
      }

      String mensajeParaUsuario = 'Error al salir del grupo. Intenta de nuevo.';
      if (nestedError is FirebaseException) {
        mensajeParaUsuario =
            'Error: ${nestedErrorMessage.isNotEmpty ? nestedErrorMessage : nestedErrorCode}';
      } else if (e is FirebaseException) {
        mensajeParaUsuario = 'Error: ${e.message ?? e.code}';
      } else if (nestedErrorMessage.isNotEmpty) {
        mensajeParaUsuario = 'Error: $nestedErrorMessage';
      } else {
        // Si sigue siendo genérico, al menos mostramos el e.toString()
        mensajeParaUsuario = 'Error: ${e.toString()}';
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mensajeParaUsuario)));
      }
      print('--- FIN DEL REPORTE DE ERROR (CON WRITEBATCH) ---');
    }
  }

  // Añade esta nueva función a tu _ChatHomePageState
  void _confirmarSalirDelGrupo(String groupId, String groupName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Salir del Grupo'),
          content: Text('¿Seguro que quieres salir del grupo "$groupName"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(); // Cierra el diálogo de confirmación
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Salir'),
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(); // Cierra el diálogo de confirmación
                _ejecutarSalirDelGrupo(groupId); // Procede a salir
              },
            ),
          ],
        );
      },
    );
  }

  // Añade esta nueva función a tu _ChatHomePageState
  Future<void> _ejecutarAgregarParticipantes(
    String groupId,
    List<String> idsNuevosMiembros,
  ) async {
    if (idsNuevosMiembros.isEmpty) return;

    final DocumentReference chatDocRef = FirebaseFirestore.instance
        .collection('Chats')
        .doc(groupId);

    // Preparamos los datos para los nuevos miembros en unreadCounts y typing
    Map<String, dynamic> updatesParaNuevosMiembros = {};
    for (String nuevoMiembroId in idsNuevosMiembros) {
      updatesParaNuevosMiembros['unreadCounts.$nuevoMiembroId'] =
          0; // Inicializar contador de no leídos
      updatesParaNuevosMiembros['typing.$nuevoMiembroId'] =
          false; // Inicializar estado de typing
    }

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // 1. Añadir los nuevos UIDs a la lista 'ids'
      batch.update(chatDocRef, {
        'ids': FieldValue.arrayUnion(idsNuevosMiembros),
      });

      // 2. Inicializar unreadCounts y typing para los nuevos miembros
      if (updatesParaNuevosMiembros.isNotEmpty) {
        batch.update(chatDocRef, updatesParaNuevosMiembros);
      }

      await batch.commit();

      // 3. Notificar a los usuarios añadidos y opcionalmente enviar mensaje al sistema
      String nombresNuevosMiembrosStr = '';
      List<String> nombresParaMensaje = [];

      for (int i = 0; i < idsNuevosMiembros.length; i++) {
        final nuevoMiembroId = idsNuevosMiembros[i];
        // Asegurarse de que la info del nuevo miembro esté en caché o cargarla para la notificación/mensaje
        if (!cacheUsuarios.containsKey(nuevoMiembroId) && mounted) {
          await _obtenerUsuario(
            nuevoMiembroId,
          ); // Esperar a que se cargue para el nombre
        }
        final nombreNuevoMiembro =
            cacheUsuarios[nuevoMiembroId]?['nombre'] ?? 'Alguien';
        nombresParaMensaje.add(nombreNuevoMiembro);

        if (mounted) {
          // Comprobar mounted antes de usar context o nombreUsuario
          await NotificationService.crearNotificacion(
            uidDestino: nuevoMiembroId,
            tipo: 'agregado_grupo', // Nuevo tipo de notificación
            titulo: 'Te han añadido a un grupo',
            contenido:
                '$nombreUsuario te ha agregado al grupo.', // Aquí necesitamos el nombre del grupo
            referenciaId: groupId,
            uidEmisor: uid,
            nombreEmisor: nombreUsuario ?? 'Alguien',
          );
        }
      }

      nombresNuevosMiembrosStr = nombresParaMensaje.join(', ');

      // Opcional: Añadir mensaje al sistema (más avanzado)
      final mensajeSistema =
          '$nombreUsuario ha añadido a $nombresNuevosMiembrosStr al grupo.';
      await FirebaseFirestore.instance
          .collection('Chats')
          .doc(groupId)
          .collection('Mensajes')
          .add({
            'AutorID': 'sistema',
            'Contenido': mensajeSistema,
            'Fecha': Timestamp.now(),
            'Tipo': 'sistema',
          });
      // Y actualizar lastMessage/lastMessageAt del chat si añades mensaje al sistema

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$nombresNuevosMiembrosStr ha(n) sido añadido(s) al grupo.',
            ),
          ),
        );
        // No necesitas llamar a setState aquí si la lista de miembros en el diálogo se actualiza
        // cuando el diálogo se reconstruye o si el StreamBuilder de _buildChatHeader lo hace.
        // Si el diálogo de miembros (`_mostrarDialogoMiembrosGrupo`) sigue abierto, no se actualizará
        // automáticamente sin un mecanismo de refresh. Podrías cerrarlo y que el usuario lo vuelva a abrir,
        // o pasar un callback para refrescar su estado si fuera un StatefulWidget.
      }
    } catch (e, s) {
      print('Error al añadir participantes: ${e.toString()}');
      print('Stack Trace: ${s.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al añadir participantes: ${e.toString()}'),
          ),
        );
      }
    }
  }

  void _mostrarDialogoSeleccionarNuevosMiembros(
    String groupId,
    List<String> idsMiembrosActuales,
  ) {
    final TextEditingController searchController = TextEditingController();
    // Usamos un ValueNotifier para el filtro DENTRO de este diálogo para que
    // el StatefulBuilder pueda reconstruir solo la lista de usuarios.
    final ValueNotifier<String> filtroDialogo = ValueNotifier<String>('');
    List<String> idsSeleccionadosParaAnadir =
        []; // IDs de usuarios seleccionados en este diálogo

    showDialog(
      context: context,
      builder: (BuildContext contextDialog) {
        return StatefulBuilder(
          // StatefulBuilder para manejar el estado del diálogo (selecciones, filtro)
          builder: (BuildContext contextSFB, StateSetter setStateDialog) {
            return AlertDialog(
              title: const Text('Añadir Participantes'),
              content: SizedBox(
                width: 350,
                height: 400, // Similar al diálogo de crear grupo
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'Buscar usuarios para añadir...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (text) {
                        // Actualizamos el ValueNotifier, lo que causará que el StreamBuilder se reconstruya
                        filtroDialogo.value = text.trim().toLowerCase();
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      // Usamos un ValueListenableBuilder para escuchar los cambios en el filtro
                      child: ValueListenableBuilder<String>(
                        valueListenable: filtroDialogo,
                        builder: (contextVLB, filtroActual, child) {
                          // StreamBuilder para obtener todos los usuarios
                          return StreamBuilder<QuerySnapshot>(
                            stream:
                                FirebaseFirestore.instance
                                    .collection('usuarios')
                                    .snapshots(),
                            builder: (contextStream, userSnapshot) {
                              if (!userSnapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              // Filtramos los usuarios:
                              // 1. No deben ser el usuario actual (uid)
                              // 2. No deben estar ya en el grupo (idsMiembrosActuales)
                              // 3. Deben coincidir con el filtro de búsqueda si existe
                              final List<DocumentSnapshot> usuariosFiltrados =
                                  userSnapshot.data!.docs.where((doc) {
                                    final bool esUsuarioActual = doc.id == uid;
                                    final bool yaEsMiembro = idsMiembrosActuales
                                        .contains(doc.id);
                                    if (esUsuarioActual || yaEsMiembro) {
                                      return false; // Excluir
                                    }
                                    if (filtroActual.isNotEmpty) {
                                      final String nombreUsuarioDoc =
                                          (doc.data()
                                                  as Map<
                                                    String,
                                                    dynamic
                                                  >)['Nombre']
                                              ?.toString()
                                              .toLowerCase() ??
                                          '';
                                      return nombreUsuarioDoc.contains(
                                        filtroActual,
                                      );
                                    }
                                    return true; // Incluir si no hay filtro de texto y no es miembro/actual
                                  }).toList();

                              if (usuariosFiltrados.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No hay más usuarios para añadir o que coincidan.',
                                  ),
                                );
                              }

                              return ListView.builder(
                                itemCount: usuariosFiltrados.length,
                                itemBuilder: (_, i) {
                                  final userDoc = usuariosFiltrados[i];
                                  final userData =
                                      userDoc.data()! as Map<String, dynamic>;
                                  final String nombre =
                                      userData['Nombre'] ?? 'Usuario';
                                  final String foto =
                                      userData['FotoPerfil'] ?? '';
                                  final bool estaSeleccionado =
                                      idsSeleccionadosParaAnadir.contains(
                                        userDoc.id,
                                      );

                                  return CheckboxListTile(
                                    value: estaSeleccionado,
                                    onChanged: (bool? seleccionado) {
                                      setStateDialog(() {
                                        // Usa el setState del StatefulBuilder
                                        if (seleccionado == true) {
                                          idsSeleccionadosParaAnadir.add(
                                            userDoc.id,
                                          );
                                        } else {
                                          idsSeleccionadosParaAnadir.remove(
                                            userDoc.id,
                                          );
                                        }
                                      });
                                    },
                                    title: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundImage:
                                              foto.isNotEmpty
                                                  ? NetworkImage(foto)
                                                  : const AssetImage(
                                                        'assets/images/avatar1.png',
                                                      )
                                                      as ImageProvider,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(nombre)),
                                      ],
                                    ),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () => Navigator.of(contextDialog).pop(),
                ),
                ElevatedButton(
                  child: const Text('Añadir Seleccionados'),
                  onPressed:
                      idsSeleccionadosParaAnadir.isNotEmpty
                          ? () {
                            Navigator.of(
                              contextDialog,
                            ).pop(); // Cierra este diálogo
                            _ejecutarAgregarParticipantes(
                              groupId,
                              idsSeleccionadosParaAnadir,
                            );
                          }
                          : null, // Deshabilitado si no hay nadie seleccionado
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _mostrarDialogoMiembrosGrupo(
    String groupId,
    String groupName,
    String? groupPhotoUrl,
    List<String> memberIds, // Lista de IDs de los miembros actuales
  ) {
    showDialog(
      context: context,
      builder: (BuildContext contextDialog) {
        // Renombrado para evitar conflicto con el context principal
        return AlertDialog(
          titlePadding: const EdgeInsets.all(0),
          title: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8), // Ajustar padding
            color: Theme.of(contextDialog).colorScheme.primary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  // Fila para avatar y nombre
                  children: [
                    CircleAvatar(
                      radius: 18, // Un poco más pequeño para que quepa el botón
                      backgroundImage:
                          (groupPhotoUrl != null && groupPhotoUrl.isNotEmpty)
                              ? NetworkImage(groupPhotoUrl)
                              : const AssetImage(
                                    'assets/images/avatar_grupo_default.png',
                                  )
                                  as ImageProvider,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      groupName,
                      style: Theme.of(
                        contextDialog,
                      ).textTheme.titleMedium?.copyWith(
                        color: Theme.of(contextDialog).colorScheme.onPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                // --- BOTÓN AÑADIDO PARA AÑADIR PARTICIPANTES ---
                IconButton(
                  icon: Icon(
                    Icons.person_add_alt_1,
                    color: Theme.of(contextDialog).colorScheme.onPrimary,
                  ),
                  tooltip: 'Añadir participante',
                  onPressed: () {
                    Navigator.of(
                      contextDialog,
                    ).pop(); // Cierra el diálogo de miembros actual
                    _mostrarDialogoSeleccionarNuevosMiembros(
                      groupId,
                      memberIds,
                    ); // Llama al nuevo diálogo
                  },
                ),
                // --- FIN DEL BOTÓN AÑADIDO ---
              ],
            ),
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            8,
            16,
            8,
            0,
          ), // Ajustar padding
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(contextDialog).size.height * 0.4,
            child: ListView.builder(
              itemCount: memberIds.length,
              itemBuilder: (BuildContext contextItem, int index) {
                final memberId = memberIds[index];
                final userInfo = cacheUsuarios[memberId];
                final String nombreMiembro = userInfo?['nombre'] ?? memberId;
                final String? fotoMiembroUrl = userInfo?['foto'];

                if (userInfo == null && mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !cacheUsuarios.containsKey(memberId)) {
                      _obtenerUsuario(memberId);
                    }
                  });
                }

                return ListTile(
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundImage:
                        (fotoMiembroUrl != null && fotoMiembroUrl.isNotEmpty)
                            ? NetworkImage(fotoMiembroUrl)
                            : const AssetImage('assets/images/avatar1.png')
                                as ImageProvider,
                  ),
                  title: Text(nombreMiembro),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              // Botón Salir del Grupo (ya lo tenías)
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(contextDialog).colorScheme.error,
              ),
              child: const Text('Salir del grupo'),
              onPressed: () {
                Navigator.of(contextDialog).pop();
                _confirmarSalirDelGrupo(groupId, groupName);
              },
            ),
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                Navigator.of(contextDialog).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Método que abre el diálogo de creación de grupo
  void _mostrarDialogoCrearGrupo() {
    // controladores y estado local del diálogo
    final TextEditingController _groupNameController = TextEditingController();
    final TextEditingController _searchController = TextEditingController();
    List<String> _selected = [];
    String _filter = '';

    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController _groupNameController =
            TextEditingController();
        final TextEditingController _searchController = TextEditingController();
        List<String> _selected = [];
        String _filter = '';

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Nuevo grupo'),
              content: SizedBox(
                width: 350,
                height: 400,
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage:
                              _imagenGrupo != null
                                  ? MemoryImage(_imagenGrupo!)
                                  : const AssetImage(
                                        'assets/images/avatar1.png',
                                      )
                                      as ImageProvider,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () async {
                              final input =
                                  html.FileUploadInputElement()
                                    ..accept = 'image/*';
                              input.click();
                              input.onChange.listen((event) {
                                final file = input.files?.first;
                                if (file != null) {
                                  final reader = html.FileReader();
                                  reader.readAsArrayBuffer(file);
                                  reader.onLoadEnd.listen((event) {
                                    _imagenGrupo = reader.result as Uint8List;
                                    setStateDialog(() {}); // <- importante
                                  });
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _groupNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del grupo',
                      ),
                      onChanged: (_) => setStateDialog(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Buscar usuarios...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (txt) {
                        _filter = txt.trim().toLowerCase();
                        setStateDialog(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('Chats')
                                .where('ids', arrayContains: uid)
                                .orderBy('lastMessageAt', descending: true)
                                .limit(5)
                                .snapshots(),
                        builder: (ctx, chatSnap) {
                          if (!chatSnap.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          // Extrae los usuarios con los que se tienen los 5 chats más recientes (1 a 1 y grupos)
                          final recentUserIds = <String>{};
                          for (var doc in chatSnap.data!.docs) {
                            final ids = List<String>.from(doc['ids']);
                            for (var id in ids) {
                              if (id != uid) recentUserIds.add(id);
                            }
                          }

                          // Si hay filtro activo, buscar entre todos los usuarios
                          final searchStream =
                              _filter.isNotEmpty
                                  ? FirebaseFirestore.instance
                                      .collection('usuarios')
                                      .snapshots()
                                  : FirebaseFirestore.instance
                                      .collection('usuarios')
                                      .where(
                                        FieldPath.documentId,
                                        whereIn: recentUserIds.toList(),
                                      )
                                      .snapshots();

                          return StreamBuilder<QuerySnapshot>(
                            stream: searchStream,
                            builder: (ctx, snap) {
                              if (!snap.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final all =
                                  snap.data!.docs
                                      .where((d) => d.id != uid)
                                      .toList();

                              // Si hay filtro, aplicamos búsqueda local
                              final filtered =
                                  _filter.isEmpty
                                      ? all
                                      : all.where((d) {
                                        final name =
                                            (d['Nombre'] ?? '')
                                                .toString()
                                                .toLowerCase();
                                        return name.contains(_filter);
                                      }).toList();

                              if (filtered.isEmpty) {
                                return const Center(
                                  child: Text("No hay usuarios"),
                                );
                              }

                              return ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (_, i) {
                                  final doc = filtered[i];
                                  final data =
                                      doc.data()! as Map<String, dynamic>;
                                  final nombre = data['Nombre'] ?? 'Usuario';
                                  final foto = data['FotoPerfil'] ?? '';
                                  final isSel = _selected.contains(doc.id);

                                  return CheckboxListTile(
                                    value: isSel,
                                    onChanged: (yes) {
                                      setStateDialog(() {
                                        if (yes == true) {
                                          _selected.add(doc.id);
                                        } else {
                                          _selected.remove(doc.id);
                                        }
                                      });
                                    },
                                    title: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundImage:
                                              foto.isNotEmpty
                                                  ? NetworkImage(foto)
                                                  : const AssetImage(
                                                        'assets/images/avatar1.png',
                                                      )
                                                      as ImageProvider,
                                          radius: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(nombre)),
                                      ],
                                    ),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed:
                      (_groupNameController.text.trim().isNotEmpty &&
                              _selected.isNotEmpty)
                          ? () async {
                            final chatId =
                                FirebaseFirestore.instance
                                    .collection('Chats')
                                    .doc()
                                    .id;
                            final now = Timestamp.now();

                            String urlImagen = '';
                            if (_imagenGrupo != null) {
                              urlImagen = await subirImagenGrupo(
                                _imagenGrupo!,
                                chatId,
                              );
                            }

                            await FirebaseFirestore.instance
                                .collection('Chats')
                                .doc(chatId)
                                .set({
                                  'ids': [uid, ..._selected],
                                  'isGroup': true,
                                  'groupName': _groupNameController.text.trim(),
                                  'groupPhoto': urlImagen,
                                  'createdBy': uid,
                                  'lastMessage': '',
                                  'lastMessageAt': now,
                                  'typing': {
                                    for (var u in [uid, ..._selected]) u: false,
                                  },
                                  'unreadCounts': {
                                    for (var u in [uid, ..._selected]) u: 0,
                                  },
                                });

                            for (final miembro in _selected) {
                              await NotificationService.crearNotificacion(
                                uidDestino: miembro,
                                tipo: 'grupo',
                                titulo: 'Nuevo grupo creado',
                                contenido:
                                    '$nombreUsuario te ha agregado al grupo "${_groupNameController.text.trim()}"',
                                referenciaId: chatId,
                                uidEmisor: uid,
                                nombreEmisor: nombreUsuario ?? 'Usuario',
                              );
                            }

                            if (!mounted) return;
                            Navigator.pop(context);
                            setState(() {
                              chatIdSeleccionado = chatId;
                              otroUid = null;
                              _showList = false;
                            });
                          }
                          : null,
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Panel izquierdo con header, tabs, buscador, historias y lista de chats
  Widget _buildChatList() {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: 200, maxWidth: 320),
      child: Container(
        color: const Color(0xFF015C8B),
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              // ——— 1) Header “Chats” con iconos ———
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Chats',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_horiz, color: Colors.white),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.create, color: Colors.white),
                      onPressed: _mostrarDialogoCrearGrupo,
                    ),
                  ],
                ),
              ),

              // ——— 2) TabBar ———
              TabBar(
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.white,
                tabs: const [
                  Tab(text: 'Todos'),
                  Tab(text: 'No leídos'),
                  Tab(text: 'Grupos'),
                ],
              ),

              // ——— 3) Buscador ———
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _busquedaController,
                  decoration: InputDecoration(
                    hintText: 'Buscar...',
                    prefixIcon: const Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                  ),
                  onChanged: (texto) async {
                    final lower = texto.trim().toLowerCase();
                    setState(() {
                      filtro = lower;
                      if (filtro.isNotEmpty) {
                        _isSearchingGlobalUsers =
                            true; // <--- INICIA ESTADO DE CARGA
                        _usuarios =
                            []; // Limpia resultados anteriores para evitar mostrar datos viejos mientras carga
                      } else {
                        _isSearchingGlobalUsers =
                            false; // No hay filtro, no estamos buscando usuarios globales
                        // Considera si _usuarios debe volver a su estado inicial (todos los usuarios)
                        // o si se vacía. Si se vacía, la lista de chats existentes se mostrará.
                        // Por ahora, la dejaremos así, _cargarUsuarios() la llena inicialmente.
                      }
                    });
                    if (filtro.isNotEmpty) {
                      final snap =
                          await FirebaseFirestore.instance
                              .collection('usuarios')
                              .get();
                      if (!mounted)
                        return; // Comprobar si el widget sigue montado
                      setState(() {
                        _usuarios =
                            snap.docs.where((u) {
                              final nombre =
                                  (u['Nombre'] ?? '').toString().toLowerCase();
                              // Asegúrate que 'filtro' ya esté en minúsculas aquí (lo está por 'lower')
                              return nombre.contains(filtro) && u.id != uid;
                            }).toList();
                        _isSearchingGlobalUsers =
                            false; // <--- TERMINA ESTADO DE CARGA
                      });
                    }
                  },
                ),
              ),

              // ——— 4) Carrusel de historias ———
              SizedBox(
                height: 80,
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('usuarios')
                          .snapshots(),
                  builder: (ctx, snap) {
                    if (!snap.hasData) return const SizedBox();
                    final users =
                        snap.data!.docs.where((d) => d.id != uid).toList();
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: users.length,
                      itemBuilder: (_, i) {
                        final u = users[i].data()! as Map<String, dynamic>;
                        final foto = u['FotoPerfil'] as String? ?? '';
                        final online = u['online'] as bool? ?? false;
                        final nombre = u['Nombre'] as String? ?? 'Usuario';
                        return GestureDetector(
                          onTap: () => _iniciarChat(users[i].id),
                          child: Container(
                            width: 60,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundImage:
                                          foto.isNotEmpty
                                              ? NetworkImage(foto)
                                              : const AssetImage(
                                                    'assets/images/avatar1.png',
                                                  )
                                                  as ImageProvider,
                                    ),
                                    if (online)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  nombre,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const Divider(color: Colors.white54, height: 1),

              // ——— 5) Contenido de cada tab ———
              Expanded(
                child: TabBarView(
                  children: [
                    // Todos
                    _chatListStream(filterUnread: false, filterGroups: false),
                    // No leídos
                    _chatListStream(filterUnread: true, filterGroups: false),
                    // Grupos (ids.length>2)
                    _chatListStream(filterUnread: false, filterGroups: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper que construye la lista aplicando filtros
  Widget _chatListStream({
    required bool filterUnread,
    required bool filterGroups,
  }) {
    // --- CASO 1: HAY TEXTO EN EL FILTRO DE BÚSQUEDA ---
    if (filtro.isNotEmpty) {
      if (_isSearchingGlobalUsers) {
        // Muestra shimmers para la lista de usuarios mientras carga
        return ListView.builder(
          itemCount: 5, // O el número de shimmers que prefieras
          itemBuilder:
              (_, __) =>
                  const ShimmerChatTile(), // Puedes crear un ShimmerUserTile() si quieres diferenciarlo
        );
      } else if (_usuarios.isEmpty) {
        // La búsqueda terminó pero no se encontraron usuarios
        return const Center(
          child: Text('No se encontraron usuarios con ese nombre.'),
        );
      } else {
        // La búsqueda terminó y SÍ hay usuarios para mostrar
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: _usuarios.length,
          itemBuilder: (_, i) {
            final userDoc = _usuarios[i];
            final nombre = userDoc['Nombre'] ?? 'Usuario';
            final foto = cacheUsuarios[userDoc.id]?['foto'] ?? '';

            // TU UI PARA MOSTRAR UN USUARIO DE LA BÚSQUEDA GLOBAL (esta parte ya la tenías bien)
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => hoveredUserId = userDoc.id),
              onExit: (_) => setState(() => hoveredUserId = null),
              child: Tooltip(
                message: 'Haz clic para chatear con $nombre',
                waitDuration: const Duration(milliseconds: 300),
                child: GestureDetector(
                  onTap:
                      () => _iniciarChat(
                        userDoc.id,
                      ), // _iniciarChat ya maneja la creación
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    transform:
                        hoveredUserId == userDoc.id
                            ? (Matrix4.identity()..scale(1.02))
                            : Matrix4.identity(),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient:
                          hoveredUserId == userDoc.id
                              ? const LinearGradient(
                                colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                              : null,
                      color:
                          hoveredUserId != userDoc.id
                              ? const Color(0xFF1565C0)
                              : null,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color:
                              hoveredUserId == userDoc.id
                                  ? Colors.blueAccent.withOpacity(0.6)
                                  : Colors.black.withOpacity(0.2),
                          blurRadius: hoveredUserId == userDoc.id ? 12 : 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundImage:
                              foto.isNotEmpty
                                  ? NetworkImage(foto)
                                  : const AssetImage(
                                        'assets/images/avatar1.png',
                                      )
                                      as ImageProvider,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombre,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Haz clic para iniciar conversación',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white54,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }
    }
    // --- CASO 2: NO HAY TEXTO EN EL FILTRO DE BÚSQUEDA (MOSTRAMOS CHATS EXISTENTES) ---
    else {
      return StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('Chats')
                .where('ids', arrayContains: uid)
                .orderBy('lastMessageAt', descending: true)
                .snapshots(),
        builder: (ctx, chatSnapshot) {
          if (chatSnapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              itemCount: 5,
              itemBuilder: (_, __) => const ShimmerChatTile(),
            );
          }

          if (!chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty) {
            if (filterUnread)
              return const Center(child: Text('No tienes mensajes no leídos'));
            if (filterGroups)
              return const Center(child: Text('No estás en ningún grupo aún'));
            return const Center(
              child: Text('Inicia una conversación o crea un grupo'),
            );
          }

          List<DocumentSnapshot> chatsExistentes = chatSnapshot.data!.docs;
          List<DocumentSnapshot> chatsFiltradosPorPestana =
              chatsExistentes.where((chatDoc) {
                final data = chatDoc.data() as Map<String, dynamic>?;
                if (data == null) return false;
                final bool esUnGrupo = (data['isGroup'] as bool?) ?? false;
                final Map<String, dynamic> unreadMap =
                    (data['unreadCounts'] as Map<String, dynamic>?) ?? {};
                final int contadorNoLeidos = (unreadMap[uid] as int?) ?? 0;

                if (filterGroups) return esUnGrupo;
                if (filterUnread) return contadorNoLeidos > 0;
                return true; // Pestaña "Todos"
              }).toList();

          if (chatsFiltradosPorPestana.isEmpty) {
            if (filterUnread)
              return const Center(child: Text('No tienes mensajes no leídos'));
            if (filterGroups)
              return const Center(child: Text('No hay grupos que coincidan'));
            return const Center(child: Text('No hay conversaciones aquí.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: chatsFiltradosPorPestana.length,
            itemBuilder: (ctxBuilder, idx) {
              final chatDoc = chatsFiltradosPorPestana[idx];
              final data = chatDoc.data()! as Map<String, dynamic>;
              final List<String> otherIds = List<String>.from(
                data['ids'] ?? [],
              );
              final bool isGroup = (data['isGroup'] as bool?) ?? false;
              final String chatId = chatDoc.id;

              final String? other =
                  isGroup
                      ? null
                      : otherIds.firstWhere(
                        (id) => id != uid,
                        orElse: () => '',
                      );

              if (!isGroup &&
                  (other == null ||
                      other.isEmpty ||
                      !cacheUsuarios.containsKey(other))) {
                return const ShimmerChatTile();
              }

              final String preview =
                  (data['lastMessage'] as String?)?.trim().isNotEmpty == true
                      ? data['lastMessage']
                      : isGroup
                      ? '${cacheUsuarios[data['createdBy']]?['nombre'] ?? "Alguien"} ha creado el grupo'
                      : 'Inicia la conversación';

              final String title =
                  isGroup
                      ? (data['groupName'] ?? 'Grupo (${otherIds.length})')
                      : cacheUsuarios[other!]!['nombre']!;

              final String? photoUrl =
                  isGroup ? data['groupPhoto'] : cacheUsuarios[other!]!['foto'];

              final String hora =
                  data['lastMessageAt'] != null
                      ? DateFormat.Hm().format(
                        (data['lastMessageAt'] as Timestamp).toDate(),
                      )
                      : '';

              final unreadMap =
                  (data['unreadCounts'] as Map<String, dynamic>?) ?? {};
              final int unreadCount = (unreadMap[uid] as int?) ?? 0;

              // TU UI PARA MOSTRAR UN CHAT EXISTENTE (esta parte ya la tenías bien)
              return ValueListenableBuilder<String?>(
                valueListenable: hoveredChatId,
                builder: (context, hovered, _) {
                  final isHovered = hovered == chatId;
                  return MouseRegion(
                    onEnter: (_) => hoveredChatId.value = chatId,
                    onExit: (_) => hoveredChatId.value = null,
                    child: GestureDetector(
                      onTap: () {
                        if (chatId != null && uid != null) {
                          FirebaseFirestore.instance
                              .collection('Chats')
                              .doc(chatId)
                              .update({'unreadCounts.$uid': 0})
                              .catchError((e) {
                                print(
                                  "Error al actualizar unreadCounts para $chatId: $e",
                                );
                              });
                        }
                        if (isGroup) {
                          setState(() {
                            chatIdSeleccionado = chatId;
                            otroUid = null;
                            _showList = false;
                          });
                        } else {
                          _iniciarChat(other!);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        transform:
                            isHovered
                                ? (Matrix4.identity()..scale(1.015))
                                : Matrix4.identity(),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isHovered
                                  ? Colors.blue.shade800
                                  : const Color(0xFF015C8B),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  isHovered
                                      ? Colors.black.withOpacity(0.3)
                                      : Colors.black26,
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundImage:
                                  photoUrl?.isNotEmpty == true
                                      ? NetworkImage(photoUrl!)
                                      : const AssetImage(
                                            'assets/images/avatar1.png',
                                          )
                                          as ImageProvider,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        hora,
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (preview.contains(
                                        'ha creado el grupo',
                                      ))
                                        const Icon(
                                          Icons.group_add,
                                          size: 14,
                                          color: Colors.white70,
                                        ),
                                      if (preview.contains(
                                        'ha creado el grupo',
                                      ))
                                        const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          preview,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (unreadCount > 0)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: Colors.white,
                                  ),
                                  onSelected: (value) {
                                    if (value == 'archivar') {
                                    } else if (value == 'silenciar') {
                                    } else if (value == 'eliminar') {}
                                  },
                                  itemBuilder:
                                      (context) => const [
                                        PopupMenuItem(
                                          value: 'archivar',
                                          child: Text('Archivar chat'),
                                        ),
                                        PopupMenuItem(
                                          value: 'silenciar',
                                          child: Text('Silenciar'),
                                        ),
                                        PopupMenuItem(
                                          value: 'eliminar',
                                          child: Text('Eliminar chat'),
                                        ),
                                      ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      );
    }
  }

  // Parte de los mensajes
  /// 1) Header con botón atrás, avatar, nombre y última conexión

  Widget _buildChatHeader() {
    return Container(
      color: const Color(
        0xFF048DD2,
      ), // Considera usar Theme.of(context).colorScheme.secondary
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed:
                () => setState(() {
                  _showList = true;
                  chatIdSeleccionado = null;
                  otroUid = null;
                }),
          ),
          const SizedBox(width: 10),

          if (chatIdSeleccionado != null)
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('Chats')
                        .doc(chatIdSeleccionado!)
                        .snapshots(),
                builder: (context, chatSnap) {
                  if (chatSnap.connectionState == ConnectionState.waiting &&
                      !chatSnap.hasData) {
                    // Si está esperando y no hay datos previos, muestra un loader
                    // (especialmente si otroUid es null, indicando que no es un inicio de chat 1a1 directo)
                    if (otroUid == null) {
                      return const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      );
                    }
                    // Si hay otroUid, _buildHeaderInfoUsuario podría manejar su propio FutureBuilder
                  }

                  // Si hay datos del chat (aunque sea de un snapshot anterior mientras se actualiza)
                  if (chatSnap.hasData) {
                    final chatData =
                        chatSnap.data!.data() as Map<String, dynamic>?;
                    if (chatData == null)
                      return const Text(
                        'Error en chat',
                        style: TextStyle(color: Colors.white),
                      );

                    final bool esGrupo =
                        (chatData['isGroup'] as bool?) ?? false;

                    if (esGrupo) {
                      final String nombreGrupo =
                          chatData['groupName'] ?? 'Grupo';
                      final String? fotoGrupoUrl =
                          chatData['groupPhoto'] as String?;
                      final List<String> miembrosIds = List<String>.from(
                        chatData['ids'] ?? [],
                      );

                      return GestureDetector(
                        onTap: () {
                          _mostrarDialogoMiembrosGrupo(
                            chatIdSeleccionado!,
                            nombreGrupo,
                            fotoGrupoUrl,
                            miembrosIds,
                          );
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage:
                                  (fotoGrupoUrl != null &&
                                          fotoGrupoUrl.isNotEmpty)
                                      ? NetworkImage(fotoGrupoUrl)
                                      : const AssetImage(
                                            'assets/images/avatar_grupo_default.png',
                                          )
                                          as ImageProvider,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    nombreGrupo,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${miembrosIds.length} miembro(s)',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      // Chat 1 a 1
                      final List<String> idsParticipantes = List<String>.from(
                        chatData['ids'] ?? [],
                      );

                      // ----- CORRECCIÓN APLICADA AQUÍ -----
                      final Iterable<String> otrosIdsFiltrados =
                          idsParticipantes.where((id) => id != uid);
                      final String? idOtroUsuarioDelChat =
                          otrosIdsFiltrados.isNotEmpty
                              ? otrosIdsFiltrados.first
                              : null;
                      // ----- FIN DE CORRECCIÓN -----

                      if (idOtroUsuarioDelChat != null) {
                        // Si 'otroUid' (variable de estado) es diferente del que viene del stream, actualízalo.
                        // Esto puede pasar si la selección de chat cambió y el stream aún no lo refleja del todo.
                        if (otroUid != idOtroUsuarioDelChat) {
                          // Es mejor no llamar a setState directamente en el builder.
                          // La UI se actualizará con _buildHeaderInfoUsuario.
                          // Si necesitas 'otroUid' para otras lógicas, asegúrate que se actualice
                          // cuando 'chatIdSeleccionado' cambia.
                        }
                        return _buildHeaderInfoUsuario(idOtroUsuarioDelChat);
                      } else {
                        return const Text(
                          'Usuario no encontrado',
                          style: TextStyle(color: Colors.white),
                        );
                      }
                    }
                  } else if (otroUid != null) {
                    // No hay datos del chat todavía, pero SÍ hay un otroUid (ej. al iniciar un nuevo chat 1a1)
                    return _buildHeaderInfoUsuario(otroUid!);
                  }
                  // Fallback si no hay datos del chat y no hay otroUid
                  return const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            )
          else if (otroUid !=
              null) // Si chatIdSeleccionado es null pero otroUid existe
            Expanded(child: _buildHeaderInfoUsuario(otroUid!))
          else
            const Expanded(
              child: Text(
                'Selecciona un chat',
                style: TextStyle(color: Colors.white, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  // Widget HELPER _buildHeaderInfoUsuario (esta función no necesita cambios, ya la tenías)
  Widget _buildHeaderInfoUsuario(String idUsuario) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('usuarios')
              .doc(idUsuario)
              .get(),
      builder: (context, userSnap) {
        if (userSnap.connectionState == ConnectionState.waiting &&
            !userSnap.hasData) {
          return const Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ],
          );
        }
        if (!userSnap.hasData || !userSnap.data!.exists) {
          return const Text(
            'Info no disponible',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          );
        }
        final userData = userSnap.data!.data() as Map<String, dynamic>?;
        if (userData == null)
          return const Text(
            'Usuario no disponible',
            style: TextStyle(color: Colors.white),
          );

        final nombre = userData['Nombre'] as String? ?? 'Usuario';
        final fotoUrl = userData['FotoPerfil'] as String?;
        final bool online = (userData['online'] as bool?) ?? false;
        final Timestamp? tsUltimaConexion =
            userData['ultimaConexion'] as Timestamp?;
        final String ultimaConexionStr =
            tsUltimaConexion != null
                ? 'Últ. vez: ${_formatearHora(tsUltimaConexion)}'
                : online
                ? ''
                : 'Desconocido'; // No mostrar 'Desconocido' si está online

        return Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage:
                  (fotoUrl != null && fotoUrl.isNotEmpty)
                      ? NetworkImage(fotoUrl)
                      : const AssetImage('assets/images/avatar1.png')
                          as ImageProvider,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    online ? '🟢 En línea' : ultimaConexionStr,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// 2) Indicador “está escribiendo…”
  Widget _buildTypingIndicator() {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('Chats')
              .doc(chatIdSeleccionado)
              .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final typingMap =
            (snap.data!.data()! as Map)['typing'] as Map<String, dynamic>? ??
            {};
        if (otroUid == null || typingMap[otroUid] != true)
          return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          color: Colors.grey.withOpacity(0.1),
          child: Text(
            '${cacheUsuarios[otroUid]!['nombre']} está escribiendo…',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.blue.shade900,
            ),
          ),
        );
      },
    );
  }

  /// 3) StreamBuilder de mensajes, con separador de fecha y ChatBubble
  Widget _buildMessagesStream() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('Chats')
              .doc(chatIdSeleccionado)
              .collection('Mensajes')
              .orderBy('Fecha')
              .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // ── 1) Marcar como leídos los mensajes que veo y que no son míos ──
        for (var doc in snap.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final autor = data['AutorID'] as String;
          final leidoPor = List<String>.from(data['leidoPor'] ?? []);
          if (autor != uid && !leidoPor.contains(uid)) {
            FirebaseFirestore.instance
                .collection('Chats')
                .doc(chatIdSeleccionado)
                .collection('Mensajes')
                .doc(doc.id)
                .update({
                  'leidoPor': FieldValue.arrayUnion([uid]),
                });
          }
        }

        // ── 2) Construir la lista invertida y auto‑scroll ──
        // final asc = snap.data!.docs;
        // final inv = asc.reversed.toList();
        final inv = snap.data!.docs.reversed.toList();

        // Después de rebuild, asegurar scroll al fondo:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.all(12),
          itemCount: inv.length, // 'inv' es tu lista de mensajes invertida
          itemBuilder: (context, i) {
            final doc = inv[i];
            final data = doc.data() as Map<String, dynamic>;
            final esMio = data['AutorID'] == uid;
            final fecha = (data['Fecha'] as Timestamp).toDate();

            // Separador de fecha (tu lógica actual)
            bool showDateSeparator = false;
            if (i == inv.length - 1) {
              showDateSeparator = true;
            } else {
              final nextTs =
                  (inv[i + 1].data() as Map<String, dynamic>)['Fecha']
                      as Timestamp;
              final d1 = fecha;
              final d2 = nextTs.toDate();
              showDateSeparator =
                  d1.year != d2.year ||
                  d1.month != d2.month ||
                  d1.day != d2.day;
            }

            final leidoPor = List<String>.from(data['leidoPor'] ?? []);
            final readByPeer = otroUid != null && leidoPor.contains(otroUid);

            // --- INICIO DE MODIFICACIÓN PARA MANEJAR autorInfo ---
            final String? autorId =
                data['AutorID'] as String?; // Hacemos el ID del autor nulable
            Map<String, String>? autorInfo =
                autorId != null ? cacheUsuarios[autorId] : null;

            // Si la info del autor no está en caché y el autorId es válido, intenta cargarla
            if (autorId != null &&
                autorId != 'sistema' &&
                autorInfo == null &&
                mounted) {
              // Llamamos esto en addPostFrameCallback para evitar llamar a setState durante un build.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !cacheUsuarios.containsKey(autorId)) {
                  // Doble chequeo
                  _obtenerUsuario(
                    autorId,
                  ); // _obtenerUsuario llama a setState cuando completa
                }
              });
            }

            // Prepara valores seguros para pasar al ChatBubbleCustom
            final String nombreAutorParaMostrar =
                autorInfo?['nombre'] ??
                (autorId == 'sistema'
                    ? ''
                    : (autorId == uid
                        ? (nombreUsuario ?? 'Tú')
                        : 'Usuario...'));
            final String? urlAvatarParaMostrar = autorInfo?['foto'];
            // Considera un estado de carga si autorInfo es null y no es un mensaje del sistema ni tuyo
            final bool estaCargandoInfoAutor =
                autorId != null &&
                autorId != 'sistema' &&
                autorId != uid &&
                autorInfo == null;
            // --- FIN DE MODIFICACIÓN ---

            final total = inv.length;
            final showName =
                i == total - 1 ||
                (i < total - 1 &&
                    (inv[i + 1].data() as Map<String, dynamic>)['AutorID'] !=
                        data['AutorID']);

            return Column(
              crossAxisAlignment:
                  esMio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (showDateSeparator) DateSeparator(fecha),

                // Si está cargando la info del autor Y NO es tu mensaje, muestra un loader simple
                // (Podrías hacer un ShimmerBubble más elaborado aquí)
                if (estaCargandoInfoAutor && !esMio)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: esMio ? 0 : 10,
                    ),
                    child: Align(
                      alignment:
                          esMio ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const SizedBox(
                          width: 100,
                          child: Text(
                            'Cargando mensaje...',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                  )
                else // Si no está cargando, o es tu mensaje, muestra el ChatBubbleCustom
                  ChatBubbleCustom(
                    isMine: esMio,
                    read: readByPeer,
                    avatarUrl:
                        urlAvatarParaMostrar ??
                        '', // Pasa string vacío si es null
                    authorName: nombreAutorParaMostrar,
                    text: data['Contenido'] as String,
                    time: fecha,
                    edited: data['editado'] as bool? ?? false,
                    deleted: data['eliminado'] as bool? ?? false,
                    reactions: Map<String, int>.from(data['reacciones'] ?? {}),
                    showName: showName,
                    onEdit:
                        () => _editarMensaje(
                          doc.id,
                          data['Contenido'],
                          data['Fecha'],
                        ),
                    onDelete: () => _eliminarMensaje(doc.id),
                    onReact: () => _reaccionarMensaje(doc.id),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  /// 4) Caja de texto + botón enviar
  Widget _buildInputBox() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _mensajeController,
              onChanged: (val) {
                mensaje = val;
                final typing = val.trim().isNotEmpty;
                if (typing != _isTyping && chatIdSeleccionado != null) {
                  _isTyping = typing;
                  FirebaseFirestore.instance
                      .collection('Chats')
                      .doc(chatIdSeleccionado)
                      .update({'typing.$uid': typing});
                }
                // Dispara rebuild para que el botón se actualice
                setState(() {});
              },
              decoration: const InputDecoration(
                hintText: 'Escribe tu mensaje…',
              ),
            ),
          ),
          // IconButton(
          //   icon: const Icon(Icons.send, color: Colors.blueAccent),
          //   onPressed: _enviarMensaje,
          // ),
          // Si mensaje.trim() está vacío, onPressed será null y el botón deshabilitado
          IconButton(
            icon: Icon(
              Icons.send,
              // color cambia según si está habilitado o no
              color:
                  mensaje.trim().isNotEmpty ? Colors.blueAccent : Colors.grey,
            ),
            onPressed: mensaje.trim().isNotEmpty ? _enviarMensaje : null,
          ),
        ],
      ),
    );
  }

  /// 5) Ensambla header + indicador + mensajes + input
  Widget _buildChatDetail() {
    return Expanded(
      flex: 3,
      child: Column(
        children: [
          _buildChatHeader(),
          if (chatIdSeleccionado != null) _buildTypingIndicator(),
          Expanded(child: _buildMessagesStream()),
          if (chatIdSeleccionado != null) _buildInputBox(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(showBack: true),

      body: Row(
        children: [
          if (_showList)
            Expanded(child: _buildChatList()), // tu panel izquierdo
          if (!_showList) _buildChatDetail(),
        ],
      ),
    );
  }
}
