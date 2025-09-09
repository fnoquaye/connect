
import 'package:connect/APIs/apis.dart';
import 'package:connect/models/chat_user.dart';
import 'package:flutter/material.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Connection Requests"),
      ),
      body: StreamBuilder(
        stream: APIS.firestore
            .collection('users')
            .doc(APIS.user.uid)
            .collection('connection_requests')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              snapshot.connectionState == ConnectionState.none) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text("No pending requests"),
            );
          }

          final requests = docs.map((e) => ChatUser.fromJson(e.data())).toList();

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final user = requests[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(user.image),
                  ),
                  title: Text(user.name),
                  subtitle: Text(user.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () async {
                          await APIS.acceptConnectionRequest(user);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("You are now connected with ${user.name}")),
                          );
                        },
                        child: const Text("Accept"),
                      ),
                      TextButton(
                        onPressed: () async {
                          await APIS.declineConnectionRequest(user);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Declined request from ${user.name}")),
                          );
                        },
                        child: const Text("Decline", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
