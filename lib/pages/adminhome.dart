import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_pisciculture_system/pages/signin_page.dart';
import 'package:smart_pisciculture_system/services/auth_services.dart';

class AdminPanelApp extends StatelessWidget {
  const AdminPanelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meemee Admin Panel',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
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

  Future<void> deleteUser(String uid, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete user "$userName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore.collection('users').doc(uid).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User "$userName" deleted successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting user: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Meemee Admin Panel',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                ),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.red),
                  tooltip: 'Logout',
                  onPressed: () async {
                    await _authServices.logout();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const SignInPage()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsCards(),
                  const SizedBox(height: 32),
                  const Text(
                    'User Management',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildUsersTable(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        final totalUsers = snapshot.hasData ? snapshot.data!.docs.length : 0;
        final adminCount = snapshot.hasData
            ? snapshot.data!.docs
                .where((doc) => (doc.data() as Map?)?['role'] == 'admin')
                .length
            : 0;
        final userCount = totalUsers - adminCount;

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Users',
                totalUsers.toString(),
                Icons.people_rounded,
                const Color(0xFF667EEA),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Admins',
                adminCount.toString(),
                Icons.admin_panel_settings_rounded,
                const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Regular Users',
                userCount.toString(),
                Icons.person_rounded,
                const Color(0xFF10B981),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(40),
              child: const CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No users found',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }

        final users = snapshot.data!.docs;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  const Color(0xFFF9FAFB),
                ),
                headingRowHeight: 56,
                dataRowHeight: 72,
                horizontalMargin: 24,
                columnSpacing: 48,
                columns: const [
                  DataColumn(
                    label: Text(
                      'Name',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Email',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Role',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Actions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
                rows: users.map((doc) {
                  final userData = doc.data() as Map<String, dynamic>?;
                  if (userData == null) {
                    return const DataRow(
                      cells: [
                        DataCell(Text('Unknown')),
                        DataCell(Text('Unknown')),
                        DataCell(Text('Unknown')),
                        DataCell(Text('—')),
                      ],
                    );
                  }

                  final name = userData['name'] ?? 'N/A';
                  final email = userData['email'] ?? 'N/A';
                  final role = userData['role'] ?? 'user';

                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFF667EEA),
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Text(
                          email,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: role == 'admin'
                                ? const Color(0xFFFEE2E2)
                                : const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: TextStyle(
                              color: role == 'admin'
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded),
                            color: Colors.red,
                            tooltip: 'Delete User',
                            onPressed: () => deleteUser(doc.id, name),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}