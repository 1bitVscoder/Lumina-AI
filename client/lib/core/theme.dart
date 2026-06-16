import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LuminaColors {
  // Backgrounds
  static const background      = Color(0xFFF5F0E8); // warm off-white, aged paper
  static const backgroundDark  = Color(0xFF0B0C14); // deep dark blue/charcoal base matching login screen
  static const surface         = Color(0xFFEDE7D5); // slightly darker paper
  static const surfaceDark     = Color(0xFF161325); // deep violet-slate matching login gradients

  // Bubbles
  static const userBubble      = Color(0xFFD4E8C2); // muted sage green (WhatsApp user)
  static const userBubbleDark  = Color(0xFF3A1F3D); // rich deep violet matching login glow
  static const aiBubble        = Color(0xFFFFFFFA); // near-white paper
  static const aiBubbleDark    = Color(0xFF1C1A30); // deep navy-slate matching login transition base

  // Text
  static const textPrimary     = Color(0xFF2C2315); // deep ink brown
  static const textSecondary   = Color(0xFF7A6E5E); // faded ink
  static const textTimestamp   = Color(0xFFA09080); // barely there
  static const textPrimaryDark = Color(0xFFF5F3EE); // soft hello-style cream
  static const textSecDark     = Color(0xFFAA9E8E); // cozy warm secondary text

  // Accents
  static const accentAmber     = Color(0xFFD4820A); // warm amber — primary accent
  static const accentGreen     = Color(0xFF6B8F5E); // sage — secondary
  static const accentRed       = Color(0xFFB04040); // muted red — errors/warnings

  // UI Elements
  static const divider         = Color(0xFFD6CDB8);
  static const dividerDark     = Color(0xFF25213B); // dark indigo divider
  static const inputBackground = Color(0xFFF0EBE0);
  static const sendButton      = Color(0xFFD4820A); // amber
  static const disabled        = Color(0xFFC8C0B0);
}

class LuminaTypography {
  // Display / AI name header
  static const fontDisplay = 'Lora';        // Serif, warm, editorial

  // Body / chat text
  static const fontBody    = 'JetBrains Mono'; // Monospace — adds old-school terminal feel
                                                // Used ONLY for AI responses
  static const fontSans    = 'DM Sans';     // User messages, UI labels

  // Sizes
  static const double sizeCaption   = 11.0;
  static const double sizeBody      = 15.0;
  static const double sizeBodyLarge = 17.0;
  static const double sizeTitle     = 20.0;
  static const double sizeHeader    = 26.0;
}

class LuminaSpacing {
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 16.0;
  static const double lg  = 24.0;
  static const double xl  = 32.0;
  static const double xxl = 48.0;
}

class LuminaRadius {
  static const double bubbleUser = 18.0;  // rounded, tail bottom-right
  static const double bubbleAi   = 18.0;  // tail bottom-left
  static const double card       = 12.0;
  static const double input      = 24.0;  // pill-shaped input bar
  static const double button     = 12.0;
}

ThemeData getLuminaTheme(BuildContext context, bool isDarkMode) {
  final baseTextTheme = isDarkMode 
      ? ThemeData.dark().textTheme 
      : ThemeData.light().textTheme;

  final textTheme = GoogleFonts.dmSansTextTheme(baseTextTheme).copyWith(
    bodyMedium: GoogleFonts.dmSans(
      fontSize: LuminaTypography.sizeBody,
      color: isDarkMode ? LuminaColors.textPrimaryDark : LuminaColors.textPrimary,
    ),
    bodyLarge: GoogleFonts.dmSans(
      fontSize: LuminaTypography.sizeBodyLarge,
      color: isDarkMode ? LuminaColors.textPrimaryDark : LuminaColors.textPrimary,
    ),
    labelSmall: GoogleFonts.dmSans(
      fontSize: LuminaTypography.sizeCaption,
      color: isDarkMode ? LuminaColors.textSecDark : LuminaColors.textSecondary,
    ),
    titleLarge: GoogleFonts.lora(
      fontSize: LuminaTypography.sizeTitle,
      fontWeight: FontWeight.bold,
      color: isDarkMode ? LuminaColors.textPrimaryDark : LuminaColors.textPrimary,
    ),
    headlineMedium: GoogleFonts.lora(
      fontSize: LuminaTypography.sizeHeader,
      fontWeight: FontWeight.bold,
      color: isDarkMode ? LuminaColors.textPrimaryDark : LuminaColors.textPrimary,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: isDarkMode ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: isDarkMode ? LuminaColors.backgroundDark : LuminaColors.background,
    dividerColor: isDarkMode ? LuminaColors.dividerDark : LuminaColors.divider,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: isDarkMode ? LuminaColors.surfaceDark : LuminaColors.surface,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(
        color: isDarkMode ? LuminaColors.textPrimaryDark : LuminaColors.textPrimary,
      ),
      titleTextStyle: GoogleFonts.lora(
        fontSize: LuminaTypography.sizeTitle,
        fontWeight: FontWeight.w600,
        color: isDarkMode ? LuminaColors.textPrimaryDark : LuminaColors.textPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      color: isDarkMode ? LuminaColors.surfaceDark : LuminaColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LuminaRadius.card),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDarkMode ? LuminaColors.surfaceDark : LuminaColors.inputBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LuminaRadius.input),
        borderSide: BorderSide.none,
      ),
      hintStyle: GoogleFonts.dmSans(
        color: isDarkMode ? LuminaColors.textSecDark : LuminaColors.textTimestamp,
        fontSize: LuminaTypography.sizeBody,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: LuminaColors.accentAmber,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuminaRadius.button),
        ),
        textStyle: GoogleFonts.dmSans(
          fontSize: LuminaTypography.sizeBody,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
