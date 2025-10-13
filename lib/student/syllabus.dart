import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class SyllabusPage extends StatefulWidget {
  const SyllabusPage({Key? key}) : super(key: key);

  @override
  State<SyllabusPage> createState() => _SyllabusPageState();
}

class _SyllabusPageState extends State<SyllabusPage> {
  String? studentYear;
  String? studentDepartment;

  @override
  void initState() {
    super.initState();
    fetchStudentInfo();
  }

  Future<void> fetchStudentInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        studentYear = data['class'];
        studentDepartment = data['department'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF42A5F5),
        elevation: 0,
        title: const Text('Syllabus', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          studentYear == null || studentDepartment == null
              ? const Center(child: CircularProgressIndicator())
              : Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('syllabus')
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
                      return const Center(
                        child: Text(
                          'No syllabus uploaded for your class yet.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: docs.length,
                      itemBuilder: (context, idx) {
                        final data = docs[idx].data() as Map<String, dynamic>;
                        final files = List<String>.from(data['files'] ?? []);
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['description'] ?? 'Syllabus',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0xFF1976D2),
                                  ),
                                ),
                                const SizedBox(height: 8),
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
                                            12,
                                          ),
                                          child: Image.network(
                                            url,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: 180,
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
                                          height: 180,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: Colors.red[50],
                                            borderRadius: BorderRadius.circular(
                                              12,
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
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                      ),
                                      child: Text(
                                        url,
                                        style: const TextStyle(
                                          color: Colors.blue,
                                        ),
                                      ),
                                    );
                                  }
                                }).toList(),
                                const SizedBox(height: 8),
                                Text(
                                  'Uploaded: ${data['uploadedAt'] != null ? (data['uploadedAt'] as Timestamp).toDate().toString().substring(0, 16) : ''}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
    );
  }
}
