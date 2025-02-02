// Main entry point for the app
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:PF/database/database_helper.dart';
import 'package:PF/screens/login_screen.dart';
import 'package:PF/screens/HomeScreen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: AuthChecker(), // Initial screen to check authentication status
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
