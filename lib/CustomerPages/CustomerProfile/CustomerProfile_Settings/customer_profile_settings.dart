import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // For Firebase Storage
import 'package:test_2/CustomerPages/CustomerProfile/CustomerProfile_Settings/customer_profile_notification.dart';
import 'package:test_2/CustomerPages/CustomerProfile/CustomerProfile_Settings/customer_profile_privacypolicy.dart';
import 'package:test_2/CustomerPages/CustomerProfile/CustomerProfile_Settings/customer_profile_security.dart';
import 'package:test_2/CustomerPages/CustomerProfile/CustomerProfile_Settings/customer_profile_terms.dart';
import 'package:test_2/userAuthentication/auth_page.dart'; // Import AuthPage for sign out
import 'package:image_picker/image_picker.dart'; // For the image picker functionality
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';


// Import your Edit Profile page
import 'customer_profile_editprofile.dart';

class CustomerProfileSettings extends StatefulWidget {
  const CustomerProfileSettings({super.key});

  @override
  _CustomerProfileSettingsState createState() =>
      _CustomerProfileSettingsState();
}

class _CustomerProfileSettingsState extends State<CustomerProfileSettings> {
  bool isLoading = false; // Loading state for sign-out process
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Firestore instance
  final FirebaseStorage _storage =
      FirebaseStorage.instance; // Firebase Storage instance
  File? _imageFile;
  String? firstName;
  String? lastName;
  String? email;
  String? profileImageUrl; // URL of the profile image from Firestore

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch user data on initialization
  }

 // Method for picking an image (camera or gallery)
Future<void> _sendImage() async {
  showCupertinoModalPopup(
    context: context,
    builder: (BuildContext context) {
      return CupertinoActionSheet(
        actions: <Widget>[
          // Camera option
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(context).pop(); // Close action sheet
              await _pickImage(ImageSource.camera); // Take a photo with camera
            },
            child: const Text(
              'Take a photo',
              style: TextStyle(
                fontSize: 18,
                color: Colors.blueAccent,
              ),
            ),
          ),
          // Gallery option
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(context).pop(); // Close action sheet
              await _pickImage(ImageSource.gallery); // Choose image from gallery
            },
            child: const Text(
              'Choose from library',
              style: TextStyle(
                fontSize: 18,
                color: Colors.blueAccent,
              ),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.of(context).pop(); // Close the action sheet
          },
          isDefaultAction: true,
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
        ),
      );
    },
  );
}

// Method for picking an image from the source selected (camera or gallery)
Future<void> _pickImage(ImageSource source) async {
  final ImagePicker picker = ImagePicker();
  final XFile? pickedFile = await picker.pickImage(source: source);
  if (pickedFile != null) {
    setState(() {
      _imageFile = File(pickedFile.path);
    });

    // Upload the image to Firebase Storage and update Firestore
    await _uploadImageToFirebase();
  }
}


  // Upload image to Firebase Storage and save the download URL in Firestore
  Future<void> _uploadImageToFirebase() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null && _imageFile != null) {
        // Define the file path in Firebase Storage
        final String filePath = 'profile_images/${user.uid}.png';

        // Upload the image file
        final UploadTask uploadTask =
            _storage.ref(filePath).putFile(_imageFile!);

        // Wait for the upload to complete and get the download URL
        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        // Update Firestore with the new profile image URL
        await _firestore.collection('Customers').doc(user.uid).update({
          'profileImageUrl': downloadUrl,
        });

        // Update the state with the new image URL
        setState(() {
          profileImageUrl = downloadUrl;
          _imageFile = null; // Reset the image file after upload
        });

        print('Profile image uploaded successfully: $downloadUrl');
      }
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  // Fetch user data (first name, last name, email, and profile image URL) from Firestore
  Future<void> _fetchUserData() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final DocumentSnapshot userData =
          await _firestore.collection('Customers').doc(user.uid).get();

      if (userData.exists) {
        final data =
            userData.data() as Map<String, dynamic>?; // Cast the data to a Map

        if (data != null) {
          setState(() {
            firstName = data['first name'];
            lastName = data['last name'];
            email = data['email'];

            // Safely fetch 'profileImageUrl' field, and check if it exists
            profileImageUrl = data.containsKey('profileImageUrl')
                ? data['profileImageUrl']
                : null;
          });
        } else {
          print("User data is null");
        }
      } else {
        print("User data not found in Firestore");
      }
    } else {
      print("No authenticated user found");
    }
  }

  // Function to handle sign-out
  Future<void> _signOut() async {
    setState(() {
      isLoading = true; // Start loading during sign-out
    });

    await _auth.signOut(); // Sign out user

    if (mounted) {
      setState(() {
        isLoading = false; // Stop loading after sign-out
      });

      // Navigate back to the AuthPage after successful sign out
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 21,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white), // Updated back button
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: isLoading // Show loading indicator while signing out
          ? const Center(
              child: CircularProgressIndicator(), // Loading spinner
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: profileImageUrl != null
                              ? CachedNetworkImageProvider(
                                  profileImageUrl!) // Use CachedNetworkImage for profile image
                              : const AssetImage('lib/assets/placeholder.png')
                                  as ImageProvider, // Temporary placeholder
                        ),
                     
Positioned(
  bottom: 0,
  right: 0,
  child: GestureDetector(
    onTap: () {
      _sendImage();  // Show the CupertinoActionSheet for choice
    },
    child: const CircleAvatar(
      radius: 18,
      backgroundColor: Colors.blueAccent,
      child: Icon(Icons.edit, color: Colors.white),
    ),
  ),
),


                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    firstName != null && lastName != null
                        ? '$firstName $lastName'
                        : 'Loading...',
                    style: GoogleFonts.roboto(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    email ?? 'Loading...',
                    style: GoogleFonts.roboto(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(
                    width: 360, // Adjust the width as needed
                    child: Divider(
                      height: 40,
                      thickness: 2,
                    ),
                  ),
                  // Options with Edit Profile navigation:
                  _buildSettingsOption(
                    context,
                    'Edit Profile',
                    Icons.person_outline,
                    navigateTo: const CustomerProfileEditprofile(),
                  ),
                  _buildSettingsOption(
                    context,
                    'Notification',
                    Icons.notifications_none_outlined,
                    navigateTo: const CustomerProfileNotification(),
                  ),
                  _buildSettingsOption(
                    context,
                    'Security',
                    Icons.lock_outline,
                    navigateTo: const CustomerProfileSecurity(),
                  ),
                  _buildSettingsOption(
                    context,
                    'Privacy Policy',
                    Icons.privacy_tip_outlined,
                    navigateTo: const CustomerProfilePrivacypolicy(),
                  ),
                  _buildSettingsOption(
                    context,
                    'Terms and Conditions',
                    Icons.info_outline_rounded,
                    navigateTo: const CustomerProfileTerms(),
                  ),
                  _buildLogoutOption(context),
                ],
              ),
            ),
    );
  }

  // Helper method for building settings options with optional navigation
  Widget _buildSettingsOption(
    BuildContext context,
    String title,
    IconData icon, {
    Widget? navigateTo, // Optional parameter for navigation
  }) {
    return GestureDetector(
      onTap: () {
        if (navigateTo != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => navigateTo),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.black),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: GoogleFonts.roboto(fontSize: 18),
                ),
              ],
            ),
            const Icon(
              Icons.arrow_forward_ios_outlined,
              color: Colors.black,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for logout option
  Widget _buildLogoutOption(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLogoutDialog(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.logout, color: Colors.red),
                const SizedBox(width: 16),
                Text(
                  'Logout',
                  style: GoogleFonts.roboto(fontSize: 18, color: Colors.red),
                ),
              ],
            ),
            const Icon(
              Icons.arrow_forward_ios_outlined,
              color: Colors.black, // Set color to black
              size: 20, // Set size to 20
            ),
          ],
        ),
      ),
    );
  }

  // Logout confirmation dialog method
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log out'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.blueGrey)),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Log out',
                  style: TextStyle(color: Colors.blueAccent)),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _signOut(); // Call sign-out function
              },
            ),
          ],
        );
      },
    );
  }
}
