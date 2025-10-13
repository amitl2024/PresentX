import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UploadAssignmentPage extends StatefulWidget {
  const UploadAssignmentPage({super.key});

  @override
  State<UploadAssignmentPage> createState() => _UploadAssignmentPageState();
}

class _UploadAssignmentPageState extends State<UploadAssignmentPage> {
  String? selectedClass;
  String? teacherDepartment;
  final titleController = TextEditingController();
  final descController = TextEditingController();
  PlatformFile? pickedFile;
  String? fileName;
  bool isUploading = false;

  final List<String> classList = ['SY', 'TY', 'B.Tech'];
  String? teacherName;

  @override
  void initState() {
    super.initState();
    fetchTeacherInfo();
  }

  Future<void> fetchTeacherInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('teachers')
            .doc(user.uid)
            .get();
    final data = doc.data();
    setState(() {
      teacherName = data?['name'];
      teacherDepartment = data?['department'];
    });
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        pickedFile = result.files.single;
        fileName = result.files.single.name;
      });
    }
  }

  Future<String?> uploadAssignmentFile(PlatformFile file) async {
    final storage = Supabase.instance.client.storage;
    final fileBytes = file.bytes!;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final response = await storage
        .from('assignment')
        .uploadBinary(
          fileName,
          fileBytes,
          fileOptions: const FileOptions(upsert: true),
        );
    if (response.isEmpty) return null;
    return storage.from('assignment').getPublicUrl(fileName);
  }

  Future<void> uploadAssignment() async {
    if (selectedClass == null ||
        teacherDepartment == null ||
        pickedFile == null ||
        titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and select a file.'),
        ),
      );
      return;
    }
    setState(() => isUploading = true);

    try {
      final fileUrl = await uploadAssignmentFile(pickedFile!);
      if (fileUrl == null) throw Exception('File upload failed');

      // Save assignment info to Firestore
      await FirebaseFirestore.instance.collection('assignments').add({
        'title': titleController.text.trim(),
        'description': descController.text.trim(),
        'fileUrl': fileUrl,
        'fileName': pickedFile!.name,
        'class': selectedClass,
        'department': teacherDepartment,
        'type':
            pickedFile!.extension == 'pdf'
                ? 'pdf'
                : (['jpg', 'jpeg', 'png'].contains(pickedFile!.extension)
                    ? 'image'
                    : 'file'),
        'uploadedBy': teacherName ?? 'Unknown',
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Assignment uploaded!')));
      setState(() {
        pickedFile = null;
        fileName = null;
        titleController.clear();
        descController.clear();
        selectedClass = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() => isUploading = false);
    }
  }

  Future<void> deleteFileFromSupabase(String fileUrl) async {
    final storage = Supabase.instance.client.storage;
    final uri = Uri.parse(fileUrl);
    final segments = uri.pathSegments;
    final assignmentIndex = segments.indexOf('assignment');
    if (assignmentIndex == -1 || assignmentIndex + 1 >= segments.length) return;
    final fileName = segments.sublist(assignmentIndex + 1).join('/');
    await storage.from('assignment').remove([fileName]);
  }

  Future<void> deleteAssignment(String docId, String fileUrl) async {
    try {
      await deleteFileFromSupabase(fileUrl);
    } catch (e) {
      // Ignore errors for missing files
    }
    await FirebaseFirestore.instance
        .collection('assignments')
        .doc(docId)
        .delete();
    setState(() {}); // Refresh UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Assignment'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Assignment Title',
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
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: pickFile,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Choose File'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    fileName ?? 'No file selected',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    isUploading || teacherName == null
                        ? null
                        : uploadAssignment,
                child:
                    isUploading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Upload Assignment'),
              ),
            ),
            const SizedBox(height: 24),
            if (selectedClass != null && teacherDepartment != null)
              SizedBox(
                height: 400,
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('assignments')
                          .where('class', isEqualTo: selectedClass)
                          .where('department', isEqualTo: teacherDepartment)
                          .orderBy('uploadedAt', descending: true)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text('No assignments uploaded yet.'),
                      );
                    }
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, idx) {
                        final doc = docs[idx];
                        final data = doc.data() as Map<String, dynamic>;
                        final fileUrl = data['fileUrl'] as String;
                        final fileType = data['type'] as String;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(
                              data['title'] ?? 'No Title',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (data['description'] != null &&
                                    data['description'].toString().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Text(data['description']),
                                  ),
                                if (fileType == 'image')
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder:
                                              (context) => Dialog(
                                                backgroundColor:
                                                    Colors.transparent,
                                                insetPadding:
                                                    const EdgeInsets.all(16),
                                                child: Stack(
                                                  children: [
                                                    Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                            top: 32,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              16,
                                                            ),
                                                      ),
                                                      padding:
                                                          const EdgeInsets.all(
                                                            16,
                                                          ),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        child: Image.network(
                                                          fileUrl,
                                                          fit: BoxFit.contain,
                                                          errorBuilder:
                                                              (
                                                                context,
                                                                error,
                                                                stackTrace,
                                                              ) => const Text(
                                                                'Could not load image',
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      right: 0,
                                                      top: 0,
                                                      child: IconButton(
                                                        icon: const Icon(
                                                          Icons.close,
                                                          color: Colors.black,
                                                        ),
                                                        onPressed:
                                                            () =>
                                                                Navigator.of(
                                                                  context,
                                                                ).pop(),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                        );
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          fileUrl,
                                          height: 160,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Text(
                                                    'Could not load image',
                                                  ),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (fileType == 'pdf')
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder:
                                              (context) => Dialog(
                                                backgroundColor:
                                                    Colors.transparent,
                                                insetPadding:
                                                    const EdgeInsets.all(16),
                                                child: Stack(
                                                  children: [
                                                    Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                            top: 32,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              16,
                                                            ),
                                                      ),
                                                      padding:
                                                          const EdgeInsets.all(
                                                            16,
                                                          ),
                                                      height: 500,
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        child:
                                                            SfPdfViewer.network(
                                                              fileUrl,
                                                            ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      right: 0,
                                                      top: 0,
                                                      child: IconButton(
                                                        icon: const Icon(
                                                          Icons.close,
                                                          color: Colors.black,
                                                        ),
                                                        onPressed:
                                                            () =>
                                                                Navigator.of(
                                                                  context,
                                                                ).pop(),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                        );
                                      },
                                      child: Container(
                                        height: 160,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.red[50],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.picture_as_pdf,
                                            color: Colors.red,
                                            size: 60,
                                          ),
                                        ),
                                      ),
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
                                await deleteAssignment(doc.id, fileUrl);
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
