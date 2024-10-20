import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:test_2/WorkerPages/WorkerProfile/WorkerProfile_Main/worker_profile_search.dart';
import 'package:test_2/WorkerPages/worker_bookings_page.dart';
import 'package:test_2/WorkerPages/WorkerProfile/WorkerProfile_Main/worker_profile_page.dart';
import 'package:test_2/WorkerPages/worker_inbox.dart';

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
    appBar: _selectedIndex != 1
        ? AppBar(
            backgroundColor: Colors.white, // Match page background
            elevation: 0,
            toolbarHeight: 80, // Increase AppBar height
            automaticallyImplyLeading: false, // Remove back button
            title: Text(
              'HANDYMNL', // Title set to 'Home'
              style: GoogleFonts.bebasNeue( // Apply GoogleFonts.bebasNeue
                color: Colors.blueAccent,
                fontSize: 35, // Larger font size for better visibility
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              // Search Icon Button
              IconButton(
                icon: const Icon(Icons.search_outlined,
                    color: Colors.grey, size: 30), // Increased size
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WorkerProfileSearch()), // Navigate to worker_profile_search.dart
                  );
                },
              ),
              // Inbox Icon Button
              IconButton(
                icon: const Icon(Icons.forum,
                    color: Colors.grey, size: 30), // Inbox icon instead of settings
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WorkerInbox()), // Navigate to worker_inbox.dart
                  );
                },
              ),
            ],
          )
        : null, // Remove AppBar when 'Profile' is selected

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
      final existingService = await FirebaseFirestore.instance
          .collection('Services')
          .where('workerId', isEqualTo: currentUser.uid)
          .where('service', isEqualTo: _selectedService)
          .where('subcategory', isEqualTo: _selectedSubcategory)
          .get();

      if (existingService.docs.isNotEmpty) {
        setState(() {
          _errorMessage = 'You have already posted this service.';
        });
        return;
      }

      final workerDoc = await FirebaseFirestore.instance
          .collection('Workers')
          .doc(currentUser.uid)
          .get();

      if (workerDoc.exists) {
        final workerData = workerDoc.data();

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
          'timestamp': FieldValue.serverTimestamp(),
          'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
          'averageRating': averageRating,
          'totalReviews': totalReviews,
        });

        Navigator.pop(context);

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select a Service',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () {
                      Navigator.pop(context); // Close the bottom sheet
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Service:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedService,
                hint: const Text(
                  'Choose a service',
                  style:
                      TextStyle(fontSize: 18), // Set font size as per reference
                ),
                items: _services.keys.map((String service) {
                  return DropdownMenuItem<String>(
                    value: service,
                    child: Center(
                      child: Text(
                        service,
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedService = value;
                    _selectedSubcategory = null;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4.0),
                    borderSide: const BorderSide(color: Colors.blueAccent),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent, width: 3),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                dropdownColor: Colors.grey[200],
                style: const TextStyle(fontSize: 18, color: Colors.black),
              ),
              if (_selectedService != null) ...[
                const SizedBox(height: 20),
                const Text(
                  'Subcategory:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedSubcategory,
                  hint: const Text('Choose a subcategory'),
                  items: _services[_selectedService]!.map((String subcategory) {
                    return DropdownMenuItem<String>(
                      value: subcategory,
                      child: Center(
                        child: Text(
                          subcategory,
                          style: const TextStyle(color: Colors.black),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSubcategory = value;
                    });
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4.0),
                      borderSide: const BorderSide(color: Colors.blueAccent),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.blueAccent, width: 3),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  dropdownColor: Colors.grey[200],
                  style: const TextStyle(fontSize: 18, color: Colors.black),
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                'Price:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Set Price',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.blueAccent,
                      width: 3,
                    ),
                  ),
                ),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, top: 8),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _postService,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text(
                    'Post',
                    style: TextStyle(color: Colors.white, fontSize: 18),
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
