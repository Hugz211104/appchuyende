import 'package:chuyende/auth/auth_wrapper.dart';
import 'package:chuyende/screens/login_screen.dart';
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

  await FirebaseAppCheck.instance.activate(
    androidProvider: androidProvider,
    // For Apple platforms, you might want a similar condition
    appleProvider: AppleProvider.debug, 
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: AppStyles.buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
         style: OutlinedButton.styleFrom(
           foregroundColor: AppColors.textPrimary,
           side: const BorderSide(color: AppColors.divider),
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
           padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
           textStyle: AppStyles.buttonText.copyWith(color: AppColors.textPrimary),
         )
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        // The label text style
        labelStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
        // The style of the label when it floats to the top
        floatingLabelStyle: GoogleFonts.poppins(color: AppColors.primary),
        // Define the border for the "OutlinedBox" style
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2.0),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
