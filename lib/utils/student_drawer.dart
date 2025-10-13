import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:present_x/login_page.dart';
import 'package:present_x/student/profile.dart';
import 'package:present_x/utils/transition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentDrawer extends StatelessWidget {
  final String? name;
  final Future<String?> Function()? getUserName;

  const StudentDrawer({super.key, this.name, this.getUserName});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black,
      child: Column(
        children: [
          FutureBuilder<String?>(
            future: getUserName != null ? getUserName!() : Future.value(name),
            builder: (context, snapshot) {
              final displayName = snapshot.data ?? "User";
              // Fetch role from FirebaseAuth user claims or Firestore if needed
              return FutureBuilder<String>(
                future: _getUserRole(),
                builder: (context, roleSnapshot) {
                  final role = roleSnapshot.data ?? "student";
                  return Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: DrawerHeader(
                      margin: EdgeInsets.zero,
                      padding: EdgeInsets.zero,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundImage: const AssetImage(
                                  'assets/images/profileicon.jpg',
                                ),
                                backgroundColor: Colors.white,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                ),
                                padding: const EdgeInsets.all(3),
                                child: const Icon(
                                  Icons.verified,
                                  color: Colors.blue,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            role == "teacher" ? "Teacher" : "Student",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerTile(
                  icon: Icons.person,
                  label: "Profile",
                  onTap: () {
                    Navigator.push(
                      context,
                      SlideLeftRoute(page: ProfilePage()),
                    );
                  },
                ),
                _drawerTile(
                  icon: Icons.home,
                  label: "Home",
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _drawerTile(
                  icon: Icons.assignment,
                  label: "Assignments",
                  onTap: () {
                    // Add navigation if needed
                  },
                ),
                _drawerTile(
                  icon: Icons.settings,
                  label: "Settings",
                  onTap: () {
                    // Add navigation if needed
                  },
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Divider(color: Colors.white24, thickness: 1),
                ),
                _drawerTile(
                  icon: Icons.logout,
                  label: "Sign Out",
                  iconColor: Colors.redAccent,
                  textColor: Colors.redAccent,
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.push(context, LoginPage.route());
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0, top: 8),
            child: Text(
              "© 2025 PresentX",
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerTile({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Color iconColor = Colors.white,
    Color textColor = Colors.white,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      hoverColor: Colors.blue.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Future<String> _getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "student";
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    return doc.data()?['role'] ?? "student";
  }
}
