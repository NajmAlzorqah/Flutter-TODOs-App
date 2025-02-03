// Main entry point for the app
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:DOIT/database/database_helper.dart';
import 'package:DOIT/screens/login_screen.dart';
import 'package:DOIT/screens/HomeScreen.dart';
import 'package:DOIT/theme/theme_provider.dart'; // Import the ThemeProvider

void main() => runApp(
  ChangeNotifierProvider(
    create: (_) => ThemeProvider(),
    child: MyApp(),
  ),
);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'To-Do App',
      theme: ThemeData.light().copyWith(
        primaryColor: Colors.blue, // Use primaryColor for a single color
        colorScheme: ColorScheme.light(
          primary: Colors.blue, // Primary color
          secondary: Colors.purple, // Accent color
        ),
        scaffoldBackgroundColor: Colors.grey[100], // Light background
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue, // Use primaryColor for a single color
        colorScheme: ColorScheme.dark(
          primary: Colors.blue, // Primary color
          secondary: Colors.purple, // Accent color
        ),
        scaffoldBackgroundColor: Colors.grey[900], // Dark background
      ),
      themeMode: themeProvider.themeMode, // Use the selected theme mode
      home: AuthChecker(),
    );
  }
}

class AuthChecker extends StatefulWidget {
  @override
  _AuthCheckerState createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  bool _isLoggedIn = false;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // Check login status from SharedPreferences
  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      // Retrieve user details from SharedPreferences
      String? username = prefs.getString('username');
      String? email = prefs.getString('email');
      setState(() {
        _isLoggedIn = true;
        _user = {'username': username, 'email': email};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If logged in and user details are available, go to HomeScreen; otherwise, show LoginScreen
    if (_isLoggedIn && _user != null) {
      return HomeScreen(user: _user!);
    } else {
      return LoginScreen();
    }
  }
}