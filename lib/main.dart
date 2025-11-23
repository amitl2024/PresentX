import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:present_x/providers/auth_provider.dart';
import 'package:present_x/login_page.dart';
import 'package:present_x/signup.dart';
import 'package:present_x/student/home.dart';
import 'package:present_x/student/events.dart';
import 'package:present_x/student/marks.dart';
import 'package:present_x/teachers/homepage.dart';
import 'package:present_x/teachers/attendance.dart';
import 'package:present_x/teachers/upAcademiccalender.dart';
import 'package:present_x/teachers/upAssign.dart';
import 'package:present_x/teachers/upMarks.dart';
import 'package:present_x/teachers/upNotifications.dart';
import 'package:present_x/teachers/upSyllabus.dart';
import 'package:present_x/teachers/upTimetable.dart';
import 'package:present_x/admin/admin_home.dart';

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Present X',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
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
            return MaterialPageRoute(builder: (context) => const AttendancePage());
          }
          return null;
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.user == null) {
      return const SignUpPage();
    }

    if (authProvider.role == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authProvider.role == 'admin') {
      return AdminHomePage();
    } else if (authProvider.role == 'teacher') {
      return const TeacherHomePage();
    } else {
      return Homeview();
    }
  }
}
