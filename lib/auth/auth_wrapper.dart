import 'package:chuyende/auth/auth_page.dart';
import 'package:chuyende/screens/home_screen.dart';
import 'package:chuyende/screens/setup_profile_screen.dart';
import 'package:chuyende/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;

    if (user == null) {
      return const AuthPage();
    } else {
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, profileSnapshot) {
          if (profileSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (!profileSnapshot.hasData || !profileSnapshot.data!.exists) {
            return const SetupProfileScreen();
          }

          final data = profileSnapshot.data!.data() as Map<String, dynamic>?;
          final bool profileCompleted = data?['profileCompleted'] ?? false;

          if (profileCompleted) {
            return const HomeScreen();
          } else {
            return const SetupProfileScreen();
          }
        },
      );
    }
  }
}
