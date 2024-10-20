import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';

// Import the new "See All" pages for services and reviews
import 'customer_checks_workerprofile_services_seeall.dart';
import 'customer_checks_workerprofile_reviews_seeall.dart';

class CustomerChecksWorkerProfilePage extends StatelessWidget {
  final String workerId;

  const CustomerChecksWorkerProfilePage({super.key, required this.workerId});

  Future<Map<String, dynamic>?> fetchWorkerDetails() async {
    try {
      final workerDoc = await FirebaseFirestore.instance
          .collection('Workers')
          .doc(workerId)
          .get();

      if (workerDoc.exists) {
        return workerDoc.data();
      }
    } catch (e) {
      print('Error fetching worker details: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchWorkerRatings() async {
    try {
      final workerRatingDoc = await FirebaseFirestore.instance
          .collection('WorkerAverageRatings')
          .doc(workerId)
          .get();

      if (workerRatingDoc.exists) {
        return workerRatingDoc.data();
      }
    } catch (e) {
      print('Error fetching worker ratings: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchWorkerServices() async {
    try {
      final servicesSnapshot = await FirebaseFirestore.instance
          .collection('Services')
          .where('workerId', isEqualTo: workerId)
          .orderBy('timestamp', descending: true)
          .limit(3)
          .get();

      return servicesSnapshot.docs.map((doc) {
        return {
          'service': doc['service'] ?? '',
          'subcategory': doc['subcategory'] ?? '',
          'price': doc['price'].toString(),
        };
      }).toList();
    } catch (e) {
      print('Error fetching worker services: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchWorkerReviews() async {
    try {
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('CustomerGiveRating')
          .where('workerId', isEqualTo: workerId)
          .orderBy('timestamp', descending: true)
          .limit(3)
          .get();

      return reviewsSnapshot.docs.map((doc) {
        return {
          'customerName': doc['customerName'],
          'timestamp': doc['timestamp'].toDate(),
          'ratingnumber': doc['ratingnumber'],
          'service': doc['service'],
          'subcategory': doc['subcategory'],
          'reviewdescription': doc['reviewdescription'],
        };
      }).toList();
    } catch (e) {
      print('Error fetching worker reviews: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
backgroundColor: Colors.white,     
      appBar: AppBar(
        title: const Text('Worker Profile'),
      ),
      body: FutureBuilder(
        future: Future.wait([
          fetchWorkerDetails(),
          fetchWorkerServices(),
          fetchWorkerReviews(),
          fetchWorkerRatings(), // Fetching worker's average ratings and total reviews
        ]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching worker data.'));
          }

          final workerData = snapshot.data?[0] ?? {};
          final services = snapshot.data?[1] ?? [];
          final reviews = snapshot.data?[2] ?? [];
          final ratingsData = snapshot.data?[3] ?? {};

          final firstName = workerData['first name'] ?? 'N/A';
          final lastName = workerData['last name'] ?? 'N/A';
          final email = workerData['email'] ?? 'N/A';
          final district = workerData['district'] ?? 'N/A';
          final averageRating = ratingsData['averageRating'] ?? 0.0;
          final totalReviews = ratingsData['totalReviews'] ?? 0;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  Text(
                    '$firstName $lastName',
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '$averageRating',
                        style:
                            const TextStyle(fontSize: 18, color: Colors.black),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($totalReviews reviews)',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Divider(thickness: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Services',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Navigate to services see-all page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CustomerChecksWorkerProfileServicesSeeAll(
                                      workerId: workerId),
                            ),
                          );
                        },
                        child: const Text(
                          'View All',
                          style:
                              TextStyle(fontSize: 16, color: Colors.blueAccent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      final service = services[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text(
                            '${service['service']} - ${service['subcategory']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            '₱${service['price']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18, // Made the price bigger
                              color: Colors.blueAccent,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(thickness: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amberAccent),
                          const SizedBox(width: 8),
                          Text(
                            '$averageRating Worker Ratings',
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
                          // Navigate to reviews see-all page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CustomerChecksWorkerProfileReviewsSeeAll(
                                      workerId: workerId),
                            ),
                          );
                        },
                        child: const Text(
                          'View All',
                          style:
                              TextStyle(fontSize: 16, color: Colors.blueAccent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  review['customerName'],
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
          );
        },
      ),
    );
  }
}
