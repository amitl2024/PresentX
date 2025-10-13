import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminSubjectsPage extends StatefulWidget {
  const AdminSubjectsPage({super.key});

  @override
  State<AdminSubjectsPage> createState() => _AdminSubjectsPageState();
}

class _AdminSubjectsPageState extends State<AdminSubjectsPage> {
  final _subjectController = TextEditingController();

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
  final List<String> classes = ['All', 'FY', 'SY', 'TY', 'BTech'];

  String selectedDepartment = 'All';
  String selectedSemester = 'All';
  String selectedClass = 'All';

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _addSubject() async {
    final subjectName = _subjectController.text.trim();
    if (subjectName.isEmpty ||
        selectedDepartment == 'All' ||
        selectedSemester == 'All' ||
        selectedClass == 'All') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select department, semester, class and enter subject name.',
          ),
        ),
      );
      return;
    }
    await FirebaseFirestore.instance.collection('subjects').add({
      'department': selectedDepartment,
      'semester': selectedSemester,
      'class': selectedClass,
      'subjectName': subjectName,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _subjectController.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Subject added!')));
  }

  Future<void> _deleteSubject(String docId) async {
    await FirebaseFirestore.instance.collection('subjects').doc(docId).delete();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Subject deleted!')));
  }

  Future<void> _editSubject(String docId, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Subject'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Subject Name',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final newName = controller.text.trim();
                  if (newName.isNotEmpty) {
                    Navigator.pop(context, newName);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
    if (result != null && result.isNotEmpty && result != currentName) {
      await FirebaseFirestore.instance.collection('subjects').doc(docId).update(
        {'subjectName': result},
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Subject updated!')));
    }
  }

  void _clearFilters() {
    setState(() {
      selectedDepartment = 'All';
      selectedSemester = 'All';
      selectedClass = 'All';
    });
  }

  Query _buildQuery() {
    Query query = FirebaseFirestore.instance.collection('subjects');
    if (selectedDepartment != 'All') {
      query = query.where('department', isEqualTo: selectedDepartment);
    }
    if (selectedSemester != 'All') {
      query = query.where('semester', isEqualTo: selectedSemester);
    }
    if (selectedClass != 'All') {
      query = query.where('class', isEqualTo: selectedClass);
    }
    return query.orderBy('createdAt', descending: false);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    Widget filterWidgets =
        isWide
            ? Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedDepartment,
                    items:
                        departments
                            .map(
                              (d) => DropdownMenuItem(value: d, child: Text(d)),
                            )
                            .toList(),
                    onChanged:
                        (val) =>
                            setState(() => selectedDepartment = val ?? 'All'),
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
                    items:
                        semesters
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text('Sem $s'),
                              ),
                            )
                            .toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedSemester = val ?? 'All';
                        // Auto-select class based on semester
                        if (selectedSemester == '1' ||
                            selectedSemester == '2') {
                          selectedClass = 'FY';
                        } else if (selectedSemester == '3' ||
                            selectedSemester == '4') {
                          selectedClass = 'SY';
                        } else if (selectedSemester == '5' ||
                            selectedSemester == '6') {
                          selectedClass = 'TY';
                        } else if (selectedSemester == '7' ||
                            selectedSemester == '8') {
                          selectedClass = 'BTech';
                        } else if (selectedSemester == 'All') {
                          selectedClass = 'All';
                        }
                      });
                    },
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
                    items:
                        classes
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                    onChanged:
                        (val) => setState(() => selectedClass = val ?? 'All'),
                    decoration: const InputDecoration(
                      labelText: 'Class',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.filter_alt_off),
                  label: const Text('Clear Filters'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[200],
                    foregroundColor: Colors.black87,
                  ),
                ),
              ],
            )
            : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedDepartment,
                  items:
                      departments
                          .map(
                            (d) => DropdownMenuItem(value: d, child: Text(d)),
                          )
                          .toList(),
                  onChanged:
                      (val) =>
                          setState(() => selectedDepartment = val ?? 'All'),
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedSemester,
                  items:
                      semesters
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text('Sem $s'),
                            ),
                          )
                          .toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedSemester = val ?? 'All';
                      // Auto-select class based on semester
                      if (selectedSemester == '1' || selectedSemester == '2') {
                        selectedClass = 'FY';
                      } else if (selectedSemester == '3' ||
                          selectedSemester == '4') {
                        selectedClass = 'SY';
                      } else if (selectedSemester == '5' ||
                          selectedSemester == '6') {
                        selectedClass = 'TY';
                      } else if (selectedSemester == '7' ||
                          selectedSemester == '8') {
                        selectedClass = 'BTech';
                      } else if (selectedSemester == 'All') {
                        selectedClass = 'All';
                      }
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Semester',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedClass,
                  items:
                      classes
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                  onChanged:
                      (val) => setState(() => selectedClass = val ?? 'All'),
                  decoration: const InputDecoration(
                    labelText: 'Class',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.filter_alt_off),
                  label: const Text('Clear Filters'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[200],
                    foregroundColor: Colors.black87,
                  ),
                ),
              ],
            );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Subjects'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          if (isWide)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: 'Clear Filters',
              onPressed: _clearFilters,
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFE3F2FD),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            filterWidgets,
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Add Subject',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _addSubject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Subjects List',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _buildQuery().snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text('No subjects added yet.'));
                  }
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, idx) {
                      final data = docs[idx].data() as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(
                            data['subjectName'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Sem: ${data['semester']} | Class: ${data['class']} | Dept: ${data['department']}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                tooltip: 'Edit',
                                onPressed:
                                    () => _editSubject(
                                      docs[idx].id,
                                      data['subjectName'] ?? '',
                                    ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                tooltip: 'Delete',
                                onPressed: () => _deleteSubject(docs[idx].id),
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
          ],
        ),
      ),
    );
  }
}
