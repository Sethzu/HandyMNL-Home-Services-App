import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'worker_checks_customerprofile.dart'; // Import for customer profile

class WorkerBookingsPage extends StatefulWidget {
  const WorkerBookingsPage({super.key});

  @override
  _WorkerBookingsPageState createState() => _WorkerBookingsPageState();
}

class _WorkerBookingsPageState extends State<WorkerBookingsPage> {
  String _selectedSegment = 'Pending'; // Default value

 @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    body: Column(
      children: [
        const SizedBox(height: 40), // Add spacing at the top
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
                .where('workerId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                .where('status', isEqualTo: _selectedSegment)
                .orderBy('timestamp', descending: true) // Show most recent offers first
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

                  // Fetch timestamp for the date/time when the worker accepted/declined
                  final Timestamp? timestamp = offer['timestamp'] as Timestamp?;
                  DateTime dateTime = timestamp?.toDate() ?? DateTime.now(); // Fallback to current time if null

                  // Convert the dateTime to Philippine Time (UTC+8)
                  dateTime = dateTime.add(const Duration(hours: 8)); // Add 8 hours for PHT (UTC+8)

                  // Format date as MM/DD/YY and time as 12-hour format with AM/PM
                  final formattedDate = DateFormat('MM/dd/yy hh:mm a').format(dateTime);

                  return GestureDetector(
                    onTap: () {
                      // Navigate to the customer profile when clicked
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkerChecksCustomerProfile(
                            customerId: offer['customerId'], // Pass customerId
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
                              offer['customerName'] ?? 'Unknown Name',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              formattedDate, // Display the timestamp in PHT
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
                                Text(offer['customerDistrict'] ?? 'Unknown District'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Service: ${offer['service']}\n'
                              'Subcategory: ${offer['subcategory']}\n'
                              'Description: ${offer['description']}',
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
      return 'You have no pending offers.';
    } else if (segment == 'Accepted') {
      return 'You have no accepted offers.';
    } else {
      return 'You have no declined offers.';
    }
  }

  Widget _buildTrailingWidget(BuildContext context, QueryDocumentSnapshot offer) {
    if (_selectedSegment == 'Pending') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            iconSize: 32, // Make the check icon larger
            icon: const Icon(Icons.check_circle, color: Colors.green),
            onPressed: () => _showAcceptConfirmation(context, offer.id),
          ),
          IconButton(
            iconSize: 32, // Make the X icon larger
            icon: const Icon(Icons.cancel, color: Colors.red),
            onPressed: () => _showDeclineConfirmation(context, offer.id),
          ),
        ],
      );
    } else if (_selectedSegment == 'Accepted') {
      // Show pop-up menu in the 'Accepted' segment
      return PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert), // Circle vertical pop-up menu icon
        onSelected: (value) {
          if (value == 'Rate & Review') {
            // Handle rate & review for worker's POV
            _showWorkerRateReviewModalBottomSheet(context, offer);
          } else if (value == 'Message') {
            // Handle message functionality
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'Rate & Review',
            child: ListTile(
              leading: Icon(Icons.star, color: Colors.amber), // Star icon
              title: Text('Rate & Review'),
            ),
          ),
          const PopupMenuItem<String>(
            value: 'Message',
            child: ListTile(
              leading: Icon(Icons.message, color: Colors.blueAccent), // Message icon
              title: Text('Message'),
            ),
          ),
        ],
      );
    } else {
      // Ensure 'Declined' text has the same font size as 'Pending'
      return const Text(
        'Declined',
        style: TextStyle(
          fontSize: 16, // Match font size with 'Pending'
          color: Colors.red,
        ),
      );
    }
  }

  // Show confirmation dialog for accepting the offer
  void _showAcceptConfirmation(BuildContext context, String offerId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you sure you want to Accept the Offer?'),
          content: const Text(
              'Once you click accept, you will be able to rate and review each other.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('PendingOffers')
                    .doc(offerId)
                    .update({
                  'status': 'Accepted',
                  'timestamp': FieldValue.serverTimestamp(), // Add timestamp when accepted
                });
                Navigator.of(context).pop(); // Close the dialog after updating
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.blueAccent,
              ),
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );
  }

  // Show confirmation dialog for declining the offer
  void _showDeclineConfirmation(BuildContext context, String offerId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you sure you want to Decline the Offer?'),
          content: const Text('Once you click decline, the customer can make another offer.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('PendingOffers')
                    .doc(offerId)
                    .update({
                  'status': 'Declined',
                  'timestamp': FieldValue.serverTimestamp(), // Add timestamp when declined
                });
                Navigator.of(context).pop(); // Close the dialog after updating
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.blueAccent,
              ),
              child: const Text('Decline'),
            ),
          ],
        );
      },
    );
  }

  // Modal Bottom Sheet for Worker Rate & Review
  void _showWorkerRateReviewModalBottomSheet(BuildContext context, QueryDocumentSnapshot offer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return WorkerRateReviewBottomSheet(offer: offer);
      },
    );
  }
}

// New Modal Bottom Sheet for Worker Rate & Review
class WorkerRateReviewBottomSheet extends StatefulWidget {
  final QueryDocumentSnapshot offer;

  const WorkerRateReviewBottomSheet({super.key, required this.offer});

  @override
  _WorkerRateReviewBottomSheetState createState() => _WorkerRateReviewBottomSheetState();
}

class _WorkerRateReviewBottomSheetState extends State<WorkerRateReviewBottomSheet> {
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
        .collection('WorkerGiveRating')
        .where('workerId', isEqualTo: currentUser.uid)
        .where('customerId', isEqualTo: widget.offer['customerId'])
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
    if (_reviewController.text.isEmpty || _rating == 0) {
      setState(() {
        _isError = true;
      });
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      setState(() {
        _isError = true;
      });
      return;
    }

    if (_hasReviewed) {
      setState(() {
        _isError = true;
      });
      return;
    }

    final workerDoc = await FirebaseFirestore.instance
        .collection('Workers')
        .doc(currentUser.uid)
        .get();

    if (!workerDoc.exists) {
      setState(() {
        _isError = true;
      });
      return;
    }

    final workerName = "${workerDoc['first name']} ${workerDoc['last name']}";

    // Add Review to Firestore
    await FirebaseFirestore.instance.collection('WorkerGiveRating').add({
      'workerId': currentUser.uid,
      'workerName': workerName,
      'service': widget.offer['service'],
      'subcategory': widget.offer['subcategory'],
      'ratingnumber': _rating,
      'reviewdescription': _reviewController.text,
      'timestamp': FieldValue.serverTimestamp(),
      'customerId': widget.offer['customerId'],
      'customerName': widget.offer['customerName'],
    });

    // Update Customer Average Rating
    await _updateCustomerAverageRating(widget.offer['customerId'], widget.offer['customerName']);

    // Success message
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Review submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Function to calculate and update customer's average rating
  Future<void> _updateCustomerAverageRating(String customerId, String customerName) async {
    final ratingSnapshot = await FirebaseFirestore.instance
        .collection('WorkerGiveRating')
        .where('customerId', isEqualTo: customerId)
        .get();

    if (ratingSnapshot.docs.isNotEmpty) {
      double totalRating = 0;
      int totalReviews = ratingSnapshot.docs.length;

      for (var doc in ratingSnapshot.docs) {
        totalRating += doc['ratingnumber'];
      }

      // Round to 1 decimal place
      double averageRating = double.parse((totalRating / totalReviews).toStringAsFixed(1));

      // Update CustomerAverageRatings collection
      await FirebaseFirestore.instance.collection('CustomerAverageRatings').doc(customerId).set({
        'customerId': customerId,
        'customerName': customerName,
        'totalReviews': totalReviews,
        'averageRating': averageRating,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets, // Prevent compression
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "How was your experience with",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                "${widget.offer['customerName']}?",
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
              const SizedBox(height: 8),
              if (_hasReviewed)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    "You have already submitted a review for this customer for the service provided.",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              if (!_hasReviewed) ...[
                if (_isError)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      "Please fill in all the fields.",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 15),
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
                const SizedBox(height: 15),
                TextField(
                  controller: _reviewController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Leave a review here...',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        width: 3,
                        color: Colors.grey,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        width: 3,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 80),
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
      ),
    );
  }
}
