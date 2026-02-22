import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_pisciculture_system/services/auth_services.dart';
import 'package:smart_pisciculture_system/pages/signin_page.dart';
import 'package:smart_pisciculture_system/pages/home.dart';
import 'package:smart_pisciculture_system/pages/profilepage.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showHomeButton;

  const CustomAppBar({
    super.key,
    this.showHomeButton = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    final AuthServices _authServices = AuthServices();

    // 🧠 Real-time user stream from Firestore
    return StreamBuilder<DocumentSnapshot>(
      stream: currentUser != null
          ? FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .snapshots()
          : null,
      builder: (context, snapshot) {
        String userName = "User";
        String userInitials = "U";
        String email = currentUser?.email ?? "";

        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          userName = data['name'] ?? "User";
          userInitials = userName
              .split(' ')
              .map((n) => n.isNotEmpty ? n[0] : '')
              .take(2)
              .join()
              .toUpperCase();
        }

        Future<void> _logout() async {
          try {
            await _authServices.logout();
            if (context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SignInPage()),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Logout failed: $e")),
              );
            }
          }
        }

        void _showProfileMenu() {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.teal,
                    child: Text(
                      userInitials,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Profile button
                  ListTile(
                    leading: const Icon(Icons.person, color: Colors.teal),
                    title: const Text("Profile"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilePage(),
                        ),
                      );
                    },
                  ),
                  // Settings
                  ListTile(
                    leading: const Icon(Icons.settings, color: Colors.teal),
                    title: const Text("Settings"),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Settings page")),
                      );
                    },
                  ),
                  // Logout
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text("Logout"),
                    onTap: () {
                      Navigator.pop(context);
                      _logout();
                    },
                  ),
                ],
              ),
            ),
          );
        }

        void _navigateToHome() {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Home()),
          );
        }

        return AppBar(
          backgroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.1),
          automaticallyImplyLeading: false,
          titleSpacing: 16,
          title: Row(
            children: [
              // Logo
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade400, Colors.teal.shade700],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    "🐟",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Logo Text
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [Colors.teal.shade400, Colors.teal.shade700],
                ).createShader(bounds),
                child: const Text(
                  "MeeMee",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            if (showHomeButton)
              IconButton(
                onPressed: _navigateToHome,
                icon: const Icon(Icons.home),
                color: Colors.teal,
                iconSize: 26,
                tooltip: "Home",
              ),
            // Profile Circle
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: _showProfileMenu,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade400, Colors.teal.shade700],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      userInitials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
