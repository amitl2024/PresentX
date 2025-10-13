import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StudentNotificationsPage extends StatelessWidget {
  const StudentNotificationsPage({super.key});

  Future<Map<String, String>?> getStudentYearAndDept() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final year =
        userDoc['class'] as String?; // Assuming 'class' is 'TY', 'SY', etc.
    final department =
        userDoc['department'] as String?; // Assuming you store department
    if (year == null || department == null) return null;
    return {'year': year, 'department': department};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: FutureBuilder<Map<String, String>?>(
        future: getStudentYearAndDept(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('Class or department not found.'));
          }
          final studentYear = data['year'];
          final studentDepartment = data['department'];
          return StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('notifications')
                    .where('year', isEqualTo: studentYear)
                    .where('department', isEqualTo: studentDepartment)
                    .orderBy('uploadedAt', descending: true)
                    .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Center(child: Text('No notifications yet.'));
              }
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, idx) {
                  final data = docs[idx].data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    child: ListTile(
                      title: Text(data['title'] ?? ''),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['description'] ?? ''),
                          Text(
                            'Posted: ${data['uploadedAt'] != null ? (data['uploadedAt'] as Timestamp).toDate().toString().substring(0, 16) : ''}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
