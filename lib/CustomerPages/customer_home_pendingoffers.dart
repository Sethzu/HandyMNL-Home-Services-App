import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart'; // For formatting dates
import 'customer_checks_workerprofile.dart'; // Import worker profile page

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
      backgroundColor: Colors.white,
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
                  .orderBy('timestamp', descending: true)
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

    // Safely check if 'timestamp' exists and handle null values
    final Timestamp? timestamp = offer['timestamp'] as Timestamp?;
    DateTime dateTime = timestamp?.toDate() ?? DateTime.now(); // Fallback to current time if null

    // Convert the dateTime to Philippine Time (UTC+8)
    dateTime = dateTime.add(const Duration(hours: 8)); // Add 8 hours for PHT (UTC+8)

    // Format date as MM/DD/YY and time as 12-hour format with AM/PM
    final formattedDate = DateFormat('MM/dd/yy').format(dateTime);
    final formattedTime = DateFormat('hh:mm a').format(dateTime); // 12-hour format with AM/PM

    return GestureDetector(
      onTap: () {
        // Navigate to worker profile on tap
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerChecksWorkerProfilePage(
              workerId: offer['workerId'],
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.all(10),
        child: ListTile(
          tileColor: Colors.white, // Set background color to white
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${offer['workerName']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$formattedDate at $formattedTime', // Display date and time in the correct format
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.blueAccent),
                  const SizedBox(width: 5),
                  Text(offer['workerDistrict'] ?? 'Unknown District'),
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
              const SizedBox(height: 12),
              _buildActionButton(context, offer),  // Call _buildActionButton for Pending/Accepted sections
            ],
          ),
          trailing: _buildTrailingWidget(context, offer), // Call _buildTrailingWidget for Declined section
                      ),
                      )
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
      return 'You currently have no pending offers.';
    } else if (segment == 'Accepted') {
      return 'You currently have no accepted offers.';
    } else {
      return 'Great job! You have no declined offers yet!';
    }
  }

  Widget _buildTrailingWidget(BuildContext context, QueryDocumentSnapshot offer) {
  if (_selectedSegment == 'Declined') {
    return const Text(
      'Declined',
      style: TextStyle(
        fontSize: 16,
        color: Colors.red,
      ),
    );
  } else {
    return const SizedBox.shrink();  // Return nothing for other sections
  }
}


  Widget _buildActionButton(BuildContext context, QueryDocumentSnapshot offer) {
    if (_selectedSegment == 'Pending') {
      // "Edit Offer" button for Pending section
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            height: 35,
            child: ElevatedButton(
              onPressed: () => _showEditOfferModalBottomSheet(context, offer),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                side: const BorderSide(color: Colors.blueAccent, width: 3),
              ),
              child: const Text(
                'Edit Offer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      );
    } else if (_selectedSegment == 'Accepted') {
      // "Leave a Review" button for Accepted section
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            height: 35,
            child: ElevatedButton(
              onPressed: () => showRateReviewModalBottomSheet(context, offer),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                side: const BorderSide(color: Colors.blueAccent, width: 3),
              ),
              child: const Text(
                'Leave a Review',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      );
    } else {
      // No button for Declined section
      return const SizedBox.shrink();
    }
  }

  void _showEditOfferModalBottomSheet(BuildContext context, QueryDocumentSnapshot offer) {
  final TextEditingController priceController =
      TextEditingController(text: offer['price']);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Edit Offer Price',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Enter new price',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.blueAccent,
                      width: 3.0, // Border width on focus
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey, // Default border color when not focused
                      width: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  // Update the price in the 'PendingOffers' collection
                  await FirebaseFirestore.instance
                      .collection('PendingOffers')
                      .doc(offer.id)
                      .update({'price': priceController.text});
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Offer price updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 80,
                  ),
                ),
                child: const Text(
                  'Update',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    },
  );
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



