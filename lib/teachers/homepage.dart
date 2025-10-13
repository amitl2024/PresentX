import 'package:flutter/material.dart';
import 'attendance.dart';
import 'package:present_x/utils/student_drawer.dart'; // <-- Import StudentDrawer

class TeacherHomePage extends StatelessWidget {
  const TeacherHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text('Teacher Home'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: StudentDrawer(), // <-- Add StudentDrawer here
      body: Column(
        children: [
          const SizedBox(height: 30),
          const Text(
            "Welcome Teacher!",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "What would you like to do today?",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                children: [
                  _HomeTile(
                    icon: Icons.check_circle_outline,
                    label: 'Take Attendance',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AttendancePage()),
                      );
                    },
                  ),
                  _HomeTile(
                    icon: Icons.assignment,
                    label: 'Upload Assignment',
                    onTap: () {
                      Navigator.pushNamed(context, '/uploadAssignment');
                    },
                  ),
                  _HomeTile(
                    icon: Icons.grade,
                    label: 'Upload Marks',
                    onTap: () {
                      Navigator.pushNamed(context, '/upMarks');
                    },
                  ),
                  _HomeTile(
                    icon: Icons.book,
                    label: 'Upload Syllabus',
                    onTap: () {
                      Navigator.pushNamed(context, '/upSyllabus');
                    },
                  ),
                  _HomeTile(
                    icon: Icons.calendar_month,
                    label: 'Academic Calendar',
                    onTap: () {
                      Navigator.pushNamed(context, '/upAcademicCalender');
                    },
                  ),
                  _HomeTile(
                    icon: Icons.schedule,
                    label: 'Upload Timetable',
                    onTap: () {
                      Navigator.pushNamed(context, '/upTimetable');
                    },
                  ),
                  _HomeTile(
                    icon: Icons.notifications,
                    label: 'Give Notifications',
                    onTap: () {
                      Navigator.pushNamed(context, '/upNotifications');
                    },
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
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.blue.shade100.withOpacity(0.3),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
