import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomerProfileReviewsSeeAll extends StatefulWidget {
  final String customerId; // Accept customerId as a parameter

  const CustomerProfileReviewsSeeAll({super.key, required this.customerId});

  @override
  _CustomerProfileReviewsSeeAllState createState() =>
      _CustomerProfileReviewsSeeAllState();
}

class _CustomerProfileReviewsSeeAllState
    extends State<CustomerProfileReviewsSeeAll> {
  List<Map<String, dynamic>> allReviews = [];

  @override
  void initState() {
    super.initState();
    fetchAllReviews();
  }

  // Fetch all reviews of the customer based on customerId from 'WorkerGiveRating' collection
  Future<void> fetchAllReviews() async {
    try {
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('WorkerGiveRating')
          .where('customerId', isEqualTo: widget.customerId) // Use customerId
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        allReviews = reviewsSnapshot.docs.map((doc) {
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
            'timestamp': localTimestamp, // Use the adjusted timestamp
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
        title: Text(
          'All Reviews',
          style: GoogleFonts.roboto( // Apply Roboto font
            color: Colors.white,
            fontSize: 21,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(
          color: Colors.white, // Make the back button white
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: allReviews.isEmpty
            ? const Center(
                child: Text(
                  "You don't have any reviews yet.",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
            : ListView.builder(
                itemCount: allReviews.length,
                itemBuilder: (context, index) {
                  final review = allReviews[index];
                  final formattedDate =
                      DateFormat.yMMMd().format(review['timestamp']);
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
      ),
    );
  }
}
