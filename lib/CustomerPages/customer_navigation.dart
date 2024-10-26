
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_2/CustomerPages/CustomerProfile/CustomerProfile_Main/customer_profile_search.dart';
import 'package:test_2/CustomerPages/customer_home.dart';
import 'package:test_2/CustomerPages/customer_home_pendingoffers.dart';
import 'package:test_2/CustomerPages/CustomerProfile/CustomerProfile_Main/customer_profile.dart';
import 'package:test_2/CustomerPages/customer_inbox.dart';


class CustomerNavigation extends StatefulWidget {
  const CustomerNavigation({super.key});


  @override
  CustomerNavigationState createState() => CustomerNavigationState();
}


class CustomerNavigationState extends State<CustomerNavigation> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String firstName = '';
  int _selectedIndex = 0;


  @override
  void initState() {
    super.initState();
    fetchCustomerFirstName();
  }


  // Fetch customer's first name from Firestore
  Future<void> fetchCustomerFirstName() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final customerDoc = await FirebaseFirestore.instance
            .collection('Customers')
            .doc(currentUser.uid)
            .get();


        if (customerDoc.exists) {
          setState(() {
            firstName = customerDoc.data()?['first name'] ?? 'Customer';
          });
        }
      }
    } catch (e) {
      print('Error fetching customer first name: $e');
    }
  }


  // List of pages for navigation
  final List<Widget> _pages = [
    const CustomerHomePendingOffers(),
    const CustomerProfilePage(),
  ];


  // Handle BottomAppBar icon tap
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }


  // Function to open the dialog for searching services
  void _openServiceDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _ServiceSearchDialog(),
    );
  }


  @override
Widget build(BuildContext context) {
  return Scaffold(
    // Only display the AppBar if the selected index is not 'Profile' (index 1)
    appBar: _selectedIndex != 1
        ? AppBar(
            backgroundColor: Colors.white, // Match page background
            elevation: 0,
            toolbarHeight: 80, // Increase AppBar height
            automaticallyImplyLeading: false, // Remove back button
            title: Text(
              'HANDYMNL', // Changed from 'Profile' to 'Home'
              style: GoogleFonts.bebasNeue( // Apply GoogleFonts.bebasNeue
                color: Colors.blueAccent,
                fontSize: 35, // Larger font size for better visibility
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              // Search Icon Button (kept the same)
              IconButton(
                icon: const Icon(Icons.search_outlined,
                    color: Colors.grey, size: 30), // Increased size
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CustomerProfileSearch()),
                  );
                },
              ),
              // Inbox Icon Button (replacing the settings icon)
              IconButton(
                icon: const Icon(Icons.forum_rounded,
                    color: Colors.grey, size: 30), // Inbox icon instead of settings
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CustomerInbox()), // Navigating to customer_inbox.dart
                  );
                },
              ),
            ],
          )
        : null, // Remove the AppBar on the Profile page


    body: SafeArea(
      child: _pages[_selectedIndex],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _openServiceDialog,
      backgroundColor: Colors.blueAccent,
      shape: const CircleBorder(),
      child: const Icon(Icons.search, color: Colors.white),
    ),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    bottomNavigationBar: SafeArea(
      child: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              IconButton(
                icon: Icon(
                  Icons.home,
                  color: _selectedIndex == 0 ? Colors.blueAccent : Colors.grey,
                ),
                iconSize: 30,
                onPressed: () {
                  _onItemTapped(0);
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.person,
                  color: _selectedIndex == 1 ? Colors.blueAccent : Colors.grey,
                ),
                iconSize: 30,
                onPressed: () {
                  _onItemTapped(1);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



// Service Search Dialog
class _ServiceSearchDialog extends StatefulWidget {
  const _ServiceSearchDialog();

  @override
  _ServiceSearchDialogState createState() => _ServiceSearchDialogState();
}

class _ServiceSearchDialogState extends State<_ServiceSearchDialog> {
  String? _selectedService;
  String? _selectedSubcategory;
  String? _selectedDistrict;
  double _minRating = 1.0;
  double _maxRating = 5.0;
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  bool _noResultsFound = false;

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
    ],
  };

  final List<String> _districts = [
    'Tondo',
    'Binondo',
    'Quiapo',
    'San Nicolas',
    'Santa Cruz',
    'Sampaloc',
    'San Miguel',
    'Santa Mesa',
    'Ermita',
    'Intramuros',
    'Malate',
    'Paco',
    'Pandacan',
    'Port Area',
    'San Andres'
  ];

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  // Function to fetch and filter services from Firestore, including new filters
  Future<void> _searchServices() async {
    final Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection('Services');
    Query<Map<String, dynamic>> baseQuery = query;

    if (_selectedService != null) {
      baseQuery = baseQuery.where('service', isEqualTo: _selectedService);
    }

    if (_selectedSubcategory != null) {
      baseQuery =
          baseQuery.where('subcategory', isEqualTo: _selectedSubcategory);
    }

    if (_selectedDistrict != null) {
      baseQuery = baseQuery.where('district', isEqualTo: _selectedDistrict);
    }

    if (_minPriceController.text.isNotEmpty) {
      int? minPrice = int.tryParse(_minPriceController.text);
      if (minPrice != null) {
        baseQuery = baseQuery.where('price', isGreaterThanOrEqualTo: minPrice);
      }
    }

    if (_maxPriceController.text.isNotEmpty) {
      int? maxPrice = int.tryParse(_maxPriceController.text);
      if (maxPrice != null) {
        baseQuery = baseQuery.where('price', isLessThanOrEqualTo: maxPrice);
      }
    }

    // Apply averageRating and totalReviews filters, including workers with no ratings or reviews (default to 0)
    baseQuery = baseQuery
        .orderBy('averageRating', descending: true)
        .orderBy('totalReviews', descending: true);

    // Filtering for workers with ratings and workers without ratings (null or 0).
    // If min/max rating is not default (1.0 and 5.0), apply the range filter.
    if (_minRating > 1.0 || _maxRating < 5.0) {
      baseQuery = baseQuery
          .where('averageRating', isGreaterThanOrEqualTo: _minRating)
          .where('averageRating', isLessThanOrEqualTo: _maxRating);
    }

    final QuerySnapshot<Map<String, dynamic>> snapshot = await baseQuery.get();
    final List<Map<String, dynamic>> services =
        snapshot.docs.map((doc) => doc.data()).toList();

    if (services.isEmpty) {
      setState(() {
        _noResultsFound = true;
      });
    } else {
      setState(() {
        _noResultsFound = false;
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomerHomePage(services: services),
        ),
      );
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
              // Header with Reset button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Search for a Service',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black), // Larger text
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        // Reset all selections to default
                        _selectedService = null;
                        _selectedSubcategory = null;
                        _selectedDistrict = null;
                        _minRating = 1.0;
                        _maxRating = 5.0;
                        _minPriceController.clear();
                        _maxPriceController.clear();
                      });
                    },
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Service Dropdown
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Service:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: SizedBox(
                      height: 48, // Set consistent height for dropdowns
                      child: DropdownButtonFormField<String>(
                        value: _selectedService,
                        hint: const Text('Choose a service'),
                        items: _services.keys.map((String service) {
                          return DropdownMenuItem<String>(
                            value: service,
                            child: Center(
                              child: Text(service,
                                  style: const TextStyle(color: Colors.black)),
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
                            borderSide:
                                const BorderSide(color: Colors.blueAccent),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.blueAccent, width: 3),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        dropdownColor: Colors.grey[200],
                        style:
                            const TextStyle(fontSize: 18, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),

              // Subcategory Dropdown
              if (_selectedService != null) ...[
                const SizedBox(height: 15),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Subcategory:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: SizedBox(
                        height: 48,
                        child: DropdownButtonFormField<String>(
                          value: _selectedSubcategory,
                          hint: const Text('Choose a subcategory'),
                          items: _services[_selectedService]!
                              .map((String subcategory) {
                            return DropdownMenuItem<String>(
                              value: subcategory,
                              child: Center(
                                child: Text(subcategory,
                                    style:
                                        const TextStyle(color: Colors.black)),
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
                              borderSide:
                                  const BorderSide(color: Colors.blueAccent),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.blueAccent, width: 3),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          dropdownColor: Colors.grey[200],
                          style: const TextStyle(
                              fontSize: 18, color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // District Dropdown with Divider after
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Location:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: SizedBox(
                      height: 48,
                      child: DropdownButtonFormField<String>(
                        value: _selectedDistrict,
                        hint: const Text('Choose a district'),
                        items: _districts.map((String district) {
                          return DropdownMenuItem<String>(
                            value: district,
                            child: Center(
                              child: Text(district,
                                  style: const TextStyle(color: Colors.black)),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDistrict = value;
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4.0),
                            borderSide:
                                const BorderSide(color: Colors.blueAccent),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.blueAccent, width: 3),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        dropdownColor: Colors.grey[200],
                        style:
                            const TextStyle(fontSize: 18, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(),

              // Rating Slider Section
              const SizedBox(height: 20),
              const Text(
                'Ratings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              RangeSlider(
                values: RangeValues(_minRating, _maxRating),
                min: 1.0,
                max: 5.0,
                divisions: 8,
                labels: RangeLabels(
                  _minRating.toStringAsFixed(1),
                  _maxRating.toStringAsFixed(1),
                ),
                activeColor: Colors.blueAccent,
                onChanged: (RangeValues values) {
                  setState(() {
                    _minRating = values.start;
                    _maxRating = values.end;
                  });
                },
              ),

              // Price Section
              const SizedBox(height: 20),
              const Text(
                'Price',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _minPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Set Minimum Spend',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent, width: 3),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent, width: 3),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _maxPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Set Maximum Spend',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent, width: 3),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent, width: 3),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // No Results Found Text
              if (_noResultsFound)
                const Center(
                  child: Text(
                    'No results found',
                    style: TextStyle(
                        color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ),

              const SizedBox(height: 15),

              // Search Button that fits full width of modal
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _searchServices,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 120),
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Search'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


