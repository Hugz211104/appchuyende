import 'package:chuyende/auth/auth_wrapper.dart';
import 'package:chuyende/screens/login_screen.dart';
import 'package:chuyende/screens/register_screen.dart';
import 'package:chuyende/services/auth_service.dart';
import 'package:chuyende/utils/app_colors.dart';
import 'package:chuyende/utils/app_styles.dart';
import 'package:flutter/foundation.dart';
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

  // Smartly set the Android provider based on the build mode (debug/release).
  const androidProvider = kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity;
  // Smartly set the Apple provider based on the build mode (debug/release).
  const appleProvider = kDebugMode ? AppleProvider.debug : AppleProvider.appAttest;

  await FirebaseAppCheck.instance.activate(
    androidProvider: androidProvider,
    appleProvider: appleProvider,
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
        scaffoldMessengerKey: scaffoldMessengerKey, // Set the key here
        title: 'GenNews',
        theme: _buildTheme(context),
        debugShowCheckedModeBanner: false,
        home: AuthWrapper(),
        // Define routes for navigation
        routes: {
          '/login': (context) => LoginScreen(
                showRegisterScreen: () {
                  Navigator.pushNamed(context, '/register');
                },
              ),
          '/register': (context) => RegisterScreen(
                showLoginScreen: () {
                  Navigator.pop(context); // Go back to the login screen
                },
              ),
        },
      ),
    );
  }

  ThemeData _buildTheme(BuildContext context) {
     final baseTheme = ThemeData.light();
    return baseTheme.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        onPrimary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        background: AppColors.background,
        error: AppColors.error,
      ),
      textTheme: baseTheme.textTheme.copyWith(
        displayLarge: AppStyles.headline, // Headline 1
        displayMedium: AppStyles.headline, // Headline 2
        displaySmall: AppStyles.headline, // Headline 3
        headlineMedium: AppStyles.headline, // Headline 4
        headlineSmall: AppStyles.appBarTitle, // Headline 5, used for AppBar
        titleLarge: AppStyles.username, // Headline 6, used for list tiles
        bodyLarge: AppStyles.postContent,
        bodyMedium: AppStyles.interactionText,
        bodySmall: AppStyles.timestamp,
        labelLarge: AppStyles.buttonText,
      ).apply(bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppStyles.appBarTitle.copyWith(color: AppColors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          textStyle: AppStyles.buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
         style: OutlinedButton.styleFrom(
           foregroundColor: AppColors.textPrimary,
           side: const BorderSide(color: AppColors.divider, width: 1.5),
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
           padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
           textStyle: AppStyles.buttonText.copyWith(color: AppColors.textPrimary),
         )
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        labelStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
        floatingLabelStyle: GoogleFonts.poppins(color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.divider, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.divider, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 2.0),
        ),
      ),
       tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.primary, width: 2.0),
        ),
        labelStyle: AppStyles.buttonText,
        unselectedLabelStyle: AppStyles.buttonText,
      ),
      cardTheme: CardThemeData(
        elevation: 0.5,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: AppColors.surface,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerColor: AppColors.divider,
    );
  }
}
