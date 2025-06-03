import 'dart:async';
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
  Timer? _debounceTimer; // Variable para el debounce
  final Duration _debounceDuration = const Duration(milliseconds: 350);

  @override
  void initState() {
    super.initState();

    _cargarUsuarios();
    _obtenerNombreUsuario();
  }

  @override
  void dispose() {
    _mensajeController.dispose();
    _busquedaController.dispose();
    _scrollController.dispose();
    hoveredChatId.dispose();
    _groupNameController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
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

  // Añade esta nueva función a tu _ChatHomePageState

  Future<void> _archivarChat(String chatId) async {
    if (chatId == null || chatId.isEmpty) {
      // Comprobación de seguridad
      print("Error: Se intentó archivar un chat con ID nulo o vacío.");
      return;
    }

    final DocumentReference chatDocRef = FirebaseFirestore.instance
        .collection('Chats')
        .doc(chatId);

    try {
      // Usamos FieldValue.arrayUnion para añadir el uid actual a la lista 'archivadoPara'.
      // arrayUnion se asegura de que el uid no se añada si ya está presente (evita duplicados).
      await chatDocRef.update({
        'archivadoPara': FieldValue.arrayUnion([
          uid,
        ]), // uid es el ID del usuario actual
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Chat archivado')));
        // Opcional: Si el chat archivado es el que está seleccionado actualmente,
        // podrías querer deseleccionarlo y volver a la lista.
        if (chatIdSeleccionado == chatId) {
          setState(() {
            _showList = true; // Mostrar la lista de chats
            chatIdSeleccionado = null;
            otroUid = null;
          });
        }
        // No es necesario un setState global aquí para la lista, ya que el StreamBuilder
        // en _chatListStream se actualizará cuando modifiquemos el filtro para ocultar
        // los chats archivados (eso lo haremos en el siguiente paso).
      }
      print('Chat $chatId archivado para el usuario $uid');
    } catch (e, s) {
      print('Error al archivar el chat: ${e.toString()}');
      print('Stack trace: ${s.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al archivar el chat: ${e.toString()}')),
        );
      }
    }
  }

  // Añade esta nueva función a tu _ChatHomePageState

  Future<void> _desarchivarChat(String chatId) async {
    if (chatId == null || chatId.isEmpty) {
      print("Error: Se intentó desarchivar un chat con ID nulo o vacío.");
      return;
    }

    final DocumentReference chatDocRef = FirebaseFirestore.instance
        .collection('Chats')
        .doc(chatId);

    try {
      // Usamos FieldValue.arrayRemove para quitar el uid actual de la lista 'archivadoPara'.
      await chatDocRef.update({
        'archivadoPara': FieldValue.arrayRemove([
          uid,
        ]), // uid es el ID del usuario actual
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Chat desarchivado')));
        // No es necesario un setState para moverlo de pestaña, el StreamBuilder lo hará
        // al detectar el cambio en los datos del chat.
      }
      print('Chat $chatId desarchivado para el usuario $uid');
    } catch (e, s) {
      print('Error al desarchivar el chat: ${e.toString()}');
      print('Stack trace: ${s.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al desarchivar el chat: ${e.toString()}'),
          ),
        );
      }
    }
  }

  // Añade estas funciones a tu _ChatHomePageState

  Future<void> _silenciarChat(String chatId) async {
    if (chatId.isEmpty) return;
    final DocumentReference chatDocRef = FirebaseFirestore.instance
        .collection('Chats')
        .doc(chatId);

    try {
      await chatDocRef.update({
        'silenciadoPor': FieldValue.arrayUnion([uid]), // Añade el uid actual
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat silenciado. No recibirás notificaciones.'),
          ),
        );
      }
      // No es necesario un setState para la UI de la lista aquí,
      // el cambio se reflejará en el ícono del PopupMenuButton en la próxima reconstrucción del item.
    } catch (e) {
      print('Error al silenciar el chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al silenciar el chat: ${e.toString()}'),
          ),
        );
      }
    }
  }

  Future<void> _quitarSilencioChat(String chatId) async {
    if (chatId.isEmpty) return;
    final DocumentReference chatDocRef = FirebaseFirestore.instance
        .collection('Chats')
        .doc(chatId);

    try {
      await chatDocRef.update({
        'silenciadoPor': FieldValue.arrayRemove([uid]), // Quita el uid actual
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notificaciones activadas para este chat.'),
          ),
        );
      }
    } catch (e) {
      print('Error al quitar silencio del chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al activar notificaciones: ${e.toString()}'),
          ),
        );
      }
    }
  }

  // Antes era: void _iniciarChat(String otroId) async {
  void _iniciarChat(String otroId, {required bool isLargeScreen}) async {
    // Nueva firma
    final nuevoChatId =
        uid.compareTo(otroId) < 0 ? '${uid}_$otroId' : '${otroId}_$uid';

    await _obtenerUsuario(otroId);

    final DocumentReference chatDocRef = FirebaseFirestore.instance
        .collection('Chats')
        .doc(nuevoChatId);
    final DocumentSnapshot chatDocSnapshot = await chatDocRef.get();

    if (!chatDocSnapshot.exists) {
      await chatDocRef.set({
        'ids': [uid, otroId],
        'isGroup': false,
        'groupName': null,
        'groupPhoto': null,
        'createdBy': null,
        'lastActivityAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'typing': {uid: false, otroId: false},
        'unreadCounts': {uid: 0, otroId: 0},
      });
    } else {
      await chatDocRef.set({
        'ids': [uid, otroId],
        'isGroup': false,
        'lastActivityAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    setState(() {
      filtro = '';
      _busquedaController.clear();
      if (!isLargeScreen) {
        // Solo oculta la lista en pantallas pequeñas
        _showList = false;
      }
      chatIdSeleccionado = nuevoChatId;
      otroUid = otroId; // Aseguramos que otroUid se actualice aquí
    });
  }

  // Reemplaza TODA tu función _enviarMensaje con esta:
  void _enviarMensaje() async {
    // 0. Verificaciones iniciales
    if (chatIdSeleccionado == null || mensaje.trim().isEmpty) return;

    final now = Timestamp.now();
    final String mensajeActual = mensaje.trim();

    // Limpiar UI inmediatamente
    _mensajeController.clear();
    setState(() {
      mensaje = '';
    });

    // 1. Añadir el nuevo mensaje a la subcolección 'Mensajes'
    await FirebaseFirestore.instance
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

    // 2. Preparar la actualización del documento principal del Chat
    final DocumentReference chatDocRef = FirebaseFirestore.instance
        .collection('Chats')
        .doc(chatIdSeleccionado!);
    final DocumentSnapshot chatSnapshot = await chatDocRef.get();

    Map<String, dynamic> chatUpdateData = {
      'typing.$uid': false,
      'lastMessageAt': now,
      'lastMessage': mensajeActual,
    };

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
          // Solo añadir a destinatarios de notificación si no es el usuario actual
          if (!uidsDestinatariosNotificacion.contains(memberId)) {
            uidsDestinatariosNotificacion.add(memberId);
          }
        }
      }
      chatUpdateData['unreadCounts'] = currentUnreadCounts;

      esNotificacionDeGrupo = (chatData['isGroup'] as bool?) ?? false;
      if (esNotificacionDeGrupo) {
        nombreGrupoParaNotificacion = chatData['groupName'] ?? 'el grupo';
        // Los destinatarios de grupo ya se llenaron en el bucle anterior.
      } else {
        // Para chat 1 a 1, aseguramos que el destinatario sea el otro miembro.
        // La lista memberIds debería tener 2 UIDs para un chat 1a1.
        final Iterable<String> otrosIdsFiltrados = memberIds.where(
          (id) => id != uid,
        );
        final String? idOtroDelChat =
            otrosIdsFiltrados.isNotEmpty ? otrosIdsFiltrados.first : null;

        if (idOtroDelChat != null) {
          // Limpiamos y añadimos solo al otro usuario para 1a1
          uidsDestinatariosNotificacion = [idOtroDelChat];
        } else {
          uidsDestinatariosNotificacion =
              []; // Seguridad: no hay otro usuario claro
        }
      }

      final List<dynamic> ocultoParaDinamico =
          chatData['ocultoPara'] as List<dynamic>? ?? [];
      final List<String> ocultoParaLista =
          ocultoParaDinamico.map((item) => item.toString()).toList();

      if (ocultoParaLista.contains(uid)) {
        chatUpdateData['ocultoPara'] = FieldValue.arrayRemove([uid]);
        print(
          "Chat $chatIdSeleccionado des-ocultado para $uid porque envió un mensaje.",
        );
      }
    } else {
      // Documento del chat NO existe (raro si _iniciarChat o creación de grupo funciona bien)
      print(
        "Advertencia: Enviando mensaje a un chatId '$chatIdSeleccionado' que no existe. _iniciarChat debería haberlo creado.",
      );
      if (otroUid != null && otroUid != uid) {
        // Asumimos 1a1 basado en la variable de estado 'otroUid'
        chatUpdateData['ids'] = [uid, otroUid!];
        chatUpdateData['isGroup'] = false;
        chatUpdateData['unreadCounts'] = {otroUid!: 1, uid: 0};
        uidsDestinatariosNotificacion = [otroUid!];
        esNotificacionDeGrupo = false;
      }
      // No se puede determinar 'ocultoPara' aquí si el chat no existe.
    }

    await chatDocRef.set(chatUpdateData, SetOptions(merge: true));

    // 3. Crear notificaciones
    if (nombreUsuario != null && uidsDestinatariosNotificacion.isNotEmpty) {
      for (String destinatarioId in uidsDestinatariosNotificacion) {
        // Asegurarse de no enviar notificación al emisor si por error estuviera en la lista
        if (destinatarioId == uid) continue;

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
          nombreEmisor: nombreUsuario!,
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

  void _confirmarEliminarChat(String chatId, String chatTitle) {
    // ... (el código que ya tienes para esta función)
    showDialog(
      context: context,
      builder: (BuildContext contextDialog) {
        return AlertDialog(
          title: Text('Eliminar Chat "$chatTitle"'),
          content: const Text(
            'Este chat se ocultará de tu lista. No podrás acceder a él a menos que alguien te envíe un nuevo mensaje en esta conversación (lo que podría hacerlo visible de nuevo, dependiendo de la lógica futura).\n\nLos demás participantes seguirán viendo el chat.\n\n¿Estás seguro?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(contextDialog).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(contextDialog).colorScheme.error,
              ),
              child: const Text('Eliminar para mí'),
              onPressed: () {
                Navigator.of(contextDialog).pop();
                _ejecutarEliminarChatParaMi(chatId);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _ejecutarEliminarChatParaMi(String chatId) async {
    // ... (el código que ya tienes para esta función)
    if (chatId.isEmpty)
      return; // Ya tenías una guarda para null/empty, isEmpty es suficiente.

    final DocumentReference chatDocRef = FirebaseFirestore.instance
        .collection('Chats')
        .doc(chatId);

    try {
      await chatDocRef.update({
        'ocultoPara': FieldValue.arrayUnion([uid]),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat eliminado de tu lista.')),
        );
        if (chatIdSeleccionado == chatId) {
          setState(() {
            _showList = true;
            chatIdSeleccionado = null;
            otroUid = null;
          });
        }
      }
      print('Chat $chatId ocultado para el usuario $uid');
    } catch (e, s) {
      print('Error al ocultar el chat: ${e.toString()}');
      print('Stack trace: ${s.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al ocultar el chat: ${e.toString()}')),
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
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 320),
      child: Container(
        color: const Color(0xFF015C8B),
        child: DefaultTabController(
          length: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1) Header “Chats” con iconos ---
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
                      tooltip: "Más opciones",
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.create, color: Colors.white),
                      tooltip: "Nuevo grupo",
                      onPressed: _mostrarDialogoCrearGrupo,
                    ),
                  ],
                ),
              ),

              // --- 2) TabBar ---
              Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                    surfaceVariant:
                        Colors
                            .transparent, // Para que el fondo del indicator sea transparente
                  ),
                ),
                child: TabBar(
                  isScrollable: true,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(
                    0.65,
                  ), // MODIFICADO: Un poco más de opacidad
                  labelStyle: const TextStyle(
                    fontSize: 13.0, // MODIFICADO: Tamaño de fuente reducido
                    fontWeight: FontWeight.bold, // Negrita para la seleccionada
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13.0, // MODIFICADO: Tamaño de fuente reducido
                    fontWeight:
                        FontWeight.w500, // Peso normal para no seleccionada
                  ),
                  indicator: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(
                      0.5,
                    ), // MODIFICADO: Color del indicador
                    borderRadius: BorderRadius.circular(
                      16,
                    ), // MODIFICADO: Radio del borde
                  ),
                  indicatorWeight:
                      0, // Necesario si usas BoxDecoration para el indicador
                  indicatorSize:
                      TabBarIndicatorSize
                          .tab, // El indicador cubre toda la pestaña
                  indicatorPadding: const EdgeInsets.symmetric(
                    vertical: 5.0,
                    horizontal: 4.0,
                  ), // MODIFICADO: Padding del indicador
                  labelPadding: const EdgeInsets.symmetric(
                    horizontal: 11.0,
                  ), // MODIFICADO: Reducido para que quepan más pestañas
                  tabs: const [
                    Tab(text: 'Todos'),
                    Tab(text: 'No leídos'),
                    Tab(text: 'Grupos'),
                    Tab(text: 'Archivados'),
                  ],
                ),
              ),

              // --- 3) Buscador ---
              Container(
                margin: const EdgeInsets.fromLTRB(
                  12,
                  10,
                  12,
                  6,
                ), // Ajustado margen inferior
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).scaffoldBackgroundColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _busquedaController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Buscar chats o usuarios...',
                    hintStyle: TextStyle(
                      color: Colors.black.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.white.withOpacity(0.7),
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 16,
                    ),
                  ),
                  onChanged: (texto) {
                    // ... (tu lógica de debounce onChanged se mantiene igual) ...
                    final lower = texto.trim().toLowerCase();
                    if (filtro != lower) {
                      setState(() {
                        filtro = lower;
                        if (filtro.isNotEmpty) {
                          _isSearchingGlobalUsers = true;
                          _usuarios = [];
                        } else {
                          _isSearchingGlobalUsers = false;
                          _usuarios = [];
                        }
                      });
                    }
                    if (_debounceTimer?.isActive ?? false)
                      _debounceTimer!.cancel();
                    if (filtro.isEmpty) {
                      if (_isSearchingGlobalUsers)
                        setState(() => _isSearchingGlobalUsers = false);
                      return;
                    }
                    _debounceTimer = Timer(_debounceDuration, () async {
                      if (filtro ==
                              _busquedaController.text.trim().toLowerCase() &&
                          mounted) {
                        try {
                          final snap =
                              await FirebaseFirestore.instance
                                  .collection('usuarios')
                                  .get();
                          if (!mounted) return;
                          setState(() {
                            _usuarios =
                                snap.docs.where((u) {
                                  final nombre =
                                      (u['Nombre'] ?? '')
                                          .toString()
                                          .toLowerCase();
                                  return nombre.contains(filtro) && u.id != uid;
                                }).toList();
                            _isSearchingGlobalUsers = false;
                          });
                        } catch (e) {
                          print("Error durante la búsqueda con debounce: $e");
                          if (mounted)
                            setState(() {
                              _isSearchingGlobalUsers = false;
                              _usuarios = [];
                            });
                        }
                      } else if (!mounted) {
                        _debounceTimer?.cancel();
                      }
                    });
                  },
                ),
              ),

              // --- Título para la sección de sugerencias ---
              Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  top: 8.0,
                  bottom: 2.0,
                  right: 16.0,
                ), // Ajustado padding
                child: Text(
                  'Quizás conozcas a...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13.5, // Ligeramente más pequeño
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // --- 4) Carrusel de "Historias" (Sugerencias de Usuarios) ---
              SizedBox(
                height: 90, // Altura para los avatares y nombres
                child: Scrollbar(
                  // Scrollbar para visibilidad en desktop/web
                  thumbVisibility:
                      true, // O false si prefieres que aparezca al hacer scroll
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('usuarios')
                            .snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting &&
                          !snap.hasData) {
                        return const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white54,
                              ),
                            ),
                          ),
                        );
                      }
                      if (!snap.hasData || snap.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            "No hay usuarios",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }

                      var allOtherUsers =
                          snap.data!.docs.where((d) => d.id != uid).toList();
                      if (allOtherUsers.isEmpty) {
                        return const Center(
                          child: Text(
                            "No hay sugerencias.",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }

                      allOtherUsers.shuffle();
                      List<DocumentSnapshot> suggestedUsers =
                          allOtherUsers.take(10).toList();

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ), // Ajustado padding
                        itemCount: suggestedUsers.length,
                        itemBuilder: (contextItemBuilder, i) {
                          final userDoc = suggestedUsers[i];
                          final userData =
                              userDoc.data()! as Map<String, dynamic>;
                          final foto = userData['FotoPerfil'] as String? ?? '';
                          final bool online =
                              (userData['online'] as bool?) ?? false;
                          final nombre =
                              userData['Nombre'] as String? ?? 'Usuario';

                          return GestureDetector(
                            onTap: () {
                              final screenWidth =
                                  MediaQuery.of(contextItemBuilder).size.width;
                              const double tabletBreakpoint = 720.0;
                              final bool currentIsLargeScreen =
                                  screenWidth >= tabletBreakpoint;
                              _iniciarChat(
                                userDoc.id,
                                isLargeScreen: currentIsLargeScreen,
                              );
                            },
                            child: Container(
                              width: 65, // Ancho para cada item
                              margin: const EdgeInsets.symmetric(
                                horizontal: 4.5,
                              ), // Margen entre items
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 26, // Tamaño del avatar
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
                                            padding: const EdgeInsets.all(1.5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF015C8B),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Container(
                                              width: 9,
                                              height:
                                                  9, // Tamaño del indicador online
                                              decoration: BoxDecoration(
                                                color:
                                                    Colors.greenAccent.shade400,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    nombre,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                    textAlign: TextAlign.center,
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
              ),
              const Divider(
                color: Colors.white30,
                height: 1,
                thickness: 0.5,
                indent: 10,
                endIndent: 10,
              ),

              // --- 5) Contenido de cada tab (Lista de Chats) ---
              Expanded(
                child: TabBarView(
                  children: [
                    _chatListStream(
                      filterUnread: false,
                      filterGroups: false,
                      filterArchived: false,
                    ),
                    _chatListStream(
                      filterUnread: true,
                      filterGroups: false,
                      filterArchived: false,
                    ),
                    _chatListStream(
                      filterUnread: false,
                      filterGroups: true,
                      filterArchived: false,
                    ),
                    _chatListStream(
                      filterUnread: false,
                      filterGroups: false,
                      filterArchived: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chatListStream({
    required bool filterUnread,
    required bool filterGroups,
    required bool filterArchived,
  }) {
    // --- CASO 1: HAY TEXTO EN EL FILTRO DE BÚSQUEDA GLOBAL DE USUARIOS ---
    if (filtro.isNotEmpty) {
      if (_isSearchingGlobalUsers) {
        // Muestra Shimmer mientras se buscan usuarios globales
        return ListView.builder(
          itemCount: 7, // Un número arbitrario de shimmers
          itemBuilder: (_, __) => const ShimmerChatTile(),
        );
      } else if (_usuarios.isEmpty) {
        // No se encontraron usuarios con el filtro actual
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'No se encontraron usuarios.',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        );
      } else {
        // Muestra la lista de usuarios encontrados
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: _usuarios.length,
          itemBuilder: (contextListBuilder, i) {
            // Contexto para MediaQuery
            final userDoc = _usuarios[i];
            final userData = userDoc.data() as Map<String, dynamic>? ?? {};
            final nombre = userData['Nombre'] ?? 'Usuario Desconocido';
            // Intenta obtener la foto del caché, si no, usa un placeholder o nada.
            final foto = cacheUsuarios[userDoc.id]?['foto'] ?? '';

            return MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => hoveredUserId = userDoc.id),
              onExit: (_) => setState(() => hoveredUserId = null),
              child: Tooltip(
                message: 'Chatear con $nombre',
                waitDuration: const Duration(milliseconds: 300),
                child: GestureDetector(
                  onTap: () {
                    final screenWidth =
                        MediaQuery.of(contextListBuilder).size.width;
                    const double tabletBreakpoint = 720.0;
                    final bool currentIsLargeScreen =
                        screenWidth >= tabletBreakpoint;
                    _iniciarChat(
                      userDoc.id,
                      isLargeScreen: currentIsLargeScreen,
                    );
                  },
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
                              ? LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.secondary,
                                  Theme.of(context).colorScheme.primaryContainer
                                      .withOpacity(0.7),
                                ],
                              )
                              : null,
                      color:
                          hoveredUserId != userDoc.id
                              ? Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.8)
                              : null, // Color base si no hay hover
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color:
                              hoveredUserId == userDoc.id
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.secondary.withOpacity(0.5)
                                  : Colors.black.withOpacity(0.15),
                          blurRadius: hoveredUserId == userDoc.id ? 10 : 5,
                          offset: const Offset(0, 3),
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
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                nombre,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Iniciar nueva conversación',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.white70),
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
                .where(
                  'ids',
                  arrayContains: uid,
                ) // Solo chats donde el usuario actual es miembro
                .orderBy('lastMessageAt', descending: true)
                .snapshots(),
        builder: (contextStreamBuilder, chatSnapshot) {
          if (chatSnapshot.connectionState == ConnectionState.waiting &&
              !chatSnapshot.hasData) {
            return ListView.builder(
              itemCount: 7,
              itemBuilder: (_, __) => const ShimmerChatTile(),
            );
          }

          if (!chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty) {
            String mensajeVacio = 'Inicia una conversación o crea un grupo';
            if (filterArchived)
              mensajeVacio = 'No tienes chats archivados';
            else if (filterUnread)
              mensajeVacio = 'No tienes mensajes no leídos';
            else if (filterGroups)
              mensajeVacio = 'No estás en ningún grupo aún';
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  mensajeVacio,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          List<DocumentSnapshot> chatsExistentes = chatSnapshot.data!.docs;
          List<DocumentSnapshot> chatsVisibles =
              chatsExistentes.where((chatDoc) {
                final data = chatDoc.data() as Map<String, dynamic>?;
                if (data == null) return false;

                final List<String> ocultoPorLista = List<String>.from(
                  data['ocultoPara'] ?? [],
                );
                if (ocultoPorLista.contains(uid)) return false;

                final List<String> archivadoPorLista = List<String>.from(
                  data['archivadoPara'] ?? [],
                );
                final bool estaArchivadoPorUsuarioActual = archivadoPorLista
                    .contains(uid);

                if (filterArchived)
                  return estaArchivadoPorUsuarioActual;
                else {
                  if (estaArchivadoPorUsuarioActual) return false;
                  final bool esUnGrupo = (data['isGroup'] as bool?) ?? false;
                  final Map<String, dynamic> unreadMap =
                      (data['unreadCounts'] as Map<String, dynamic>?) ?? {};
                  final int contadorNoLeidos = (unreadMap[uid] as int?) ?? 0;

                  if (filterGroups && !esUnGrupo)
                    return false; // Si filtramos por grupos y no es grupo, no mostrar
                  if (filterUnread && contadorNoLeidos == 0)
                    return false; // Si filtramos por no leídos y no hay, no mostrar
                  return true; // Cumple con los filtros o no hay filtros específicos (pestaña "Todos")
                }
              }).toList();

          if (chatsVisibles.isEmpty) {
            String mensajeVacioFiltrado =
                'No hay conversaciones para mostrar aquí';
            if (filterArchived)
              mensajeVacioFiltrado = 'No tienes chats archivados';
            else if (filterUnread)
              mensajeVacioFiltrado =
                  'No tienes mensajes no leídos en esta vista';
            else if (filterGroups)
              mensajeVacioFiltrado = 'No hay grupos para mostrar en esta vista';
            else if (chatsExistentes.isNotEmpty)
              mensajeVacioFiltrado =
                  'Todos tus chats están ocultos o archivados'; // Para la pestaña "Todos" si todo está filtrado por otras condiciones
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  mensajeVacioFiltrado,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: chatsVisibles.length,
            itemBuilder: (contextItemBuilder, idx) {
              // Contexto para MediaQuery
              final chatDoc = chatsVisibles[idx];
              final data = chatDoc.data()! as Map<String, dynamic>;
              final List<dynamic> idsDynamic = data['ids'] ?? [];
              final List<String> idsParticipantes = List<String>.from(
                idsDynamic,
              );
              final bool isGroup = (data['isGroup'] as bool?) ?? false;
              final String chatId = chatDoc.id;

              String? otherIdForChat;
              if (!isGroup) {
                otherIdForChat = idsParticipantes.firstWhere(
                  (id) => id != uid,
                  orElse: () => '',
                );
                if (otherIdForChat.isNotEmpty &&
                    !cacheUsuarios.containsKey(otherIdForChat)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _obtenerUsuario(otherIdForChat!);
                  });
                }
              }

              final String preview =
                  (data['lastMessage'] as String?)?.trim().isNotEmpty == true
                      ? data['lastMessage'] as String
                      : isGroup
                      ? '${cacheUsuarios[data['createdBy']]?['nombre'] ?? "Alguien"} creó el grupo'
                      : 'Inicia la conversación';

              String calculatedTitle;
              String? calculatedPhotoUrl;

              if (isGroup) {
                calculatedTitle = (data['groupName'] ?? 'Grupo').toString();
                calculatedPhotoUrl = data['groupPhoto'] as String?;
              } else {
                if (otherIdForChat != null && otherIdForChat.isNotEmpty) {
                  final cachedUserData = cacheUsuarios[otherIdForChat];
                  if (cachedUserData != null) {
                    calculatedTitle =
                        cachedUserData['nombre'] ?? 'Nombre no disponible';
                    calculatedPhotoUrl = cachedUserData['foto'] ?? '';
                  } else {
                    calculatedTitle =
                        'Cargando...'; // Usuario aún no cargado en caché
                    calculatedPhotoUrl = ''; // Sin foto mientras carga
                  }
                } else {
                  calculatedTitle =
                      'Chat Individual'; // Fallback si otherIdForChat es inválido
                  calculatedPhotoUrl = '';
                }
              }

              final String title = calculatedTitle;
              final String? photoUrl = calculatedPhotoUrl;
              // ----- FIN DE LÓGICA CORREGIDA Y DESGLOSADA -----

              if (!isGroup &&
                  (otherIdForChat == null ||
                      otherIdForChat.isEmpty ||
                      title == 'Cargando...')) {
                return const ShimmerChatTile(); // Muestra shimmer si la info del otro user aún no está
              }

              final String hora =
                  data['lastMessageAt'] != null
                      ? DateFormat.Hm().format(
                        (data['lastMessageAt'] as Timestamp).toDate(),
                      )
                      : '';
              final unreadMap =
                  (data['unreadCounts'] as Map<String, dynamic>?) ?? {};
              final int unreadCount = (unreadMap[uid] as int?) ?? 0;
              final List<String> archivadoPorItem = List<String>.from(
                data['archivadoPara'] ?? [],
              );
              final bool estaArchivadoItem = archivadoPorItem.contains(uid);
              final List<String> silenciadoPorItem = List<String>.from(
                data['silenciadoPor'] ?? [],
              );
              final bool estaSilenciadoItem = silenciadoPorItem.contains(uid);

              return ValueListenableBuilder<String?>(
                valueListenable: hoveredChatId,
                builder: (context, hoveredValue, _) {
                  final isHovered = hoveredValue == chatId;
                  return MouseRegion(
                    onEnter: (_) => hoveredChatId.value = chatId,
                    onExit: (_) => hoveredChatId.value = null,
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        if (chatId.isNotEmpty &&
                            uid.isNotEmpty &&
                            !estaArchivadoItem &&
                            unreadCount > 0) {
                          FirebaseFirestore.instance
                              .collection('Chats')
                              .doc(chatId)
                              .update({'unreadCounts.$uid': 0})
                              .catchError(
                                (e) => print(
                                  "Error al actualizar unreadCounts para $chatId: $e",
                                ),
                              );
                        }

                        final screenWidth =
                            MediaQuery.of(contextItemBuilder).size.width;
                        const double tabletBreakpoint = 720.0;
                        final bool currentIsLargeScreen =
                            screenWidth >= tabletBreakpoint;

                        if (isGroup) {
                          setState(() {
                            chatIdSeleccionado = chatId;
                            otroUid =
                                null; // Para grupos, otroUid no es relevante
                            if (!currentIsLargeScreen) {
                              _showList = false;
                            }
                          });
                        } else {
                          if (otherIdForChat != null &&
                              otherIdForChat.isNotEmpty) {
                            _iniciarChat(
                              otherIdForChat,
                              isLargeScreen: currentIsLargeScreen,
                            );
                          }
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
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer
                                  : const Color(
                                    0xFF015C8B,
                                  ), // Ajusta colores de hover
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  isHovered
                                      ? Theme.of(
                                        context,
                                      ).colorScheme.shadow.withOpacity(0.4)
                                      : Colors.black26.withOpacity(0.15),
                              blurRadius: isHovered ? 8 : 4,
                              offset: Offset(0, isHovered ? 3 : 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    title,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    preview,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  hora,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (unreadCount > 0 && !estaArchivadoItem)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.error,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                    if (estaSilenciadoItem &&
                                        !estaArchivadoItem) // Mostrar icono de silencio si no está archivado
                                      Padding(
                                        padding: EdgeInsets.only(
                                          left: unreadCount > 0 ? 4.0 : 0.0,
                                        ), // Espacio si hay contador
                                        child: Icon(
                                          Icons.notifications_off,
                                          color: Colors.white54,
                                          size: 16,
                                        ),
                                      ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(
                                        Icons.more_vert,
                                        color: Colors.white70,
                                        size: 20,
                                      ),
                                      tooltip: "Más opciones",
                                      color:
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.grey[800]
                                              : Colors
                                                  .white, // Ajustar color del menú
                                      onSelected: (value) {
                                        if (value == 'archivar')
                                          _archivarChat(chatId);
                                        else if (value == 'desarchivar')
                                          _desarchivarChat(chatId);
                                        else if (value == 'silenciar')
                                          _silenciarChat(chatId);
                                        else if (value == 'quitar_silencio')
                                          _quitarSilencioChat(chatId);
                                        else if (value == 'eliminar')
                                          _confirmarEliminarChat(chatId, title);
                                      },
                                      itemBuilder: (BuildContext popupContext) {
                                        List<PopupMenuEntry<String>> items = [];
                                        if (estaArchivadoItem) {
                                          items.add(
                                            const PopupMenuItem(
                                              value: 'desarchivar',
                                              child: Text('Desarchivar chat'),
                                            ),
                                          );
                                        } else {
                                          items.add(
                                            const PopupMenuItem(
                                              value: 'archivar',
                                              child: Text('Archivar chat'),
                                            ),
                                          );
                                        }
                                        if (estaSilenciadoItem) {
                                          items.add(
                                            const PopupMenuItem(
                                              value: 'quitar_silencio',
                                              child: Text('Activar sonido'),
                                            ),
                                          );
                                        } else {
                                          items.add(
                                            const PopupMenuItem(
                                              value: 'silenciar',
                                              child: Text('Silenciar'),
                                            ),
                                          );
                                        }
                                        items.add(const PopupMenuDivider());
                                        items.add(
                                          PopupMenuItem(
                                            value: 'eliminar',
                                            child: Text(
                                              'Eliminar chat',
                                              style: TextStyle(
                                                color:
                                                    Theme.of(
                                                      popupContext,
                                                    ).colorScheme.error,
                                              ),
                                            ),
                                          ),
                                        );
                                        return items;
                                      },
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

  // Antes era: Widget _buildChatHeader() {
  Widget _buildChatHeader({required bool isLargeScreen}) {
    // Nueva firma
    return Container(
      color: const Color(0xFF048DD2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // ---- INICIO: Lógica condicional para el botón de Atrás ----
          if (!isLargeScreen) // Solo muestra el botón si NO es pantalla grande
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                // En pantalla pequeña, este botón siempre te lleva de vuelta a la lista.
                setState(() {
                  _showList = true;
                  chatIdSeleccionado = null;
                  otroUid = null;
                });
              },
            ),
          if (!isLargeScreen) // Solo muestra el SizedBox si el botón de atrás está presente
            const SizedBox(width: 10),
          // ---- FIN: Lógica condicional para el botón de Atrás ----

          // El resto del contenido del Header
          if (chatIdSeleccionado != null)
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('Chats')
                        .doc(chatIdSeleccionado!)
                        .snapshots(),
                builder: (context, chatSnap) {
                  if (!chatSnap.hasData && otroUid == null) {
                    // Si no hay datos Y no estamos iniciando un nuevo chat 1a1
                    // En pantalla grande y sin chat seleccionado, mostrar placeholder
                    if (isLargeScreen) {
                      return const Text(
                        'Selecciona un chat',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      );
                    }
                    // En pantalla pequeña (o si hay error cargando), un loader simple
                    return const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    );
                  }

                  if (chatSnap.hasData && chatSnap.data?.data() != null) {
                    final chatData =
                        chatSnap.data!.data() as Map<String, dynamic>;
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
                      final Iterable<String> otrosIdsFiltrados =
                          idsParticipantes.where((id) => id != uid);
                      final String? idOtroUsuarioDelChat =
                          otrosIdsFiltrados.isNotEmpty
                              ? otrosIdsFiltrados.first
                              : null;

                      if (idOtroUsuarioDelChat != null) {
                        // Actualizar otroUid si es diferente y estamos en un chat 1a1 ya cargado
                        if (otroUid != idOtroUsuarioDelChat) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                otroUid = idOtroUsuarioDelChat;
                              });
                            }
                          });
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
                    // Si estamos iniciando un nuevo chat 1a1 y el stream del chat aún no tiene datos
                    return _buildHeaderInfoUsuario(otroUid!);
                  }

                  // Fallback general (puede ser un loader o un placeholder si estamos en pantalla grande)
                  return Expanded(
                    child:
                        (isLargeScreen && chatIdSeleccionado == null)
                            ? const Text(
                              'Selecciona un chat',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            )
                            : const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                  );
                },
              ),
            )
          else // Si chatIdSeleccionado es null (esto se mostrará en pantalla grande antes de seleccionar un chat)
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
  // Dentro de tu clase _ChatHomePageState

  Widget _buildMessagesStream() {
    // Asegurarnos de que chatIdSeleccionado no sea null antes de construir el stream
    if (chatIdSeleccionado == null) {
      return const Center(
        child: Text("Selecciona un chat para ver los mensajes."),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('Chats')
              .doc(
                chatIdSeleccionado,
              ) // No necesita '!' si ya verificamos arriba
              .collection('Mensajes')
              .orderBy(
                'Fecha',
              ) // Ordena por fecha, la lista se invierte luego para visualización
              .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Aún no hay mensajes en este chat. ¡Sé el primero en enviar uno!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          );
        }

        // --- INICIO: LÓGICA PARA MARCAR MENSAJES COMO LEÍDOS Y LIMPIAR TYPING DEL OTRO (OPCIONAL) ---
        // (Esta parte la tenías antes, la mantenemos y revisamos)
        List<Future<void>> updateFutures =
            []; // Para agrupar las actualizaciones de 'leidoPor'

        for (var doc in snap.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final autorIdMensaje = data['AutorID'] as String?;

          // Marcar como leído
          if (autorIdMensaje != null && autorIdMensaje != uid) {
            final leidoPor = List<String>.from(data['leidoPor'] ?? []);
            if (!leidoPor.contains(uid)) {
              updateFutures.add(
                doc.reference.update({
                  'leidoPor': FieldValue.arrayUnion([uid]),
                }),
              );
            }
          }

          // Opcional: Limpiar "está escribiendo..." del otro usuario si este mensaje es de él
          // (Como lo discutimos para el bug del indicador de "escribiendo" atascado)
          if (otroUid != null &&
              autorIdMensaje == otroUid &&
              chatIdSeleccionado != null) {
            // Verificamos el estado actual antes de escribir para evitar escrituras innecesarias
            FirebaseFirestore.instance
                .collection('Chats')
                .doc(chatIdSeleccionado!)
                .get()
                .then((chatDocSnap) {
                  if (chatDocSnap.exists) {
                    final chatDataTyping =
                        chatDocSnap.data() as Map<String, dynamic>;
                    final typingMap =
                        chatDataTyping['typing'] as Map<String, dynamic>? ?? {};
                    if (typingMap[otroUid!] == true) {
                      // Solo actualiza si realmente estaba en true
                      FirebaseFirestore.instance
                          .collection('Chats')
                          .doc(chatIdSeleccionado!)
                          .update({'typing.$otroUid': false})
                          .catchError(
                            (e) => print(
                              "Error al limpiar typing del otro al recibir mensaje: $e",
                            ),
                          );
                    }
                  }
                });
          }
        }
        // Si quieres esperar a que todas las actualizaciones de 'leidoPor' terminen antes de construir la lista (raro, puede ser lento)
        // Podrías usar Future.wait(updateFutures).then((_) { /* construir lista */ });
        // Pero usualmente dejar que se actualicen en segundo plano está bien para 'leidoPor'.
        // --- FIN: LÓGICA PARA MARCAR MENSAJES COMO LEÍDOS Y LIMPIAR TYPING ---

        final List<DocumentSnapshot> inv = snap.data!.docs.reversed.toList();

        // Auto-scroll al final (o al principio, ya que está invertida)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients &&
              _scrollController.position.maxScrollExtent > 0) {
            // Solo si hay contenido para scrollear
            _scrollController.animateTo(
              0.0, // Al principio de la lista invertida (últimos mensajes)
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        return ListView.builder(
          controller: _scrollController,
          reverse:
              true, // Fundamental para que los mensajes nuevos aparezcan abajo y el scroll sea natural
          padding: const EdgeInsets.all(12.0),
          itemCount: inv.length,
          itemBuilder: (context, i) {
            final docMsg = inv[i];
            final dataMsg = docMsg.data() as Map<String, dynamic>;
            final bool esMio = dataMsg['AutorID'] == uid;
            final Timestamp fechaTimestamp =
                dataMsg['Fecha'] as Timestamp? ??
                Timestamp.now(); // Default a now() si es null
            final DateTime fecha = fechaTimestamp.toDate();

            bool showDateSeparator = false;
            if (i == inv.length - 1) {
              // Es el mensaje más antiguo en la lista (el primero después de invertir)
              showDateSeparator = true;
            } else {
              final Timestamp nextTs =
                  (inv[i + 1].data() as Map<String, dynamic>)['Fecha']
                      as Timestamp? ??
                  Timestamp.now();
              final DateTime d1 = fecha;
              final DateTime d2 = nextTs.toDate();
              showDateSeparator =
                  d1.year != d2.year ||
                  d1.month != d2.month ||
                  d1.day != d2.day;
            }

            final List<String> leidoPor = List<String>.from(
              dataMsg['leidoPor'] ?? [],
            );
            final bool readByPeer =
                otroUid != null && leidoPor.contains(otroUid!);

            final String? autorId = dataMsg['AutorID'] as String?;
            Map<String, String>? autorInfo =
                autorId != null ? cacheUsuarios[autorId] : null;

            if (autorId != null &&
                autorId != 'sistema' &&
                autorInfo == null &&
                mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !cacheUsuarios.containsKey(autorId)) {
                  _obtenerUsuario(autorId);
                }
              });
            }

            final String nombreAutorParaMostrar =
                autorInfo?['nombre'] ??
                (autorId == 'sistema'
                    ? '' // Los mensajes del sistema no suelen mostrar nombre de autor
                    : (autorId == uid
                        ? (nombreUsuario ?? 'Tú')
                        : 'Cargando...')); // Muestra 'Cargando...' si no está en caché

            final String? urlAvatarParaMostrar = autorInfo?['foto'];

            final bool estaCargandoInfoAutor =
                autorId != null &&
                autorId != 'sistema' &&
                autorId !=
                    uid && // No mostrar "cargando" para mis propios mensajes
                autorInfo == null;

            final int totalMensajes = inv.length;
            final bool showName =
                (dataMsg['isGroup'] == true &&
                    !esMio && // Solo para mensajes de otros en grupos
                    (i ==
                            totalMensajes -
                                1 || // Primer mensaje del bloque de ese autor
                        (i < totalMensajes - 1 &&
                            (inv[i + 1].data()
                                    as Map<String, dynamic>)['AutorID'] !=
                                autorId))) ||
                // O si el mensaje anterior es de un autor diferente o es un separador de fecha (si es el primer mensaje después del separador)
                (i > 0 &&
                    showDateSeparator &&
                    !esMio &&
                    dataMsg['isGroup'] == true) ||
                (i > 0 &&
                    !esMio &&
                    dataMsg['isGroup'] == true &&
                    (inv[i - 1].data() as Map<String, dynamic>)['AutorID'] !=
                        autorId &&
                    !showDateSeparator);

            return Column(
              crossAxisAlignment:
                  esMio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (showDateSeparator)
                  DateSeparator(fecha), // Tu widget DateSeparator

                if (estaCargandoInfoAutor) // No esMio ya está implícito en la definición de estaCargandoInfoAutor
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 4.0,
                      horizontal: esMio ? 0 : 8.0,
                    ),
                    child: Align(
                      alignment:
                          Alignment
                              .centerLeft, // Los mensajes de otros siempre a la izquierda
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              Colors.grey[200], // Un color de burbuja de carga
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '...',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  ChatBubbleCustom(
                    // Tu widget ChatBubbleCustom
                    isMine: esMio,
                    read: readByPeer,
                    avatarUrl:
                        urlAvatarParaMostrar ??
                        '', // Pasa string vacío como fallback si tu ChatBubble no maneja null
                    authorName: nombreAutorParaMostrar,
                    text:
                        dataMsg['Contenido'] as String? ??
                        '', // Manejar contenido null
                    time: fecha,
                    edited: dataMsg['editado'] as bool? ?? false,
                    deleted: dataMsg['eliminado'] as bool? ?? false,
                    reactions: Map<String, int>.from(
                      dataMsg['reacciones'] ?? {},
                    ),
                    showName:
                        showName &&
                        nombreAutorParaMostrar.isNotEmpty &&
                        nombreAutorParaMostrar !=
                            'Cargando...', // Solo mostrar nombre si es relevante
                    onEdit:
                        esMio
                            ? () => _editarMensaje(
                              docMsg.id,
                              dataMsg['Contenido'],
                              fechaTimestamp,
                            )
                            : null,
                    onDelete: esMio ? () => _eliminarMensaje(docMsg.id) : null,
                    onReact: () => _reaccionarMensaje(docMsg.id),
                    // Asegúrate que ChatBubbleCustom puede manejar avatarUrl vacío y authorName como "Cargando..." o ""
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
  Widget _buildChatDetail({required bool isLargeScreen}) {
    // Nueva firma
    return Expanded(
      flex: 3,
      child: Column(
        children: [
          _buildChatHeader(isLargeScreen: isLargeScreen), // Pasa isLargeScreen
          if (chatIdSeleccionado != null) _buildTypingIndicator(),
          Expanded(child: _buildMessagesStream()),
          if (chatIdSeleccionado != null) _buildInputBox(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const double tabletBreakpoint = 720.0; // Puedes ajustar este valor
    final bool isLargeScreen = screenWidth >= tabletBreakpoint;

    return Scaffold(
      // Tu CustomAppBar se mantiene igual
      appBar: const CustomAppBar(showBack: true),
      body:
          isLargeScreen
              ? Row(
                // Diseño para Pantalla Grande
                children: [
                  _buildChatList(), // El panel de lista de chats
                  const VerticalDivider(
                    thickness: 1,
                    width: 1,
                  ), // Un separador visual
                  // El panel de detalle del chat, necesita isLargeScreen para su cabecera
                  _buildChatDetail(isLargeScreen: true),
                ],
              )
              : Row(
                // Diseño para Pantalla Pequeña
                // Usamos un Row y Expanded para asegurar que el widget visible ocupe todo el espacio
                children: [
                  if (_showList) // Si debemos mostrar la lista de chats
                    Expanded(child: _buildChatList()),
                  if (!_showList) // Si debemos mostrar el detalle del chat
                    // El panel de detalle del chat, necesita isLargeScreen para su cabecera
                    _buildChatDetail(isLargeScreen: false),
                ],
              ),
    );
  }
}
