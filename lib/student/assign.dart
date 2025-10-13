import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;

class AssignmentPage extends StatefulWidget {
  static route() =>
      MaterialPageRoute(builder: (context) => const AssignmentPage());
  const AssignmentPage({super.key});

  @override
  State<AssignmentPage> createState() => _AssignmentPageState();
}

class _AssignmentPageState extends State<AssignmentPage> {
  String searchQuery = "";
  String? studentClass;
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
        studentClass = data['class'];
        studentDepartment = data['department'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Assignments",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 27,
          ),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? size.width * 0.15 : 16.0,
              vertical: 20,
            ),
            child: Column(
              children: [
                // Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: "Search assignments...",
                    prefixIcon: Icon(Icons.search),
                    filled: true,
                    fillColor: Color(0xFFF2F4F8),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                if (studentClass == null || studentDepartment == null)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('assignments')
                              .where('class', isEqualTo: studentClass)
                              .where('department', isEqualTo: studentDepartment)
                              .orderBy('uploadedAt', descending: true)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final docs = snapshot.data!.docs;
                        final assignments =
                            docs
                                .map(
                                  (doc) => doc.data() as Map<String, dynamic>,
                                )
                                .where((assignment) {
                                  final query = searchQuery.toLowerCase();
                                  return assignment["title"]
                                          .toLowerCase()
                                          .contains(query) ||
                                      assignment["description"]
                                          .toLowerCase()
                                          .contains(query) ||
                                      (assignment["uploadedBy"] ?? "")
                                          .toLowerCase()
                                          .contains(query);
                                })
                                .toList();

                        if (assignments.isEmpty) {
                          return const Center(
                            child: Text(
                              "No assignments uploaded yet.",
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 18,
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          itemCount: assignments.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 18),
                          itemBuilder: (context, index) {
                            final assignment = assignments[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 18,
                                horizontal: 18,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    assignment["title"] ?? "",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[900],
                                      fontSize: isWide ? 22 : 18,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    assignment["description"] ?? "",
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  if (assignment["type"] == "image")
                                    GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder:
                                              (_) => Dialog(
                                                backgroundColor:
                                                    Colors.transparent,
                                                child: Stack(
                                                  children: [
                                                    GestureDetector(
                                                      onTap:
                                                          () => Navigator.pop(
                                                            context,
                                                          ),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              16,
                                                            ),
                                                        child: Image.network(
                                                          assignment["fileUrl"],
                                                          fit: BoxFit.contain,
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
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          assignment["fileUrl"],
                                          height: 180,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  if (assignment["type"] == "pdf")
                                    GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder:
                                              (_) => Dialog(
                                                backgroundColor:
                                                    Colors.transparent,
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
                                                        child: SfPdfViewer.network(
                                                          assignment["fileUrl"],
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
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.blue[100],
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const SizedBox(width: 10),
                                            const Icon(
                                              Icons.picture_as_pdf,
                                              color: Colors.red,
                                              size: 32,
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Text(
                                                "View PDF",
                                                style: TextStyle(
                                                  color: Colors.blue[900],
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: isWide ? 18 : 15,
                                                ),
                                              ),
                                            ),
                                            const Icon(
                                              Icons.open_in_new,
                                              color: Colors.blue,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Uploaded by: ${assignment["uploadedBy"] ?? ""}",
                                        style: TextStyle(
                                          color: Colors.blueGrey[700],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
        ),
      ),
    );
  }
}
