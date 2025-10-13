import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UploadSyllabusPage extends StatefulWidget {
  const UploadSyllabusPage({Key? key}) : super(key: key);

  @override
  State<UploadSyllabusPage> createState() => _UploadSyllabusPageState();
}

class _UploadSyllabusPageState extends State<UploadSyllabusPage> {
  String? selectedYear;
  String? teacherDepartment;
  final List<String> yearList = ['SY', 'TY', 'B.Tech'];
  final descController = TextEditingController();
  List<PlatformFile> pickedFiles = [];
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    fetchTeacherDepartment();
  }

  Future<void> fetchTeacherDepartment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('teachers')
            .doc(user.uid)
            .get();
    setState(() {
      teacherDepartment = doc.data()?['department'];
    });
  }

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
        .from('syllabus')
        .uploadBinary(
          fileName,
          fileBytes,
          fileOptions: const FileOptions(upsert: true),
        );

    if (response.isEmpty) return null;

    // Get the public URL
    final publicUrl = storage.from('syllabus').getPublicUrl(fileName);
    return publicUrl;
  }

  Future<void> uploadSyllabus() async {
    if (selectedYear == null ||
        teacherDepartment == null ||
        pickedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select year and files.')),
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

    await FirebaseFirestore.instance.collection('syllabus').add({
      'year': selectedYear,
      'department': teacherDepartment,
      'description': descController.text.trim(),
      'files': fileUrls,
      'uploadedAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      pickedFiles = [];
      descController.clear();
      isUploading = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Syllabus uploaded!')));
  }

  Future<void> deleteFileFromSupabase(String fileUrl) async {
    final storage = Supabase.instance.client.storage;
    final uri = Uri.parse(fileUrl);
    final segments = uri.pathSegments;
    final syllabusIndex = segments.indexOf('syllabus');
    if (syllabusIndex == -1 || syllabusIndex + 1 >= segments.length) return;
    final fileName = segments.sublist(syllabusIndex + 1).join('/');

    await storage.from('syllabus').remove([fileName]);
  }

  Future<void> deleteSyllabus(String docId, List<dynamic> fileUrls) async {
    for (var url in fileUrls) {
      try {
        await deleteFileFromSupabase(url);
      } catch (e) {
        // Ignore errors for missing files
      }
    }
    await FirebaseFirestore.instance.collection('syllabus').doc(docId).delete();
    setState(() {}); // Refresh UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Upload Syllabus',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 12),

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
              label: const Text('Pick Syllabus Files (PDF/Images)'),
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
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: isUploading ? null : uploadSyllabus,
              child:
                  isUploading
                      ? const CircularProgressIndicator()
                      : const Text('Upload Syllabus'),
            ),
            const SizedBox(height: 16),
            if (selectedYear != null && teacherDepartment != null)
              SizedBox(
                height: 400,
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('syllabus')
                          .where('year', isEqualTo: selectedYear)
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
                        child: Text('No syllabus uploaded yet.'),
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
                                ...files.map((url) {
                                  if (url.endsWith('.jpg') ||
                                      url.endsWith('.jpeg') ||
                                      url.endsWith('.png')) {
                                    return Padding(
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
                                                            url,
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            url,
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
                                    );
                                  } else if (url.endsWith('.pdf')) {
                                    return Padding(
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
                                                                url,
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
                                    );
                                  } else {
                                    return InkWell(
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
                                    );
                                  }
                                }),
                                Text(
                                  'Uploaded: ${data['uploadedAt'] != null ? (data['uploadedAt'] as Timestamp).toDate().toString().substring(0, 16) : ''}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await deleteSyllabus(doc.id, files);
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
