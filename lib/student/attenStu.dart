import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendanceStudent extends StatefulWidget {
  static route() =>
      MaterialPageRoute(builder: (context) => const AttendanceStudent());
  const AttendanceStudent({super.key});

  @override
  State<AttendanceStudent> createState() => _AttendanceStudentState();
}

class _AttendanceStudentState extends State<AttendanceStudent> {
  List<Map<String, dynamic>> subjectAttendance = [];
  String? studentDepartment;
  String? studentClass;
  bool isLoading = true;
  List<String> subjects = [];

  @override
  void initState() {
    super.initState();
    fetchDepartmentClassAndSubjectsAndAttendance();
  }

  Future<void> fetchDepartmentClassAndSubjectsAndAttendance() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      // Fetch student department and class from users collection
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      studentDepartment = userDoc.data()?['department'];
      studentClass = userDoc.data()?['class'];

      if (studentDepartment == null || studentClass == null) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Department or class not set for your account.'),
          ),
        );
        return;
      }

      // Fetch subjects for this department and class from subjects collection (like marks.dart)
      final subjectsSnap =
          await FirebaseFirestore.instance
              .collection('subjects')
              .where('class', isEqualTo: studentClass)
              .where('department', isEqualTo: studentDepartment)
              .get();

      subjects =
          subjectsSnap.docs
              .map((doc) => doc.data()['subjectName'] as String)
              .toSet()
              .toList();

      if (subjects.isEmpty) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No subjects found for your department and class.'),
          ),
        );
        return;
      }

      // For each subject, calculate attendance percentage
      List<Map<String, dynamic>> tempAttendance = [];
      for (final subject in subjects) {
        final attendanceSnap =
            await FirebaseFirestore.instance
                .collection('attendance')
                .where('studentUid', isEqualTo: user.uid)
                .where('subject', isEqualTo: subject)
                .get();

        final total = attendanceSnap.docs.length;
        final present =
            attendanceSnap.docs.where((doc) => doc['present'] == true).length;
        final percent = total > 0 ? (present / total) * 100 : 0.0;

        tempAttendance.add({"subject": subject, "percent": percent});
      }

      setState(() {
        subjectAttendance = tempAttendance;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Color getAttendanceColor(double attendance) {
    if (attendance >= 75) return const Color(0xFFD4EDDA); // Light green
    if (attendance >= 50) return Colors.yellow[200]!; // Light yellow
    return Colors.red[200]!; // Light red
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    double overall =
        subjectAttendance.isNotEmpty
            ? subjectAttendance
                    .map((e) => e['percent'] as double)
                    .reduce((a, b) => a + b) /
                subjectAttendance.length
            : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
        ],
      ),
      backgroundColor: Colors.black,
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(30),
                          topLeft: Radius.circular(30),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isWide ? size.width * 0.15 : 16.0,
                          vertical: 24,
                        ),
                        child: Column(
                          children: [
                            // Overall Attendance Card
                            Container(
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(width: 20),
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        height: 50,
                                        width: 50,
                                        child: CircularProgressIndicator(
                                          value: overall / 100,
                                          backgroundColor: Colors.blue[100],
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                Color
                                              >(Colors.blue),
                                          strokeWidth: 7,
                                        ),
                                      ),
                                      Text(
                                        "${overall.toStringAsFixed(0)}%",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isWide ? 20 : 17,
                                          color: Colors.blue[900],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 30),
                                  Text(
                                    "Overall Attendance",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: isWide ? 22 : 18,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),
                            const Text(
                              "Subject wise Attendance:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Responsive grid for subject attendance
                            Expanded(
                              child: GridView.builder(
                                itemCount: subjectAttendance.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: isWide ? 3 : 2,
                                      crossAxisSpacing: 20,
                                      mainAxisSpacing: 20,
                                      childAspectRatio: 1,
                                    ),
                                itemBuilder: (context, index) {
                                  final subject = subjectAttendance[index];
                                  return Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      color: getAttendanceColor(
                                        subject["percent"],
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "${subject["subject"]}: \n${subject["percent"].toInt()}%",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                          fontSize: isWide ? 18 : 15,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
