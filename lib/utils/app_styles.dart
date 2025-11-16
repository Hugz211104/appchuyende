import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppStyles {
  // Headline (e.g., "Trang chủ")
  static final TextStyle headline = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  // Username in posts or profiles
  static final TextStyle username = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  // Post content
  static final TextStyle postContent = GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: Colors.black87,
  );

  // Timestamp (e.g., "5 minutes ago")
  static final TextStyle timestamp = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Colors.grey[600],
  );

  // Interaction text (Like, Comment)
  static final TextStyle interactionText = GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w500, // Medium weight
    color: Colors.grey[800],
  );

  // Button text
  static final TextStyle buttonText = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  
  // AppBar title
  static final TextStyle appBarTitle = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );
}
