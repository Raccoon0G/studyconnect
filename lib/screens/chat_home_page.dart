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
  bool _showList = true;
  List<String> _selectedForGroup = [];
  final TextEditingController _groupNameController = TextEditingController();

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

  void _iniciarChat(String otroId) async {
    // 1) Creamos el chatId ordenado
    final nuevoChatId =
        uid.compareTo(otroId) < 0 ? '${uid}_$otroId' : '${otroId}_$uid';
    // 2) Precargamos datos del otro usuario en caché
    await _obtenerUsuario(otroId);

    // ── creamos/mergeamos el documento Chats/{chatId}
    await FirebaseFirestore.instance.collection('Chats').doc(nuevoChatId).set({
      'ids': [uid, otroId],
      'UltimaAct': FieldValue.serverTimestamp(),
      'typing': {uid: false, otroId: false},
    }, SetOptions(merge: true));

    // 3) Disparamos el cambio de chat
    setState(() {
      filtro = ''; // reset del filtro
      _busquedaController.clear(); // limpiamos la caja de texto
      _showList = false;
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
          'lastMessageAt': now,
          'lastMessage': mensaje.trim(),
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
        return AlertDialog(
          title: const Text('Nuevo grupo'),
          content: SizedBox(
            width: 350,
            height: 400,
            child: Column(
              children: [
                // Nombre del grupo
                TextField(
                  controller: _groupNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del grupo',
                  ),
                ),
                const SizedBox(height: 12),
                // Buscador de usuarios
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Buscar usuarios...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (txt) {
                    _filter = txt.trim().toLowerCase();
                    // notificar sólo al contenido del diálogo
                    (context as Element).markNeedsBuild();
                  },
                ),
                const SizedBox(height: 12),
                // Lista de usuarios filtrada con foto y checkbox
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('usuarios')
                            .where(FieldPath.documentId, whereNotIn: [uid])
                            .snapshots(),
                    builder: (ctx, snap) {
                      if (!snap.hasData)
                        return const Center(child: CircularProgressIndicator());
                      // todos los usuarios excepto yo
                      final all = snap.data!.docs;
                      // aplicar filtro por nombre
                      final filtered =
                          all.where((d) {
                            final name =
                                (d['Nombre'] ?? '').toString().toLowerCase();
                            return name.contains(_filter);
                          }).toList();
                      if (filtered.isEmpty)
                        return const Center(child: Text("No hay usuarios"));
                      return ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final doc = filtered[i];
                          final data = doc.data()! as Map<String, dynamic>;
                          final nombre = data['Nombre'] as String? ?? 'Usuario';
                          final foto = data['FotoPerfil'] as String? ?? '';
                          final isSel = _selected.contains(doc.id);
                          return CheckboxListTile(
                            value: isSel,
                            onChanged: (yes) {
                              if (yes == true)
                                _selected.add(doc.id);
                              else
                                _selected.remove(doc.id);
                              (context as Element).markNeedsBuild();
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
                            controlAffinity: ListTileControlAffinity.leading,
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
              onPressed: () {
                Navigator.pop(context);
              },
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
                        await FirebaseFirestore.instance
                            .collection('Chats')
                            .doc(chatId)
                            .set({
                              'ids': [uid, ..._selected],
                              'isGroup': true,
                              'groupName': _groupNameController.text.trim(),
                              'groupPhoto': '',
                              'lastMessage': '',
                              'lastMessageAt': now,
                              'unreadCounts': {
                                for (var u in [uid, ..._selected]) u: 0,
                              },
                            });
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
  }

  // 3) Lógica para crear el documento de grupo:
  Future<void> _crearGrupo(String nombre, List<String> miembros) async {
    // incluirme a mí:
    if (!miembros.contains(uid)) miembros.add(uid);
    final doc = FirebaseFirestore.instance.collection('Chats').doc();
    await doc.set({
      'ids': miembros,
      'isGroup': true,
      'groupName': nombre,
      'groupPhoto': '', // podrías permitir subir foto
      'createdBy': uid,

      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'typing': {for (var m in miembros) m: false},
      'unreadCounts': {for (var m in miembros) m: 0},
    });
  }

  // Panel izquierdo con header, tabs, buscador, historias y lista de chats
  Widget _buildChatList() {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: 200, maxWidth: 320),
      child: Container(
        color: Colors.lightBlue.shade300,
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
                            fontSize: 20,
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
                    setState(() => filtro = lower);
                    if (filtro.isNotEmpty) {
                      final snap =
                          await FirebaseFirestore.instance
                              .collection('usuarios')
                              .get();
                      setState(() {
                        _usuarios =
                            snap.docs.where((u) {
                              final nombre =
                                  (u['Nombre'] ?? '').toString().toLowerCase();
                              return nombre.contains(filtro) && u.id != uid;
                            }).toList();
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
    // 1) Si hay texto en el buscador, muestro usuarios
    if (filtro.isNotEmpty) {
      if (_usuarios.isEmpty) {
        return const Center(child: Text('No se encontraron usuarios'));
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _usuarios.length,
        itemBuilder: (_, i) {
          final userDoc = _usuarios[i];
          final nombre = userDoc['Nombre'] ?? 'Usuario';
          final foto = cacheUsuarios[userDoc.id]!['foto']!;
          return ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: CircleAvatar(
              backgroundImage:
                  foto.isNotEmpty
                      ? NetworkImage(foto)
                      : const AssetImage('assets/images/avatar1.png')
                          as ImageProvider,
            ),
            title: Text(nombre, style: const TextStyle(color: Colors.white)),
            onTap: () => _iniciarChat(userDoc.id),
          );
        },
      );
    }

    // 2) Si no hay texto, muestro el StreamBuilder de Chats
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('Chats')
              .where('ids', arrayContains: uid)
              .orderBy('lastMessageAt', descending: true)
              .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            itemCount: 5,
            itemBuilder: (_, __) => const ShimmerChatTile(),
          );
        }

        // aquí sí existe docs
        final docs =
            snap.data!.docs.where((chatDoc) {
              final ids = List<String>.from((chatDoc.data()! as Map)['ids']);
              final isGroup = ids.length > 2;
              return (!filterGroups || isGroup) &&
                  (!filterUnread /*|| hasUnread*/ );
            }).toList();

        if (docs.isEmpty) {
          return const Center(child: Text('Sin conversaciones'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: docs.length,
          itemBuilder: (ctx, idx) {
            final chatDoc = docs[idx];
            final data = chatDoc.data()! as Map<String, dynamic>;
            final otherIds = List<String>.from(data['ids']);
            final bool isGroup = (data['isGroup'] as bool?) == true;
            final String chatId = chatDoc.id;

            // Determinar "other" para 1‑a‑1
            final String? other =
                isGroup ? null : otherIds.firstWhere((id) => id != uid);

            // Todas las variables que luego usarás en el ListTile
            final String title =
                isGroup
                    ? (data['groupName'] as String? ??
                        'Grupo (${otherIds.length})')
                    : cacheUsuarios[other]!['nombre']!;
            // averiguamos si es grupo y quién lo creó

            final String? creatorId =
                data['createdBy'] as String? ?? otherIds.first; // fallback
            final String creatorName = cacheUsuarios[creatorId]!['nombre']!;

            // ahora el preview:
            final String preview;
            if ((data['lastMessage'] as String?)?.trim().isNotEmpty == true) {
              preview = data['lastMessage'] as String;
            } else if (isGroup) {
              preview = '$creatorName ha creado el grupo';
            } else {
              preview = '— sin mensajes —';
            }

            final String? photoUrl =
                isGroup
                    ? (data['groupPhoto'] as String?)
                    : cacheUsuarios[other]!['foto']!;
            final String hora =
                data['lastMessageAt'] != null
                    ? DateFormat.Hm().format(
                      (data['lastMessageAt'] as Timestamp).toDate(),
                    )
                    : '';
            final Map<String, dynamic> unreadMap =
                data['unreadCounts'] as Map<String, dynamic>? ?? {};
            final int unreadCount = (unreadMap[uid] as int?) ?? 0;

            return Container(
              color:
                  chatIdSeleccionado == chatId
                      ? Colors.blue.shade100
                      : Colors.transparent,
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: CircleAvatar(
                  backgroundImage:
                      photoUrl?.isNotEmpty == true
                          ? NetworkImage(photoUrl!)
                          : const AssetImage('assets/images/avatar1.png')
                              as ImageProvider,
                ),
                title: Text(title, style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  preview,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      hora,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                    if (unreadCount > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
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
                          ),
                        ),
                      ),
                  ],
                ),
                onTap: () {
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
              ),
            );
          },
        );
      },
    );
  }

  // Parte de los mensajes
  /// 1) Header con botón atrás, avatar, nombre y última conexión
  Widget _buildChatHeader() {
    return Container(
      color: const Color(0xFF048DD2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed:
                () => setState(() {
                  _showList = true;
                  chatIdSeleccionado = null; //  limpio la selección
                  otroUid = null;
                }),
          ),

          if (otroUid != null)
            FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('usuarios')
                      .doc(otroUid!)
                      .get(),
              builder: (context, snap) {
                if (!snap.hasData)
                  return const CircularProgressIndicator(color: Colors.white);
                final data = snap.data!.data()! as Map<String, dynamic>;
                final nombre = data['Nombre'] as String? ?? 'Usuario';
                final online = (data['online'] as bool?) == true;
                final ts = data['ultimaConexion'] as Timestamp?;
                final ultima =
                    ts != null ? _formatearHora(ts) : 'hace un momento';
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage:
                          (data['FotoPerfil'] as String?)?.isNotEmpty == true
                              ? NetworkImage(data['FotoPerfil'])
                              : const AssetImage('assets/images/avatar1.png')
                                  as ImageProvider,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          online ? '🟢 En línea' : 'Últ. conexión: $ultima',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            )
          else
            const Text(
              'Selecciona un chat',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
        ],
      ),
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
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final asc = snap.data!.docs;
        final inv = asc.reversed.toList();
        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.all(12),
          itemCount: inv.length,
          itemBuilder: (context, i) {
            final doc = inv[i];
            final data = doc.data() as Map<String, dynamic>;
            final esMio = data['AutorID'] == uid;
            final fecha = (data['Fecha'] as Timestamp).toDate();
            // showDateSeparator
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
            // readByPeer
            final leidoPor = List<String>.from(data['leidoPor'] ?? []);
            final readByPeer = otroUid != null && leidoPor.contains(otroUid);
            // autorInfo
            final autorInfo = cacheUsuarios[data['AutorID']]!;
            // agrupación de nombre
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
                ChatBubble(
                  isMine: esMio,
                  read: readByPeer,
                  avatarUrl: autorInfo['foto']!,
                  authorName: autorInfo['nombre']!,
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
              },
              decoration: const InputDecoration(
                hintText: 'Escribe tu mensaje…',
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blueAccent),
            onPressed: _enviarMensaje,
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
          if (_showList)
            Expanded(child: _buildChatList()), // tu panel izquierdo
          if (!_showList) _buildChatDetail(),
        ],
      ),
    );
  }
}
