import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../APIs/apis.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reported Users'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: APIS.firestore.collection('reports').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data?.docs ?? [];

          if (reports.isEmpty) {
            return const Center(
              child: Text('No reports found'),
            );
          }

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final reportData = reports[index].data();
              final reporterId = reportData['reportedBy'] ?? '';
              final reportedId = reportData['reportedUser'] ?? '';
              final reason = reportData['reason'] ?? 'No reason provided';

              return ListTile(
                leading: const Icon(Icons.report, color: Colors.red),
                title: Text('Reported User ID: $reportedId'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reported By: $reporterId'),
                    Text('Reason: $reason'),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
