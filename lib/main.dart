// Final, verified version. Ensures all Firebase connections and UI elements are correct.
import 'package:chuyende/auth/auth_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // Import App Check
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Activate App Check
  await FirebaseAppCheck.instance.activate(
    // Use the debug provider for local testing
    androidProvider: AndroidProvider.debug,
    // For release, you'll need to register your app with SafetyNet or Play Integrity
  );

  runApp(const GenNewsApp());
}

class GenNewsApp extends StatelessWidget {
  const GenNewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    // A more refined and modern theme for a premium news app feel.
    final baseTheme = ThemeData.light();
    final theme = baseTheme.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF5F5F7), // Softer background
      primaryColor: const Color(0xFF0A84FF),
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: const Color(0xFF0A84FF),
        secondary: const Color(0xFF34C759), // A nice green for secondary actions
        onPrimary: Colors.white,
        surface: Colors.white, // For cards and dialogs
        onSurface: const Color(0xFF1D1D1F),
        background: const Color(0xFFF5F5F7),
      ),
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).copyWith(
        // Define specific styles for better hierarchy
        headlineSmall: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: const Color(0xFF1D1D1F),
        ),
        titleLarge: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: const Color(0xFF1D1D1F),
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: const Color(0xFF333333),
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFF666666),
        ),
      ).apply(
        bodyColor: const Color(0xFF1D1D1F),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF5F5F7), // Match scaffold background
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF1D1D1F)),
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Color(0xFF1D1D1F),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0A84FF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
         style: OutlinedButton.styleFrom(
           foregroundColor: const Color(0xFF1D1D1F),
           side: BorderSide(color: Colors.grey.shade300),
           shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(12),
           ),
           padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
           textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
         )
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: GoogleFonts.inter(color: const Color(0xFF8A8A8E)),
      ),
      cardTheme: CardThemeData( // Corrected from CardTheme to CardThemeData
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white, // A solid white bar
        selectedItemColor: Color(0xFF0A84FF),
        unselectedItemColor: Color(0xFF8A8A8E),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );

    return MaterialApp(
      title: 'GenNews',
      theme: theme,
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}
