import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({Key? key}) : super(key: key);

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  String? selectedYear;
  String? selectedDepartment;
  String? selectedSubject;
  String? teacherUid;
  String? teacherName;
  List<Map<String, dynamic>> assignedSubjects = [];
  List<String> subjectList = [];
  List<String> yearList = [];
  List<String> departmentList = [];
  Map<String, bool?> attendance = {};
  List<Map<String, dynamic>> students = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchTeacherInfoAndSubjects();
  }

  Future<void> fetchTeacherInfoAndSubjects() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    teacherUid = user.uid;

    // Fetch teacher name
    final doc =
        await FirebaseFirestore.instance
            .collection('teachers')
            .doc(user.uid)
            .get();
    teacherName = doc.data()?['name'] ?? '';

    // Fetch assigned subjects for this teacher from subject_teachers collection
    final subjSnap =
        await FirebaseFirestore.instance
            .collection('subject_teachers')
            .where('teacherId', isEqualTo: teacherUid)
            .get();

    assignedSubjects =
        subjSnap.docs.map((doc) {
          final data = doc.data();
          return {
            'subjectName': data['subjectName'],
            'department': data['department'],
            'class': data['class'],
          };
        }).toList();

    subjectList =
        assignedSubjects.map((e) => e['subjectName'] as String).toList();
    yearList =
        assignedSubjects.map((e) => e['class'] as String).toSet().toList();
    departmentList =
        assignedSubjects.map((e) => e['department'] as String).toSet().toList();

    setState(() {
      // If only one subject, preselect it and its department/year
      if (assignedSubjects.length == 1) {
        selectedSubject = assignedSubjects.first['subjectName'];
        selectedDepartment = assignedSubjects.first['department'];
        selectedYear = assignedSubjects.first['class'];
        fetchStudents();
      }
    });
  }

  Future<void> fetchStudents() async {
    if (selectedYear == null || selectedDepartment == null) return;
    setState(() {
      isLoading = true;
      students = [];
      attendance = {};
    });

    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'student')
            .where('class', isEqualTo: selectedYear)
            .where('department', isEqualTo: selectedDepartment)
            .get();

    students =
        snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['uid'] = doc.id;
          return data;
        }).toList();

    attendance = {for (var s in students) s['uid'] as String: null};
    setState(() {
      isLoading = false;
    });
  }

  void _setAttendance(String uid, bool isPresent) {
    setState(() {
      attendance[uid] = isPresent;
    });
  }

  Future<void> _submitAttendance() async {
    if (selectedYear == null ||
        selectedDepartment == null ||
        selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select year, department, and subject.'),
        ),
      );
      return;
    }
    final now = DateTime.now();
    final dateStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final batch = FirebaseFirestore.instance.batch();

    for (var s in students) {
      final uid = s['uid'] as String;
      final present = attendance[uid];
      if (present != null) {
        final docRef =
            FirebaseFirestore.instance.collection('attendance').doc();
        batch.set(docRef, {
          'studentUid': uid,
          'name': s['name'],
          'department': s['department'],
          'class': s['class'],
          'date': dateStr,
          'present': present,
          'prn': s['prn'],
          'takenBy': teacherUid,
          'teacherName': teacherName,
          'subject': selectedSubject,
        });
      }
    }
    await batch.commit();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Attendance Submitted'),
            content: const Text('Attendance has been saved to the database.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Widget _buildStudentRow(Map<String, dynamic> s) {
    final uid = s['uid'] as String;
    return ListTile(
      title: Text(s['name']),
      subtitle: Text('PRN: ${s['prn']}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: attendance[uid] == true,
            onChanged: (val) => _setAttendance(uid, true),
            activeColor: Colors.green,
          ),
          const Text('P'),
          const SizedBox(width: 8),
          Checkbox(
            value: attendance[uid] == false,
            onChanged: (val) => _setAttendance(uid, false),
            activeColor: Colors.red,
          ),
          const Text('A'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Take Attendance'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedYear,
                    hint: const Text('Select Year'),
                    items:
                        yearList
                            .map(
                              (year) => DropdownMenuItem(
                                value: year,
                                child: Text(year),
                              ),
                            )
                            .toList(),
                    onChanged:
                        assignedSubjects.length == 1
                            ? null // Disable if only one subject assigned
                            : (val) {
                              setState(() => selectedYear = val);
                              // When year changes, filter department and subject accordingly
                              selectedDepartment = null;
                              selectedSubject = null;
                            },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedDepartment,
                    hint: const Text('Select Department'),
                    items:
                        departmentList
                            .map(
                              (dept) => DropdownMenuItem(
                                value: dept,
                                child: Text(dept),
                              ),
                            )
                            .toList(),
                    onChanged:
                        assignedSubjects.length == 1
                            ? null // Disable if only one subject assigned
                            : (val) {
                              setState(() => selectedDepartment = val);
                              // When department changes, filter year and subject accordingly
                              selectedYear = null;
                              selectedSubject = null;
                            },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedSubject,
              hint: const Text('Select Subject'),
              items:
                  subjectList
                      .where((subj) {
                        // Only show subjects matching selected year and department
                        if (assignedSubjects.isEmpty) return true;
                        final subjInfo = assignedSubjects.firstWhere(
                          (e) => e['subjectName'] == subj,
                          orElse: () => {},
                        );
                        if (selectedYear != null &&
                            subjInfo['class'] != selectedYear)
                          return false;
                        if (selectedDepartment != null &&
                            subjInfo['department'] != selectedDepartment)
                          return false;
                        return true;
                      })
                      .map(
                        (sub) => DropdownMenuItem(value: sub, child: Text(sub)),
                      )
                      .toList(),
              onChanged:
                  assignedSubjects.length == 1
                      ? null // Disable if only one subject assigned
                      : (val) {
                        setState(() {
                          selectedSubject = val;
                          // Set department and year based on selected subject
                          final subjInfo = assignedSubjects.firstWhere(
                            (e) => e['subjectName'] == val,
                            orElse: () => {},
                          );
                          selectedDepartment = subjInfo['department'];
                          selectedYear = subjInfo['class'];
                          fetchStudents();
                        });
                      },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (students.isEmpty)
              const Text('No students found for selected year and department.')
            else
              Expanded(
                child: ListView(
                  children: students.map(_buildStudentRow).toList(),
                ),
              ),
            const SizedBox(height: 20),
            if (students.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitAttendance,
                  child: const Text('Submit Attendance'),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
