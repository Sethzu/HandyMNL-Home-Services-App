import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:test_2/userAuthentication/auth_page.dart';  // Import AuthPage for sign out
import 'package:test_2/CustomerPages/customer_navigation.dart';  // Import CustomerNavigation

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Signed in as: ${user.email ?? 'No Email'}'),
            // Button to Navigate to Customer Navigation
            MaterialButton(
              onPressed: () {
                // Navigate to CustomerNavigation
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomerNavigation(), // Open customer navigation
                  ),
                );
              },
              color: Colors.greenAccent,
              child: const Text('Go to Customer Navigation'),
            ),
            const SizedBox(height: 20),
            MaterialButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();  // Sign out user
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthPage()), // Navigate to sign-in page
                  );
                }
              },
              color: Colors.blueAccent[200],
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
