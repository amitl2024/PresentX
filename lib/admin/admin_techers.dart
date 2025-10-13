import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart'; // Add this import
import 'package:flutter/material.dart';

class AdminTeachersPage extends StatefulWidget {
  const AdminTeachersPage({super.key});

  @override
  State<AdminTeachersPage> createState() => _AdminTeachersPageState();
}

class _AdminTeachersPageState extends State<AdminTeachersPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _deptController = TextEditingController();
  final _passwordController = TextEditingController();

  final List<String> departments = ['CSE', 'AIDS'];
  String? selectedDepartment;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _deptController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _addTeacher() async {
    if (!_formKey.currentState!.validate() || selectedDepartment == null)
      return;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    // 1. Create a secondary Firebase app instance
    final FirebaseApp secondaryApp = await Firebase.initializeApp(
      name: 'SecondaryApp',
      options: Firebase.app().options,
    );
    final FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(
      app: secondaryApp,
    );

    try {
      // 2. Create teacher in Firebase Auth using secondary instance
      UserCredential userCredential = await secondaryAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      final uid = userCredential.user!.uid;

      // 3. Save info in 'users' collection
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'department': selectedDepartment,
        'role': 'teacher',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Save info in 'teachers' collection
      await FirebaseFirestore.instance.collection('teachers').doc(uid).set({
        'name': name,
        'email': email,
        'department': selectedDepartment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 5. Clean up: delete secondary app instance
      await secondaryApp.delete();

      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      setState(() {
        selectedDepartment = null;
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Teacher added!')));
    } on FirebaseAuthException catch (e) {
      await secondaryApp.delete();
      String msg = 'Failed to add teacher.';
      if (e.code == 'email-already-in-use') {
        msg = 'Email already in use.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      await secondaryApp.delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('An error occurred.')));
    }
  }

  Future<void> _editTeacher(String docId, Map<String, dynamic> data) async {
    _nameController.text = data['name'] ?? '';
    _emailController.text = data['email'] ?? '';
    selectedDepartment = data['department'];
    _passwordController.text = data['password'] ?? '';
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Teacher'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator:
                          (v) => v == null || v.isEmpty ? 'Enter name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator:
                          (v) => v == null || v.isEmpty ? 'Enter email' : null,
                      enabled: false, // Don't allow editing email
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedDepartment,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                      ),
                      items:
                          departments
                              .map(
                                (d) =>
                                    DropdownMenuItem(value: d, child: Text(d)),
                              )
                              .toList(),
                      onChanged:
                          (val) => setState(() => selectedDepartment = val),
                      validator: (v) => v == null ? 'Select department' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator:
                          (v) =>
                              v == null || v.isEmpty ? 'Enter password' : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate() &&
                      selectedDepartment != null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(docId)
                        .update({
                          'name': _nameController.text.trim(),
                          'department': selectedDepartment,
                          'password': _passwordController.text.trim(),
                        });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Teacher updated!')),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    setState(() {
      selectedDepartment = null;
    });
  }

  Future<void> _deleteTeacher(String docId) async {
    await FirebaseFirestore.instance.collection('users').doc(docId).delete();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Teacher deleted!')));
  }

  void _showAddTeacherDialog() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    setState(() {
      selectedDepartment = null;
    });
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Teacher'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator:
                          (v) => v == null || v.isEmpty ? 'Enter name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator:
                          (v) => v == null || v.isEmpty ? 'Enter email' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedDepartment,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                      ),
                      items:
                          departments
                              .map(
                                (d) =>
                                    DropdownMenuItem(value: d, child: Text(d)),
                              )
                              .toList(),
                      onChanged:
                          (val) => setState(() => selectedDepartment = val),
                      validator: (v) => v == null ? 'Select department' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator:
                          (v) =>
                              v == null || v.isEmpty ? 'Enter password' : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(onPressed: _addTeacher, child: const Text('Add')),
            ],
          ),
    );
  }

  String? filterDepartment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Teachers'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),

      backgroundColor: const Color(0xFFE3F2FD),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTeacherDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Teacher'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Filter by Department:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: filterDepartment,
                  hint: const Text('All'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ...departments.map(
                      (d) => DropdownMenuItem(value: d, child: Text(d)),
                    ),
                  ],
                  onChanged: (val) => setState(() => filterDepartment = val),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    (filterDepartment == null)
                        ? FirebaseFirestore.instance
                            .collection('users')
                            .where('role', isEqualTo: 'teacher')
                            .orderBy('createdAt', descending: false)
                            .snapshots()
                        : FirebaseFirestore.instance
                            .collection('users')
                            .where('role', isEqualTo: 'teacher')
                            .where('department', isEqualTo: filterDepartment)
                            .orderBy('createdAt', descending: false)
                            .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text('No teachers found.'));
                  }
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, idx) {
                      final data = docs[idx].data() as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(
                            data['name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Email: ${data['email'] ?? ''}\nDepartment: ${data['department'] ?? ''}',
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
                                    () => _editTeacher(docs[idx].id, data),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                tooltip: 'Delete',
                                onPressed: () => _deleteTeacher(docs[idx].id),
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
