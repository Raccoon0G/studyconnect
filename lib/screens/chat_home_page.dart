import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:study_connect/services/notification_service.dart';
import 'package:study_connect/widgets/notification_icon_widget.dart';

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
    final nuevoChatId =
        uid.compareTo(otroId) < 0 ? '${uid}_$otroId' : '${otroId}_$uid';

    // Precargar datos del otro usuario
    if (!cacheUsuarios.containsKey(otroId)) {
      final doc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(otroId)
              .get();
      cacheUsuarios[otroId] = {
        'nombre': doc['Nombre'] ?? 'Usuario',
        'foto': doc['FotoPerfil'] ?? '',
      };
    }

    setState(() {
      chatIdSeleccionado = nuevoChatId;
      otroUid = otroId;
    });
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

  Widget _buildChatBubble(
    Map<String, dynamic> data,
    bool esMio,
    String id, {
    bool mostrarNombre = true,
  }) {
    final reacciones = Map<String, dynamic>.from(data['reacciones'] ?? {});
    final eliminado = data['eliminado'] ?? false;
    final autorId = data['AutorID'];
    final nombre = cacheUsuarios[autorId]?['nombre'] ?? 'Usuario';
    final foto = cacheUsuarios[autorId]?['foto'] ?? '';

    return FutureBuilder<Map<String, String>>(
      future: _obtenerUsuario(data['AutorID']),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final nombre = snapshot.data!['nombre']!;
        final foto = snapshot.data!['foto']!;

        return GestureDetector(
          onLongPress: () {
            showModalBottomSheet(
              context: context,
              builder:
                  (_) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (esMio && !eliminado) ...[
                        ListTile(
                          leading: const Icon(Icons.edit),
                          title: const Text('Editar'),
                          onTap: () {
                            Navigator.pop(context);
                            _editarMensaje(
                              id,
                              data['Contenido'],
                              data['Fecha'],
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete),
                          title: const Text('Eliminar'),
                          onTap: () {
                            Navigator.pop(context);
                            _eliminarMensaje(id);
                          },
                        ),
                      ],
                      ListTile(
                        leading: const Icon(Icons.emoji_emotions),
                        title: const Text('Reaccionar'),
                        onTap: () {
                          Navigator.pop(context);
                          _reaccionarMensaje(id);
                        },
                      ),
                    ],
                  ),
            );
          },
          child: Align(
            alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      eliminado
                          ? Colors.grey[400]
                          : esMio
                          ? Colors.purple.shade200
                          : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (mostrarNombre) ...[
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundImage:
                                foto.isNotEmpty
                                    ? NetworkImage(foto)
                                    : const AssetImage(
                                          'assets/images/avatar1.png',
                                        )
                                        as ImageProvider,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],

                    const SizedBox(height: 4),
                    Text(
                      eliminado ? 'Mensaje eliminado' : data['Contenido'],
                      style: const TextStyle(fontSize: 15, height: 1.3),
                    ),

                    if (reacciones.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        children:
                            reacciones.entries
                                .map(
                                  (e) => Text(
                                    '${e.key} ${e.value}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                )
                                .toList(),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (data['editado'] == true && !eliminado)
                          const Text(
                            '(editado)',
                            style: TextStyle(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        Text(
                          _formatearHora(data['Fecha']),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        ),
                        if (esMio) const SizedBox(width: 4),
                        if (esMio)
                          if (data['leidoPor']?.contains(otroUid) == true)
                            const Icon(
                              Icons.done_all,
                              size: 14,
                              color: Colors.blue,
                            ) // doble check
                          else
                            const Icon(
                              Icons.check,
                              size: 14,
                              color: Color.fromARGB(255, 25, 167, 180),
                            ), // check simple
                      ],
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

                              // 1) invertimos la lista para facilitar el reverse:
                              final mensajes = snapshot.data!.docs;
                              final mensajesInvertidos =
                                  mensajes.reversed.toList();

                              // 2) devolvemos un ListView.builder CON `reverse: true`:
                              return ListView.builder(
                                controller: _scrollController,
                                reverse: true,
                                padding: const EdgeInsets.all(12),
                                itemCount: mensajesInvertidos.length,
                                itemBuilder: (context, i) {
                                  final doc = mensajesInvertidos[i];
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final esMio = data['AutorID'] == uid;

                                  // 3) mostramos nombre/avatar solo si cambia de autor
                                  final total = mensajesInvertidos.length;
                                  final mostrarNombreYFoto =
                                      i == total - 1 ||
                                      (i < total - 1 &&
                                          (mensajesInvertidos[i + 1].data()
                                                  as Map<
                                                    String,
                                                    dynamic
                                                  >)['AutorID'] !=
                                              data['AutorID']);

                                  return Column(
                                    crossAxisAlignment:
                                        esMio
                                            ? CrossAxisAlignment.end
                                            : CrossAxisAlignment.start,
                                    children: [
                                      if (mostrarNombreYFoto)
                                        const SizedBox(height: 12),
                                      _buildChatBubble(
                                        data,
                                        esMio,
                                        doc.id,
                                        mostrarNombre: mostrarNombreYFoto,
                                      ),
                                    ],
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
