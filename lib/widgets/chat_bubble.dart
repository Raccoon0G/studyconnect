import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_chat_bubble/bubble_type.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_1.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

// Solo para web, si decides construir HtmlElementView aquí
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
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingAudio = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  PlayerState? _audioPlayerState;

  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isVideoPlayerInitialized = false;

  static final Set<String> _registeredViewFactories = {}; // Para web

  @override
  void initState() {
    super.initState();
    if (widget.tipoContenido == 'audio' &&
        widget.urlContenido != null &&
        widget.urlContenido!.isNotEmpty) {
      _initAudioPlayer();
    } else if (widget.tipoContenido == 'video' &&
        widget.urlContenido != null &&
        widget.urlContenido!.isNotEmpty &&
        !kIsWeb) {
      _initializeVideoPlayerMobile();
    }
  }

  void _initAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _audioDuration = d);
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _audioPosition = p);
    });
    _audioPlayer.onPlayerStateChanged.listen((s) {
      if (mounted) {
        setState(() {
          _audioPlayerState = s;
          _isPlayingAudio = s == PlayerState.playing;
        });
      }
    });
    if (widget.urlContenido != null && widget.urlContenido!.isNotEmpty) {
      _audioPlayer.setSourceUrl(widget.urlContenido!).catchError((e) {
        print("Error al configurar la fuente de audio en initState: $e");
      });
    }
  }

  Future<void> _initializeVideoPlayerMobile() async {
    if (widget.urlContenido == null || widget.urlContenido!.isEmpty) return;
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.urlContenido!),
    );

    try {
      await _videoPlayerController!.initialize();
      if (_videoPlayerController!.value.isInitialized) {
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
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
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
      } else {
        throw Exception(
          "VideoPlayerController no se inicializó correctamente (móvil).",
        );
      }
    } catch (e) {
      print("Error al inicializar VideoPlayer (móvil): $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error al cargar video.")));
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.release(); // Mejor que dispose para audioplayers >1.0.0
    _audioPlayer.dispose();
    _chewieController?.dispose();
    _videoPlayerController?.dispose(); // Dispose video controller
    super.dispose();
  }

  Future<void> _toggleAudioPlay() async {
    if (widget.urlContenido == null || widget.urlContenido!.isEmpty) return;
    try {
      if (_isPlayingAudio) {
        await _audioPlayer.pause();
      } else {
        if (_audioPlayerState == PlayerState.paused) {
          await _audioPlayer.resume();
        } else {
          await _audioPlayer.stop();
          await _audioPlayer.setSourceUrl(widget.urlContenido!);
          await _audioPlayer.resume();
        }
      }
    } catch (e) {
      print("Error al reproducir/pausar audio: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error con audio: ${e.toString()}')),
        );
        setState(() => _isPlayingAudio = false);
      }
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    if (d.inHours > 0) {
      return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  // ESTA ES LA FUNCIÓN QUE FALTABA
  String _formatTime(DateTime dt) {
    return DateFormat.Hm().format(dt); // Formato HH:mm (ej: 17:05)
  }

  Future<void> _launchUrl(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    final Uri? uri = Uri.tryParse(urlString);
    if (uri != null) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo abrir: $urlString')),
          );
      }
    } else {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Enlace no válido: $urlString')));
    }
  }

  Widget _buildVideoPlayerWeb(String url) {
    final viewId =
        'web_video_player_${url.hashCode}_${DateTime.now().microsecondsSinceEpoch}';
    if (kIsWeb && !_registeredViewFactories.contains(viewId)) {
      _registeredViewFactories.add(viewId);
      // Asegúrate que 'ui' es 'dart:ui_web'
      ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
        return html.VideoElement()
          ..src = url
          ..controls = true
          ..autoplay =
              false // No autoPlay por defecto
          ..style.width = '100%'
          ..style.height =
              '100%' // Chewie lo maneja con AspectRatio
          ..style.borderRadius = '8px'
          ..style.objectFit = 'contain'; // Para que el video se vea completo
      });
    }
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: HtmlElementView(viewType: viewId),
    );
  }

  Widget _buildAudioPlayerWeb(String url, String fileName) {
    final viewId =
        'web_audio_player_${url.hashCode}_${DateTime.now().microsecondsSinceEpoch}';
    if (kIsWeb && !_registeredViewFactories.contains(viewId)) {
      _registeredViewFactories.add(viewId);
      ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
        // Crear un div para el nombre y luego el audio
        final div =
            html.DivElement()
              ..style.display = 'flex'
              ..style.flexDirection = 'column'
              ..style.alignItems =
                  'flex-start'; // Para alinear el nombre a la izquierda

        // No es fácil estilizar el nombre del archivo encima del reproductor HTML nativo
        // de forma consistente. Por simplicidad, solo el reproductor.
        // Si necesitas el nombre, considera no usar HtmlElementView para audio en web
        // y usar audioplayers package que también tiene soporte web.

        final audio =
            html.AudioElement()
              ..src = url
              ..controls = true
              ..style.width = '100%'; // Que ocupe el ancho disponible

        div.append(audio);
        return div;
      });
    }
    return SizedBox(height: 50, child: HtmlElementView(viewType: viewId));
  }

  Widget _buildYoutubePreviewWidget({
    required bool isMine,
    String? videoId,
    required String title,
    String? thumbnailUrl,
    required String originalUrl,
  }) {
    // Si no tenemos un videoId explícito (porque vino de un texto plano), intentamos extraerlo
    final String effectiveVideoId =
        videoId ?? _extractYoutubeIdFromUrl(originalUrl) ?? '';

    return GestureDetector(
      onTap:
          () => _launchUrl(
            originalUrl,
          ), // Usa la URL original que es el texto del mensaje
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(11),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: thumbnailUrl,
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
                                  widget.isMine
                                      ? Colors.white54
                                      : Theme.of(context).primaryColor,
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
                              color:
                                  widget.isMine
                                      ? Colors.white54
                                      : Colors.grey[400],
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
              title,
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
              _isPlayingAudio
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
                            ? Colors.white.withOpacity(0.9)
                            : Colors.black.withOpacity(0.9),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (_audioDuration.inSeconds > 0 ||
                    _audioPlayerState == PlayerState.playing ||
                    _audioPlayerState == PlayerState.paused)
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor:
                          widget.isMine
                              ? Colors.white
                              : Theme.of(context).colorScheme.primary,
                      inactiveTrackColor:
                          widget.isMine ? Colors.white30 : Colors.grey.shade400,
                      thumbColor:
                          widget.isMine
                              ? Colors.white
                              : Theme.of(context).colorScheme.primary,
                      overlayColor:
                          widget.isMine
                              ? Colors.white.withAlpha(32)
                              : Theme.of(
                                context,
                              ).colorScheme.primary.withAlpha(32),
                      trackHeight: 2.5,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 7.0,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14.0,
                      ),
                    ),
                    child: Slider(
                      min: 0.0,
                      max:
                          _audioDuration.inSeconds.toDouble() > 0
                              ? _audioDuration.inSeconds.toDouble()
                              : 1.0,
                      value: _audioPosition.inSeconds.toDouble().clamp(
                        0.0,
                        _audioDuration.inSeconds.toDouble().isFinite &&
                                _audioDuration.inSeconds.toDouble() > 0
                            ? _audioDuration.inSeconds.toDouble()
                            : 1.0,
                      ),
                      onChanged: (value) async {
                        final position = Duration(seconds: value.toInt());
                        await _audioPlayer.seek(position);
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    _audioDuration.inSeconds > 0
                        ? "${_formatDuration(_audioPosition)} / ${_formatDuration(_audioDuration)}"
                        : (_audioPlayerState == PlayerState.playing ||
                                _audioPlayerState == PlayerState.paused
                            ? _formatDuration(_audioPosition)
                            : "00:00"),
                    style: TextStyle(
                      fontSize: 10,
                      color: widget.isMine ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentWidget(BuildContext context) {
    if (widget.deleted || widget.tipoContenido == 'texto_eliminado') {
      return Text(
        widget.text ?? 'Mensaje eliminado',
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
      case 'imagen':
      case 'gif':
        mediaContent =
            widget.urlContenido != null
                ? GestureDetector(
                  onTap: () {
                    /* Tu lógica para ver imagen en pantalla completa */
                  },
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                      maxWidth: MediaQuery.of(context).size.width * 0.65,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: CachedNetworkImage(
                        imageUrl: widget.urlContenido!,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Container(
                              height: 150,
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
                ? (kIsWeb
                    ? _buildVideoPlayerWeb(widget.urlContenido!)
                    : (_isVideoPlayerInitialized &&
                            _chewieController != null &&
                            _videoPlayerController!.value.isInitialized
                        ? AspectRatio(
                          aspectRatio:
                              _videoPlayerController!.value.aspectRatio,
                          child: Chewie(controller: _chewieController!),
                        )
                        : InkWell(
                          // Fallback para móvil si el video no carga o como placeholder
                          onTap: () => _launchUrl(widget.urlContenido),
                          child: Container(
                            height: 150,
                            width:
                                MediaQuery.of(context).size.width *
                                0.6, // Ancho similar a imágenes
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
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
                    ? _buildAudioPlayerWeb(
                      widget.urlContenido!,
                      widget.nombreArchivo ?? 'Audio',
                    )
                    : _buildAudioPlayerMobile())
                : const Text('[Error: URL de audio no disponible]');
        break;

      case 'youtube_link':
        mediaContent = _buildYoutubePreviewWidget(
          isMine: widget.isMine,
          // Si youtubeVideoId no viene de Firestore (mensajes antiguos), intenta extraerlo de text (que sería la URL)
          videoId:
              widget.youtubeVideoId ??
              _extractYoutubeIdFromUrl(widget.text ?? '') ??
              '',
          title: widget.youtubeTitle ?? 'Video de YouTube',
          thumbnailUrl: widget.youtubeThumbnail,
          originalUrl:
              widget.text ??
              widget.urlContenido ??
              'https://www.youtube.com/watch?v=${widget.youtubeVideoId ?? ''}',
        );
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

      default: // 'texto'
        mediaContent = Text(
          widget.text ?? '',
          style: TextStyle(
            fontSize: 15,
            height: 1.3,
            color: widget.isMine ? Colors.white : Colors.black87,
          ),
        );
    }

    List<Widget> children = [];
    if (widget.showName && !widget.isMine && widget.authorName.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 3.0, left: 8.0),
          child: Text(
            widget.authorName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color:
                  widget.isMine
                      ? Colors.white70
                      : Colors.black.withOpacity(0.7),
            ),
          ),
        ),
      );
    }

    children.add(mediaContent);

    // Mostrar caption (widget.text) debajo si es multimedia y el texto no es la URL de YouTube
    bool isYoutubeLinkWhereTextIsUrl =
        widget.tipoContenido == 'youtube_link' &&
        (widget.text == widget.urlContenido ||
            widget.text ==
                'https://www.youtube.com/watch?v=${widget.youtubeVideoId}');

    if (widget.tipoContenido != 'texto' &&
        widget.tipoContenido != 'texto_eliminado' &&
        !isYoutubeLinkWhereTextIsUrl && // No mostrar la URL de YT como caption si ya se muestra el preview
        widget.text != null &&
        widget.text!.trim().isNotEmpty) {
      children.add(const SizedBox(height: 6));
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
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
      crossAxisAlignment:
          widget.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    Color bubbleBackgroundColor =
        widget.deleted
            ? (widget.isMine ? Colors.grey.shade700 : Colors.grey.shade300)
            : widget.isMine
            ? Theme.of(context).colorScheme.primary
            : const Color(0xFFE7E7ED);

    EdgeInsets contentPadding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 8,
    );
    bool hasMediaWithoutStandardPadding =
        widget.tipoContenido == 'imagen' ||
        widget.tipoContenido == 'gif' ||
        widget.tipoContenido == 'video' ||
        widget.tipoContenido == 'youtube_link';

    if (hasMediaWithoutStandardPadding &&
        (widget.text == null ||
            widget.text!.trim().isEmpty ||
            widget.tipoContenido == 'youtube_link')) {
      contentPadding =
          widget.tipoContenido == 'youtube_link' ||
                  widget.tipoContenido == 'video'
              ? EdgeInsets.zero
              : const EdgeInsets.all(3);
    } else if (widget.tipoContenido == 'audio') {
      contentPadding = const EdgeInsets.symmetric(horizontal: 2, vertical: 0);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 8),
      child: Row(
        mainAxisAlignment:
            widget.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!widget.isMine)
            Padding(
              padding: const EdgeInsets.only(right: 6.0, bottom: 5.0),
              child: CircleAvatar(
                radius: 14,
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
                if (widget.deleted && !widget.isMine) return;
                showModalBottomSheet(
                  backgroundColor: Theme.of(context).canvasColor,
                  context: context,
                  builder:
                      (_) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.isMine &&
                              !widget.deleted &&
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
                          if (widget.isMine &&
                              !widget.deleted &&
                              widget.onDelete != null)
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
                          if (!widget.deleted && widget.onReact != null)
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
                    maxWidth:
                        MediaQuery.of(context).size.width *
                        (kIsWeb ? 0.5 : 0.75),
                  ), // Burbujas más anchas en web
                  child: Column(
                    crossAxisAlignment:
                        widget.isMine
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildContentWidget(context),
                      if (widget.reactions.isNotEmpty && !widget.deleted) ...[
                        const SizedBox(height: 4),
                        Wrap(
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
                                        color:
                                            widget.isMine
                                                ? Colors.black.withOpacity(0.2)
                                                : Colors.black.withOpacity(
                                                  0.08,
                                                ),
                                        borderRadius: BorderRadius.circular(10),
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
                      ],
                      if (!widget.deleted)
                        Padding(
                          padding: EdgeInsets.only(
                            top:
                                (widget.tipoContenido == 'audio' ||
                                        hasMediaWithoutStandardPadding)
                                    ? 3.0
                                    : 5.0,
                            left: 8,
                            right: 8,
                          ),
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
          if (widget.isMine)
            Padding(
              padding: const EdgeInsets.only(left: 6.0, bottom: 5.0),
              child: CircleAvatar(
                radius: 14,
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

  String? _extractYoutubeIdFromUrl(String url) {
    // Helper duplicado aquí para uso interno de _buildYoutubePreviewInBubble
    if (!url.contains("http") && !url.contains("www.")) return null;
    RegExp regExp = RegExp(
      r'.*(?:(?:youtu\.be\/|v\/|vi\/|u\/\w\/|embed\/|shorts\/)|(?:(?:watch)?\?v(?:i)?=|\&v(?:i)?=))([^#\&\?]*).*',
      caseSensitive: false,
      multiLine: false,
    );
    final match = regExp.firstMatch(url);
    if (match != null && match.group(1) != null && match.group(1)!.length == 11)
      return match.group(1);
    return null;
  }
}
