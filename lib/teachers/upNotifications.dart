import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UploadNotificationsPage extends StatefulWidget {
  const UploadNotificationsPage({Key? key}) : super(key: key);

  @override
  State<UploadNotificationsPage> createState() =>
      _UploadNotificationsPageState();
}

class _UploadNotificationsPageState extends State<UploadNotificationsPage> {
  String? selectedYear;
  String? selectedDepartment;
  final List<String> yearList = ['SY', 'TY', 'B.Tech'];
  final List<String> departmentList = ['CSE', 'AIDS'];
  final titleController = TextEditingController();
  final descController = TextEditingController();
  bool isUploading = false;

  Future<void> uploadNotification() async {
    if (selectedYear == null ||
        selectedDepartment == null ||
        titleController.text.trim().isEmpty ||
        descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields.')));
      return;
    }
    setState(() => isUploading = true);

    await FirebaseFirestore.instance.collection('notifications').add({
      'year': selectedYear,
      'department': selectedDepartment,
      'title': titleController.text.trim(),
      'description': descController.text.trim(),
      'uploadedAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      titleController.clear();
      descController.clear();
      isUploading = false;
      selectedYear = null;
      selectedDepartment = null;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Notification posted!')));
  }

  Future<void> deleteNotification(String docId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .delete();
    setState(() {}); // Refresh UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Post Notification',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedYear,
              hint: const Text('Select Year'),
              items:
                  yearList
                      .map(
                        (year) =>
                            DropdownMenuItem(value: year, child: Text(year)),
                      )
                      .toList(),
              onChanged: (val) => setState(() => selectedYear = val),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedDepartment,
              hint: const Text('Select Department'),
              items:
                  departmentList
                      .map(
                        (dept) =>
                            DropdownMenuItem(value: dept, child: Text(dept)),
                      )
                      .toList(),
              onChanged: (val) => setState(() => selectedDepartment = val),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isUploading ? null : uploadNotification,
              child:
                  isUploading
                      ? const CircularProgressIndicator()
                      : const Text('Post Notification'),
            ),
            const SizedBox(height: 16),
            if (selectedYear != null && selectedDepartment != null)
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('notifications')
                          .where('year', isEqualTo: selectedYear)
                          .where('department', isEqualTo: selectedDepartment)
                          .orderBy('uploadedAt', descending: true)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text('No notifications posted yet.'),
                      );
                    }
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, idx) {
                        final doc = docs[idx];
                        final data = doc.data() as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
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
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await deleteNotification(doc.id);
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
