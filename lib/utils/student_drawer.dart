import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:present_x/providers/auth_provider.dart';
import 'package:present_x/student/profile.dart';
import 'package:present_x/utils/transition.dart';

class StudentDrawer extends StatelessWidget {
  const StudentDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    // We might need to fetch the name if it's not in the User object (User object has displayName but we store it in Firestore)
    // However, AuthProvider currently only fetches role. Let's update AuthProvider to fetch user data or at least name.
    // For now, let's assume we can get it or we will update AuthProvider.
    
    // Actually, let's check AuthProvider again. It only fetches role. 
    // I should probably update AuthProvider to fetch the full user profile or at least the name.
    // But for this step, I will use a FutureBuilder with a method from AuthProvider if I add one, 
    // or better, let's update AuthProvider first to fetch user data.
    
    return Drawer(
      backgroundColor: Colors.black,
      child: Column(
        children: [
          _buildHeader(context, authProvider),
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
                    await authProvider.signOut();
                    // Navigation to login is handled by AuthWrapper in main.dart
                    // But since we are in a drawer, we might need to pop or just let the stream handle it.
                    // The AuthWrapper is at the root. If we sign out, the stream updates, and AuthWrapper shows SignUpPage (or Login).
                    // However, we are currently pushed onto the stack.
                    // We should probably pop everything until first route.
                    Navigator.of(context).popUntil((route) => route.isFirst);
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

  Widget _buildHeader(BuildContext context, AuthProvider authProvider) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: authProvider.getUserData(), // We need to add this method to AuthProvider
      builder: (context, snapshot) {
        final data = snapshot.data;
        final name = data?['name'] ?? "User";
        final role = authProvider.role ?? "student";

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
                  name,
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
}
