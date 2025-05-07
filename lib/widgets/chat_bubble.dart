import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:intl/intl.dart';

typedef BubbleCallback = void Function();

class ChatBubbleCustom extends StatelessWidget {
  final bool isMine;
  final bool read;
  final String avatarUrl;
  final String authorName;
  final String text;
  final DateTime time;
  final bool edited;
  final bool deleted;
  final Map<String, int> reactions;
  final bool showName;
  final BubbleCallback? onEdit;
  final BubbleCallback? onDelete;
  final BubbleCallback? onReact;

  const ChatBubbleCustom({
    super.key,
    required this.isMine,
    required this.read,
    required this.avatarUrl,
    required this.authorName,
    required this.text,
    required this.time,
    this.edited = false,
    this.deleted = false,
    this.reactions = const {},
    this.showName = true,
    this.onEdit,
    this.onDelete,
    this.onReact,
  });

  String _formatTime(DateTime dt) => DateFormat.Hm().format(dt);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMine)
            CircleAvatar(
              radius: 14,
              backgroundImage:
                  avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : const AssetImage('assets/images/avatar1.png')
                          as ImageProvider,
            ),
          const SizedBox(width: 6),

          // Aquí envolvemos el ChatBubble en un GestureDetector
          GestureDetector(
            onLongPress: () {
              showModalBottomSheet(
                context: context,
                builder:
                    (_) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isMine && !deleted) ...[
                          ListTile(
                            leading: const Icon(Icons.edit),
                            title: const Text('Editar'),
                            onTap: onEdit,
                          ),
                          ListTile(
                            leading: const Icon(Icons.delete),
                            title: const Text('Eliminar'),
                            onTap: onDelete,
                          ),
                        ],
                        ListTile(
                          leading: const Icon(Icons.emoji_emotions),
                          title: const Text('Reaccionar'),
                          onTap: onReact,
                        ),
                      ],
                    ),
              );
            },
            child: ChatBubble(
              clipper: ChatBubbleClipper1(
                type:
                    isMine ? BubbleType.sendBubble : BubbleType.receiverBubble,
              ),
              backGroundColor:
                  deleted
                      ? Colors.grey[400]!
                      : isMine
                      ? Colors.purple.shade200
                      : Colors.grey.shade300,
              margin: EdgeInsets.zero,
              alignment: isMine ? Alignment.topRight : Alignment.topLeft,
              child: Container(
                padding: const EdgeInsets.all(10),
                constraints: const BoxConstraints(maxWidth: 280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showName) ...[
                      Text(
                        authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      deleted ? 'Mensaje eliminado' : text,
                      style: const TextStyle(fontSize: 15, height: 1.3),
                    ),
                    if (reactions.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children:
                            reactions.entries
                                .map(
                                  (e) => Text(
                                    '${e.key} ${e.value}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (edited && !deleted)
                          const Text(
                            '(editado) ',
                            style: TextStyle(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        Text(
                          _formatTime(time),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 4),
                          Icon(
                            read ? Icons.done_all : Icons.check,
                            size: 14,
                            color: read ? Colors.blue : Colors.black54,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),
          if (isMine)
            CircleAvatar(
              radius: 14,
              backgroundImage:
                  avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : const AssetImage('assets/images/avatar1.png')
                          as ImageProvider,
            ),
        ],
      ),
    );
  }
}
