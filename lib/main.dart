import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_pisciculture_system/pages/adminhome.dart';
import 'package:smart_pisciculture_system/pages/home.dart';
import 'package:smart_pisciculture_system/pages/signin_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Fish Pond',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthStateHandler(),
    );
  }
}

class AuthStateHandler extends StatefulWidget {
  const AuthStateHandler({super.key});

  @override
  State<AuthStateHandler> createState() => _AuthStateHandlerState();
}

class _AuthStateHandlerState extends State<AuthStateHandler> {
  User? _currentUser;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _initializeAuthState();
  }

  void _initializeAuthState() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (!mounted) return;
      setState(() {
        _currentUser = user;
      });
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!mounted) return;
        if (userDoc.exists) {
          setState(() {
            _userRole = userDoc['role'];
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const SignInPage(); // Redirect to SignInPage if not authenticated
    }
    if (_userRole == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()), // Loading state
      );
    }
    return _userRole == "Admin"
        ? const AdminPanelApp()
        : const Home(); // Show Home if user is a regular user
  }
}
