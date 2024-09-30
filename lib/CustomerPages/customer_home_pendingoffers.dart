import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class CustomerHomePendingOffers extends StatefulWidget {
  const CustomerHomePendingOffers({super.key});

  @override
  _CustomerHomePendingOffersState createState() =>
      _CustomerHomePendingOffersState();
}

class _CustomerHomePendingOffersState extends State<CustomerHomePendingOffers> {
  String _selectedSegment = 'Pending';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: CupertinoSegmentedControl<String>(
              children: const {
                'Pending': Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    'Pending',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                'Accepted': Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    'Accepted',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                'Declined': Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    'Declined',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              },
              groupValue: _selectedSegment,
              onValueChanged: (value) {
                setState(() {
                  _selectedSegment = value;
                });
              },
              borderColor: Colors.blueAccent,
              selectedColor: Colors.blueAccent,
              unselectedColor: Colors.white,
              pressedColor: Colors.blue[100],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('PendingOffers')
                  .where('customerId',
                      isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                  .where('status', isEqualTo: _selectedSegment)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final offers = snapshot.data!.docs;

                if (offers.isEmpty) {
                  return Center(
                    child: Text(
                      _getEmptyMessage(_selectedSegment),
                      style: const TextStyle(fontSize: 18),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: offers.length,
                  itemBuilder: (context, index) {
                    final offer = offers[index];
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(
                          'Offer to ${offer['workerName']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: Colors.blueAccent),
                                const SizedBox(width: 5),
                                Text(offer['workerDistrict'] ??
                                    'Unknown District'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Service: ${offer['service']}\n'
                              'Subcategory: ${offer['subcategory']}\n'
                              'Description: ${offer['description'] ?? 'No description provided'}',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Offered Price: ₱${offer['price']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ],
                        ),
                        trailing: _buildTrailingWidget(context, offer),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getEmptyMessage(String segment) {
    if (segment == 'Pending') {
      return 'You have not made any offers yet.';
    } else if (segment == 'Accepted') {
      return 'You have no accepted offers.';
    } else {
      return 'You have no declined offers.';
    }
  }

  Widget _buildTrailingWidget(
      BuildContext context, QueryDocumentSnapshot offer) {
    if (_selectedSegment == 'Pending') {
      return const Text(
        'Pending',
        style: TextStyle(
          fontSize: 16,
          color: Colors.orange,
        ),
      );
    } else if (_selectedSegment == 'Accepted') {
      return PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) {
          if (value == 'Rate & Review') {
            showRateReviewModalBottomSheet(context, offer);
          } else if (value == 'Message') {}
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'Rate & Review',
            child: ListTile(
              leading: Icon(Icons.star, color: Colors.amber),
              title: Text('Rate & Review'),
            ),
          ),
          const PopupMenuItem<String>(
            value: 'Message',
            child: ListTile(
              leading: Icon(Icons.message, color: Colors.blueAccent),
              title: Text('Message'),
            ),
          ),
        ],
      );
    } else {
      return const Text(
        'Declined',
        style: TextStyle(
          fontSize: 16,
          color: Colors.red,
        ),
      );
    }
  }

  void showRateReviewModalBottomSheet(
      BuildContext context, QueryDocumentSnapshot offer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return RateReviewBottomSheet(offer: offer);
      },
    );
  }
}

// Modal Bottom Sheet for Rating and Review

class RateReviewBottomSheet extends StatefulWidget {
  final QueryDocumentSnapshot offer;

  const RateReviewBottomSheet({super.key, required this.offer});

  @override
  _RateReviewBottomSheetState createState() => _RateReviewBottomSheetState();
}

class _RateReviewBottomSheetState extends State<RateReviewBottomSheet> {
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 3.0;
  bool _isError = false;
  bool _hasReviewed = false;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyReviewed();
  }

  Future<void> _checkIfAlreadyReviewed() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    final reviewSnapshot = await FirebaseFirestore.instance
        .collection('CustomerGiveRating')
        .where('customerId', isEqualTo: currentUser.uid)
        .where('workerId', isEqualTo: widget.offer['workerId'])
        .where('service', isEqualTo: widget.offer['service'])
        .where('subcategory', isEqualTo: widget.offer['subcategory'])
        .get();

    if (reviewSnapshot.docs.isNotEmpty) {
      setState(() {
        _hasReviewed = true;
      });
    }
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.isEmpty) {
      setState(() {
        _isError = true;
      });
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_hasReviewed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "You have already given a review for this worker and service."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final customerDoc = await FirebaseFirestore.instance
        .collection('Customers')
        .doc(currentUser.uid)
        .get();

    if (!customerDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer data not found!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final customerName =
        "${customerDoc['first name']} ${customerDoc['last name']}";

    // Add Review to Firestore
    await FirebaseFirestore.instance.collection('CustomerGiveRating').add({
      'workerId': widget.offer['workerId'],
      'workerName': widget.offer['workerName'],
      'service': widget.offer['service'],
      'subcategory': widget.offer['subcategory'],
      'price': widget.offer['price'],
      'ratingnumber': _rating,
      'reviewdescription': _reviewController.text,
      'timestamp': FieldValue.serverTimestamp(),
      'customerId': currentUser.uid,
      'customerName': customerName,
      'customerEmail': currentUser.email,
    });

    // Calculate and Update Worker Average Rating
    await _updateWorkerAverageRating(widget.offer['workerId'],
        widget.offer['workerName'], widget.offer['service']);

    // Success message
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Review submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Function to calculate and update worker's average rating in both 'WorkerAverageRatings' and 'Services' collection
  Future<void> _updateWorkerAverageRating(
      String workerId, String workerName, String service) async {
    final ratingSnapshot = await FirebaseFirestore.instance
        .collection('CustomerGiveRating')
        .where('workerId', isEqualTo: workerId)
        .get();

    if (ratingSnapshot.docs.isNotEmpty) {
      double totalRating = 0;
      int totalReviews = ratingSnapshot.docs.length;

      for (var doc in ratingSnapshot.docs) {
        totalRating += doc['ratingnumber'];
      }

      // Round to 1 decimal place
      double averageRating =
          double.parse((totalRating / totalReviews).toStringAsFixed(1));

      // Update WorkerAverageRatings collection
      await FirebaseFirestore.instance
          .collection('WorkerAverageRatings')
          .doc(workerId)
          .set({
        'workerId': workerId,
        'workerName': workerName,
        'totalReviews': totalReviews,
        'averageRating': averageRating,
      });

      // Update Services collection for the specific worker and service
      await FirebaseFirestore.instance
          .collection('Services')
          .where('workerId', isEqualTo: workerId)
          .get()
          .then((querySnapshot) {
        for (var doc in querySnapshot.docs) {
          doc.reference.update({
            'totalReviews': totalReviews,
            'averageRating': averageRating,
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text(
              "How was your experience with",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4), // Adjusted spacing
            Text(
              "${widget.offer['workerName']}'s?",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.offer['service']} - ${widget.offer['subcategory']}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (_hasReviewed)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  "You have already given a review for this worker and its service.",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            if (!_hasReviewed) ...[
              const SizedBox(height: 20),
              RatingBar.builder(
                initialRating: _rating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  setState(() {
                    _rating = rating;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _reviewController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Leave a review here...',
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(
                      width: 3,
                      color: Colors.grey,
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      width: 3,
                      color: Colors.blueAccent,
                    ),
                  ),
                  errorText: _isError ? 'Please fill in all the fields.' : null,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 80),
                ),
                child: const Text(
                  'Submit Review',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
