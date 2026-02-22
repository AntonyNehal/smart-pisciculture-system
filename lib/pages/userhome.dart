import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_pisciculture_system/components/custom_app_bar.dart';
import 'package:smart_pisciculture_system/pages/weatherDetailsPage.dart';
import 'package:smart_pisciculture_system/pages/waterqualitypage.dart';
import 'package:smart_pisciculture_system/pages/harvest_predict.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToPage(String title) {
    if (title == 'Weather Insights') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const WeatherDetailsPage(city: 'Kochi'),
        ),
      );
    } else if (title == 'Water Quality Monitor') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const WaterQualityPage(),
        ),
      );
    }
      else if (title == 'Harvest Prediction') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HarvestPredictionPage(),
          ),
        );
      } 
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Navigation to $title page")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: const CustomAppBar(showHomeButton: false),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.teal.shade400,
              Colors.teal.shade700,
            ],
          ),
        ),
        // 🔁 StreamBuilder automatically updates when Firestore changes
        child: currentUser == null
            ? const Center(child: Text("No user logged in"))
            : StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.white));
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(
                        child: Text(
                      "User data not found",
                      style: TextStyle(color: Colors.white),
                    ));
                  }

                  var userData =
                      snapshot.data!.data() as Map<String, dynamic>? ?? {};
                  String userName = userData['name'] ?? "User";

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildWelcomeCard(userName),
                        const SizedBox(height: 24),
                        _buildDashboardGrid(),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildWelcomeCard(String userName) {
    return FadeTransition(
      opacity: _animationController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOut,
        )),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    "Welcome, ",
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.black87,
                    ),
                  ),
                  Flexible(
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Colors.teal.shade400, Colors.teal.shade700],
                      ).createShader(bounds),
                      child: Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const Text(
                    "! 👋",
                    style: TextStyle(fontSize: 24),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                "Manage your fish pond with ease and precision",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardGrid() {
    final dashboardItems = [
      {
        'icon': '💧',
        'title': 'Water Quality Monitor',
        'description':
            'Track temperature, pH, ammonia levels and other vital parameters in real-time',
        'gradient': [Colors.blue.shade300, Colors.blue.shade600],
        'delay': 0.1,
      },
      {
        'icon': '🌤️',
        'title': 'Weather Insights',
        'description':
            'View current weather conditions and forecasts for optimal pond management',
        'gradient': [Colors.pink.shade300, Colors.red.shade400],
        'delay': 0.2,
      },
      {
        'icon': '📹',
        'title': 'Live Camera Feed',
        'description':
            'Monitor your pond remotely with live streaming and theft detection alerts',
        'gradient': [Colors.cyan.shade300, Colors.cyan.shade600],
        'delay': 0.3,
      },
      {
        'icon': '⏰',
        'title': 'Harvest Prediction',
        'description':
            'Predict optimal harvest time based on fish growth and feeding patterns',
        'gradient': [Colors.green.shade300, Colors.teal.shade400],
        'delay': 0.5,
      },
      {
        'icon': '⚙️',
        'title': 'System Control',
        'description':
            'Manage automated feeding schedules and overflow control systems',
        'gradient': [Colors.green.shade300, Colors.teal.shade400],
        'delay': 0.4,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: dashboardItems.length,
      itemBuilder: (context, index) {
        final item = dashboardItems[index];
        return _buildDashboardCard(
          icon: item['icon'] as String,
          title: item['title'] as String,
          description: item['description'] as String,
          gradient: item['gradient'] as List<Color>,
          delay: item['delay'] as double,
        );
      },
    );
  }

  Widget _buildDashboardCard({
    required String icon,
    required String title,
    required String description,
    required List<Color> gradient,
    required double delay,
  }) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(delay, delay + 0.3, curve: Curves.easeOut),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(delay, delay + 0.3, curve: Curves.easeOut),
          ),
        ),
        child: GestureDetector(
          onTap: () => _navigateToPage(title),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
