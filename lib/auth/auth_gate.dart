import 'package:chuyende/screens/login_screen.dart';
import 'package:chuyende/screens/register_screen.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showRegisterScreen = false;

  void _toggleScreens() {
    setState(() {
      _showRegisterScreen = !_showRegisterScreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showRegisterScreen) {
      return RegisterScreen(showLoginScreen: _toggleScreens);
    } else {
      return LoginScreen(showRegisterScreen: _toggleScreens);
    }
  }
}
