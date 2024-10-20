import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import for Roboto font

class WorkerProfileEditprofile extends StatelessWidget {
  const WorkerProfileEditprofile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Profile',
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
          icon: const Icon(
              Icons.arrow_back_ios_new), // Change to arrow_back_ios_new
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: const Center(
        child: Text('Edit Profile'),
      ),
    );
  }
}
