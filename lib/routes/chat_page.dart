// ChatPage COMPLETO actualizado (Messenger/WhatsApp style mejorado)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class ChatPage extends StatefulWidget {
  final String chatId;
  const ChatPage({super.key, required this.chatId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final String uid = FirebaseAuth.instance.currentUser!.uid;
  String? otroUid;
  String nombreOtro = '';
  String fotoOtro = '';
  bool escribiendo = false;

  @override
  void initState() {
    super.initState();
    _cargarInfoDelChat();
    _actualizarEstadoUsuario(true);
    _controller.addListener(_detectarEscritura);
  }

  @override
  void dispose() {
    _actualizarEstadoUsuario(false);
    _actualizarEscribiendo(false);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _cargarInfoDelChat() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('Chats')
            .doc(widget.chatId)
            .get();
    if (!doc.exists) return;

    final participantes = List<String>.from(doc['Participantes']);
    otroUid = participantes.firstWhere((id) => id != uid);

    final nombres = Map<String, dynamic>.from(doc['Nombres'] ?? {});
    final usuarioDoc =
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(otroUid)
            .get();

    setState(() {
      nombreOtro = nombres[otroUid] ?? 'Desconocido';
      fotoOtro = usuarioDoc.data()?['FotoPerfil'] ?? '';
    });
  }

  Future<void> _actualizarEstadoUsuario(bool online) async {
    await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
      'online': online,
      'ultimaConexion': Timestamp.now(),
    });
  }

  void _detectarEscritura() {
    final escribiendoAhora = _controller.text.isNotEmpty;
    if (escribiendoAhora != escribiendo) {
      escribiendo = escribiendoAhora;
      _actualizarEscribiendo(escribiendo);
    }
  }

  Future<void> _actualizarEscribiendo(bool escribiendo) async {
    if (otroUid == null) return;
    await FirebaseFirestore.instance
        .collection('Chats')
        .doc(widget.chatId)
        .update({'Escribiendo.$uid': escribiendo});
  }

  String _formatearHora(Timestamp fecha) {
    return DateFormat('HH:mm').format(fecha.toDate());
  }

  void _enviarMensaje() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;

    final nuevo = await FirebaseFirestore.instance
        .collection('Chats')
        .doc(widget.chatId)
        .collection('Mensajes')
        .add({
          'AutorID': uid,
          'Contenido': texto,
          'Fecha': Timestamp.now(),
          'editado': false,
          'reacciones': {},
          'eliminado': false,
          'leidoPor': [uid],
        });

    await FirebaseFirestore.instance
        .collection('Chats')
        .doc(widget.chatId)
        .update({'UltimaAct': Timestamp.now()});

    _controller.clear();
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent + 200);
  }

  void _editarMensaje(
    String mensajeId,
    String contenidoActual,
    Timestamp fecha,
  ) async {
    final diferencia = DateTime.now().difference(fecha.toDate());
    if (diferencia.inMinutes > 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya no puedes editar este mensaje.')),
      );
      return;
    }

    final TextEditingController editCtrl = TextEditingController(
      text: contenidoActual,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Editar mensaje'),
            content: TextField(controller: editCtrl),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final nuevo = editCtrl.text.trim();
                  if (nuevo.isNotEmpty) {
                    await FirebaseFirestore.instance
                        .collection('Chats')
                        .doc(widget.chatId)
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
        .doc(widget.chatId)
        .collection('Mensajes')
        .doc(mensajeId)
        .update({'eliminado': true});
  }

  void _reaccionarMensaje(String mensajeId) async {
    final reacciones = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

    showModalBottomSheet(
      context: context,
      builder:
          (context) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:
                reacciones
                    .map(
                      (emoji) => IconButton(
                        icon: Text(emoji, style: const TextStyle(fontSize: 24)),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('Chats')
                              .doc(widget.chatId)
                              .collection('Mensajes')
                              .doc(mensajeId)
                              .update({
                                'reacciones.$emoji': FieldValue.increment(1),
                              });
                          Navigator.pop(context);
                        },
                      ),
                    )
                    .toList(),
          ),
    );
  }

  void _mostrarInfoContacto() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(otroUid!)
            .get();

    showModalBottomSheet(
      context: context,
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        fotoOtro.isNotEmpty
                            ? NetworkImage(fotoOtro)
                            : const AssetImage('assets/images/avatar1.png')
                                as ImageProvider,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Nombre: ${doc['Nombre']}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Correo: ${doc['Correo']}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Registrado: ${DateFormat('dd/MM/yyyy').format(doc['FechaRegistro'].toDate())}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/'),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: CircleAvatar(
                radius: 20,
                backgroundImage:
                    fotoOtro.isNotEmpty
                        ? NetworkImage(fotoOtro)
                        : const AssetImage('assets/images/avatar1.png')
                            as ImageProvider,
              ),
            ),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream:
                    (otroUid != null)
                        ? FirebaseFirestore.instance
                            .collection('usuarios')
                            .doc(otroUid!)
                            .snapshots()
                        : const Stream.empty(),
                builder: (context, snapshotUser) {
                  final bool online =
                      snapshotUser.data?.data() != null &&
                      (snapshotUser.data!.get('online') ?? false);
                  final Timestamp? ultima = snapshotUser.data?.get(
                    'ultimaConexion',
                  );

                  return StreamBuilder<DocumentSnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('Chats')
                            .doc(widget.chatId)
                            .snapshots(),
                    builder: (context, snapshotChat) {
                      if (!snapshotChat.hasData) return const SizedBox();

                      final escribiendoOtro =
                          snapshotChat.data!.get('Escribiendo')?[otroUid] ??
                          false;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombreOtro,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            escribiendoOtro
                                ? 'Escribiendo...'
                                : (online
                                    ? '🟢 En línea'
                                    : 'Últ. conexión: ${_formatearHora(ultima ?? Timestamp.now())}'),
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  escribiendoOtro
                                      ? Colors.lightBlueAccent
                                      : Colors.white70,
                              fontStyle:
                                  escribiendoOtro
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _mostrarInfoContacto,
            ),
          ],
        ),

        backgroundColor: const Color(0xFF048DD2),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('Chats')
                      .doc(widget.chatId)
                      .collection('Mensajes')
                      .orderBy('Fecha')
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final mensajes = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: mensajes.length,
                  itemBuilder: (context, index) {
                    final doc = mensajes[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final esMio = data['AutorID'] == uid;
                    final eliminado = data['eliminado'] ?? false;
                    final contenido =
                        eliminado ? 'Mensaje eliminado' : data['Contenido'];
                    final hora = _formatearHora(data['Fecha']);
                    final reacciones = Map<String, dynamic>.from(
                      data['reacciones'] ?? {},
                    );
                    final List leidoPor = data['leidoPor'] ?? [];

                    return Align(
                      alignment:
                          esMio ? Alignment.centerRight : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: () {
                          if (!eliminado) {
                            showModalBottomSheet(
                              context: context,
                              builder:
                                  (_) => Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (esMio) ...[
                                        ListTile(
                                          leading: const Icon(Icons.edit),
                                          title: const Text('Editar'),
                                          onTap:
                                              () => _editarMensaje(
                                                doc.id,
                                                data['Contenido'],
                                                data['Fecha'],
                                              ),
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.delete),
                                          title: const Text('Eliminar'),
                                          onTap: () => _eliminarMensaje(doc.id),
                                        ),
                                      ],
                                      ListTile(
                                        leading: const Icon(
                                          Icons.emoji_emotions,
                                        ),
                                        title: const Text('Reaccionar'),
                                        onTap: () => _reaccionarMensaje(doc.id),
                                      ),
                                    ],
                                  ),
                            );
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                eliminado
                                    ? Colors.grey[400]
                                    : esMio
                                    ? Colors.blue[200]
                                    : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(contenido),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  if (data['editado'] == true && !eliminado)
                                    const Text(
                                      '(editado)',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  Text(
                                    hora,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  if (esMio)
                                    Icon(
                                      leidoPor.length > 1
                                          ? Icons.done_all
                                          : Icons.done,
                                      size: 16,
                                      color:
                                          leidoPor.length > 1
                                              ? Colors.blue
                                              : Colors.grey,
                                    ),
                                ],
                              ),
                              if (reacciones.isNotEmpty && !eliminado)
                                Wrap(
                                  spacing: 4,
                                  children:
                                      reacciones.entries
                                          .map(
                                            (e) => Text(
                                              '${e.key} ${e.value}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                ),
                            ],
                          ),
                        ),
                      ),
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
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Escribe tu mensaje...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _enviarMensaje,
                  color: const Color(0xFF048DD2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
