import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  
  // Threshold controllers
  final TextEditingController tempMinController = TextEditingController();
  final TextEditingController tempMaxController = TextEditingController();
  final TextEditingController phMinController = TextEditingController();
  final TextEditingController phMaxController = TextEditingController();
  final TextEditingController doMinController = TextEditingController();
  final TextEditingController doMaxController = TextEditingController();
  final TextEditingController ammoniaMaxController = TextEditingController();

  late AnimationController _animationController;
  bool isLoading = true;
  bool isSaving = false;
  String userId = '';

  // Default threshold values
  final Map<String, double> defaultThresholds = {
    'tempMin': 24.0,
    'tempMax': 28.0,
    'phMin': 7.0,
    'phMax': 7.5,
    'doMin': 6.5,
    'doMax': 8.0,
    'ammoniaMax': 0.2,
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    nameController.dispose();
    emailController.dispose();
    cityController.dispose();
    tempMinController.dispose();
    tempMaxController.dispose();
    phMinController.dispose();
    phMaxController.dispose();
    doMinController.dispose();
    doMaxController.dispose();
    ammoniaMaxController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        userId = currentUser.uid;
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists && mounted) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          
          setState(() {
            nameController.text = userData['name'] ?? '';
            emailController.text = userData['email'] ?? '';
            cityController.text = userData['defaultCity'] ?? 'Kochi';
            
            // Load thresholds or use defaults
            Map<String, dynamic>? thresholds = userData['thresholds'] as Map<String, dynamic>?;
            tempMinController.text = (thresholds?['tempMin'] ?? defaultThresholds['tempMin']).toString();
            tempMaxController.text = (thresholds?['tempMax'] ?? defaultThresholds['tempMax']).toString();
            phMinController.text = (thresholds?['phMin'] ?? defaultThresholds['phMin']).toString();
            phMaxController.text = (thresholds?['phMax'] ?? defaultThresholds['phMax']).toString();
            doMinController.text = (thresholds?['doMin'] ?? defaultThresholds['doMin']).toString();
            doMaxController.text = (thresholds?['doMax'] ?? defaultThresholds['doMax']).toString();
            ammoniaMaxController.text = (thresholds?['ammoniaMax'] ?? defaultThresholds['ammoniaMax']).toString();
            
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading profile: $e")),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_validateInputs()) return;

    User? currentUser = FirebaseAuth.instance.currentUser;
    bool emailChanged = currentUser != null && 
                        currentUser.email != emailController.text.trim();

    // If email is being changed, ask for password to re-authenticate
    if (emailChanged) {
      String? password = await _showPasswordDialog();
      if (password == null) {
        // User cancelled the dialog
        return;
      }

      try {
        // Re-authenticate user before updating email
        AuthCredential credential = EmailAuthProvider.credential(
          email: currentUser!.email!,
          password: password,
        );
        await currentUser.reauthenticateWithCredential(credential);
      } catch (e) {
        _showError("Authentication failed. Please check your password.");
        return;
      }
    }

    setState(() {
      isSaving = true;
    });

    try {
      // Update user data in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'defaultCity': cityController.text.trim(),
        'thresholds': {
          'tempMin': double.parse(tempMinController.text),
          'tempMax': double.parse(tempMaxController.text),
          'phMin': double.parse(phMinController.text),
          'phMax': double.parse(phMaxController.text),
          'doMin': double.parse(doMinController.text),
          'doMax': double.parse(doMaxController.text),
          'ammoniaMax': double.parse(ammoniaMaxController.text),
        },
      });

      // Update email in Firebase Auth if changed
      if (emailChanged && currentUser != null) {
        await currentUser.verifyBeforeUpdateEmail(emailController.text.trim());
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Verification email sent! Please verify your new email address."),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(emailChanged 
              ? "Profile updated! Please check your email to verify the new address."
              : "Profile updated successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Error updating profile: $e");
      if (mounted) {
        setState(() {
          isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating profile: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showPasswordDialog() async {
    final TextEditingController passwordController = TextEditingController();
    bool isPasswordVisible = false;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Verify Password"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "To update your email, please enter your current password:",
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: !isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    passwordController.dispose();
                    Navigator.of(context).pop(null);
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                  ),
                  onPressed: () {
                    String password = passwordController.text;
                    passwordController.dispose();
                    Navigator.of(context).pop(password);
                  },
                  child: const Text(
                    "Verify",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _validateInputs() {
    if (nameController.text.trim().isEmpty) {
      _showError("Name cannot be empty");
      return false;
    }
    if (emailController.text.trim().isEmpty || !emailController.text.contains('@')) {
      _showError("Please enter a valid email");
      return false;
    }
    if (cityController.text.trim().isEmpty) {
      _showError("City cannot be empty");
      return false;
    }

    // Validate threshold values
    try {
      double tempMin = double.parse(tempMinController.text);
      double tempMax = double.parse(tempMaxController.text);
      if (tempMin >= tempMax) {
        _showError("Temperature min must be less than max");
        return false;
      }

      double phMin = double.parse(phMinController.text);
      double phMax = double.parse(phMaxController.text);
      if (phMin >= phMax) {
        _showError("pH min must be less than max");
        return false;
      }

      double doMin = double.parse(doMinController.text);
      double doMax = double.parse(doMaxController.text);
      if (doMin >= doMax) {
        _showError("DO min must be less than max");
        return false;
      }
    } catch (e) {
      _showError("Please enter valid numbers for thresholds");
      return false;
    }

    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset to Defaults"),
        content: const Text("Are you sure you want to reset all threshold values to defaults?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () {
              setState(() {
                tempMinController.text = defaultThresholds['tempMin'].toString();
                tempMaxController.text = defaultThresholds['tempMax'].toString();
                phMinController.text = defaultThresholds['phMin'].toString();
                phMaxController.text = defaultThresholds['phMax'].toString();
                doMinController.text = defaultThresholds['doMin'].toString();
                doMaxController.text = defaultThresholds['doMax'].toString();
                ammoniaMaxController.text = defaultThresholds['ammoniaMax'].toString();
              });
              Navigator.pop(context);
            },
            child: const Text("Reset", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildProfileSection(),
                            const SizedBox(height: 20),
                            _buildThresholdsSection(),
                            const SizedBox(height: 30),
                            _buildSaveButton(),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          const Text(
            'Profile Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return FadeTransition(
      opacity: _animationController,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade400, Colors.teal.shade700],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: nameController,
              label: 'Name',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: cityController,
              label: 'Default Weather City',
              icon: Icons.location_city,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdsSection() {
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade700],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.tune, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Threshold Values',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _resetToDefaults,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text(''),
                  style: TextButton.styleFrom(foregroundColor: Colors.teal),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildThresholdRow(
              'Temperature (°C)',
              tempMinController,
              tempMaxController,
              Icons.thermostat,
              Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildThresholdRow(
              'pH Level',
              phMinController,
              phMaxController,
              Icons.science,
              Colors.deepPurple,
            ),
            const SizedBox(height: 16),
            _buildThresholdRow(
              'Dissolved Oxygen (mg/L)',
              doMinController,
              doMaxController,
              Icons.air,
              Colors.lightBlue,
            ),
            const SizedBox(height: 16),
            _buildSingleThreshold(
              'Ammonia Max (mg/L)',
              ammoniaMaxController,
              Icons.bubble_chart,
              Colors.amber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdRow(
    String label,
    TextEditingController minController,
    TextEditingController maxController,
    IconData icon,
    MaterialColor color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color[700], size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildNumberField(
                controller: minController,
                label: 'Min',
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildNumberField(
                controller: maxController,
                label: 'Max',
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSingleThreshold(
    String label,
    TextEditingController controller,
    IconData icon,
    MaterialColor color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color[700], size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildNumberField(
          controller: controller,
          label: 'Maximum',
          color: color,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.teal, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required MaterialColor color,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildSaveButton() {
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: isSaving ? null : _updateProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
          ),
          child: isSaving
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}