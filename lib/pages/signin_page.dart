import 'package:flutter/material.dart';
import 'package:smart_pisciculture_system/pages/adminhome.dart';
import 'package:smart_pisciculture_system/pages/userhome.dart';
import 'signup_page.dart';
import 'package:smart_pisciculture_system/services/auth_services.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordHidden = true;
  final AuthServices _authServices = AuthServices();
  bool isLoading = false;
  String selectedRole = "User"; // default role

  Future<void> _login() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    String? result = await _authServices.login(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    if (!mounted) return; // stop if widget disposed
    setState(() {
      isLoading = false;
    });

    if (result == "Admin" && selectedRole == "Admin") {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminPanelApp()),
      );
    } else if (result == "User" && selectedRole == "User") {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Home()),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login failed: $result")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset("assets/images/bg1.jpeg", fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.4)), // dark overlay
          Center(
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
                      "MeeMee",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Sign in to continue",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
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
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(
                        labelText: "Role",
                        border: OutlineInputBorder(),
                      ),
                      items: ["Admin", "User"].map((role) {
                        return DropdownMenuItem(value: role, child: Text(role));
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedRole = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
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
                            onPressed: _login,
                            child: const Text(
                              "Sign In",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const SignUpPage()),
                        );
                      },
                      child: const Text(
                        "Don't have an account? Sign Up",
                        style: TextStyle(
                          color: Color.fromARGB(255, 65, 64, 64),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
