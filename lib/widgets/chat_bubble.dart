import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_chat_bubble/bubble_type.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_1.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Para imágenes de red con caché y placeholders
import 'package:url_launcher/url_launcher.dart'; // Para abrir URLs (documentos, videos)
import 'package:audioplayers/audioplayers.dart'; // Para reproducir audio

typedef BubbleCallback = void Function();

class ChatBubbleCustom extends StatefulWidget {
  final bool isMine;
  final bool read;
  final String avatarUrl;
  final String authorName;
  final String?
  text; // Ahora es opcional, puede ser el caption o el mensaje de texto
  final DateTime time;
  final bool edited;
  final bool deleted;
  final Map<String, int> reactions;
  final bool showName;
  final BubbleCallback? onEdit;
  final BubbleCallback? onDelete;
  final BubbleCallback? onReact;

  // Nuevos campos para contenido multimedia
  final String
  tipoContenido; // "texto", "imagen", "video", "audio", "documento", "gif"
  final String? urlContenido;
  final String? nombreArchivo;
  // final String? mimeType; // Podrías usarlo si necesitas lógica específica de MIME aquí

  const ChatBubbleCustom({
    super.key,
    required this.isMine,
    required this.read,
    required this.avatarUrl,
    required this.authorName,
    this.text, // Ya no es 'required' si tipoContenido no es 'texto'
    required this.time,
    this.edited = false,
    this.deleted = false,
    this.reactions = const {},
    this.showName = true,
    this.onEdit,
    this.onDelete,
    this.onReact,
    required this.tipoContenido,
    this.urlContenido,
    this.nombreArchivo,
    // this.mimeType,
  });

  @override
  State<ChatBubbleCustom> createState() => _ChatBubbleCustomState();
}

class _ChatBubbleCustomState extends State<ChatBubbleCustom> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingAudio = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  PlayerState? _playerState; // Para saber si está pausado, reproduciendo, etc.

  @override
  void initState() {
    super.initState();
    if (widget.tipoContenido == 'audio' && widget.urlContenido != null) {
      _audioPlayer.onDurationChanged.listen((d) {
        if (mounted) setState(() => _audioDuration = d);
      });
      _audioPlayer.onPositionChanged.listen((p) {
        if (mounted) setState(() => _audioPosition = p);
      });
      _audioPlayer.onPlayerStateChanged.listen((s) {
        if (mounted) {
          setState(() {
            _playerState = s;
            _isPlayingAudio = s == PlayerState.playing;
          });
        }
      });
      // Cargar duración inicial
      // No se puede obtener la duración hasta que se cargue la fuente,
      // lo cual haremos al presionar play por primera vez o al cargar la URL.
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    if (widget.urlContenido == null) return;
    try {
      if (_playerState == PlayerState.paused) {
        await _audioPlayer.resume();
      } else {
        // Detener cualquier reproducción anterior antes de iniciar una nueva fuente
        await _audioPlayer.stop();
        await _audioPlayer.setSourceUrl(widget.urlContenido!);
        await _audioPlayer.resume(); // Inicia la reproducción
      }
      if (mounted) setState(() => _isPlayingAudio = true);
    } catch (e) {
      print("Error al reproducir audio: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al reproducir audio: ${e.toString()}')),
        );
        setState(() => _isPlayingAudio = false);
      }
    }
  }

  Future<void> _pauseAudio() async {
    try {
      await _audioPlayer.pause();
      if (mounted) setState(() => _isPlayingAudio = false);
    } catch (e) {
      print("Error al pausar audio: $e");
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds"
            .startsWith("00:")
        ? "$twoDigitMinutes:$twoDigitSeconds"
        : "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<void> _launchUrl(String? urlString) async {
    if (urlString == null) return;
    final Uri? uri = Uri.tryParse(urlString);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el enlace: $urlString')),
        );
      }
      throw 'Could not launch $urlString';
    }
  }

  Widget _buildContentWidget(BuildContext context) {
    if (widget.deleted) {
      return Text(
        'Mensaje eliminado',
        style: TextStyle(
          fontSize: 15,
          height: 1.3,
          fontStyle: FontStyle.italic,
          color: Colors.blue.shade50, // Color para mensajes eliminados
        ),
      );
    }

    Widget mediaContent;

    switch (widget.tipoContenido) {
      case 'imagen':
      case 'gif':
        mediaContent =
            widget.urlContenido != null
                ? GestureDetector(
                  onTap: () {
                    // Opcional: Abrir imagen en pantalla completa
                    if (widget.urlContenido != null) {
                      showDialog(
                        context: context,
                        builder:
                            (_) => Dialog(
                              child: Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: widget.urlContenido!,
                                    fit: BoxFit.contain,
                                    placeholder:
                                        (context, url) => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                    errorWidget:
                                        (context, url, error) =>
                                            const Icon(Icons.error),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 2,
                                          color: Colors.black,
                                        ),
                                      ],
                                    ),
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                  ),
                                ],
                              ),
                            ),
                      );
                    }
                  },
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight:
                          MediaQuery.of(context).size.height *
                          0.4, // Limitar altura
                      maxWidth:
                          MediaQuery.of(context).size.width *
                          0.6, // Limitar ancho
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: CachedNetworkImage(
                        imageUrl: widget.urlContenido!,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Container(
                              height: 150, // Altura del placeholder
                              color: Colors.grey[300],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              height: 150,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                              ),
                            ),
                      ),
                    ),
                  ),
                )
                : const Text('[Error: URL de imagen no disponible]');
        break;
      case 'video':
        mediaContent =
            widget.urlContenido != null
                ? InkWell(
                  onTap: () => _launchUrl(widget.urlContenido),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.play_circle_fill,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.nombreArchivo ?? 'Ver video',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                : const Text('[Error: URL de video no disponible]');
        break;
      case 'audio':
        mediaContent =
            widget.urlContenido != null
                ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color:
                        widget.isMine
                            ? Colors.purple.shade100.withOpacity(0.5)
                            : Colors.grey.shade200.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _isPlayingAudio
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          color:
                              widget.isMine
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
                          size: 36,
                        ),
                        onPressed: _isPlayingAudio ? _pauseAudio : _playAudio,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.nombreArchivo ?? 'Audio',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color:
                                    widget.isMine
                                        ? Colors.white70
                                        : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_audioDuration.inSeconds > 0)
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor:
                                      widget.isMine
                                          ? Colors.white
                                          : Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                  inactiveTrackColor:
                                      widget.isMine
                                          ? Colors.white30
                                          : Colors.grey.shade400,
                                  thumbColor:
                                      widget.isMine
                                          ? Colors.white
                                          : Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                  overlayColor:
                                      widget.isMine
                                          ? Colors.white.withAlpha(32)
                                          : Theme.of(
                                            context,
                                          ).colorScheme.primary.withAlpha(32),
                                  trackHeight: 2.0,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6.0,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 12.0,
                                  ),
                                ),
                                child: Slider(
                                  min: 0.0,
                                  max:
                                      _audioDuration.inSeconds.toDouble() > 0
                                          ? _audioDuration.inSeconds.toDouble()
                                          : 1.0,
                                  value: _audioPosition.inSeconds
                                      .toDouble()
                                      .clamp(
                                        0.0,
                                        _audioDuration.inSeconds.toDouble(),
                                      ),
                                  onChanged: (value) async {
                                    final position = Duration(
                                      seconds: value.toInt(),
                                    );
                                    await _audioPlayer.seek(position);
                                    // if (!_isPlayingAudio) { // Opcional: resumir si estaba pausado y el usuario mueve el slider
                                    //   _playAudio();
                                    // }
                                  },
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: Text(
                                _playerState != null
                                    ? "${_formatDuration(_audioPosition)} / ${_formatDuration(_audioDuration)}"
                                    : _formatDuration(_audioDuration),
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      widget.isMine
                                          ? Colors.white60
                                          : Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                : const Text('[Error: URL de audio no disponible]');
        break;
      case 'documento':
        mediaContent =
            widget.urlContenido != null
                ? InkWell(
                  onTap: () => _launchUrl(widget.urlContenido),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color:
                          widget.isMine
                              ? Colors.deepPurple.shade100.withOpacity(0.8)
                              : Colors.blueGrey.shade100.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.insert_drive_file_rounded,
                          color:
                              widget.isMine
                                  ? Colors.deepPurple.shade700
                                  : Colors.blueGrey.shade700,
                          size: 30,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.nombreArchivo ?? 'Ver documento',
                            style: TextStyle(
                              color:
                                  widget.isMine
                                      ? Colors.deepPurple.shade900
                                      : Colors.blueGrey.shade900,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                : const Text('[Error: URL de documento no disponible]');
        break;
      case 'texto':
      default:
        mediaContent = Text(
          widget.text ?? '', // Mensaje de texto
          style: TextStyle(
            fontSize: 15,
            height: 1.3,
            color: widget.isMine ? Colors.white : Colors.black87,
          ),
        );
    }

    // Si el tipo de contenido NO es texto y SÍ hay un texto (caption), lo mostramos debajo.
    // Si es solo texto, mediaContent ya es el Text widget.
    List<Widget> children = [];
    if (widget.showName && !widget.isMine) {
      // Solo para mensajes recibidos si showName es true
      children.add(
        Text(
          widget.authorName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color:
                widget.isMine ? Colors.white70 : Colors.black.withOpacity(0.6),
          ),
        ),
      );
      children.add(const SizedBox(height: 4));
    }

    // Añadir el contenido principal (media o texto)
    children.add(mediaContent);

    // Añadir caption si existe y el tipo de contenido no es 'texto' (o si es texto y quieres que esté separado)
    if (widget.tipoContenido != 'texto' &&
        widget.text != null &&
        widget.text!.trim().isNotEmpty) {
      children.add(const SizedBox(height: 6));
      children.add(
        Text(
          widget.text!,
          style: TextStyle(
            fontSize: 14,
            height: 1.2,
            color:
                widget.isMine
                    ? Colors.white.withOpacity(0.9)
                    : Colors.black.withOpacity(0.8),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment:
          widget.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize:
          MainAxisSize.min, // Para que la columna se ajuste al contenido
      children: children,
    );
  }

  String _formatTime(DateTime dt) => DateFormat.Hm().format(dt);

  @override
  Widget build(BuildContext context) {
    // El color de fondo se podría ajustar según el tipo de contenido si es necesario
    Color bubbleBackgroundColor =
        widget.deleted
            ? (widget.isMine
                ? Colors
                    .blueGrey
                    .shade400 // mis mensajes eliminados
                : Colors
                    .blueGrey
                    .shade200 // Mensajes eliminados de otros
                    )
            : widget.isMine
            ? Colors
                .blue
                .shade700 // Mis mensajes NO eliminados
            : Colors.indigo.shade200; // Mensajes NO eliminados de otros

    // Para imágenes/videos, podrías querer un fondo transparente o sin padding extra de la burbuja.
    // Pero el paquete flutter_chat_bubble ya maneja bien el clipping.

    EdgeInsets contentPadding = const EdgeInsets.all(10);
    if (widget.tipoContenido == 'imagen' ||
        widget.tipoContenido == 'gif' ||
        widget.tipoContenido == 'video') {
      // Menos padding para imágenes/videos para que ocupen más espacio de la burbuja
      // O podrías querer padding cero y manejar el padding dentro del widget de imagen/video.
      contentPadding = const EdgeInsets.all(3);
    } else if (widget.tipoContenido == 'audio') {
      contentPadding = const EdgeInsets.symmetric(horizontal: 6, vertical: 4);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment:
            widget.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isMine)
            CircleAvatar(
              radius: 14,
              backgroundImage:
                  widget.avatarUrl.isNotEmpty
                      ? CachedNetworkImageProvider(widget.avatarUrl)
                      : const AssetImage('assets/images/avatar1.png')
                          as ImageProvider,
            ),
          if (!widget.isMine) const SizedBox(width: 6),
          Flexible(
            // Usar Flexible para que la burbuja no cause overflow si el contenido es muy ancho
            child: GestureDetector(
              onLongPress: () {
                if (widget.deleted && !widget.isMine)
                  return; // No mostrar menú para mensajes eliminados de otros
                showModalBottomSheet(
                  context: context,
                  builder:
                      (_) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.isMine &&
                              !widget.deleted &&
                              widget.tipoContenido == 'texto' &&
                              widget.onEdit != null) // Solo editar texto
                            ListTile(
                              leading: const Icon(Icons.edit),
                              title: const Text('Editar'),
                              onTap: () {
                                Navigator.pop(context); // Cerrar bottom sheet
                                widget.onEdit!();
                              },
                            ),
                          if (widget.isMine &&
                              !widget.deleted &&
                              widget.onDelete != null)
                            ListTile(
                              leading: const Icon(Icons.delete),
                              title: const Text('Eliminar'),
                              onTap: () {
                                Navigator.pop(context);
                                widget.onDelete!();
                              },
                            ),
                          if (!widget.deleted &&
                              widget.onReact !=
                                  null) // Reaccionar a cualquier mensaje no eliminado
                            ListTile(
                              leading: const Icon(
                                Icons.emoji_emotions_outlined,
                              ),
                              title: const Text('Reaccionar'),
                              onTap: () {
                                Navigator.pop(context);
                                widget.onReact!();
                              },
                            ),
                        ],
                      ),
                );
              },
              child: ChatBubble(
                clipper: ChatBubbleClipper1(
                  type:
                      widget.isMine
                          ? BubbleType.sendBubble
                          : BubbleType.receiverBubble,
                ),
                backGroundColor: bubbleBackgroundColor,
                margin:
                    EdgeInsets
                        .zero, // El padding exterior ya lo maneja el Padding widget
                alignment:
                    widget.isMine ? Alignment.topRight : Alignment.topLeft,
                child: Container(
                  padding: contentPadding,
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ), // Ancho máximo de la burbuja
                  child: Column(
                    crossAxisAlignment:
                        widget.isMine
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildContentWidget(
                        context,
                      ), // Aquí se renderiza el contenido principal
                      if (widget.reactions.isNotEmpty && !widget.deleted) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          alignment:
                              widget.isMine
                                  ? WrapAlignment.end
                                  : WrapAlignment.start,
                          spacing: 6,
                          runSpacing: 4,
                          children:
                              widget.reactions.entries
                                  .map(
                                    (e) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            widget.isMine
                                                ? Colors.black.withOpacity(0.1)
                                                : Colors.black.withOpacity(
                                                  0.05,
                                                ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${e.key} ${e.value > 1 ? e.value : ''}'
                                            .trim(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              widget.isMine
                                                  ? Colors.white70
                                                  : Colors.black54,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                      if (!widget
                          .deleted) // Solo mostrar hora y checks si no está eliminado
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 4.0,
                          ), // Espacio antes de la hora
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment:
                                widget.isMine
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                            children: [
                              if (widget.edited)
                                Text(
                                  '(editado) ',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontStyle: FontStyle.italic,
                                    color:
                                        widget.isMine
                                            ? Colors.white70
                                            : Colors.black54,
                                  ),
                                ),
                              Text(
                                _formatTime(widget.time),
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      widget.isMine
                                          ? Colors.white70
                                          : Colors.black54,
                                ),
                              ),
                              if (widget.isMine) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  widget.read ? Icons.done_all : Icons.check,
                                  size: 14,
                                  color:
                                      widget.read
                                          ? (widget.isMine
                                              ? Colors.lightBlueAccent.shade100
                                              : Colors.blue)
                                          : (widget.isMine
                                              ? Colors.white70
                                              : Colors.black54),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (widget.isMine) const SizedBox(width: 6),
          if (widget.isMine)
            CircleAvatar(
              radius: 14,
              backgroundImage:
                  widget.avatarUrl.isNotEmpty
                      ? CachedNetworkImageProvider(widget.avatarUrl)
                      : const AssetImage('assets/images/avatar1.png')
                          as ImageProvider,
            ),
        ],
      ),
    );
  }
}
