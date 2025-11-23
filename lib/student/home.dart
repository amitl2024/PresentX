import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:present_x/providers/auth_provider.dart';
import 'package:present_x/student/assign.dart';
import 'package:present_x/student/attenStu.dart';
import 'package:present_x/student/events.dart';
import 'package:present_x/student/marks.dart';
import 'package:present_x/student/syllabus.dart';
import 'package:present_x/student/timetabel.dart';
import 'package:present_x/utils/transition.dart';
import 'package:present_x/utils/student_drawer.dart';

class Homeview extends StatefulWidget {
  static route() => MaterialPageRoute(builder: (context) => const Homeview());
  const Homeview({super.key});

  @override
  State<Homeview> createState() => _HomeviewState();
}

class _HomeviewState extends State<Homeview> {
  // Example events/notifications list (replace with Firestore data later)
  final List<Map<String, String>> events = [
    {
      "title": "Guest Lecture",
      "description": "Attend the guest lecture on AI at 2 PM in Seminar Hall.",
    },
    {
      "title": "Sports Day",
      "description":
          "Annual sports day on 5th June. Register with your class teacher.",
    },
    {
      "title": "Result Announcement",
      "description": "Mid-semester results will be announced on 10th June.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF42A5F5),
        elevation: 0,
        title: const Text(
          'Student Home',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                SlideLeftRoute(page: StudentNotificationsPage()),
              );
            },
          ),
        ],
      ),
      drawer: const StudentDrawer(),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFBBDEFB),
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/images/profileicon.jpg',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 20),
                FutureBuilder<Map<String, dynamic>?>(
                  future: authProvider.getUserData(),
                  builder: (context, snapshot) {
                    final name = snapshot.data?['name'] ?? "User";
                    return Text(
                      "Welcome, $name!",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Color(0xFF1976D2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: GridView.count(
                padding: const EdgeInsets.all(24),
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  _HomeTile(
                    icon: Icons.check_circle_outline,
                    label: 'Attendance',
                    onTap:
                        () => Navigator.push(
                          context,
                          SlideLeftRoute(page: AttendanceStudent()),
                        ),
                  ),
                  _HomeTile(
                    icon: Icons.assignment,
                    label: 'Assignments',
                    onTap:
                        () => Navigator.push(
                          context,
                          SlideLeftRoute(page: AssignmentPage()),
                        ),
                  ),
                  _HomeTile(
                    icon: Icons.grade,
                    label: 'Marks',
                    onTap:
                        () => Navigator.push(
                          context,
                          SlideLeftRoute(page: MarksPage()),
                        ),
                  ),
                  _HomeTile(
                    icon: Icons.book,
                    label: 'Syllabus',
                    onTap: () {
                      Navigator.push(
                        context,
                        SlideLeftRoute(page: SyllabusPage()),
                      );
                    }, // Add navigation if needed
                  ),
                  _HomeTile(
                    icon: Icons.schedule,
                    label: 'Timetable',
                    onTap:
                        () => Navigator.push(
                          context,
                          SlideLeftRoute(page: TimetablePage()),
                        ),
                  ),
                  _HomeTile(
                    icon: Icons.event,
                    label: 'Events',
                    onTap:
                        () => Navigator.push(
                          context,
                          SlideLeftRoute(page: StudentNotificationsPage()),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HomeTile({
    required this.icon,
    required this.label,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F8FD),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Color(0xFF1976D2)),
            const SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF1976D2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
