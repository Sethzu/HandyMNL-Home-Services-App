import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:test_2/Widgets/handyman_loading_indicator.dart'; // Importing the custom loading indicator

class CustomerChecksWorkerProfileReviewsSeeAll extends StatefulWidget {
  final String workerId;

  const CustomerChecksWorkerProfileReviewsSeeAll({super.key, required this.workerId});

  @override
  _CustomerChecksWorkerProfileReviewsSeeAllState createState() =>
      _CustomerChecksWorkerProfileReviewsSeeAllState();
}

class _CustomerChecksWorkerProfileReviewsSeeAllState
    extends State<CustomerChecksWorkerProfileReviewsSeeAll> {
  List<Map<String, dynamic>> allReviews = [];
  bool isLoading = true; // State to track loading

  @override
  void initState() {
    super.initState();
    fetchAllReviews();
  }

  Future<void> fetchAllReviews() async {
    try {
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('CustomerGiveRating')
          .where('workerId', isEqualTo: widget.workerId)
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
        isLoading = false; // Data fetched, stop loading
      });
    } catch (e) {
      print('Error fetching all reviews: $e');
      setState(() {
        isLoading = false; // Stop loading even on error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('All Reviews'),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading // Show loading indicator if data is still being fetched
            ? const Center(child: HandymanLoadingIndicator()) // Use the custom loading indicator
            : allReviews.isNotEmpty
                ? ListView.builder(
                    itemCount: allReviews.length,
                    itemBuilder: (context, index) {
                      final review = allReviews[index];
                      final formattedDate = DateFormat.yMMMd()
                          .format(review['timestamp']);

                      return Column(
                        children: [
                          ListTile(
                            tileColor: Colors.white,
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
                                  itemBuilder: (context, index) =>
                                      const Icon(Icons.star, color: Colors.amber),
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
