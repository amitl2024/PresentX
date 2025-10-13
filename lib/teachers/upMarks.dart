import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UploadMarksPage extends StatefulWidget {
  const UploadMarksPage({Key? key}) : super(key: key);

  @override
  State<UploadMarksPage> createState() => _UploadMarksPageState();
}

class _UploadMarksPageState extends State<UploadMarksPage> {
  String? selectedClass;
  String? selectedExam;
  String? selectedSubject;
  String? teacherDepartment;
  final List<String> classList = ['SY', 'TY', 'B.Tech'];
  final List<String> examTypes = ['CA1', 'Mid sem', 'CA2'];
  final List<String> subjectList = ['Math', 'Physics', 'Chemistry', 'CS'];
  List<Map<String, dynamic>> students = [];
  Map<String, TextEditingController> marksControllers = {};
  List<Map<String, String>> assignedSubjectsWithClass = [];

  @override
  void initState() {
    super.initState();
    fetchTeacherInfo();
  }

  Future<void> fetchTeacherInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Fetch department
    final teacherDoc =
        await FirebaseFirestore.instance
            .collection('teachers')
            .doc(user.uid)
            .get();
    teacherDepartment = teacherDoc.data()?['department'];

    // Fetch assigned subjects
    final subjectQuery =
        await FirebaseFirestore.instance
            .collection('subject_teachers')
            .where('teacherId', isEqualTo: user.uid)
            .get();
    assignedSubjectsWithClass =
        subjectQuery.docs
            .map(
              (doc) => {
                'subjectName': doc.data()['subjectName'] as String,
                'class': doc.data()['class'] as String,
              },
            )
            .toList();

    setState(() {});
    // If class is already selected, fetch students now
    if (selectedClass != null) {
      fetchStudents();
    }
  }

  Future<void> fetchStudents() async {
    if (selectedClass == null || teacherDepartment == null) return;
    final query =
        await FirebaseFirestore.instance
            .collection('users')
            .where('class', isEqualTo: selectedClass)
            .where('department', isEqualTo: teacherDepartment)
            .where('role', isEqualTo: 'student')
            .get();
    students = query.docs.map((doc) => doc.data()).toList();
    marksControllers.clear();
    for (var student in students) {
      marksControllers[student['prn']] = TextEditingController();
    }
    setState(() {});
  }

  Future<void> uploadMarks() async {
    if (selectedClass == null ||
        selectedExam == null ||
        selectedSubject == null)
      return;
    for (var student in students) {
      final mark = marksControllers[student['prn']]?.text.trim();
      if (mark != null && mark.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('marks')
            .doc('${student['prn']}${selectedExam}$selectedSubject')
            .set({
              'studentId': student['prn'],
              'studentName': student['name'],
              'class': selectedClass,
              'exam': selectedExam,
              'subject': selectedSubject,
              'marks': mark,
              'uploadedAt': FieldValue.serverTimestamp(),
            });
      }
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Marks uploaded!')));
    for (var controller in marksControllers.values) {
      controller.clear();
    }
    setState(() {}); // Refresh the UI to show new marks
  }

  Future<void> deleteMark(String docId) async {
    await FirebaseFirestore.instance.collection('marks').doc(docId).delete();
    setState(() {}); // Refresh the UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marks', style: TextStyle(color: Colors.white)),
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
              onChanged: (val) {
                setState(() {
                  selectedClass = val;
                  students = [];
                  selectedExam = null;
                  selectedSubject = null;
                });
                fetchStudents();
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedSubject,
              hint: const Text('Select Subject'),
              items:
                  selectedClass == null
                      ? []
                      : assignedSubjectsWithClass
                          .where((sub) => sub['class'] == selectedClass)
                          .map(
                            (sub) => DropdownMenuItem(
                              value: sub['subjectName'],
                              child: Text(sub['subjectName']!),
                            ),
                          )
                          .toList(),
              onChanged:
                  selectedClass == null
                      ? null
                      : (val) => setState(() => selectedSubject = val),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedExam,
              hint: const Text('Select Exam Type'),
              items:
                  examTypes
                      .map(
                        (exam) =>
                            DropdownMenuItem(value: exam, child: Text(exam)),
                      )
                      .toList(),
              onChanged: (val) => setState(() => selectedExam = val),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  (selectedClass != null &&
                          selectedExam != null &&
                          selectedSubject != null)
                      ? StreamBuilder<QuerySnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('marks')
                                .where('class', isEqualTo: selectedClass)
                                .where('exam', isEqualTo: selectedExam)
                                .where('subject', isEqualTo: selectedSubject)
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final docs = snapshot.data!.docs;
                          if (docs.isEmpty) {
                            // If no marks uploaded, show students list for entry
                            return students.isEmpty
                                ? const Center(
                                  child: Text(
                                    'Select a class to load students',
                                  ),
                                )
                                : ListView.builder(
                                  itemCount: students.length,
                                  itemBuilder: (context, idx) {
                                    final student = students[idx];
                                    return ListTile(
                                      title: Text(student['name']),
                                      subtitle: Text('PRN: ${student['prn']}'),
                                      trailing: SizedBox(
                                        width: 80,
                                        child: TextField(
                                          controller:
                                              marksControllers[student['prn']],
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Marks',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                          }
                          // If marks uploaded, show marks list
                          return ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (context, idx) {
                              final doc = docs[idx];
                              final data = doc.data() as Map<String, dynamic>;
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  title: Text(data['studentName'] ?? ''),
                                  subtitle: Text('Marks: ${data['marks']}'),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      await deleteMark(doc.id);
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      )
                      : students.isEmpty
                      ? const Center(
                        child: Text('Select a class to load students'),
                      )
                      : ListView.builder(
                        itemCount: students.length,
                        itemBuilder: (context, idx) {
                          final student = students[idx];
                          return ListTile(
                            title: Text(student['name']),
                            subtitle: Text('PRN: ${student['prn']}'),
                            trailing: SizedBox(
                              width: 80,
                              child: TextField(
                                controller: marksControllers[student['prn']],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Marks',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
            ElevatedButton(
              onPressed: uploadMarks,
              child: const Text('Save Marks'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
