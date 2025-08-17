import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:smart_pisciculture_system/pages/signin_page.dart';
import 'package:smart_pisciculture_system/services/auth_services.dart'; // your auth services
import 'package:firebase_auth/firebase_auth.dart';

class AdminPanelApp extends StatelessWidget {
  const AdminPanelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meemee Admin Panel',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AdminDashboard(),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthServices _authServices = AuthServices();

  // Delete user from Firestore
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      print("Error deleting user: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meemee Admin Panel"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authServices.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const SignInPage()),
                (route) => false, // removes all previous routes
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No users found"));
          }

          final users = snapshot.data!.docs;

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              border: TableBorder.all(),
              columns: const [
                DataColumn(label: Text("Name")),
                DataColumn(label: Text("Email")),
                DataColumn(label: Text("Role")),
                DataColumn(label: Text("Actions")),
              ],
              rows: users.map((doc) {
                final userData =
                    doc.data() as Map<String, dynamic>?; // allow null
                if (userData == null) {
                  return const DataRow(
                    cells: [
                      DataCell(Text("Unknown")),
                      DataCell(Text("Unknown")),
                      DataCell(Text("Unknown")),
                      DataCell(Text("No actions")),
                    ],
                  );
                }

                return DataRow(
                  cells: [
                    DataCell(Text(userData['name'] ?? '')),
                    DataCell(Text(userData['email'] ?? '')),
                    DataCell(Text(userData['role'] ?? '')),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteUser(doc.id),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
