import 'package:flutter/material.dart'; // Sa module na to yung Service Results. Nagkamali lang ng file name
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:test_2/ChatPage/chat_page.dart';
import 'customer_checks_workerprofile.dart'; // Import for navigation to worker profile page


class CustomerHomePage extends StatelessWidget {
  final List<Map<String, dynamic>> services;

  const CustomerHomePage({super.key, required this.services});
  

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.blueAccent, // Set the background color to blueAccent
      centerTitle: true, // Center-align the title
      title: Text(
        'Service Results',
        style: GoogleFonts.roboto(
          // Apply the Roboto font
          fontSize: 21, // Set font size to 21
          color: Colors.white, // Set the text color to white
        ),
      ),
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
        ), // Change to arrow_back_ios_new
        onPressed: () {
          Navigator.pop(context); // Pop the current route (go back)
        },
      ),
    ),
    body: ListView.builder(
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        final double averageRating = service['averageRating'] ?? 0.0; // Fetch averageRating
        final int totalReviews = service['totalReviews'] ?? 0; // Fetch totalReviews

        return GestureDetector(
          onTap: () {
            // Navigate to worker profile page when tile is clicked
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CustomerChecksWorkerProfilePage(
                  workerId: service['workerId'],
                ),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${service['first name']} ${service['last name']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '₱${service['price']}',
                        style: const TextStyle(
                          fontSize: 22, // Larger font size
                          color: Colors.blueAccent, // Accent color
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Rating display with star and number of reviews
                  Row(
                    children: [
                      // Single Star for rating
                      Icon(
                        averageRating >= 5
                            ? Icons.star_rate
                            : Icons.star_half_outlined, // Full star or half star
                        color: Colors.amber, // Amber color for star
                        size: 24,
                      ),
                      const SizedBox(width: 4),

                      // Display average rating and total reviews with different styles
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${averageRating.toStringAsFixed(1)} ',  // Average rating (bold and black)
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,  // Bold and black for the rating
                              ),
                            ),
                            TextSpan(
                              text: '($totalReviews reviews)',  // Total reviews (not bold and gray)
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,  // Normal weight (not bold)
                                color: Colors.black
                                ,  // Gray for the total reviews
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Service subcategory
                  Row(
                    children: [
                      const Icon(Icons.handyman_outlined, color: Colors.grey),  // Updated icon for handyman tool
                      const SizedBox(width: 5),
                      Text('${service['subcategory']}', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Worker district
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.blueAccent),
                      const SizedBox(width: 5),
                      Text('${service['district']}', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Buttons for making offer and messaging
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Show the modal bottom sheet for making an offer
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) {
                                return OfferBottomSheet(service: service);
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(
                                width: 3,
                                color: Colors.blueAccent,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: const Text(
                            'Make Offer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            // Redirect to the ChatPage when the message button is clicked
                            final currentUser = FirebaseAuth.instance.currentUser;
                            if (currentUser == null) return;

                            // Generate or fetch the conversation ID
                            final conversationDoc = await FirebaseFirestore
                                .instance
                                .collection('Conversations')
                                .where('workerId', isEqualTo: service['workerId'])
                                .where('customerId', isEqualTo: currentUser.uid)
                                .limit(1)
                                .get();

                            String conversationId;
                            if (conversationDoc.docs.isEmpty) {
                              // If no conversation exists, create a new one
                              final newConversation = await FirebaseFirestore.instance
                                  .collection('Conversations')
                                  .add({
                                'workerId': service['workerId'],
                                'customerId': currentUser.uid,
                                'lastMessage': '',
                                'lastMessageTimestamp': FieldValue.serverTimestamp(),
                              });
                              conversationId = newConversation.id;
                            } else {
                              // Use the existing conversation
                              conversationId = conversationDoc.docs.first.id;
                            }

                            // Navigate to the ChatPage
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatPage(
                                  conversationId: conversationId,
                                  receiverFirstName: service['first name'],
                                  receiverLastName: service['last name'],
                                  receiverEmail: service['email'],
                                  receiverUid: service['workerId'],
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            side: const BorderSide(
                              width: 3,
                              color: Colors.blueAccent,
                            ),
                          ),
                          child: const Text(
                            'Message',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


// Reuse the OfferBottomSheet widget code you provided
class OfferBottomSheet extends StatefulWidget {
  final Map<String, dynamic> service;

  const OfferBottomSheet({super.key, required this.service});

  @override
  _OfferBottomSheetState createState() => _OfferBottomSheetState();
}

class _OfferBottomSheetState extends State<OfferBottomSheet> {
  final TextEditingController _offerPriceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isError = false; // Error handling flag
  String? _errorMessage; // Error message for existing offer

  @override
  void initState() {
    super.initState();
    _offerPriceController.text =
        widget.service['price'].toString(); // Default offer price
  }

  Future<void> _makeOffer() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Check if the offer has already been made for this worker and service
    final query = await FirebaseFirestore.instance
        .collection('PendingOffers')
        .where('customerId', isEqualTo: currentUser.uid)
        .where('workerId', isEqualTo: widget.service['workerId'])
        .where('service', isEqualTo: widget.service['service'])
        .where('subcategory', isEqualTo: widget.service['subcategory'])
        .where('status', isEqualTo: 'Pending')
        .get();

    if (query.docs.isNotEmpty) {
      setState(() {
        _errorMessage =
            "You have already made an offer for this worker. Please wait for the worker to accept your offer.";
      });
      return;
    }

    // Fetch the customer's first name, last name, and district from the 'Customers' collection
    final customerDoc = await FirebaseFirestore.instance
        .collection('Customers')
        .doc(currentUser.uid)
        .get();

    if (!customerDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Customer information not found."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Fetch customer details
    final customerData = customerDoc.data();
    final customerFirstName = customerData?['first name'];
    final customerLastName = customerData?['last name'];
    final customerDistrict = customerData?['district'];

    if (_offerPriceController.text.isEmpty ||
        _descriptionController.text.isEmpty) {
      setState(() {
        _isError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all the fields."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Add a timestamp for when the offer is made
    final timestamp = FieldValue.serverTimestamp();

    // Show confirmation dialog before posting the offer
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              "Are you sure you want to offer ₱${_offerPriceController.text} to ${widget.service['first name']} ${widget.service['last name']}?"),
          content: Text(
              "Once you select 'Offer Now,' your offer will be visible to ${widget.service['first name']} ${widget.service['last name']}. When they accept, you’ll both have the opportunity to leave a review for each other. Please make sure to message the worker first."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('PendingOffers')
                    .add({
                  'workerId': widget.service['workerId'],
                  'workerName':
                      '${widget.service['first name']} ${widget.service['last name']}',
                  'customerId': currentUser.uid,
                  'customerEmail': currentUser.email,
                  'customerName': '$customerFirstName $customerLastName',
                  'service': widget.service['service'],
                  'subcategory': widget.service['subcategory'],
                  'price': _offerPriceController.text,
                  'description': _descriptionController.text,
                  'status': 'Pending',
                  'workerDistrict': widget.service['district'],
                  'customerDistrict': customerDistrict,
                  'timestamp': timestamp, // Add timestamp
                  'date': DateFormat('yyyy-MM-dd HH:mm')
                      .format(DateTime.now()), // Add formatted date
                });
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Close the bottom sheet

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Service Offer Success! Please wait for the worker to accept your offer. Thank you!",
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text("Yes, I'm sure!"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 10),
                  color: Colors.redAccent.withOpacity(0.1),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              Text(
                '${widget.service['first name']} ${widget.service['last name']} is offering this service for ₱${widget.service['price']}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              const Text(
                'How much do you want to offer for this service?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _offerPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '₱ Your Offer Price',
                  labelStyle: const TextStyle(color: Colors.blueAccent),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent, width: 3),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent, width: 3),
                  ),
                  errorText: _isError && _offerPriceController.text.isEmpty
                      ? 'This field is required'
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Describe the service needed:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe the service you need...',
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent, width: 3),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent, width: 3),
                  ),
                  errorText: _isError && _descriptionController.text.isEmpty
                      ? 'This field is required'
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _makeOffer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Center(
                  child: Text(
                    'Offer Now',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
