import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final bool isReadOnly;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.isReadOnly = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final admin = FirebaseAuth.instance.currentUser;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.userId)
        .collection('messages')
        .add({
      'text': text,
      'sender': admin?.uid,
      'fromAdmin': true,
      'timestamp': DateTime.now(),
    });

    _controller.clear();
  }

  void _closeChat() async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.userId)
        .update({'status': 'closed'});

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat cu ${widget.userName}'),
        actions: [
          if (!widget.isReadOnly)
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Închide conversația',
              onPressed: _closeChat,
            )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.userId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final messages = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final fromAdmin = msg['fromAdmin'] == true;
                    final align = fromAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start;
                    final color = fromAdmin ? Colors.blue[100] : Colors.grey[300];

                    return Column(
                      crossAxisAlignment: align,
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(msg['text'] ?? ''),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          if (!widget.isReadOnly)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Scrie un mesaj...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }
}
