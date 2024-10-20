import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart'; // For formatting the timestamp

class WorkerReviewsSeeAll extends StatefulWidget {
  const WorkerReviewsSeeAll({super.key});

  @override
  _WorkerReviewsSeeAllState createState() => _WorkerReviewsSeeAllState();
}

class _WorkerReviewsSeeAllState extends State<WorkerReviewsSeeAll> {
  List<Map<String, dynamic>> allReviews = [];

  @override
  void initState() {
    super.initState();
    fetchAllReviews();
  }

  Future<void> fetchAllReviews() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final reviewsSnapshot = await FirebaseFirestore.instance
            .collection('CustomerGiveRating')
            .where('workerId', isEqualTo: currentUser.uid)
            .orderBy('timestamp', descending: true)
            .get();

        setState(() {
          allReviews = reviewsSnapshot.docs.map((doc) {
            return {
              'customerName': doc['customerName'],
              'timestamp': doc['timestamp'].toDate(),
              'ratingnumber': doc['ratingnumber'],
              'service': doc['service'],
              'subcategory': doc['subcategory'],
              'reviewdescription': doc['reviewdescription'],
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Error fetching all reviews: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('All Reviews'),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white), // Make AppBar icons white
        actionsIconTheme: const IconThemeData(color: Colors.white), // Make actions icons white
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20), // Make title text white
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: allReviews.isNotEmpty
            ? ListView.builder(
                itemCount: allReviews.length,
                itemBuilder: (context, index) {
                  final review = allReviews[index];
                  final formattedDate = DateFormat.yMMMd()
                      .format(review['timestamp']); // Format the timestamp

                  return Column(
                    children: [
                      ListTile(
                        tileColor: Colors.white, // Set the background color to white
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                review['customerName'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              formattedDate, // Use formatted timestamp
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
                                color: Colors.amber,
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
                      const Divider(thickness: 1), // Add subtle border (divider) below each review
                    ],
                  );
                },
              )
            : const Center(
                child: Text(
                  'No reviews available',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),
      ),
    );
  }
}
