import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// AppStyles now defines only font properties, not colors.
// Colors should be applied in the widget using Theme.of(context).

class AppStyles {
  // Headline (e.g., "Trang chủ")
  static final TextStyle headline = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  // Username in posts or profiles
  static final TextStyle username = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  // Post content
  static final TextStyle postContent = GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    height: 1.5, // Improved line spacing for readability
  );

  // Timestamp (e.g., "5 minutes ago")
  static final TextStyle timestamp = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.normal,
  );

  // Interaction text (Like, Comment)
  static final TextStyle interactionText = GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w500, // Medium weight
  );

  // Button text
  static final TextStyle buttonText = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );
  
  // AppBar title
  static final TextStyle appBarTitle = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );
}
