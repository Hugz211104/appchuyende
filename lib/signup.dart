// signup.dart
import 'package:flutter/material.dart';
import 'package:chuyende/login.dart'; // Import for the reusable widgets

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6DD5FA), Color(0xFF2980B9)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const GenNewsLogo(), // Reusing the logo with Hero animation
                const SizedBox(height: 16),
                Text(
                  'Create your account',
                  style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8)),
                ),
                const SizedBox(height: 60),
                const CustomTextField(hintText: 'Email'),
                const SizedBox(height: 16),
                const CustomTextField(hintText: 'Password', obscureText: true),
                const SizedBox(height: 16),
                const CustomTextField(hintText: 'Confirm Password', obscureText: true),
                const SizedBox(height: 30),
                GradientButton(
                  text: 'Sign Up',
                  onPressed: () {
                    // TODO: Add actual sign up logic here
                    // On success, pop back to the login screen
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    // This pop will trigger the reverse animation of PageRouteBuilder
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "Already have an account? Log In",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
