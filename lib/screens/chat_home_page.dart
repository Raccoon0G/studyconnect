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

    // // Precargar datos del otro usuario
    // if (!cacheUsuarios.containsKey(otroId)) {
    //   final doc =
    //       await FirebaseFirestore.instance
    //           .collection('usuarios')
    //           .doc(otroId)
    //           .get();
    //   cacheUsuarios[otroId] = {
    //     'nombre': doc['Nombre'] ?? 'Usuario',
    //     'foto': doc['FotoPerfil'] ?? '',
    //   };
    // }

    // 3) Disparamos el cambio de chat
    setState(() {
      chatIdSeleccionado = nuevoChatId;
      otroUid = otroId;
    });
  }

  /// En una lista invertida (reverse: true),
  /// devuelve true **solo** cuando docs[i] arranca un nuevo día.
  bool _shouldShowDateSeparator(int i, List<QueryDocumentSnapshot> docs) {
    if (i == 0) return false; // nunca antes del mensaje más nuevo
    final currTs = (docs[i].data() as Map)['Fecha'] as Timestamp;
    final prevTs = (docs[i - 1].data() as Map)['Fecha'] as Timestamp;
    final curr = currTs.toDate();
    final prev = prevTs.toDate();
    return curr.year != prev.year ||
        curr.month != prev.month ||
        curr.day != prev.day;
  }

  void _enviarMensaje() async {
    if (chatIdSeleccionado == null || mensaje.trim().isEmpty) return;

    final mensajesRef = FirebaseFirestore.instance
        .collection('Chats')
        .doc(chatIdSeleccionado)
        .collection('Mensajes');

    await mensajesRef.add({
      'AutorID': uid,
      'Contenido': mensaje.trim(),
      'Fecha': Timestamp.now(),
      'reacciones': {},
      'editado': false,
      'eliminado': false,
      'leidoPor': [uid],
    });

    await FirebaseFirestore.instance
        .collection('Chats')
        .doc(chatIdSeleccionado)
        .update({'UltimaAct': Timestamp.now()});

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
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.lightBlue.shade300,
              child: Column(
                children: [
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
                        final all =
                            await FirebaseFirestore.instance
                                .collection('usuarios')
                                .get();
                        setState(() {
                          _usuarios =
                              all.docs.where((u) {
                                final nombre =
                                    (u['Nombre'] ?? '')
                                        .toString()
                                        .toLowerCase();
                                return nombre.contains(lower) && u.id != uid;
                              }).toList();
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children:
                          _usuarios.map((userDoc) {
                            final nombre = userDoc['Nombre'] ?? 'Usuario';
                            return ListTile(
                              leading: const Icon(Icons.search),
                              title: Text(nombre),
                              onTap: () => _iniciarChat(userDoc.id),
                            );
                          }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
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
                              final data = snapshot.data!;
                              final nombre = data['Nombre'] ?? 'Usuario';
                              final foto = data['FotoPerfil'] ?? '';
                              final online =
                                  data.data().toString().contains('online')
                                      ? data['online']
                                      : false;

                              final ultimaConexion =
                                  data.data().toString().contains(
                                        'ultimaConexion',
                                      )
                                      ? data['ultimaConexion'] as Timestamp?
                                      : null;

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
                                            : 'Últ. conexión: ${_formatearHora(ultimaConexion ?? Timestamp.now())}',
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

                              // ——— 0) Marcar como leídos SOLO los que NO SON MÍOS ———
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                final docs = snapshot.data!.docs;
                                for (final doc in docs) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final autor = data['AutorID'] as String?;
                                  if (autor == null || autor == uid) continue;
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

                              // 1) Lista ascendente + su inversa para el ListView
                              final asc = snapshot.data!.docs;
                              final inv = asc.reversed.toList();

                              return ListView.builder(
                                controller: _scrollController,
                                reverse: true,
                                padding: const EdgeInsets.all(12),
                                itemCount: inv.length,
                                itemBuilder: (context, i) {
                                  // ——— 2) Índice en ascendente para el separador de fecha ———
                                  final ascIndex = asc.length - 1 - i;
                                  final doc = inv[i];
                                  final data =
                                      doc.data() as Map<String, dynamic>;

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

                                  // ——— 3) showName solo cuando cambia autor ———
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

                                  // ——— 4) separador de fecha ———
                                  bool showDateSeparator;
                                  if (ascIndex == 0) {
                                    showDateSeparator = true;
                                  } else {
                                    final currTs =
                                        (asc[ascIndex].data()
                                                as Map<
                                                  String,
                                                  dynamic
                                                >)['Fecha']
                                            as Timestamp;
                                    final prevTs =
                                        (asc[ascIndex - 1].data()
                                                as Map<
                                                  String,
                                                  dynamic
                                                >)['Fecha']
                                            as Timestamp;
                                    final curr = currTs.toDate();
                                    final prev = prevTs.toDate();
                                    showDateSeparator =
                                        curr.year != prev.year ||
                                        curr.month != prev.month ||
                                        curr.day != prev.day;
                                  }

                                  // ——— 5) Si es mi mensaje, ¿lo leyó el peer? ———
                                  final leidoPor = List<String>.from(
                                    data['leidoPor'] ?? [],
                                  );
                                  final readByPeer =
                                      otroUid != null &&
                                      leidoPor.contains(otroUid);

                                  // ——— 6) sacamos nombre/foto del caché ———
                                  final nombre =
                                      cacheUsuarios[data['AutorID']]!['nombre']!;
                                  final foto =
                                      cacheUsuarios[data['AutorID']]!['foto']!;

                                  // ——— 7) montamos Column con opcional separador + burbuja ———
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
                                      read: readByPeer, // ← aquí
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

                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _mensajeController,
                          onChanged: (val) => setState(() => mensaje = val),
                          decoration: const InputDecoration(
                            hintText: 'Escribe tu mensaje...',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.blueAccent),
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
