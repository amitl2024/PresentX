import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:present_x/providers/auth_provider.dart';
import 'package:present_x/login_page.dart';

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

  Future<void> signUp() async {
    if (!formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signUp(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      name: nameController.text.trim(),
      role: role,
      department: selectedDept,
      className: selectedClass,
      prn: role == 'student' ? prnController.text.trim() : null,
    );

    if (success) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Signup failed'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authProvider = Provider.of<AuthProvider>(context);

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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a username';
                      }
                      return null;
                    },
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: 'Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
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
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a department';
                      }
                      return null;
                    },
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
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a class';
                      }
                      return null;
                    },
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
                      validator: (value) {
                        if (role == 'student' && (value == null || value.isEmpty)) {
                          return 'Please enter PRN number';
                        }
                        return null;
                      },
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
                      onPressed: authProvider.isLoading ? null : () async {
                        await signUp();
                      },
                      child: authProvider.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
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
