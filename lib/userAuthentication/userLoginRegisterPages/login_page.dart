import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_2/CustomerPages/home_page.dart';  // Customer home page
import 'package:test_2/WorkerPages/workerhome_page.dart';  // Worker home page

class LoginPage extends StatefulWidget {
  final VoidCallback showRegisterPage;
  const LoginPage({super.key, required this.showRegisterPage});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false; // To show loading indicator
  String? _errorMessage;

  Future<void> signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Email and Password cannot be empty';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear error message
    });

    try {
      // Sign in the user
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // After successful login, fetch user data from Firestore
      User? user = userCredential.user;

      if (user != null) {
        // Check if the user is a Customer or Worker by querying the respective collections
        final customerSnapshot = await FirebaseFirestore.instance.collection('Customers').doc(user.uid).get();
        final workerSnapshot = await FirebaseFirestore.instance.collection('Workers').doc(user.uid).get();

        if (customerSnapshot.exists) {
          // Ensure the widget is still mounted before navigating
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        } else if (workerSnapshot.exists) {
          // Ensure the widget is still mounted before navigating
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const WorkerHomePage()),
            );
          }
        } else {
          if (mounted) {
            setState(() {
              _errorMessage = "Error: User type not found.";
            });
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;  // Show error message if login fails
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set the background to white
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.handyman_outlined, size: 100),
                const SizedBox(height: 75),

                // Title
                Text(
                  'Hello Again!',
                  style: GoogleFonts.bebasNeue(fontSize: 62),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Welcome to our App!',
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 50),

                // Error message (if any)
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                // Email textfield
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      fillColor: Colors.grey[200],
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white, width: 2.0),
                        borderRadius: BorderRadius.circular(12), // Rounded edges
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0),
                        borderRadius: BorderRadius.circular(12), // Rounded edges
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Password textfield
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      fillColor: Colors.grey[200],
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white, width: 2.0),
                        borderRadius: BorderRadius.circular(12), // Rounded edges
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0),
                        borderRadius: BorderRadius.circular(12), // Rounded edges
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Sign In button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: GestureDetector(
                    onTap: _isLoading ? null : signIn,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _isLoading ? Colors.grey : Colors.blueAccent,
                        borderRadius: BorderRadius.circular(30), // Make the button round
                        boxShadow: [
                          if (!_isLoading)
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 4), // Make it elevated
                            ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // Loading indicator
                if (_isLoading)
                  const CircularProgressIndicator(),

                // Not a member? Register now
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Not a member?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    GestureDetector(
                      onTap: widget.showRegisterPage,
                      child: const Text(
                        ' Register now',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
