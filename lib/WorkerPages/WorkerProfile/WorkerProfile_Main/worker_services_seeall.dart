import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WorkerServicesSeeAll extends StatefulWidget {
  const WorkerServicesSeeAll({super.key});

  @override
  _WorkerServicesSeeAllState createState() => _WorkerServicesSeeAllState();
}

class _WorkerServicesSeeAllState extends State<WorkerServicesSeeAll> {
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> plumbingServices = [];
  List<Map<String, dynamic>> electricalServices = [];

  @override
  void initState() {
    super.initState();
    fetchAllServices();
  }

  // Fetch all worker's services from Firestore
  Future<void> fetchAllServices() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final servicesSnapshot = await FirebaseFirestore.instance
            .collection('Services')
            .where('workerId', isEqualTo: currentUser.uid)
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
        });
      }
    } catch (e) {
      print('Error fetching worker services: $e');
    }
  }

  // Edit and delete functionality
  Future<void> updateServicePrice(String serviceId, String newPrice) async {
    try {
      await FirebaseFirestore.instance
          .collection('Services')
          .doc(serviceId)
          .update({'price': int.tryParse(newPrice) ?? 0});
      fetchAllServices(); // Refresh the services after update
    } catch (e) {
      print('Error updating price: $e');
    }
  }

  Future<void> deleteService(String serviceId) async {
    try {
      await FirebaseFirestore.instance
          .collection('Services')
          .doc(serviceId)
          .delete();
      fetchAllServices(); // Refresh the services after deletion
    } catch (e) {
      print('Error deleting service: $e');
    }
  }

  // Show the edit confirmation dialog
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

  // Show delete confirmation dialog
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

  // Widget to display services by category
  Widget buildServiceList(
      String title, List<Map<String, dynamic>> servicesList) {
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
            final TextEditingController priceController =
                TextEditingController(text: service['price']);

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
        iconTheme:
            const IconThemeData(color: Colors.white), // Set icon color to white
        titleTextStyle: const TextStyle(
            color: Colors.white, fontSize: 20), // Set title color to white
      ),
      body: services.isNotEmpty
          ? SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display Plumbing services
                    if (plumbingServices.isNotEmpty)
                      buildServiceList('Plumbing', plumbingServices),

                    // Display Electrical services
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
