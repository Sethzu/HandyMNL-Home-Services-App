import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // For formatting the timestamp
import 'worker_services_seeall.dart';
import 'worker_reviews_seeall.dart';
import 'worker_profile_search.dart'; // Add the worker profile search page
import '../WorkerProfile_Settings/worker_profile_settings.dart'; // Add the worker profile settings page

class WorkerProfilePage extends StatefulWidget {
  const WorkerProfilePage({super.key});

  @override
  _WorkerProfilePageState createState() => _WorkerProfilePageState();
}

class _WorkerProfilePageState extends State<WorkerProfilePage> {
  String firstName = '';
  String lastName = '';
  String district = '';
  String email = '';
  double averageRating = 0.0;
  int totalReviews = 0;
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> reviews = [];

  @override
  void initState() {
    super.initState();
    fetchWorkerDetails();
    fetchWorkerServices();
    fetchRatingsAndReviews();
    fetchAverageRating();
  }

  Future<void> fetchWorkerDetails() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final workerDoc = await FirebaseFirestore.instance
            .collection('Workers')
            .doc(currentUser.uid)
            .get();

        if (workerDoc.exists) {
          setState(() {
            firstName = workerDoc.data()?['first name'] ?? '';
            lastName = workerDoc.data()?['last name'] ?? '';
            district = workerDoc.data()?['district'] ?? '';
            email = workerDoc.data()?['email'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Error fetching worker details: $e');
    }
  }

  Future<void> fetchWorkerServices() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final servicesSnapshot = await FirebaseFirestore.instance
            .collection('Services')
            .where('workerId', isEqualTo: currentUser.uid)
            .orderBy('timestamp', descending: true)
            .limit(3)
            .get();

        setState(() {
          services = servicesSnapshot.docs.map((doc) {
            return {
              'id': doc.id,
              'service': doc['service'] ?? '',
              'subcategory': doc['subcategory'] ?? '',
              'price': doc['price'].toString(),
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Error fetching worker services: $e');
    }
  }

  Future<void> fetchRatingsAndReviews() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final reviewsSnapshot = await FirebaseFirestore.instance
            .collection('CustomerGiveRating')
            .where('workerId', isEqualTo: currentUser.uid)
            .orderBy('timestamp', descending: true)
            .limit(3)
            .get();

        setState(() {
          reviews = reviewsSnapshot.docs.map((doc) {
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
      print('Error fetching ratings and reviews: $e');
    }
  }

  Future<void> fetchAverageRating() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final workerRatingDoc = await FirebaseFirestore.instance
            .collection('WorkerAverageRatings')
            .doc(currentUser.uid)
            .get();

        if (workerRatingDoc.exists) {
          setState(() {
            averageRating = workerRatingDoc.data()?['averageRating'] ?? 0.0;
            totalReviews = workerRatingDoc.data()?['totalReviews'] ?? 0;
          });
        }
      }
    } catch (e) {
      print('Error fetching average rating: $e');
    }
  }

  // Dialog to confirm price edit
  void showEditPriceDialog(String serviceId, String service, String subcategory,
      TextEditingController priceController) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Price Edit'),
          content: Text(
              "Are you sure you want to edit the price for '$service' - '$subcategory'?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                updateServicePrice(serviceId, priceController.text);
                Navigator.of(context).pop();
              },
              child: const Text("Yes, I'm sure"),
            ),
          ],
        );
      },
    );
  }

  // Dialog to confirm service deletion
  void showDeleteServiceDialog(
      String serviceId, String service, String subcategory) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Service Deletion'),
          content: Text(
              "Are you sure you want to delete '$service' - '$subcategory'?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                deleteService(serviceId);
                Navigator.of(context).pop();
              },
              child: const Text("Yes, I'm sure"),
            ),
          ],
        );
      },
    );
  }

  // Method to update service price
  Future<void> updateServicePrice(String serviceId, String newPrice) async {
    try {
      await FirebaseFirestore.instance
          .collection('Services')
          .doc(serviceId)
          .update({'price': int.tryParse(newPrice) ?? 0});
      fetchWorkerServices(); // Refresh the services after update
    } catch (e) {
      print('Error updating price: $e');
    }
  }

  // Method to delete service
  Future<void> deleteService(String serviceId) async {
    try {
      await FirebaseFirestore.instance
          .collection('Services')
          .doc(serviceId)
          .delete();
      fetchWorkerServices(); // Refresh the services after deletion
    } catch (e) {
      print('Error deleting service: $e');
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
          style: GoogleFonts.bebasNeue(
            // Apply GoogleFonts.bebasNeue
            color: Colors.black,
            fontSize: 35, // Larger font size for better visibility
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.search_outlined, color: Colors.grey, size: 30),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const WorkerProfileSearch()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.grey, size: 30),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const WorkerProfileSettings()),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const WorkerServicesSeeAll()),
                      );
                    },
                    child: const Text(
                      'See All',
                      style: TextStyle(fontSize: 16, color: Colors.blueAccent),
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
                  final TextEditingController priceController =
                      TextEditingController(text: service['price']);
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
                      subtitle: Row(
                        children: [
                          const Text(
                            '₱',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: TextField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                              onSubmitted: (newValue) {
                                showEditPriceDialog(
                                  service['id'],
                                  service['service'],
                                  service['subcategory'],
                                  priceController,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          showDeleteServiceDialog(
                            service['id'],
                            service['service'],
                            service['subcategory'],
                          );
                        },
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const WorkerReviewsSeeAll()),
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
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
