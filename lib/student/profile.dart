import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:provider/provider.dart';
import 'package:present_x/providers/auth_provider.dart';

class ProfilePage extends StatefulWidget {
  static route() =>
      MaterialPageRoute(builder: (context) => const ProfilePage());
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  Future<String?> uploadProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return null;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('profile_images')
        .child('${user.uid}.jpg');

    await storageRef.putData(await pickedFile.readAsBytes());
    final downloadUrl = await storageRef.getDownloadURL();

    // Save the URL to Firestore
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'profileUrl': downloadUrl,
    });

    setState(() {}); // Refresh UI after upload
    return downloadUrl;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 500;

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        title: const Text("Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF42A5F5),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: authProvider.getUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              );
            }
            final data = snapshot.data;
            if (data == null) {
              return const Center(
                child: Text(
                  "No user data found",
                  style: TextStyle(color: Colors.black54),
                ),
              );
            }
            return Column(
              children: [
                Container(
                  width: double.infinity,
                  color: const Color(0xFFBBDEFB),
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage:
                                data['profileUrl'] != null
                                    ? NetworkImage(data['profileUrl'])
                                    : const AssetImage(
                                          'assets/images/profileicon.jpg',
                                        )
                                        as ImageProvider,
                            backgroundColor: Colors.blue[900],
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () async {
                                await uploadProfileImage();
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue[700],
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(6),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] ?? '',
                            style: const TextStyle(
                              color: Color(0xFF1976D2),
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['role']?.toUpperCase() ?? '',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isWide ? size.width * 0.2 : 24.0,
                          vertical: 32,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            infoTile(Icons.email, "Email", data['email']),
                            if (data['department'] != null)
                              infoTile(
                                Icons.school,
                                "Department",
                                data['department'],
                              ),
                            if (data['class'] != null)
                              infoTile(Icons.class_, "Class", data['class']),
                            if (data['prn'] != null)
                              infoTile(
                                Icons.confirmation_number,
                                "PRN",
                                data['prn'],
                              ),
                            if (data['roll_no'] != null)
                              infoTile(
                                Icons.format_list_numbered,
                                "Roll No",
                                data['roll_no'],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget infoTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF1976D2), size: 24),
          const SizedBox(width: 16),
          Text(
            "$title: ",
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87, fontSize: 17),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
