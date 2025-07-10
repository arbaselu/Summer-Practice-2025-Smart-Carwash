import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_messages_screen.dart';
import 'login_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panou Administrativ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _currentTab == 0 ? _buildActiveChats() : _buildClosedChats(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (index) => setState(() => _currentTab = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Tichete active',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Tichete rezolvate',
          ),
        ],
      ),
    );
  }

  Widget _buildActiveChats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('status', whereIn: ['open', 'in_progress'])
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('Nicio conversație activă.'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final chat = docs[index].data() as Map<String, dynamic>;
            final chatDocId = docs[index].id;
            final userUid = chat['userId'];
            final userName = chat['userName'] ?? 'Client';
            final status = chat['status'];
            final createdAt = chat['createdAt']?.toDate();
            final timeStr = createdAt != null ? timeago.format(createdAt, locale: 'en_short') : '';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListTile(
                title: Text(userName),
                subtitle: Text(
                    '${status == 'in_progress' ? 'Tichet în desfășurare' : 'Tichet deschis'} • $timeStr'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.card_giftcard),
                      tooltip: 'Compensează jetoane',
                      onPressed: () => _showCompensateDialog(userUid, userName),
                    ),
                    ElevatedButton(
                      child: const Text('Preia'),
                      onPressed: () async {
                        if (status != 'in_progress') {
                          await FirebaseFirestore.instance
                              .collection('chats')
                              .doc(chatDocId)
                              .update({'status': 'in_progress'});
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              userId: chatDocId,
                              userName: userName,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showCompensateDialog(String userUid, String userName) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Trimite jetoane către $userName'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Număr jetoane'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () async {
              final tokens = int.tryParse(controller.text);
              if (tokens == null || tokens <= 0) return;

              final userDocRef =
              FirebaseFirestore.instance.collection('utilizatori').doc(userUid);
              final userSnap = await userDocRef.get();

              if (!userSnap.exists) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Utilizatorul nu a fost găsit.')),
                );
                Navigator.pop(context);
                return;
              }

              final currentTokens = userSnap.data()?['jetoane'] ?? 0;
              await userDocRef.update({'jetoane': currentTokens + tokens});


              final chatsQuery = await FirebaseFirestore.instance
                  .collection('chats')
                  .where('userId', isEqualTo: userUid)
                  .orderBy('createdAt', descending: true)
                  .limit(1)
                  .get();

              if (chatsQuery.docs.isNotEmpty) {
                final chatId = chatsQuery.docs.first.id;
                await FirebaseFirestore.instance
                    .collection('chats')
                    .doc(chatId)
                    .collection('messages')
                    .add({
                  'text': 'Ai primit $tokens jetoane ca recompensă din partea administratorului.',
                  'sender': 'admin',
                  'timestamp': Timestamp.now(),
                });
              }

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Au fost adăugate $tokens jetoane către $userName.')),
              );
            },
            child: const Text('Trimite'),
          ),
        ],
      ),
    );
  }

  Widget _buildClosedChats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('status', isEqualTo: 'closed')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('Niciun tichet rezolvat.'));
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final chat = docs[index].data() as Map<String, dynamic>;
            final chatDocId = docs[index].id;
            final userName = chat['userName'] ?? 'Client';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListTile(
                title: Text(userName),
                subtitle: const Text('Tichet rezolvat'),
                trailing: IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          userId: chatDocId,
                          userName: userName,
                          isReadOnly: true,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}