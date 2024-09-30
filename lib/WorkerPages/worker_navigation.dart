import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:test_2/WorkerPages/worker_bookings_page.dart';
import 'package:test_2/WorkerPages/worker_profile_page.dart';

class WorkerNavigation extends StatefulWidget {
  const WorkerNavigation({super.key});

  @override
  _WorkerNavigationState createState() => _WorkerNavigationState();
}

class _WorkerNavigationState extends State<WorkerNavigation> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String firstName = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchWorkerFirstName();
  }

  Future<void> fetchWorkerFirstName() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final workerDoc = await FirebaseFirestore.instance
            .collection('Workers')
            .doc(currentUser.uid)
            .get();

        if (workerDoc.exists) {
          setState(() {
            firstName = workerDoc.data()?['first name'] ?? 'Worker';
          });
        }
      }
    } catch (e) {
      print('Error fetching worker first name: $e');
    }
  }

  final List<Widget> _pages = [
    const WorkerBookingsPage(),
    const WorkerProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openServiceDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _ServiceDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hello, $firstName'),
        centerTitle: true,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openServiceDialog,
        backgroundColor: Colors.blueAccent,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class _ServiceDialog extends StatefulWidget {
  const _ServiceDialog();

  @override
  _ServiceDialogState createState() => _ServiceDialogState();
}

class _ServiceDialogState extends State<_ServiceDialog> {
  String? _selectedService;
  String? _selectedSubcategory;
  final TextEditingController _priceController = TextEditingController();
  String? _errorMessage;

  final Map<String, List<String>> _services = {
    'Plumbing': [
      'Faucet Leak Repair',
      'Sink P-Trap Repair',
      'Sink Declogging',
      'Toilet Repair',
      'Drainage Declogging',
      'Grease Trap Cleaning'
    ],
    'Electrical': [
      'Lighting Installation',
      'Ceiling Fan Installation',
      'Outlet Installation',
      'Electrical Repair'
    ]
  };

  Future<void> _postService() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (_selectedService == null ||
        _selectedSubcategory == null ||
        _priceController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill out all the fields';
      });
      return;
    }

    if (currentUser != null) {
      // Check if the service and subcategory already exist for this worker
      final existingService = await FirebaseFirestore.instance
          .collection('Services')
          .where('workerId', isEqualTo: currentUser.uid)
          .where('service', isEqualTo: _selectedService)
          .where('subcategory', isEqualTo: _selectedSubcategory)
          .get();

      // If the service already exists, show an error message
      if (existingService.docs.isNotEmpty) {
        setState(() {
          _errorMessage = 'You have already posted this service.';
        });
        return;
      }

      // Get the worker's data
      final workerDoc = await FirebaseFirestore.instance
          .collection('Workers')
          .doc(currentUser.uid)
          .get();

      if (workerDoc.exists) {
        final workerData = workerDoc.data();

        // Fetch the worker's average rating and total reviews from 'WorkerAverageRatings'
        final ratingDoc = await FirebaseFirestore.instance
            .collection('WorkerAverageRatings')
            .doc(currentUser.uid)
            .get();

        double averageRating = 0.0;
        int totalReviews = 0;

        if (ratingDoc.exists) {
          averageRating = ratingDoc.data()?['averageRating'] ?? 0.0;
          totalReviews = ratingDoc.data()?['totalReviews'] ?? 0;
        }

        // Add the service data along with averageRating and totalReviews
        await FirebaseFirestore.instance.collection('Services').add({
          'service': _selectedService,
          'subcategory': _selectedSubcategory,
          'price': int.tryParse(_priceController.text) ?? 0,
          'workerId': currentUser.uid,
          'email': workerData?['email'],
          'first name': workerData?['first name'],
          'last name': workerData?['last name'],
          'district': workerData?['district'],
          'phone': workerData?['phone'],
          'timestamp':
              FieldValue.serverTimestamp(), // Firestore server timestamp
          'date':
              DateFormat('yyyy-MM-dd').format(DateTime.now()), // Formatted date
          'averageRating': averageRating, // Add average rating
          'totalReviews': totalReviews, // Add total reviews
        });

        Navigator.pop(context); // Close the dialog after posting

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 10),
                Text("Service posted successfully!"),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Service',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              DropdownButton<String>(
                value: _selectedService,
                hint: const Text('Choose a service'),
                items: _services.keys.map((String service) {
                  return DropdownMenuItem<String>(
                    value: service,
                    child: Text(service),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedService = value;
                    _selectedSubcategory = null;
                  });
                },
              ),
              if (_selectedService != null) ...[
                const SizedBox(height: 20),
                const Text(
                  'Select Subcategory',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: _selectedSubcategory,
                  hint: const Text('Choose a subcategory'),
                  items: _services[_selectedService]!.map((String subcategory) {
                    return DropdownMenuItem<String>(
                      value: subcategory,
                      child: Text(subcategory),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSubcategory = value;
                    });
                  },
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('PHP'),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Set Price',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.blueAccent,
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _postService, // Post to Firestore
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Post'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
