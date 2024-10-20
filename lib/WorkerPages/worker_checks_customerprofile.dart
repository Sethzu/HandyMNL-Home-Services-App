import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'worker_checks_customerprofile_seeall.dart'; // Import the 'see all' page

class WorkerChecksCustomerProfile extends StatefulWidget {
  final String customerId;

  const WorkerChecksCustomerProfile({super.key, required this.customerId});

  @override
  _WorkerChecksCustomerProfileState createState() =>
      _WorkerChecksCustomerProfileState();
}

class _WorkerChecksCustomerProfileState
    extends State<WorkerChecksCustomerProfile> {
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

  Future<void> fetchCustomerDetails() async {
    try {
      final customerDoc = await FirebaseFirestore.instance
          .collection('Customers')
          .doc(widget.customerId)
          .get();

      if (customerDoc.exists) {
        setState(() {
          firstName = customerDoc.data()?['first name'] ?? '';
          lastName = customerDoc.data()?['last name'] ?? '';
          district = customerDoc.data()?['district'] ?? '';
          email = customerDoc.data()?['email'] ?? '';
        });
      }
    } catch (e) {
      print('Error fetching customer details: $e');
    }
  }

  Future<void> fetchAverageRating() async {
    try {
      final customerRatingDoc = await FirebaseFirestore.instance
          .collection('CustomerAverageRatings')
          .doc(widget.customerId)
          .get();

      if (customerRatingDoc.exists) {
        setState(() {
          averageRating = customerRatingDoc.data()?['averageRating'] ?? 0.0;
          totalReviews = customerRatingDoc.data()?['totalReviews'] ?? 0;
        });
      }
    } catch (e) {
      print('Error fetching average rating: $e');
    }
  }

  Future<void> fetchRecentReviews() async {
    try {
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('WorkerGiveRating')
          .where('customerId', isEqualTo: widget.customerId)
          .orderBy('timestamp', descending: true)
          .limit(3)
          .get();

      setState(() {
        reviews = reviewsSnapshot.docs.map((doc) {
          DateTime timestamp = doc['timestamp'].toDate();
          DateTime localTimestamp = timestamp.add(const Duration(hours: 8));
          return {
            'workerName': doc['workerName'],
            'ratingnumber': doc['ratingnumber'],
            'service': doc['service'],
            'subcategory': doc['subcategory'],
            'reviewdescription': doc['reviewdescription'],
            'timestamp': localTimestamp,
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching reviews: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous page
          },
        ),
        title: Text(
          'Customer Profile',
          style: GoogleFonts.roboto( // Apply Roboto font
            color: Colors.white,
            fontSize: 21,
          ),
        ),
        centerTitle: true,
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
                        '$averageRating Ratings by Workers',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '($totalReviews)',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      // Navigate to the see-all reviews page, passing the customerId
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerProfileReviewsSeeAll(
                            customerId: widget.customerId, // Pass customerId
                          ),
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
              // Display recent reviews
              reviews.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 200.0),
                        child: Text(
                          "This customer doesn't have reviews yet.",
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
                        final formattedDate = DateFormat.yMMMd().format(review['timestamp']);
                        return Column(
                          children: [
                            ListTile(
                              tileColor: Colors.white,
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
