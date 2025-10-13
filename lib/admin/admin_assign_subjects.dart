import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminAssignSubjectsPage extends StatefulWidget {
  const AdminAssignSubjectsPage({super.key});

  @override
  State<AdminAssignSubjectsPage> createState() =>
      _AdminAssignSubjectsPageState();
}

class _AdminAssignSubjectsPageState extends State<AdminAssignSubjectsPage> {
  String? selectedTeacherId = 'All';
  String? selectedDepartment = 'All';
  String? selectedSemester = 'All';
  String? selectedClass = 'All';
  List<String> selectedSubjectIds = [];

  final List<String> departments = ['All', 'CSE', 'AIDS'];
  final List<String> semesters = [
    'All',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
  ];
  final List<String> classes = ['All', 'SY', 'TY', 'BTech'];

  Future<List<QueryDocumentSnapshot>> fetchTeachers() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'teacher')
            .get();
    return snapshot.docs;
  }

  Future<List<QueryDocumentSnapshot>> fetchSubjects() async {
    Query query = FirebaseFirestore.instance.collection('subjects');
    if (selectedDepartment != null && selectedDepartment != 'All') {
      query = query.where('department', isEqualTo: selectedDepartment);
    }
    if (selectedSemester != null && selectedSemester != 'All') {
      query = query.where('semester', isEqualTo: selectedSemester);
    }
    if (selectedClass != null && selectedClass != 'All') {
      query = query.where('class', isEqualTo: selectedClass);
    }
    final snapshot = await query.get();
    return snapshot.docs;
  }

  Query _buildAssignmentsQuery() {
    Query query = FirebaseFirestore.instance.collection('subject_teachers');
    if (selectedDepartment != null && selectedDepartment != 'All') {
      query = query.where('department', isEqualTo: selectedDepartment);
    }
    if (selectedSemester != null && selectedSemester != 'All') {
      query = query.where('semester', isEqualTo: selectedSemester);
    }
    if (selectedClass != null && selectedClass != 'All') {
      query = query.where('class', isEqualTo: selectedClass);
    }
    if (selectedTeacherId != null && selectedTeacherId != 'All') {
      query = query.where('teacherId', isEqualTo: selectedTeacherId);
    }
    return query.orderBy('assignedAt', descending: true);
  }

  Future<void> assignSubjectsToTeacher(
    String teacherId,
    String teacherName,
    List<QueryDocumentSnapshot> subjects,
  ) async {
    for (final subjectDoc in subjects) {
      // Prevent duplicate assignments
      final existing =
          await FirebaseFirestore.instance
              .collection('subject_teachers')
              .where('teacherId', isEqualTo: teacherId)
              .where('subjectId', isEqualTo: subjectDoc.id)
              .get();
      if (existing.docs.isEmpty) {
        await FirebaseFirestore.instance.collection('subject_teachers').add({
          'teacherId': teacherId,
          'teacherName': teacherName,
          'subjectId': subjectDoc.id,
          'subjectName': subjectDoc['subjectName'],
          'department': subjectDoc['department'],
          'semester': subjectDoc['semester'],
          'class': subjectDoc['class'],
          'assignedAt': FieldValue.serverTimestamp(),
        });
      }
    }
    // Show snackbar after all assignments
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Teacher assigned!')));
    setState(() {
      selectedTeacherId = null;
      selectedSubjectIds.clear();
      // Optionally reset filters:
      // selectedDepartment = null;
      // selectedSemester = null;
      // selectedClass = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    Widget filterSection = Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isWide = constraints.maxWidth > 600;
            Widget dropdowns =
                isWide
                    ? Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedDepartment,
                            hint: const Text('Department'),
                            items:
                                departments
                                    .map(
                                      (d) => DropdownMenuItem(
                                        value: d,
                                        child: Text(d),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (val) => setState(() {
                                  selectedDepartment = val;
                                  selectedSubjectIds.clear();
                                }),
                            decoration: const InputDecoration(
                              labelText: 'Department',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedSemester,
                            hint: const Text('Semester'),
                            items:
                                semesters
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text('Sem $s'),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (val) => setState(() {
                                  selectedSemester = val;
                                  selectedSubjectIds.clear();
                                }),
                            decoration: const InputDecoration(
                              labelText: 'Semester',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedClass,
                            hint: const Text('Class'),
                            items:
                                classes
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (val) => setState(() {
                                  selectedClass = val;
                                  selectedSubjectIds.clear();
                                }),
                            decoration: const InputDecoration(
                              labelText: 'Class',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    )
                    : Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedDepartment,
                          hint: const Text('Department'),
                          items:
                              departments
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(d),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (val) => setState(() {
                                selectedDepartment = val;
                                selectedSubjectIds.clear();
                              }),
                          decoration: const InputDecoration(
                            labelText: 'Department',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedSemester,
                          hint: const Text('Semester'),
                          items:
                              semesters
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text('Sem $s'),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (val) => setState(() {
                                selectedSemester = val;
                                selectedSubjectIds.clear();
                              }),
                          decoration: const InputDecoration(
                            labelText: 'Semester',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedClass,
                          hint: const Text('Class'),
                          items:
                              classes
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (val) => setState(() {
                                selectedClass = val;
                                selectedSubjectIds.clear();
                              }),
                          decoration: const InputDecoration(
                            labelText: 'Class',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Assign Filters",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<QueryDocumentSnapshot>>(
                  future: fetchTeachers(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const LinearProgressIndicator();
                    }
                    final teachers = snapshot.data!;
                    return DropdownButtonFormField<String>(
                      value: selectedTeacherId,
                      hint: const Text('Select Teacher'),
                      items: [
                        const DropdownMenuItem(
                          value: 'All',
                          child: Text('All'),
                        ),
                        ...teachers.map(
                          (t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t['name'] ?? t['email'] ?? t.id),
                          ),
                        ),
                      ],
                      onChanged:
                          (val) => setState(() => selectedTeacherId = val),
                      decoration: const InputDecoration(
                        labelText: 'Teacher',
                        border: OutlineInputBorder(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                dropdowns,
              ],
            );
          },
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Subjects to Teachers'),
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFE3F2FD),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            filterSection,
            const Text(
              "Subjects",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: FutureBuilder<List<QueryDocumentSnapshot>>(
                future: fetchSubjects(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final subjects = snapshot.data!;
                  if (subjects.isEmpty) {
                    return const Center(child: Text('No subjects found.'));
                  }
                  return ListView.separated(
                    itemCount: subjects.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final subjectDoc = subjects[idx];
                      final subjectId = subjectDoc.id;
                      final subjectName = subjectDoc['subjectName'];
                      final isSelected = selectedSubjectIds.contains(subjectId);
                      return ListTile(
                        leading: Checkbox(
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                selectedSubjectIds.add(subjectId);
                              } else {
                                selectedSubjectIds.remove(subjectId);
                              }
                            });
                          },
                        ),
                        title: Text(
                          subjectName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          'Sem: ${subjectDoc['semester']} | Class: ${subjectDoc['class']}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              selectedSubjectIds.remove(subjectId);
                            } else {
                              selectedSubjectIds.add(subjectId);
                            }
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    selectedTeacherId != null && selectedSubjectIds.isNotEmpty
                        ? () async {
                          final teachers = await fetchTeachers();
                          final teacherDoc = teachers.firstWhere(
                            (t) => t.id == selectedTeacherId,
                          );
                          final subjects = await fetchSubjects();
                          final selectedSubjects =
                              subjects
                                  .where(
                                    (s) => selectedSubjectIds.contains(s.id),
                                  )
                                  .toList();
                          await assignSubjectsToTeacher(
                            selectedTeacherId!,
                            teacherDoc['name'] ?? teacherDoc['email'] ?? '',
                            selectedSubjects,
                          );
                        }
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Assign Selected Subjects'),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Current Assignments',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: StreamBuilder<QuerySnapshot>(
                stream: _buildAssignmentsQuery().snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text('No assignments yet.'));
                  }
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, idx) {
                      final data = docs[idx].data() as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(
                            '${data['subjectName']} (${data['department']}, Sem ${data['semester']}, ${data['class']})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Teacher: ${data['teacherName']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('subject_teachers')
                                  .doc(docs[idx].id)
                                  .delete();
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
