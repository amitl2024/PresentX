import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadAcademicCalendarPage extends StatefulWidget {
  const UploadAcademicCalendarPage({Key? key}) : super(key: key);

  @override
  State<UploadAcademicCalendarPage> createState() =>
      _UploadAcademicCalendarPageState();
}

class _UploadAcademicCalendarPageState
    extends State<UploadAcademicCalendarPage> {
  String? selectedClass;
  final List<String> classList = ['SY', 'TY', 'B.Tech'];
  final descController = TextEditingController();
  List<PlatformFile> pickedFiles = [];
  bool isUploading = false;

  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null) {
      setState(() {
        pickedFiles = result.files;
      });
    }
  }

  Future<String?> uploadFileToSupabase(PlatformFile file) async {
    final storage = Supabase.instance.client.storage;
    final fileBytes = file.bytes ?? await File(file.path!).readAsBytes();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';

    final response = await storage
        .from('academiccalendar') // changed bucket name
        .uploadBinary(
          fileName,
          fileBytes,
          fileOptions: const FileOptions(upsert: true),
        );

    if (response.isEmpty) return null;

    // Get the public URL
    final publicUrl = storage
        .from('academiccalendar')
        .getPublicUrl(fileName); // changed bucket name
    return publicUrl;
  }

  Future<void> uploadCalendar() async {
    if (selectedClass == null || pickedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select class and files.')),
      );
      return;
    }
    setState(() => isUploading = true);

    List<String> fileUrls = [];
    for (var file in pickedFiles) {
      final url = await uploadFileToSupabase(file);
      if (url != null) {
        fileUrls.add(url);
      }
    }

    await FirebaseFirestore.instance.collection('academic_calendar').add({
      'class': selectedClass,
      'description': descController.text.trim(),
      'files': fileUrls,
      'uploadedAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      pickedFiles = [];
      descController.clear();
      isUploading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Academic Calendar uploaded!')),
    );
  }

  Future<void> deleteFileFromSupabase(String fileUrl) async {
    final storage = Supabase.instance.client.storage;
    final uri = Uri.parse(fileUrl);
    final segments = uri.pathSegments;
    final index = segments.indexOf('academiccalendar'); // changed bucket name
    if (index == -1 || index + 1 >= segments.length) return;
    final fileName = segments.sublist(index + 1).join('/');

    await storage.from('academiccalendar').remove([
      fileName,
    ]); // changed bucket name
  }

  Future<void> deleteCalendar(String docId, List<dynamic> fileUrls) async {
    // Delete files from Supabase Storage
    for (var url in fileUrls) {
      try {
        await deleteFileFromSupabase(url);
      } catch (e) {
        // Ignore errors for missing files
      }
    }
    // Delete Firestore document
    await FirebaseFirestore.instance
        .collection('academic_calendar')
        .doc(docId)
        .delete();
    setState(() {}); // Refresh UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Academic Calendar',
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
              value: selectedClass,
              hint: const Text('Select Class'),
              items:
                  classList
                      .map(
                        (cls) => DropdownMenuItem(value: cls, child: Text(cls)),
                      )
                      .toList(),
              onChanged: (val) => setState(() => selectedClass = val),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: pickFiles,
              icon: const Icon(Icons.attach_file),
              label: const Text('Pick Calendar Files (PDF/Images)'),
            ),
            const SizedBox(height: 8),
            if (pickedFiles.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children:
                      pickedFiles
                          .map(
                            (file) => Card(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(file.name),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
            ElevatedButton(
              onPressed: isUploading ? null : uploadCalendar,
              child:
                  isUploading
                      ? const CircularProgressIndicator()
                      : const Text('Upload Academic Calendar'),
            ),
            const SizedBox(height: 16),
            if (selectedClass != null)
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('academic_calendar')
                          .where('class', isEqualTo: selectedClass)
                          .orderBy('uploadedAt', descending: true)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text('No academic calendar uploaded yet.'),
                      );
                    }
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, idx) {
                        final doc = docs[idx];
                        final data = doc.data() as Map<String, dynamic>;
                        final files = List<String>.from(data['files'] ?? []);
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(
                              data['description'] ?? 'No Description',
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...files.map(
                                  (url) => InkWell(
                                    child: Text(
                                      url.split('/').last,
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    onTap: () {
                                      // Optionally open the file in browser
                                    },
                                  ),
                                ),
                                Text(
                                  'Uploaded: ${data['uploadedAt'] != null ? (data['uploadedAt'] as Timestamp).toDate().toString().substring(0, 16) : ''}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await deleteCalendar(doc.id, files);
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
