import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkerBookingsPage extends StatefulWidget {
  const WorkerBookingsPage({super.key});

  @override
  _WorkerBookingsPageState createState() => _WorkerBookingsPageState();
}

class _WorkerBookingsPageState extends State<WorkerBookingsPage> {
  String _selectedSegment = 'Pending';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                          offer['customerName'] ?? 'Unknown Name',
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
                        trailing: _buildTrailingWidget(context, offer), // Trailing logic for buttons or menu
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
      // Show pop-up menu only in 'Accepted' segment
      return PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert), // Circle vertical pop-up menu icon
        onSelected: (value) {
          if (value == 'Rate & Review') {
            // Handle rate & review
          } else if (value == 'Message') {
            // Handle message
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

  // Pop-up message for accepting offer
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
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('PendingOffers')
                    .doc(offerId)
                    .update({'status': 'Accepted'});
                Navigator.of(context).pop();
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

  // Pop-up message for declining offer
  void _showDeclineConfirmation(BuildContext context, String offerId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you sure you want to Decline the Offer?'),
          content: const Text(
              'Once you click decline, the customer can make another offer.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('PendingOffers')
                    .doc(offerId)
                    .update({'status': 'Declined'});
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.blueAccent,
              ),
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
  }
}
