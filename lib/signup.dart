import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:present_x/student/home.dart';
import 'package:present_x/login_page.dart';
import 'package:present_x/teachers/homepage.dart';

class SignUpPage extends StatefulWidget {
  static route() => MaterialPageRoute(builder: (context) => const SignUpPage());
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final prnController = TextEditingController();
  String role = 'student';
  final formKey = GlobalKey<FormState>();

  final List<String> deptList = ['CSE', 'AIDS'];
  String? selectedDept;
  String? selectedClass;

  // Class options for each department
  final Map<String, List<String>> classOptions = {
    'CSE': ['SY(A)', 'SY(B)', 'TY', 'B.Tech'],
    'AIDS': ['SY', 'TY', 'B.Tech'],
  };

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    prnController.dispose();
    super.dispose();
  }

  Future<void> createUserWithEmailAndPassword() async {
    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );
      final uid = userCredential.user!.uid;

      await FirebaseFirestore.instance
          .collection('departments')
          .doc(selectedDept!.toLowerCase())
          .collection('classes')
          .doc(selectedClass)
          .collection('students')
          .doc(uid)
          .set({
            'name': nameController.text.trim(),
            'role': role,
            'class': selectedClass,
            'department': selectedDept,
            'email': emailController.text.trim(),
            if (role == 'student') 'prn': prnController.text.trim(),
          });

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': nameController.text.trim(),
        'role': role,
        'class': selectedClass,
        'department': selectedDept,
        'email': emailController.text.trim(),
        if (role == 'student') 'prn': prnController.text.trim(),
      });

      await FirebaseFirestore.instance
          .collection('departments')
          .doc(selectedDept!.toLowerCase())
          .set({'name': selectedDept}, SetOptions(merge: true));

      // Ensure class document exists under department
      await FirebaseFirestore.instance
          .collection('departments')
          .doc(selectedDept!.toLowerCase())
          .collection('classes')
          .doc(selectedClass)
          .set({'name': selectedClass}, SetOptions(merge: true));

      if (role == 'teacher') {
        Navigator.pushReplacementNamed(context, '/teacherHome');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      print(e.message);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Signup failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size.width > 500 ? size.width * 0.2 : 15.0,
              vertical: 20,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Sign Up.',
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      hintText: 'Username',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      hintText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 15),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: 'Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: selectedDept,
                    hint: const Text('Select Department'),
                    items:
                        deptList
                            .map(
                              (dept) => DropdownMenuItem(
                                value: dept,
                                child: Text(dept),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDept = value;
                        selectedClass = null; // Reset class when dept changes
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: selectedClass,
                    hint: const Text('Select Class'),
                    items:
                        selectedDept == null
                            ? []
                            : classOptions[selectedDept]!
                                .map(
                                  (cls) => DropdownMenuItem(
                                    value: cls,
                                    child: Text(cls),
                                  ),
                                )
                                .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedClass = value;
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: role,
                    items: [
                      const DropdownMenuItem(
                        value: 'student',
                        child: Text('Student'),
                      ),
                      const DropdownMenuItem(
                        value: 'teacher',
                        child: Text('Teacher'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        role = value!;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Role',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),
                  if (role == 'student') ...[
                    TextFormField(
                      controller: prnController,
                      decoration: const InputDecoration(
                        hintText: 'PRN No.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],

                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                    ),

                    child: TextButton(
                      onPressed: () async {
                        await createUserWithEmailAndPassword();
                      },
                      child: Text(
                        'SIGN UP',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, LoginPage.route());
                    },
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: Theme.of(context).textTheme.titleMedium,
                        children: [
                          TextSpan(
                            text: 'Log In',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
