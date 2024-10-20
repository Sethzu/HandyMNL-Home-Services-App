import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import for Roboto font

class WorkerProfileSearch extends StatelessWidget {
  const WorkerProfileSearch({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search',
          style: GoogleFonts.roboto(
            // Apply Roboto font
            color: Colors.white,
            fontSize: 21,
          ),
        ),
        centerTitle: true, // Center the title
        backgroundColor: Colors.blueAccent, // Set AppBar background color
        iconTheme: const IconThemeData(
          color: Colors.white, // Set back button color to white
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new), // Back button
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: const Center(
        child: Text('Search Page'),
      ),
    );
  }
}
