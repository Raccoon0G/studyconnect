import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- IMPORTANTE: Añadido para poder copiar al portapapeles
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_chat_bubble/bubble_type.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_1.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

// Solo para web
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;

typedef BubbleCallback = void Function();

class ChatBubbleCustom extends StatefulWidget {
  final bool isMine;
  final bool read;
  final String avatarUrl;
  final String authorName;
  final String? text; // Caption o mensaje de texto
  final DateTime time;
  final bool edited;
  final bool deleted;
  final Map<String, int> reactions;
  final bool showName;
  final BubbleCallback? onEdit;
  final BubbleCallback? onDelete;
  final BubbleCallback? onReact;

  final String tipoContenido;
  final String? urlContenido;
  final String? nombreArchivo;

  final String? youtubeVideoId;
  final String? youtubeTitle;
  final String? youtubeThumbnail;

  const ChatBubbleCustom({
    super.key,
    required this.isMine,
    required this.read,
    required this.avatarUrl,
    required this.authorName,
    this.text,
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
    this.youtubeVideoId,
    this.youtubeTitle,
    this.youtubeThumbnail,
  });

  @override
  State<ChatBubbleCustom> createState() => _ChatBubbleCustomState();
}

class _ChatBubbleCustomState extends State<ChatBubbleCustom> {
  // --- Controladores de Media (Sin cambios) ---
  final AudioPlayer _audioPlayer = AudioPlayer();
  PlayerState? _audioPlayerState;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isVideoPlayerInitialized = false;
  static final Set<String> _registeredViewFactories = {};

  @override
  void initState() {
    super.initState();
    if (widget.urlContenido != null && widget.urlContenido!.isNotEmpty) {
      if (widget.tipoContenido == 'audio') {
        _initAudioPlayer();
      } else if (widget.tipoContenido == 'video' && !kIsWeb) {
        _initializeVideoPlayerMobile();
      }
    }
  }

  void _initAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _audioPlayerState = s);
    });
  }

  Future<void> _initializeVideoPlayerMobile() async {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.urlContenido!),
    );

    try {
      await _videoPlayerController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        aspectRatio:
            _videoPlayerController!.value.aspectRatio > 0
                ? _videoPlayerController!.value.aspectRatio
                : 16 / 9,
        placeholder: Container(
          color: Colors.black,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        },
      );
      if (mounted) {
        setState(() => _isVideoPlayerInitialized = true);
      }
    } catch (e) {
      print("Error inicializando VideoPlayer (móvil): $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _toggleAudioPlay() async {
    try {
      if (_audioPlayerState == PlayerState.playing) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(UrlSource(widget.urlContenido!));
      }
    } catch (e) {
      print("Error al reproducir/pausar audio: $e");
    }
  }

  String _formatTime(DateTime dt) => DateFormat.Hm().format(dt);

  Future<void> _launchUrl(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    final Uri? uri = Uri.tryParse(urlString);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildContentWidget(BuildContext context) {
    // --- INICIO DE CORRECCIÓN 1: LÓGICA DE ELIMINAR ---
    if (widget.deleted) {
      // Si el widget está marcado como eliminado, SIEMPRE mostramos este texto.
      return Text(
        'Mensaje eliminado',
        style: TextStyle(
          fontSize: 15,
          height: 1.3,
          fontStyle: FontStyle.italic,
          color: widget.isMine ? Colors.white70 : Colors.grey[600],
        ),
      );
    }

    Widget mediaContent;

    switch (widget.tipoContenido) {
      // ... (El resto de tu switch case no necesita cambios)
      case 'imagen':
      case 'gif':
        mediaContent =
            widget.urlContenido != null
                ? GestureDetector(
                  onTap: () {
                    /* Lógica para ver imagen en pantalla completa */
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: CachedNetworkImage(
                      imageUrl: widget.urlContenido!,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            height: 150,
                            width: 200,
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            height: 150,
                            width: 200,
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
                )
                : const Text('[Error: URL no disponible]');
        break;

      case 'video':
        mediaContent =
            widget.urlContenido != null
                ? (kIsWeb
                    ? _buildVideoPlayerWeb(widget.urlContenido!)
                    : (_isVideoPlayerInitialized && _chewieController != null
                        ? AspectRatio(
                          aspectRatio:
                              _videoPlayerController!.value.aspectRatio,
                          child: Chewie(controller: _chewieController!),
                        )
                        : InkWell(
                          onTap: () => _launchUrl(widget.urlContenido),
                          child: Container(
                            height: 180,
                            width: MediaQuery.of(context).size.width * 0.6,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_outline,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                          ),
                        )))
                : const Text('[Error: URL de video no disponible]');
        break;

      case 'audio':
        mediaContent =
            widget.urlContenido != null
                ? (kIsWeb
                    ? _buildAudioPlayerWeb(widget.urlContenido!)
                    : _buildAudioPlayerMobile())
                : const Text('[Error: URL de audio no disponible]');
        break;

      case 'youtube_link':
        mediaContent = _buildYoutubePreviewWidget();
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
                              ? Colors.blue.shade50.withOpacity(0.8)
                              : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.insert_drive_file_rounded,
                          color:
                              widget.isMine
                                  ? Colors.blue.shade800
                                  : Colors.grey.shade700,
                          size: 30,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.nombreArchivo ?? 'Ver documento',
                            style: TextStyle(
                              color:
                                  widget.isMine
                                      ? Colors.blue.shade900
                                      : Colors.black87,
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
        mediaContent = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: SelectableText(
            // <-- TAMBIÉN SE PUEDE CAMBIAR Text POR SelectableText
            widget.text ?? '',
            style: TextStyle(
              fontSize: 15,
              height: 1.3,
              color: widget.isMine ? Colors.white : Colors.black87,
            ),
          ),
        );
    }

    // ... (el resto del método no cambia)
    List<Widget> children = [];
    if (widget.showName && !widget.isMine && widget.authorName.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0, left: 4.0),
          child: Text(
            widget.authorName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    children.add(mediaContent);

    if (widget.tipoContenido != 'texto' &&
        widget.tipoContenido != 'youtube_link' &&
        widget.text != null &&
        widget.text!.trim().isNotEmpty) {
      children.add(const SizedBox(height: 6));
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SelectableText(
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
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  // ... (Pega aquí tus otros helpers: _buildYoutubePreviewWidget, _buildAudioPlayerMobile, etc. sin cambios)
  Widget _buildYoutubePreviewWidget() {
    return GestureDetector(
      onTap: () => _launchUrl(widget.text),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.youtubeThumbnail != null &&
              widget.youtubeThumbnail!.isNotEmpty)
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(11),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: widget.youtubeThumbnail!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder:
                        (context, url) => AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Container(
                            color: Colors.grey[800],
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white54,
                                ),
                              ),
                            ),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Container(
                            color: Colors.grey[800],
                            child: Icon(
                              Icons.ondemand_video,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10.0, 8.0, 10.0, 6.0),
            child: Text(
              widget.youtubeTitle ?? 'Video de YouTube',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: widget.isMine ? Colors.white : Colors.black87,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayerMobile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              _audioPlayerState == PlayerState.playing
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_fill_rounded,
              color:
                  widget.isMine
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary,
              size: 38,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: _toggleAudioPlay,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.nombreArchivo ?? 'Audio',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color:
                    widget.isMine
                        ? Colors.white.withOpacity(0.9)
                        : Colors.black.withOpacity(0.9),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayerWeb(String url) {
    final viewId = 'web_video_player_${url.hashCode}';
    if (!_registeredViewFactories.contains(viewId)) {
      _registeredViewFactories.add(viewId);
      ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
        return html.VideoElement()
          ..src = url
          ..controls = true
          ..autoplay = false
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.borderRadius = '8px'
          ..style.objectFit = 'contain';
      });
    }
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: HtmlElementView(viewType: viewId),
    );
  }

  Widget _buildAudioPlayerWeb(String url) {
    final viewId = 'web_audio_player_${url.hashCode}';
    if (!_registeredViewFactories.contains(viewId)) {
      _registeredViewFactories.add(viewId);
      ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
        return html.AudioElement()
          ..src = url
          ..controls = true
          ..style.width = '100%';
      });
    }
    return SizedBox(height: 50, child: HtmlElementView(viewType: viewId));
  }

  @override
  Widget build(BuildContext context) {
    Color bubbleBackgroundColor =
        widget.isMine
            ? Theme.of(context).colorScheme.primary
            : const Color(0xFFE7E7ED);

    // Si el mensaje está eliminado, el color de fondo es siempre gris, sin importar de quién sea.
    if (widget.deleted) {
      bubbleBackgroundColor =
          widget.isMine ? Colors.grey.shade700 : Colors.grey.shade300;
    }

    EdgeInsets contentPadding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 8,
    );
    bool hasMediaWithoutCaption =
        (widget.tipoContenido == 'imagen' ||
            widget.tipoContenido == 'gif' ||
            widget.tipoContenido == 'video') &&
        (widget.text == null || widget.text!.trim().isEmpty);
    bool isSpecialMedia =
        widget.tipoContenido == 'youtube_link' ||
        widget.tipoContenido == 'audio' ||
        widget.tipoContenido == 'video';

    if (isSpecialMedia) {
      contentPadding = EdgeInsets.zero;
    } else if (hasMediaWithoutCaption) {
      contentPadding = const EdgeInsets.all(3);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment:
            widget.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isMine)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                radius: 16,
                backgroundImage:
                    widget.avatarUrl.isNotEmpty
                        ? CachedNetworkImageProvider(widget.avatarUrl)
                        : const AssetImage('assets/images/avatar1.webp')
                            as ImageProvider,
              ),
            ),

          Flexible(
            child: GestureDetector(
              onLongPress: () {
                if (widget.deleted) return;
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Theme.of(context).canvasColor,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder:
                      (_) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // --- INICIO DE CORRECCIÓN 2: AÑADIR OPCIÓN DE COPIAR ---
                          // Solo mostramos la opción si el mensaje tiene texto
                          if (widget.text != null && widget.text!.isNotEmpty)
                            ListTile(
                              leading: const Icon(Icons.copy_rounded),
                              title: const Text('Copiar mensaje'),
                              onTap: () {
                                Navigator.pop(context); // Cierra el menú
                                Clipboard.setData(
                                  ClipboardData(text: widget.text!),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Mensaje copiado al portapapeles',
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),

                          // --- FIN DE CORRECCIÓN 2 ---
                          if (widget.isMine &&
                              widget.tipoContenido == 'texto' &&
                              widget.onEdit != null)
                            ListTile(
                              leading: const Icon(Icons.edit),
                              title: const Text('Editar'),
                              onTap: () {
                                Navigator.pop(context);
                                widget.onEdit!();
                              },
                            ),
                          if (widget.isMine && widget.onDelete != null)
                            ListTile(
                              leading: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              title: const Text(
                                'Eliminar',
                                style: TextStyle(color: Colors.red),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                widget.onDelete!();
                              },
                            ),
                          if (widget.onReact != null)
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
                margin: EdgeInsets.zero,
                alignment:
                    widget.isMine ? Alignment.topRight : Alignment.topLeft,
                child: Container(
                  padding: contentPadding,
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        widget.isMine
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildContentWidget(context),
                      if (widget.reactions.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Wrap(
                            alignment:
                                widget.isMine
                                    ? WrapAlignment.end
                                    : WrapAlignment.start,
                            spacing: 4,
                            runSpacing: 2,
                            children:
                                widget.reactions.entries
                                    .map(
                                      (e) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          '${e.key} ${e.value > 1 ? e.value : ''}'
                                              .trim(),
                                          style: TextStyle(
                                            fontSize: 11,
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
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 4.0,
                          left: 8.0,
                          right: 8.0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
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
                                        ? Colors.lightBlueAccent.shade100
                                        : Colors.white70,
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
          if (widget.isMine)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: CircleAvatar(
                radius: 16,
                backgroundImage:
                    widget.avatarUrl.isNotEmpty
                        ? CachedNetworkImageProvider(widget.avatarUrl)
                        : const AssetImage('assets/images/avatar1.webp')
                            as ImageProvider,
              ),
            ),
        ],
      ),
    );
  }
}
