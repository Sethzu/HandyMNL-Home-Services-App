import 'package:flutter/material.dart';
import 'package:test_2/userAuthentication/userLoginRegisterPages/login_page.dart';
import 'package:test_2/userAuthentication/userLoginRegisterPages/register_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool showLoginPage = true;

  // Toggle between login and register screens
  void toggleScreens() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return showLoginPage
        ? LoginPage(showRegisterPage: toggleScreens)
        : RegisterPage(showLoginPage: toggleScreens);
  }
}


//Kapag nag open yung app tinitrigger netong module na ito yung Login Page since yun dapat yung unang module na makikita ni customer
//Tinitrigger din netong module na ito yung Login page tsaka Register Page