import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spalatorie_auto/services/auth_service.dart';
import 'package:spalatorie_auto/screens/store_screen.dart';
import 'package:spalatorie_auto/screens/bluetooth_screen.dart';
import 'package:spalatorie_auto/screens/wash_options_screen.dart';
import 'package:spalatorie_auto/screens/bluetooth_manager.dart';
import 'dart:async';
import 'package:intl/intl.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final bluetooth = BluetoothManager();

    final List<Widget> tabs = [
      const HomeTab(),
      bluetooth.isConnected && bluetooth.connection != null
          ? WashTab(
        connection: bluetooth.connection!,
        onProgramStarted: (jetoane, programName) async {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null) {
            final userRef = FirebaseFirestore.instance.collection('utilizatori').doc(uid);

            await FirebaseFirestore.instance.runTransaction((transaction) async {
              final snapshot = await transaction.get(userRef);
              final currentTokens = snapshot['jetoane'] ?? 0;
              transaction.update(userRef, {'jetoane': currentTokens - jetoane});
            });

            final now = DateTime.now();

            await FirebaseFirestore.instance
                .collection('utilizatori')
                .doc(uid)
                .collection('istoric')
                .add({
              'actiune': 'Program: $programName, Jetoane: $jetoane',
              'timestamp': now,
            });
          }
        },
      )
          : const Center(
        child: Text(
          'Conectează-te mai întâi la Bluetooth!',
          style: TextStyle(fontSize: 18),
        ),
      ),
      const BluetoothTab(),
      const StoreTab(),
    ];

    return Scaffold(
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.local_car_wash), label: 'Wash'),
          BottomNavigationBarItem(icon: Icon(Icons.bluetooth), label: 'Bluetooth'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Store'),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  Future<Map<String, dynamic>> getUserData(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('utilizatori').doc(uid).get();
    return doc.data() ?? {};
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panou principal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
          )
        ],
      ),
      body: user != null
          ? FutureBuilder<Map<String, dynamic>>(
        future: getUserData(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data ?? {};
          final name = user.displayName ?? data['nume'] ?? 'Utilizator';
          final tokens = data['jetoane'] ?? 0;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.blueAccent,
                        child: Icon(Icons.account_circle, size: 32, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.token, color: Colors.amber),
                                const SizedBox(width: 6),
                                Text('Jetoane: $tokens',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.storefront),
                        label: const Text('Cumpără jetoane'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const StoreTab()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.help_outline),
                        label: const Text('Ajutor'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        onPressed: () {
                          Navigator.pushNamed(context, '/ajutor');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const Text('Istoric activități:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('utilizatori')
                        .doc(user.uid)
                        .collection('istoric')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const Text('Niciun istoric disponibil.');
                      }
                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final item = docs[index].data() as Map<String, dynamic>;
                          final timestamp = (item['timestamp'] as Timestamp).toDate().toLocal();
                          final formatted = DateFormat('yyyy-MM-dd HH:mm').format(timestamp);
                          return ListTile(
                            leading: const Icon(Icons.history),
                            title: Text(item['actiune'] ?? '---'),
                            subtitle: Text(formatted),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      )
          : const Center(child: Text('Nicio sesiune activă.')),
    );
  }
}




