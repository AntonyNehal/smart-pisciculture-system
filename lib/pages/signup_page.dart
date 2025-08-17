import 'package:flutter/material.dart';
import 'signin_page.dart';
import 'package:smart_pisciculture_system/services/auth_services.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String selectedRole = "User"; // Default role
  bool isLoading = false;
  bool isPasswordHidden = true;

  final AuthServices _authServices = AuthServices();

  void _signup() async {
    setState(() {
      isLoading = true;
    });

    String? result = await _authServices.signup(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      name: nameController.text.trim(),
      role: selectedRole,
    );

    setState(() {
      isLoading = false;
    });

    if (result == null) {
      // Success
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signup successful! Please sign in.")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SignInPage()),
      );
    } else {
      // Failure
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Signup failed: $result")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset("assets/images/bg1.jpeg", fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.4)),
          Center(
            child: SingleChildScrollView(
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Create Account",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person),
                          labelText: "Name",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email),
                          labelText: "Email",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: passwordController,
                        obscureText: isPasswordHidden,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock),
                          labelText: "Password",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                isPasswordHidden = !isPasswordHidden;
                              });
                            },
                            icon: Icon(
                              isPasswordHidden
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 80,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _signup,
                              child: const Text(
                                "Sign Up",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                      const SizedBox(height: 15),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignInPage(),
                            ),
                          );
                        },
                        child: const Text(
                          "Already have an account? Sign In",
                          style: TextStyle(
                            color: Color.fromARGB(255, 65, 63, 63),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
