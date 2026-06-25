import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:nafahat/src/features/landing/presentation/splash_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/pages/users/auth_page.dart';
import 'package:nafahat/providers/language_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: MaterialApp(
        title: 'Nafahat Platform',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // ✅ Police Cairo via GoogleFonts (pas besoin de fichiers locaux)
          textTheme: GoogleFonts.cairoTextTheme(),
          // AppBar avec Cairo
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
        // ✅ Localisations pour DatePicker, etc.
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
      ),
    );
  }
}
