import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:test_2/WorkerPages/worker_navigation.dart';
import 'package:test_2/userAuthentication/auth_page.dart';  // Import AuthPage to navigate after sign out

class WorkerHomePage extends StatefulWidget {
  const WorkerHomePage({super.key});

  @override
  State<WorkerHomePage> createState() => _WorkerHomePageState();
}

class _WorkerHomePageState extends State<WorkerHomePage> {
  final user = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome Worker! Signed in as: ${user.email ?? 'No Email'}'),
            ElevatedButton(
              onPressed: () {
                // Worker-specific action, e.g., checking jobs
              },
              child: const Text('Check Jobs'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to worker_navigation.dart
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WorkerNavigation(),
                  ),
                );
              },
              child: const Text('Go to Worker Navigation'),
            ),
            const SizedBox(height: 20),
            MaterialButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();  // Sign the user out
                // Navigate to AuthPage after signing out
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthPage()),
                );
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
