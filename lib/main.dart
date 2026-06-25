import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // ✅ Ajout pour localisations
import 'package:nafahat/src/features/landing/presentation/splash_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nafahat Platform',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // ✅ Application globale de la police Cairo
        fontFamily: 'Cairo',
        textTheme: GoogleFonts.cairoTextTheme(),
        // ✅ AppBar avec titre en Cairo
        appBarTheme: AppBarTheme(
          titleTextStyle: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          toolbarTextStyle: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        primarySwatch: Colors.indigo,
      ),
      // ✅ Ajout des localisations pour le DatePicker et autres widgets Material
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('ar', 'AR'),
        Locale('en', 'US'),
      ],
      home: const SplashScreen(),
    );
  }
}
