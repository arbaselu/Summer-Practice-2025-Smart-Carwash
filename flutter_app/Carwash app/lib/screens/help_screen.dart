import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _controller = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  String? activeTicketId;
  bool isTicketClosed = false;

  @override
  void initState() {
    super.initState();
    _checkActiveTicket();
  }

  void _checkActiveTicket() async {
    if (user == null) return;
    final query = await FirebaseFirestore.instance
        .collection('chats')
        .where('userId', isEqualTo: user!.uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      setState(() {
        activeTicketId = doc.id;
        isTicketClosed = doc['status'] == 'closed';
      });
    }
  }

  Future<void> _createNewTicket(String text) async {
    final ticketRef = FirebaseFirestore.instance.collection('chats').doc();
    activeTicketId = ticketRef.id;

    await ticketRef.set({
      'userId': user!.uid,
      'userName': user!.displayName ?? 'Client',
      'status': 'open',
      'createdAt': Timestamp.now(),
    });

    await ticketRef.collection('messages').add({
      'text': text,
      'sender': 'client',
      'timestamp': Timestamp.now(),
    });

    setState(() {
      isTicketClosed = false;
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || user == null || isTicketClosed) return;

    if (activeTicketId == null) {
      await _createNewTicket(text);
    } else {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(activeTicketId)
          .collection('messages')
          .add({
        'text': text,
        'sender': 'client',
        'timestamp': Timestamp.now(),
      });
    }

    _controller.clear();
  }

  void _callSupport() async {
    final Uri uri = Uri(scheme: 'tel', path: 'nr_tel');
    if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
      throw Exception('Nu se poate iniția apelul.');
    }
  }

  Widget _buildNoTicketUI() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _callSupport,
          icon: const Icon(Icons.phone),
          label: const Text('Sună la suport'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
        ),
        const SizedBox(height: 12),
        const Text('Trimite un mesaj către un administrator:'),
        const SizedBox(height: 8),
        const Expanded(
          child: Center(child: Text('Niciun mesaj până acum.')),
        ),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Padding(
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
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajutor')),
      body: activeTicketId == null
          ? _buildNoTicketUI()
          : StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .doc(activeTicketId)
            .snapshots(),
        builder: (context, ticketSnapshot) {
          // dacă nu exista tichet sters sau null, permite trimiterea
          if (!ticketSnapshot.hasData || !ticketSnapshot.data!.exists) {
            return _buildNoTicketUI();
          }

          final isTicketClosed = ticketSnapshot.data?['status'] == 'closed';

          return Column(
            children: [
              ElevatedButton.icon(
                onPressed: _callSupport,
                icon: const Icon(Icons.phone),
                label: const Text('Sună la suport'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent),
              ),
              const SizedBox(height: 12),
              const Text('Trimite un mesaj către un administrator:'),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .doc(activeTicketId)
                      .collection('messages')
                      .orderBy('timestamp')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const CircularProgressIndicator();
                    final messages = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index].data() as Map<
                            String,
                            dynamic>;
                        final isClient = msg['sender'] == 'client';
                        return Align(
                          alignment: isClient
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 14),
                            decoration: BoxDecoration(
                              color: isClient ? Colors.blue[100] : Colors
                                  .green[100],
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(12),
                                topRight: const Radius.circular(12),
                                bottomLeft: isClient
                                    ? const Radius.circular(12)
                                    : Radius.zero,
                                bottomRight: isClient
                                    ? Radius.zero
                                    : const Radius.circular(12),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(msg['text'] ?? '',
                                    style: const TextStyle(fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(
                                  isClient ? 'Eu' : 'Admin',
                                  style: const TextStyle(fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black54),
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
              isTicketClosed
                  ? Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    const Text(
                      'Tichetul a fost închis.',
                      style: TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          activeTicketId = null;
                        });
                      },
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Deschide un nou tichet'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  ],
                ),
              )
                  : _buildMessageInput(),
            ],
          );
        },
      ),
    );
  }
}
