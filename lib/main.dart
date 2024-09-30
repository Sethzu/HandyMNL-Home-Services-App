import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';  // Import Firebase core for initializing Firebase
import 'package:test_2/userAuthentication/main_page.dart';  // Import your custom MainPage which handles authentication logic
import 'package:logging/logging.dart';  // Import the logging package

// Main entry point of the app
void main() async {
  // Ensure that widget binding is initialized before interacting with Flutter engine
  WidgetsFlutterBinding.ensureInitialized();

  // Setup logging
  _setupLogging();

  // Initialize Firebase and handle potential errors during the process
  try {
    await Firebase.initializeApp();  // Initialize Firebase services
    runApp(const MyApp());  // Run the main Flutter app
  } catch (e) {
    Logger('FirebaseInit').severe('Error during Firebase initialization', e);  // Log the error with proper severity
  }
}

// Setup the logging system for the app
void _setupLogging() {
  Logger.root.level = Level.ALL;  // Set logging level to ALL (can be changed for production)
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });
}

// MyApp class defines the overall structure of the Flutter app
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Return a MaterialApp widget with no debug banner and the MainPage as the home screen
    return const MaterialApp(
      debugShowCheckedModeBanner: false,  // Disable the debug banner in the app
      home: MainPage(),  // Set MainPage as the home page of the app
    );
  }
}
