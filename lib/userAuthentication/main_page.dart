import 'package:firebase_auth/firebase_auth.dart';  // Import Firebase Authentication package
import 'package:flutter/material.dart';  // Import Flutter's Material Design package
import 'package:cloud_firestore/cloud_firestore.dart';  // Import Firestore to fetch user data
import 'package:test_2/CustomerPages/customer_navigation.dart';
import 'package:test_2/WorkerPages/worker_navigation.dart';
import 'package:test_2/userAuthentication/auth_page.dart';  // Import the authentication page for login/register

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // User is logged in, fetch user type
            User? user = snapshot.data;

            if (user != null) {
              // Fetch user data from Firestore
              return FutureBuilder(
                future: getUserType(user.uid),
                builder: (context, AsyncSnapshot<int?> userTypeSnapshot) {
                  if (userTypeSnapshot.connectionState == ConnectionState.waiting) {
                    // While fetching userType, show a loading indicator
                    return const Center(child: CircularProgressIndicator());
                  } else if (userTypeSnapshot.hasData) {
                    // Once userType is fetched, navigate accordingly
                    if (userTypeSnapshot.data == 1) {
                      return const CustomerNavigation();  // Show Customer's HomePage
                    } else if (userTypeSnapshot.data == 2) {
                      return const WorkerNavigation();  // Show Worker's HomePage
                    } else {
                      return const Center(child: Text('User type not found.'));
                    }
                  } else {
                    return const Center(child: Text('Error fetching user type.'));
                  }
                },
              );
            } else {
              return const AuthPage();
            }
          } else {
            // If the user is not logged in, show the AuthPage (login/register)
            return const AuthPage();
          }
        },
      ),
    );
  }

  // Fetch userType based on the logged-in user's UID from Firestore
  Future<int?> getUserType(String uid) async {
    // Check if the user is a Customer
    DocumentSnapshot customerSnapshot =
        await FirebaseFirestore.instance.collection('Customers').doc(uid).get();

    if (customerSnapshot.exists) {
      return 1; // userType 1 for Customer
    }

    // Check if the user is a Worker
    DocumentSnapshot workerSnapshot =
        await FirebaseFirestore.instance.collection('Workers').doc(uid).get();

    if (workerSnapshot.exists) {
      return 2; // userType 2 for Worker
    }

    return null; // Return null if the user type is not found
  }
}

//Kapag si user ay hindi nag log out, minamake netong module na to na nakalogin pa rin siya sa app at hindi babalik sa Login page. 