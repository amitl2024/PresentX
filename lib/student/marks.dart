import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MarksPage extends StatefulWidget {
  static route() => MaterialPageRoute(builder: (context) => const MarksPage());
  const MarksPage({super.key});

  @override
  State<MarksPage> createState() => _MarksPageState();
}

class _MarksPageState extends State<MarksPage> {
  String? studentClass;
  String? studentDepartment;
  String? studentPrn;
  List<String> subjects = [];
  Map<String, Map<String, dynamic>> marks = {}; // subject -> {examType: mark}

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
      studentClass = data['class'];
      studentDepartment = data['department'];
      studentPrn = data['prn'];
      await fetchSubjects();
      await fetchMarks();
      setState(() {});
    }
  }

  Future<void> fetchSubjects() async {
    if (studentClass == null || studentDepartment == null) return;
    final query =
        await FirebaseFirestore.instance
            .collection('subjects')
            .where('class', isEqualTo: studentClass)
            .where('department', isEqualTo: studentDepartment)
            .get();
    subjects =
        query.docs
            .map((doc) => doc.data()['subjectName'] as String)
            .toSet()
            .toList();
  }

  Future<void> fetchMarks() async {
    if (studentPrn == null) return;
    final query =
        await FirebaseFirestore.instance
            .collection('marks')
            .where('studentId', isEqualTo: studentPrn)
            .get();
    marks.clear();
    for (var doc in query.docs) {
      final data = doc.data();
      final subject = data['subject'];
      final exam = data['exam'];
      final mark = data['marks'];
      marks[subject] ??= {};
      marks[subject]![exam] = mark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.black,
              iconTheme: IconThemeData(color: Colors.white),
              title: Text(
                "Marks",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 27,
                ),
              ),
              elevation: 0,
              automaticallyImplyLeading: true,
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  color: Colors.white,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? size.width * 0.15 : 12.0,
                    vertical: 20,
                  ),
                  child:
                      subjects.isEmpty
                          ? const Center(child: Text("No subjects found"))
                          : ListView.separated(
                            itemCount: subjects.length,
                            separatorBuilder: (_, __) => SizedBox(height: 18),
                            itemBuilder: (context, index) {
                              final subject = subjects[index];
                              final subjectMarks = marks[subject] ?? {};
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
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
                                      subject,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[900],
                                        fontSize: isWide ? 22 : 18,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        markColumn(
                                          "CA1",
                                          subjectMarks["CA1"]?.toString() ??
                                              "-",
                                          isWide,
                                        ),
                                        markColumn(
                                          "Mid",
                                          subjectMarks["Mid sem"]?.toString() ??
                                              "-",
                                          isWide,
                                        ),
                                        markColumn(
                                          "CA2",
                                          subjectMarks["CA2"]?.toString() ??
                                              "-",
                                          isWide,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget markColumn(String label, String value, bool isWide) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.blue[700],
            fontWeight: FontWeight.w600,
            fontSize: isWide ? 18 : 15,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: isWide ? 18 : 15,
            ),
          ),
        ),
      ],
    );
  }
}
