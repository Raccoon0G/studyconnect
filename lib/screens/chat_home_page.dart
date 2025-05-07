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
  bool _isTyping = false;
  String filtro = '';

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
    });
  }

  String _formatearHora(Timestamp timestamp) {
    final dt = timestamp.toDate();
    return DateFormat.Hm().format(dt);
  }

  Future<Map<String, String>> _obtenerUsuario(String usuarioId) async {
    if (cacheUsuarios.containsKey(usuarioId)) return cacheUsuarios[usuarioId]!;
    final doc =
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(usuarioId)
            .get();
    final nombre = doc['Nombre'] ?? 'Usuario';
    final foto = doc['FotoPerfil'] ?? '';
    final userInfo = {'nombre': nombre, 'foto': foto};
    cacheUsuarios[usuarioId] = userInfo.cast<String, String>();
    return userInfo.cast<String, String>();
  }

  void _iniciarChat(String otroId) async {
    // 1) Creamos el chatId ordenado
    final nuevoChatId =
        uid.compareTo(otroId) < 0 ? '${uid}_$otroId' : '${otroId}_$uid';
    // 2) Precargamos datos del otro usuario en caché
    await _obtenerUsuario(otroId);

    // ── BONUS: creamos/mergeamos el documento Chats/{chatId}
    await FirebaseFirestore.instance.collection('Chats').doc(nuevoChatId).set({
      'ids': [uid, otroId],
      'UltimaAct': FieldValue.serverTimestamp(),
      'typing': {uid: false, otroId: false},
    }, SetOptions(merge: true));

    // 3) Disparamos el cambio de chat
    setState(() {
      filtro = ''; // reset del filtro
      _busquedaController.clear(); // limpiamos la caja de texto
      chatIdSeleccionado = nuevoChatId;
      otroUid = otroId;
    });
  }

  void _enviarMensaje() async {
    if (chatIdSeleccionado == null || mensaje.trim().isEmpty) return;

    // 1) Creamos un timestamp único para usarlo en mensaje y chat
    final now = Timestamp.now();

    // 2) Añadimos el mensaje con esa fecha
    await FirebaseFirestore.instance
        .collection('Chats')
        .doc(chatIdSeleccionado)
        .collection('Mensajes')
        .add({
          'AutorID': uid,
          'Contenido': mensaje.trim(),
          'Fecha': now, // <-- usamos now aquí
          'reacciones': {},
          'editado': false,
          'eliminado': false,
          'leidoPor': [uid],
        });

    // 3) Actualizamos el documento de chat con lastMessageAt
    await FirebaseFirestore.instance
        .collection('Chats')
        .doc(chatIdSeleccionado)
        .update({
          'typing.$uid': false,
          'lastMessageAt': now, // <-- nuevo campo
        });

    // Crear notificación para el receptor
    if (otroUid != null && otroUid != uid) {
      await NotificationService.crearNotificacion(
        uidDestino: otroUid!,
        tipo: 'mensaje',
        titulo: 'Nuevo mensaje de $nombreUsuario',
        contenido:
            mensaje.trim().length > 40
                ? '${mensaje.trim().substring(0, 40)}...'
                : mensaje.trim(),
        referenciaId: chatIdSeleccionado!,
        uidEmisor: uid,
        nombreEmisor: nombreUsuario ?? 'Usuario',
      );
    }

    _mensajeController.clear();
    setState(() => mensaje = '');

    // ── AUTO‐SCROLL TRAS ENVÍO ──
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF048DD2),
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 8),
            Image.asset('assets/images/logo_ipn.png', height: 32),
            const SizedBox(width: 8),
            const Text(
              'Study Connect',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/'),
            child: const Text('Inicio', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/ranking'),
            child: const Text('Ranking', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/content'),
            child: const Text(
              'Contenidos',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const NotificationIconWidget(),
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/user_profile'),
            icon: const Icon(Icons.person, color: Colors.white),
            label: const Text('Perfil', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 10),
        ],
      ),

      body: Row(
        children: [
          // ─── Panel izquierdo ───
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.lightBlue.shade300,
              child: Column(
                children: [
                  // 1) Barra de búsqueda
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _busquedaController,
                      decoration: const InputDecoration(
                        hintText: 'Buscar...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (texto) async {
                        final lower = texto.trim().toLowerCase();
                        setState(() => filtro = lower);

                        if (filtro.isNotEmpty) {
                          // Buscamos sólo usuarios
                          final snapshot =
                              await FirebaseFirestore.instance
                                  .collection('usuarios')
                                  .get();
                          setState(() {
                            _usuarios =
                                snapshot.docs.where((u) {
                                  final nombre =
                                      (u['Nombre'] ?? '')
                                          .toString()
                                          .toLowerCase();
                                  return nombre.contains(filtro) && u.id != uid;
                                }).toList();
                          });
                        }
                      },
                    ),
                  ),

                  // 2) Lista de resultados
                  Expanded(
                    child:
                        filtro.isNotEmpty
                            // —— MOSTRAR USUARIOS FILTRADOS ——
                            ? (_usuarios.isEmpty
                                ? const Center(
                                  child: Text('No se encontraron usuarios'),
                                )
                                : ListView(
                                  children:
                                      _usuarios.map((userDoc) {
                                        final nombre =
                                            userDoc['Nombre'] ?? 'Usuario';
                                        return ListTile(
                                          leading: const Icon(Icons.person),
                                          title: Text(nombre),
                                          onTap: () => _iniciarChat(userDoc.id),
                                        );
                                      }).toList(),
                                ))
                            // —— MOSTRAR LISTA DE CHATS ——
                            : StreamBuilder<QuerySnapshot>(
                              stream:
                                  FirebaseFirestore.instance
                                      .collection('Chats')
                                      .where('ids', arrayContains: uid)
                                      .orderBy(
                                        'lastMessageAt',
                                        descending: true,
                                      )
                                      .snapshots(),
                              builder: (context, snap) {
                                if (snap.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (!snap.hasData || snap.data!.docs.isEmpty) {
                                  return const Center(
                                    child: Text('Sin conversaciones'),
                                  );
                                }

                                final chats = snap.data!.docs;

                                // 1) Precargar en caché datos de "otros"
                                for (var chatDoc in chats) {
                                  final ids = List<String>.from(
                                    (chatDoc.data()! as Map)['ids'] ?? [],
                                  );
                                  final other = ids.firstWhere((m) => m != uid);
                                  if (!cacheUsuarios.containsKey(other)) {
                                    _obtenerUsuario(other);
                                  }
                                }

                                // 2) Renderizar
                                return ListView.builder(
                                  itemCount: chats.length,
                                  itemBuilder: (context, idx) {
                                    final chatDoc = chats[idx];
                                    final data =
                                        chatDoc.data()! as Map<String, dynamic>;
                                    final ids = List<String>.from(
                                      data['ids'] ?? [],
                                    );
                                    final other = ids.firstWhere(
                                      (m) => m != uid,
                                    );
                                    final ts =
                                        data['lastMessageAt'] as Timestamp?;
                                    final hora =
                                        ts == null
                                            ? ''
                                            : DateFormat.Hm().format(
                                              ts.toDate(),
                                            );

                                    final userInfo = cacheUsuarios[other];
                                    final nombre =
                                        userInfo?['nombre'] ?? 'Cargando…';
                                    final foto = userInfo?['foto'] ?? '';

                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundImage:
                                            foto.isNotEmpty
                                                ? NetworkImage(foto)
                                                : const AssetImage(
                                                      'assets/images/avatar1.png',
                                                    )
                                                    as ImageProvider,
                                      ),
                                      title: Text(nombre),
                                      subtitle: Text(hora),
                                      onTap:
                                          userInfo == null
                                              ? null
                                              : () => _iniciarChat(other),
                                    );
                                  },
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            //Panel Derecho
            flex: 3,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  color: const Color(0xFF048DD2),
                  child:
                      otroUid == null
                          ? const Text(
                            'Selecciona un chat',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          )
                          : FutureBuilder<DocumentSnapshot>(
                            future:
                                FirebaseFirestore.instance
                                    .collection('usuarios')
                                    .doc(otroUid!)
                                    .get(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const CircularProgressIndicator(
                                  color: Colors.white,
                                );
                              }

                              final data =
                                  snapshot.data!.data()!
                                      as Map<String, dynamic>;
                              final nombre =
                                  data['Nombre'] as String? ?? 'Usuario';
                              final foto = data['FotoPerfil'] as String? ?? '';

                              // 1) Sacamos online
                              final online = (data['online'] as bool?) == true;

                              // 2) Leemos 'ultimaConexion' del usuario
                              final ts = data['ultimaConexion'] as Timestamp?;
                              final ultimaConexionStr =
                                  ts != null
                                      ? _formatearHora(ts)
                                      : 'hace un momento';

                              return Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundImage:
                                        foto.isNotEmpty
                                            ? NetworkImage(foto)
                                            : const AssetImage(
                                                  'assets/images/avatar1.png',
                                                )
                                                as ImageProvider,
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nombre,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        online
                                            ? '🟢 En línea'
                                            : 'Últ. conexión: $ultimaConexionStr',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                ),
                if (chatIdSeleccionado != null)
                  StreamBuilder<DocumentSnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('Chats')
                            .doc(chatIdSeleccionado)
                            .snapshots(),
                    builder: (context, snap) {
                      // 1) Si no hay Snapshot aún, o no hay peer, o el doc no existe/no tiene data
                      if (!snap.hasData ||
                          otroUid == null ||
                          !snap.data!.exists ||
                          snap.data!.data() == null) {
                        return const SizedBox.shrink();
                      }

                      // 2) Ahora SÍ tenemos un Map<String,dynamic>
                      final dataMap =
                          snap.data!.data()! as Map<String, dynamic>;

                      // 3) Extraemos typing con fallback a {}
                      final typingMap =
                          (dataMap['typing'] as Map<String, dynamic>?) ?? {};
                      final otherTyping = typingMap[otroUid] == true;

                      if (!otherTyping) return const SizedBox.shrink();

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 6.0,
                          horizontal: 12.0,
                        ),
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
                  ),
                Expanded(
                  child:
                      chatIdSeleccionado == null
                          ? const Center(
                            child: Text('Selecciona un usuario para chatear'),
                          )
                          : StreamBuilder<QuerySnapshot>(
                            stream:
                                FirebaseFirestore.instance
                                    .collection('Chats')
                                    .doc(chatIdSeleccionado)
                                    .collection('Mensajes')
                                    .orderBy('Fecha')
                                    .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              // 0) Marcar como leídos los mensajes que NO SON MÍOS
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                final docs = snapshot.data!.docs;
                                for (final doc in docs) {
                                  final data =
                                      doc.data()! as Map<String, dynamic>;
                                  final autor = data['AutorID'] as String;
                                  if (autor == uid)
                                    continue; // solo marcamos los de él
                                  final leidoPor = List<String>.from(
                                    data['leidoPor'] ?? [],
                                  );
                                  if (!leidoPor.contains(uid)) {
                                    FirebaseFirestore.instance
                                        .collection('Chats')
                                        .doc(chatIdSeleccionado)
                                        .collection('Mensajes')
                                        .doc(doc.id)
                                        .update({
                                          'leidoPor': FieldValue.arrayUnion([
                                            uid,
                                          ]),
                                        });
                                  }
                                }
                              });

                              // 1) Preparamos lista ascendente/invertida
                              final asc = snapshot.data!.docs;
                              final inv = asc.reversed.toList();

                              return ListView.builder(
                                controller: _scrollController,
                                reverse: true,
                                padding: const EdgeInsets.all(12),
                                itemCount: inv.length,
                                itemBuilder: (context, i) {
                                  final ascIndex = asc.length - 1 - i;
                                  final doc = inv[i];
                                  final data =
                                      doc.data() as Map<String, dynamic>;

                                  // Campos básicos
                                  final esMio = data['AutorID'] == uid;
                                  final texto =
                                      data['Contenido'] as String? ?? '';
                                  final fecha =
                                      (data['Fecha'] as Timestamp).toDate();
                                  final editado =
                                      data['editado'] as bool? ?? false;
                                  final eliminado =
                                      data['eliminado'] as bool? ?? false;
                                  final reacciones = Map<String, int>.from(
                                    data['reacciones']
                                            as Map<String, dynamic>? ??
                                        {},
                                  );

                                  // 2) ¿Mostrar nombre?
                                  final total = inv.length;
                                  final showName =
                                      i == total - 1 ||
                                      (i < total - 1 &&
                                          (inv[i + 1].data()
                                                  as Map<
                                                    String,
                                                    dynamic
                                                  >)['AutorID'] !=
                                              data['AutorID']);

                                  // 3) Separador de fecha
                                  bool showDateSeparator = false;
                                  if (ascIndex == 0) {
                                    showDateSeparator = true;
                                  } else {
                                    final curr =
                                        (asc[ascIndex].data() as Map)['Fecha']
                                            as Timestamp;
                                    final prev =
                                        (asc[ascIndex - 1].data()
                                                as Map)['Fecha']
                                            as Timestamp;
                                    final cd = curr.toDate();
                                    final pd = prev.toDate();
                                    showDateSeparator =
                                        cd.year != pd.year ||
                                        cd.month != pd.month ||
                                        cd.day != pd.day;
                                  }

                                  // 4) ¿Lo leyó el peer?
                                  final leidoPor = List<String>.from(
                                    data['leidoPor'] ?? [],
                                  );
                                  final readByPeer =
                                      otroUid != null &&
                                      leidoPor.contains(otroUid);

                                  // 5) Datos de autor desde caché
                                  final nombre =
                                      cacheUsuarios[data['AutorID']]!['nombre']!;
                                  final foto =
                                      cacheUsuarios[data['AutorID']]!['foto']!;

                                  // 6) Construir widgets
                                  final children = <Widget>[];
                                  if (showDateSeparator) {
                                    children.add(
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: Row(
                                          children: [
                                            const Expanded(
                                              child: Divider(thickness: 1),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade200,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Text(
                                                DateFormat(
                                                  'dd MMM yyyy',
                                                ).format(fecha),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black54,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const Expanded(
                                              child: Divider(thickness: 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  children.add(
                                    ChatBubble(
                                      isMine: esMio,
                                      read: readByPeer,
                                      avatarUrl: foto,
                                      authorName: nombre,
                                      text: texto,
                                      time: fecha,
                                      edited: editado,
                                      deleted: eliminado,
                                      reactions: reacciones,
                                      showName: showName,
                                      onEdit:
                                          () => _editarMensaje(
                                            doc.id,
                                            texto,
                                            data['Fecha'] as Timestamp,
                                          ),
                                      onDelete: () => _eliminarMensaje(doc.id),
                                      onReact: () => _reaccionarMensaje(doc.id),
                                    ),
                                  );

                                  return Column(
                                    crossAxisAlignment:
                                        esMio
                                            ? CrossAxisAlignment.end
                                            : CrossAxisAlignment.start,
                                    children: children,
                                  );
                                },
                              );
                            },
                          ),
                ),

                if (chatIdSeleccionado != null)
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _mensajeController,
                            onChanged: (val) {
                              // setState(() => mensaje = val);
                              mensaje = val;

                              // Solo si cambió el estado:
                              final typing = val.trim().isNotEmpty;
                              if (typing != _isTyping &&
                                  chatIdSeleccionado != null) {
                                _isTyping = typing;
                                FirebaseFirestore.instance
                                    .collection('Chats')
                                    .doc(chatIdSeleccionado)
                                    .update({'typing.$uid': typing});
                              }
                            },
                            decoration: const InputDecoration(
                              hintText: 'Escribe tu mensaje…',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Colors.blueAccent,
                          ),
                          onPressed: _enviarMensaje,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
