import 'package:chuyende/auth/auth_page.dart';
import 'package:chuyende/screens/home_screen.dart';
import 'package:chuyende/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().user,
      builder: (context, snapshot) {
        // User is logged in
        if (snapshot.hasData) {
          return const HomeScreen(); // This is the line causing the error
        }
        // User is not logged in
        else {
          return const AuthPage();
        }
      },
    );
  }
}
