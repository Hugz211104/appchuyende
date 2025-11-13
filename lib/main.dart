import 'package:chuyende/auth/auth_wrapper.dart';
import 'package:chuyende/screens/login_screen.dart';
import 'package:chuyende/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  timeago.setLocaleMessages('vi', timeago.ViMessages());
  await Firebase.initializeApp();
  
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  runApp(const GenNewsApp());
}

class GenNewsApp extends StatelessWidget {
  const GenNewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: MaterialApp(
        title: 'GenNews',
        theme: _buildTheme(context),
        debugShowCheckedModeBanner: false,
        home: AuthWrapper(),
        routes: {
          '/login': (context) => LoginScreen(showRegisterScreen: () {}),
        },
      ),
    );
  }

  ThemeData _buildTheme(BuildContext context) {
     final baseTheme = ThemeData.light();
    return baseTheme.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF5F5F7),
      primaryColor: const Color(0xFF0A84FF),
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: const Color(0xFF0A84FF),
        secondary: const Color(0xFF34C759),
        onPrimary: Colors.white,
        surface: Colors.white, 
        onSurface: const Color(0xFF1D1D1F),
        background: const Color(0xFFF5F5F7),
      ),
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).copyWith(
        headlineSmall: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 24, color: const Color(0xFF1D1D1F)),
        titleLarge: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20, color: const Color(0xFF1D1D1F)),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF333333)),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF666666)),
      ).apply(bodyColor: const Color(0xFF1D1D1F)),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF5F5F7),
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF1D1D1F)),
        titleTextStyle: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1D1D1F)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0A84FF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
         style: OutlinedButton.styleFrom(
           foregroundColor: const Color(0xFF1D1D1F),
           side: BorderSide(color: Colors.grey.shade300),
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
           padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
           textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
         )
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        hintStyle: GoogleFonts.inter(color: const Color(0xFF8A8A8E)),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF0A84FF),
        unselectedItemColor: Color(0xFF8A8A8E),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
