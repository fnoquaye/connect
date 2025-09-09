import 'package:flutter/material.dart';

import '../APIs/apis.dart';
import '../models/chat_user.dart';

class BlockedUserScreen extends StatefulWidget {
  const BlockedUserScreen({super.key});

  @override
  State<BlockedUserScreen> createState() => _BlockedUserScreenState();
}

class _BlockedUserScreenState extends State<BlockedUserScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Blocked Users")),
      body: StreamBuilder(
        stream: APIS.firestore
            .collection('users')
            .doc(APIS.user.uid)
            .collection('blocked')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.docs;
          if (data.isEmpty) {
            return const Center(child: Text("No blocked users"));
          }

          final blocked = data.map((e) => ChatUser.fromJson(e.data())).toList();

          return ListView.builder(
            itemCount: blocked.length,
            itemBuilder: (context, index) {
              final user = blocked[index];
              return ListTile(
                leading: CircleAvatar(backgroundImage: NetworkImage(user.image)),
                title: Text(user.name),
                subtitle: Text(user.email),
                trailing: IconButton(
                  icon: const Icon(Icons.undo),
                  onPressed: () {
                    // unblock
                    APIS.firestore
                        .collection('users')
                        .doc(APIS.user.uid)
                        .collection('blocked')
                        .doc(user.id)
                        .delete();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
