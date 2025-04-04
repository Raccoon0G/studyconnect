import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final List<String> allUsers = [
    'Jonathan Valdez',
    'Jonathan Santiago',
    'Jonathan Patterson',
    'Jonathan XD',
    'Jonathan Perez',
  ];
  List<String> filteredUsers = [];
  List<Map<String, dynamic>> messages = [
    {'text': 'Hola, me puedes ayudar?', 'isMe': true, 'time': '8:30'},
    {'text': 'Claro en que puedo ayudarte!', 'isMe': false, 'time': '8:30'},
  ];

  @override
  void initState() {
    super.initState();
    filteredUsers = allUsers;
  }

  void _filterUsers(String query) {
    setState(() {
      filteredUsers =
          allUsers
              .where((u) => u.toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({'text': text, 'isMe': true, 'time': '8:31'});
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF036799),
      appBar: AppBar(
        backgroundColor: const Color(0xFF048DD2),
        title: const Text('Study Connect'),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Inicio', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Ranking', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Contenidos',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Perfil',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Panel izquierdo: búsqueda
            Container(
              width: 250,
              decoration: BoxDecoration(
                color: const Color(0xFF48C9EF),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: _filterUsers,
                    decoration: InputDecoration(
                      hintText: 'Jonathan',
                      fillColor: Colors.white,
                      filled: true,
                      suffixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(Icons.search),
                          title: Text(filteredUsers[index]),
                          onTap: () {}, // cambiar chat
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Panel derecho: chat
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEFEF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // Header de conversación
                    Row(
                      children: const [
                        CircleAvatar(
                          backgroundImage: AssetImage(
                            'assets/images/avatar1.png',
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Jonathan Patterson',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 10),
                        Text('Online', style: TextStyle(color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Lista de mensajes
                    Expanded(
                      child: ListView.builder(
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          return Align(
                            alignment:
                                msg['isMe']
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    msg['isMe']
                                        ? Colors.purple.shade100
                                        : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(msg['text']),
                                  Text(
                                    msg['time'],
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Input de mensaje
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Tengo duda en tu ejercicio',
                              fillColor: Colors.white,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _sendMessage,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
