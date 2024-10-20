import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:test_2/Widgets/handyman_loading_indicator.dart'; // Importing the custom loading indicator

class CustomerChecksWorkerProfileServicesSeeAll extends StatefulWidget {
  final String workerId;

  const CustomerChecksWorkerProfileServicesSeeAll({super.key, required this.workerId});

  @override
  _CustomerChecksWorkerProfileServicesSeeAllState createState() =>
      _CustomerChecksWorkerProfileServicesSeeAllState();
}

class _CustomerChecksWorkerProfileServicesSeeAllState
    extends State<CustomerChecksWorkerProfileServicesSeeAll> {
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> plumbingServices = [];
  List<Map<String, dynamic>> electricalServices = [];
  bool isLoading = true; // Add loading state

  @override
  void initState() {
    super.initState();
    fetchAllServices();
  }

  // Fetch all worker's services from Firestore
  Future<void> fetchAllServices() async {
    try {
      final servicesSnapshot = await FirebaseFirestore.instance
          .collection('Services')
          .where('workerId', isEqualTo: widget.workerId)
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

        // Sort services based on the 'service' field (Plumbing or Electrical)
        plumbingServices = services
            .where((service) => service['service'] == 'Plumbing')
            .toList();
        electricalServices = services
            .where((service) => service['service'] == 'Electrical')
            .toList();
        isLoading = false; // Stop loading when data is fetched
      });
    } catch (e) {
      print('Error fetching worker services: $e');
      setState(() {
        isLoading = false; // Stop loading in case of an error
      });
    }
  }

  // Widget to display services by category
  Widget buildServiceList(String title, List<Map<String, dynamic>> servicesList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: servicesList.length,
          itemBuilder: (context, index) {
            final service = servicesList[index];

            return Card(
              margin:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: ListTile(
                title: Text(
                  '${service['service']} - ${service['subcategory']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: Text(
                    '₱${service['price']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('All Services'),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      body: isLoading // Check if still loading
          ? const Center(
              child: HandymanLoadingIndicator(), // Show custom loading indicator
            )
          : services.isNotEmpty
              ? SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (plumbingServices.isNotEmpty)
                          buildServiceList('Plumbing', plumbingServices),
                        if (electricalServices.isNotEmpty)
                          buildServiceList('Electrical', electricalServices),
                      ],
                    ),
                  ),
                )
              : const Center(
                  child: Text(
                    'No services available',
                    style: TextStyle(color: Colors.blueAccent, fontSize: 18),
                  ),
                ),
    );
  }
}
