import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:test_2/CustomerPages/home_page.dart';
import 'package:test_2/WorkerPages/workerhome_page.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback showLoginPage;
  const RegisterPage({super.key, required this.showLoginPage});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Text controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmpasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthdateController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedDistrict;

  int _selectedUserType = 1; // 1 for Customer, 2 for Worker
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmpasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthdateController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blueAccent, // Calendar primary color
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _birthdateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future signUp() async {
    setState(() {
      _errorMessage = null;
    });

    if (_validateInput()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        addUserDetails(
          _firstNameController.text.trim(),
          _lastNameController.text.trim(),
          _emailController.text.trim(),
          _birthdateController.text.trim(),
          _selectedDistrict ?? '',
          '+63${_phoneController.text.trim()}',
          _selectedUserType,
        );

        if (_selectedUserType == 1) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const HomePage()));
        } else {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const WorkerHomePage()));
        }

        _showSuccessDialog();
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to register: $e';
        });
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future addUserDetails(String firstName, String lastName, String email,
      String birthdate, String district, String phone, int userType) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final collection = userType == 1 ? 'Customers' : 'Workers';
    await FirebaseFirestore.instance.collection(collection).doc(uid).set({
      'first name': firstName,
      'last name': lastName,
      'email': email,
      'birthdate': birthdate,
      'district': district,
      'phone': phone,
      'userType': userType,
    });
  }

  bool _validateInput() {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmpasswordController.text.isEmpty ||
        _firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _birthdateController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _selectedDistrict == null) {
      setState(() {
        _errorMessage = 'Please fill in all fields.';
      });
      return false;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailController.text)) {
      setState(() {
        _errorMessage = 'Please enter a valid email.';
      });
      return false;
    }

    if (_passwordController.text != _confirmpasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
      });
      return false;
    }

    if (_passwordController.text.length < 6) {
      setState(() {
        _errorMessage = 'Password should be at least 6 characters long.';
      });
      return false;
    }

    if (_phoneController.text.length != 10) {
      setState(() {
        _errorMessage = 'Please enter a valid 10-digit phone number.';
      });
      return false;
    }

    return true;
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Registration Successful'),
          content: const Text('Your account has been created successfully!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _selectedUserType == 2 ? Colors.black : Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Create An Account',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 52,
                    color: _selectedUserType == 2 ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'First, tell us whether you are a',
                  style: TextStyle(
                    fontSize: 20,
                    color:
                        _selectedUserType == 2 ? Colors.white70 : Colors.black,
                  ),
                ),
                const SizedBox(height: 20),

                // User Type Segmented Control
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: CupertinoSegmentedControl<int>(
                    children: const {
                      1: Padding(
                          padding: EdgeInsets.all(10),
                          child: Text('Customer')),
                      2: Padding(
                          padding: EdgeInsets.all(10),
                          child: Text('Worker')),
                    },
                    onValueChanged: (value) {
                      setState(() {
                        _selectedUserType = value;
                      });
                    },
                    groupValue: _selectedUserType,
                    unselectedColor: _selectedUserType == 2
                        ? Colors.grey[700]
                        : Colors.white,
                    selectedColor: _selectedUserType == 2
                        ? Colors.blueAccent
                        : Colors.blueAccent,
                    borderColor: _selectedUserType == 2
                        ? Colors.blueAccent
                        : Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 20),

                // Error message (if any)
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),

                // Email TextField
                _buildTextField(_emailController, 'Email', Icons.email),
                // Password TextField
                _buildTextField(_passwordController, 'Password', Icons.lock,
                    obscureText: true),
                // Confirm Password TextField
                _buildTextField(
                    _confirmpasswordController, 'Confirm Password', Icons.lock,
                    obscureText: true),
                // First Name TextField
                _buildTextField(
                    _firstNameController, 'First Name', Icons.person),
                // Last Name TextField
                _buildTextField(
                    _lastNameController, 'Last Name', Icons.person_outline),

                // Birthdate TextField with DatePicker
                _buildDateField(),

                // Phone Number TextField
                _buildPhoneNumberField(),

                // District Dropdown
                _buildDistrictDropdown(),

                const SizedBox(height: 20),

                // Sign Up Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: GestureDetector(
                    onTap: _isLoading ? null : signUp,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _isLoading ? Colors.grey : Colors.blueAccent,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          if (!_isLoading)
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // Already a member? Login now
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'I am a member!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _selectedUserType == 2
                            ? Colors.white70
                            : Colors.black,
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.showLoginPage,
                      child: Text(
                        ' Login now',
                        style: TextStyle(
                          color: _selectedUserType == 2
                              ? Colors.blueAccent
                              : Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String hintText, IconData icon,
      {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: _selectedUserType == 2
                ? Colors.white70
                : Colors.black54, // White hintText for dark mode
          ),
          prefixIcon: Icon(
            icon,
            color: _selectedUserType == 2 ? Colors.white : Colors.black,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white, width: 2.0),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0),
            borderRadius: BorderRadius.circular(12),
          ),
          fillColor:
              _selectedUserType == 2 ? Colors.grey[850] : Colors.grey[200],
          filled: true,
        ),
        style: TextStyle(
            color: _selectedUserType == 2 ? Colors.white : Colors.black),
      ),
    );
  }

  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
      child: TextField(
        controller: _birthdateController,
        readOnly: true,
        onTap: () => _selectDate(context),
        decoration: InputDecoration(
          hintText: 'Birthdate',
          hintStyle: TextStyle(
            color: _selectedUserType == 2
                ? Colors.white70
                : Colors.black54, // White hintText for dark mode
          ),
          prefixIcon: Icon(
            Icons.calendar_today,
            color: _selectedUserType == 2 ? Colors.white : Colors.black,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white, width: 2.0),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0),
            borderRadius: BorderRadius.circular(12),
          ),
          fillColor:
              _selectedUserType == 2 ? Colors.grey[850] : Colors.grey[200],
          filled: true,
        ),
        style: TextStyle(
            color: _selectedUserType == 2 ? Colors.white : Colors.black),
      ),
    );
  }

  Widget _buildPhoneNumberField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueAccent, width: 2.0),
              borderRadius: BorderRadius.circular(12),
              color:
                  _selectedUserType == 2 ? Colors.grey[850] : Colors.grey[200],
            ),
            child: Text(
              '+63',
              style: TextStyle(
                  color: _selectedUserType == 2 ? Colors.white : Colors.black),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: InputDecoration(
                hintText: 'Phone Number',
                hintStyle: TextStyle(
                  color: _selectedUserType == 2
                      ? Colors.white70
                      : Colors.black54, // White hintText for dark mode
                ),
                counterText: '',
                prefixIcon: Icon(
                  Icons.phone,
                  color: _selectedUserType == 2 ? Colors.white : Colors.black,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white, width: 2.0),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      const BorderSide(color: Colors.blueAccent, width: 2.0),
                  borderRadius: BorderRadius.circular(12),
                ),
                fillColor: _selectedUserType == 2
                    ? Colors.grey[850]
                    : Colors.grey[200],
                filled: true,
              ),
              style: TextStyle(
                  color: _selectedUserType == 2 ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistrictDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          hintText: 'Select District',
          hintStyle: TextStyle(
            color: _selectedUserType == 2
                ? Colors.white70
                : Colors.black54, // White hintText for dark mode
          ),
          prefixIcon: Icon(
            Icons.location_on,
            color: _selectedUserType == 2 ? Colors.white : Colors.black,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white, width: 2.0),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0),
            borderRadius: BorderRadius.circular(12),
          ),
          fillColor:
              _selectedUserType == 2 ? Colors.grey[850] : Colors.grey[200],
          filled: true,
        ),
        value: _selectedDistrict,
        items: [
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
        ].map((district) {
          return DropdownMenuItem<String>(
            value: district,
            child: Text(district),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedDistrict = value;
          });
        },
        style: TextStyle(
            color: _selectedUserType == 2 ? Colors.white : Colors.black),
        dropdownColor: _selectedUserType == 2 ? Colors.grey[800] : Colors.white,
      ),
    );
  }
}
