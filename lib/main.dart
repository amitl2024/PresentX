import 'package:flutter/material.dart';
import 'package:present_x/student/events.dart';
import 'package:present_x/student/home.dart';
import 'package:present_x/login_page.dart';
import 'package:present_x/signup.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:present_x/student/marks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:present_x/teachers/homepage.dart';
import 'package:present_x/teachers/attendance.dart';
import 'package:present_x/teachers/upAcademiccalender.dart';
import 'package:present_x/teachers/upAssign.dart';
import 'package:present_x/teachers/upMarks.dart';
import 'package:present_x/teachers/upNotifications.dart';
import 'package:present_x/teachers/upSyllabus.dart';
import 'package:present_x/teachers/upTimetable.dart';
import 'package:present_x/admin/admin_home.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  await Firebase.initializeApp();
  await supabase.Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/':
            (context) => StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final user = snapshot.data;
                if (user == null) {
                  return const SignUpPage();
                }
                return StreamBuilder<DocumentSnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .snapshots(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final data =
                        userSnapshot.data?.data() as Map<String, dynamic>?;
                    final role = data?['role'];
                    if (role == null) {
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) setState(() {});
                      });
                      return const Center(
                        child: Text('Setting up your account...'),
                      );
                    }
                    if (role == 'admin') {
                      return AdminHomePage();
                    } else if (role == 'teacher') {
                      return const TeacherHomePage();
                    } else {
                      return Homeview();
                    }
                  },
                );
              },
            ),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => Homeview(),
        '/teacherHome': (context) => const TeacherHomePage(),
        '/marks': (context) => const MarksPage(),
        '/attendance': (context) => const AttendancePage(),
        '/events': (context) => const StudentNotificationsPage(),
        '/uploadAssignment': (context) => const UploadAssignmentPage(),
        '/upMarks': (context) => const UploadMarksPage(),
        '/upTimetable': (context) => const UploadTimetablePage(),
        '/upSyllabus': (context) => const UploadSyllabusPage(),
        '/upAcademicCalender': (context) => const UploadAcademicCalendarPage(),
        '/upNotifications': (context) => const UploadNotificationsPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/attendance') {
          final args = settings.arguments as List<String>;
          return MaterialPageRoute(builder: (context) => AttendancePage());
        }
        return null;
      },
    );
  }
}
