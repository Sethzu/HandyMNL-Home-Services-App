import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  _CustomerProfilePageState createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  String firstName = '';
  String lastName = '';
  String district = '';
  String email = '';

  @override
  void initState() {
    super.initState();
    fetchCustomerDetails();
  }

  // Fetch customer's details from Firestore
  Future<void> fetchCustomerDetails() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final customerDoc = await FirebaseFirestore.instance
            .collection('Customers')
            .doc(currentUser.uid)
            .get();

        if (customerDoc.exists) {
          setState(() {
            firstName = customerDoc.data()?['first name'] ?? '';
            lastName = customerDoc.data()?['last name'] ?? '';
            district = customerDoc.data()?['district'] ?? '';
            email = customerDoc.data()?['email'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Error fetching customer details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30), // To add some space at the top
            // Display Customer Details
            Text(
              '$firstName $lastName',
              style: const TextStyle(
                fontSize: 28,
                fontFamily: 'BebasNeue',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.email, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'BebasNeue',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Text(
                  district,
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'BebasNeue',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Divider(thickness: 2),
            // Reviews Section
            const Text(
              'Reviews',
              style: TextStyle(
                fontSize: 24,
                fontFamily: 'BebasNeue',
              ),
            ),
            const SizedBox(height: 10),


            
            // For now, we can show a placeholder for reviews
            Expanded(
              child: ListView.builder(
                itemCount: 3, // Replace this with actual review count
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text('Reviewer ${index + 1}'),
                    subtitle: const Text('This is a sample review.'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
