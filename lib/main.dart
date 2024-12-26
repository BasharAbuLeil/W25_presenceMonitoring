import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import firebase_core
import 'firebase_options.dart'; // Import the generated options
import 'login_page.dart';
import 'id_login_page.dart';
import 'session_data.dart';
import 'homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false, // Added this line to remove the debug banner
      initialRoute: '/', // Start with the login page
      routes: {
        '/': (context) => const LoginPage(),
        '/id_login': (context) => const IDLoginPage(),
        // '/profile': (context) => const ProfilePage(userID: '',), // No need for a direct route with a static userID
        '/home': (context) => const MyHomePage(title: 'Flutter Demo Home Page'),
      },
    );
  }
}