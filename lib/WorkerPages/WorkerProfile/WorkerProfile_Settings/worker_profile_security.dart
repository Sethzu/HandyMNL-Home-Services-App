import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase authentication
import 'package:google_fonts/google_fonts.dart';

class WorkerProfileSecurity extends StatefulWidget {
  const WorkerProfileSecurity({super.key});

  @override
  _WorkerProfileSecurityState createState() =>
      _WorkerProfileSecurityState();
}

class _WorkerProfileSecurityState extends State<WorkerProfileSecurity> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  bool _isCurrentPasswordValid = true;
  bool _isNewPasswordValid = true;
  bool _isConfirmPasswordValid = true;
  bool _showErrorMessage = false; // To check if all fields are filled

  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _changePassword() async {
    final User? user = _auth.currentUser;

    if (user != null) {
      final String currentPassword = _currentPasswordController.text.trim();
      final String newPassword = _newPasswordController.text.trim();
      final String confirmPassword = _confirmPasswordController.text.trim();

      setState(() {
        _currentPasswordError = null;
        _newPasswordError = null;
        _confirmPasswordError = null;
        _isCurrentPasswordValid = true;
        _isNewPasswordValid = true;
        _isConfirmPasswordValid = true;
        _showErrorMessage = false; // Reset error message flag
      });

      // Check if any of the fields are empty
      if (currentPassword.isEmpty ||
          newPassword.isEmpty ||
          confirmPassword.isEmpty) {
        setState(() {
          _showErrorMessage = true; // Set error message flag
        });
        return;
      }

      // Validate new password length
      if (newPassword.length < 6) {
        setState(() {
          _isNewPasswordValid = false;
          _newPasswordError = 'Password should be 6 characters long.';
        });
        return;
      }

      // Validate new password and confirm password match
      if (newPassword != confirmPassword) {
        setState(() {
          _isConfirmPasswordValid = false;
          _confirmPasswordError = 'Passwords do not match.';
        });
        return;
      }

      // Reauthenticate user with current password
      try {
        final AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );

        await user.reauthenticateWithCredential(credential);

        // Change password
        await user.updatePassword(newPassword);

        // Show success message and clear text fields
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Password Changed'),
              content: const Text('Password successfully changed!'),
              actions: [
                TextButton(
                  child: const Text('OK',
                      style: TextStyle(color: Colors.blueAccent)),
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Clear the text fields
                    _currentPasswordController.clear();
                    _newPasswordController.clear();
                    _confirmPasswordController.clear();
                  },
                ),
              ],
            );
          },
        );
      } catch (e) {
        setState(() {
          _isCurrentPasswordValid = false;
          _currentPasswordError = 'Incorrect current password.';
        });
      }
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Security',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 21,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      resizeToAvoidBottomInset: true, // Adjust when keyboard pops up

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Adjust padding to move content up
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10), // Reduced space between appbar and title
              Text(
                'CHANGE PASSWORD',
                style: GoogleFonts.bebasNeue(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20), // Reduced space here

              // Error message for empty fields
              if (_showErrorMessage)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Please fill in all fields.',
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),

              // Current Password
              Text(
                'Current Password',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: _currentPasswordController,
                hintText: 'Current Password',
                isPasswordVisible: _showCurrentPassword,
                onVisibilityToggle: () {
                  setState(() {
                    _showCurrentPassword = !_showCurrentPassword;
                  });
                },
                isValid: _isCurrentPasswordValid,
              ),
              if (_currentPasswordError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _currentPasswordError!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              const SizedBox(height: 20),

              // New Password
              Text(
                'Enter New Password',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: _newPasswordController,
                hintText: 'Enter New Password',
                isPasswordVisible: _showNewPassword,
                onVisibilityToggle: () {
                  setState(() {
                    _showNewPassword = !_showNewPassword;
                  });
                },
                isValid: _isNewPasswordValid,
              ),
              if (_newPasswordError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _newPasswordError!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              const SizedBox(height: 20),

              // Confirm Password
              Text(
                'Confirm Password',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: _confirmPasswordController,
                hintText: 'Confirm Password',
                isPasswordVisible: _showConfirmPassword,
                onVisibilityToggle: () {
                  setState(() {
                    _showConfirmPassword = !_showConfirmPassword;
                  });
                },
                isValid: _isConfirmPasswordValid,
              ),
              if (_confirmPasswordError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _confirmPasswordError!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),

              const SizedBox(height: 25),

              // Center the Change Password Button vertically
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 120), // Adjusted button height
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text(
                      'Change Password',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for password fields
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool isPasswordVisible,
    required VoidCallback onVisibilityToggle,
    required bool isValid,
  }) {
    return TextField(
      controller: controller,
      obscureText: !isPasswordVisible,
      decoration: InputDecoration(
        hintText: hintText,
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red, width: 3.0),
          borderRadius: BorderRadius.circular(12), // Consistent border radius
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: isValid ? Colors.grey : Colors.red, // Red border if error
            width: 1.0, // Adjusted thickness to 1 when not focused
          ),
          borderRadius: BorderRadius.circular(12), // Consistent border radius
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blueAccent, width: 3.0),
          borderRadius: BorderRadius.circular(12),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: Colors.grey,
          ),
          onPressed: onVisibilityToggle,
        ),
        filled: true,
        fillColor: Colors.white, // White background inside text field
      ),
    );
  }
}
