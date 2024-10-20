import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../CustomerProfile_Settings/customer_profile_settings.dart'; // Import for settings page
import 'customer_profile_search.dart'; // Import for search page
import 'customer_profile_reviews_seeall.dart'; // Import the 'see all reviews' page

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
  double averageRating = 0.0;
  int totalReviews = 0;
  List<Map<String, dynamic>> reviews = [];

  @override
  void initState() {
    super.initState();
    fetchCustomerDetails();
    fetchAverageRating();
    fetchRecentReviews();
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

  // Fetch the average rating and total reviews of the customer
  Future<void> fetchAverageRating() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final customerRatingDoc = await FirebaseFirestore.instance
            .collection('CustomerAverageRatings')
            .doc(currentUser.uid)
            .get();

        if (customerRatingDoc.exists) {
          setState(() {
            averageRating = customerRatingDoc.data()?['averageRating'] ?? 0.0;
            totalReviews = customerRatingDoc.data()?['totalReviews'] ?? 0;
          });
        }
      }
    } catch (e) {
      print('Error fetching average rating: $e');
    }
  }

  // Fetch the most recent 3 reviews of the customer from 'WorkerGiveRating' collection
  Future<void> fetchRecentReviews() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final reviewsSnapshot = await FirebaseFirestore.instance
            .collection('WorkerGiveRating')
            .where('customerId', isEqualTo: currentUser.uid)
            .orderBy('timestamp', descending: true)
            .limit(3)
            .get();

        setState(() {
          reviews = reviewsSnapshot.docs.map((doc) {
            // Convert Firestore timestamp to DateTime and adjust to UTC+8
            DateTime timestamp = doc['timestamp'].toDate();
            DateTime localTimestamp =
                timestamp.add(const Duration(hours: 8)); // Adjust to UTC+8
            return {
              'workerName': doc['workerName'],
              'ratingnumber': doc['ratingnumber'],
              'service': doc['service'],
              'subcategory': doc['subcategory'],
              'reviewdescription': doc['reviewdescription'],
              'timestamp': localTimestamp, // Use local timestamp
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Error fetching reviews: $e');
    }
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white, // Match page background
      elevation: 0,
      toolbarHeight: 80, // Increase AppBar height
      automaticallyImplyLeading: false, // Remove back button
      // Set 'Profile' text directly as the title (left-aligned by default)
      title: Text(
        'Profile',
        style: GoogleFonts.bebasNeue( // Apply GoogleFonts.bebasNeue
          color: Colors.black,
          fontSize: 35, // Larger font size for better visibility
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        // First, Search Icon Button
        IconButton(
          icon: const Icon(Icons.search_outlined,
              color: Colors.grey, size: 30), // Increased size
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const CustomerProfileSearch()),
            );
          },
        ),
        // Then, Settings Icon Button
        IconButton(
          icon: const Icon(Icons.settings,
              color: Colors.grey, size: 30), // Increased size
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const CustomerProfileSettings()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Display Customer Name
              Text(
                '$firstName $lastName',
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              // Customer Email and District
              Row(
                children: [
                  const Icon(Icons.email, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    email,
                    style: const TextStyle(fontSize: 18),
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
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Customer Average Rating and Total Reviews
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '$averageRating',
                    style: const TextStyle(fontSize: 18, color: Colors.black),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '($totalReviews reviews)',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Divider(thickness: 2),
              // Customer Ratings Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amberAccent),
                      const SizedBox(width: 8),
                      Text(
                        '$averageRating Customer Ratings',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '($totalReviews)',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const CustomerProfileReviewsSeeAll(),
                        ),
                      );
                    },
                    child: const Text(
                      'View All',
                      style: TextStyle(fontSize: 16, color: Colors.blueAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Display recent reviews or message if no reviews
              reviews.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 200.0),
                        child: Text(
                          "You don't have any reviews yet.",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reviews.length,
                      itemBuilder: (context, index) {
                        final review = reviews[index];
                        final formattedDate =
                            DateFormat.yMMMd().format(review['timestamp']);
                        return Column(
                          children: [
                            ListTile(
                              tileColor: Colors.white,
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    review['workerName'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    formattedDate,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RatingBarIndicator(
                                    rating: review['ratingnumber'],
                                    itemBuilder: (context, index) => const Icon(
                                      Icons.star,
                                      color: Colors.amberAccent,
                                    ),
                                    itemCount: 5,
                                    itemSize: 20.0,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${review['service']} - ${review['subcategory']}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(review['reviewdescription']),
                                ],
                              ),
                            ),
                            const Divider(thickness: 1),
                          ],
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
