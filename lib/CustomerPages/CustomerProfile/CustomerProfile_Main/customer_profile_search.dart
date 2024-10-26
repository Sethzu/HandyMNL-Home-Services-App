import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import for Roboto font

class CustomerProfileSearch extends StatefulWidget {
  const CustomerProfileSearch({super.key});

  @override
  _CustomerProfileSearchState createState() => _CustomerProfileSearchState();
}

class _CustomerProfileSearchState extends State<CustomerProfileSearch> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus on the search bar when the page is navigated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent, // Blue accent background
        elevation: 1, // Slight elevation for shadow effect
        iconTheme: const IconThemeData(
          color: Colors.white, // Set back button color to white
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new), // Back button
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Container(
          height: 35, // Facebook-style height
          width: double.infinity, // Make search bar wider
          padding: const EdgeInsets.symmetric(horizontal: 18), // Add padding
          decoration: BoxDecoration(
            color: Colors.white, // Light gray background
            borderRadius: BorderRadius.circular(30), // Rounded corners
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode, // Auto-focus on the search bar
            textAlign: TextAlign.left, // Center the text
            decoration: InputDecoration(
              hintText: 'Search Handymnl', // Custom hint text
              hintStyle: GoogleFonts.roboto(
                color: Colors.grey, // Light gray text color for hint
                fontSize: 16,
              ),
              border: InputBorder.none, // Remove underline
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 9), // Vertically center text
            ),
            style: GoogleFonts.roboto(
              color: Colors.black, // Black text for user input
              fontSize: 16,
            ),
            cursorColor: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('Search Page Content'),
      ),
    );
  }
}
