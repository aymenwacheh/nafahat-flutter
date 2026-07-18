// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nafahat/pages/landing/widgets/chatbot/chatbot_widget.dart';
import 'package:provider/provider.dart';
import '/pages/landing/splash_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/pages/users/auth_page.dart';
import 'package:nafahat/providers/language_provider.dart';
import 'package:nafahat/providers/card_config_provider.dart'; // 👈 AJOUT
import 'pages/landing/widgets/chatbot/chatbot_widget.dart';
import 'package:nafahat/config/api_config.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // 👈 CHANGEMENT : MultiProvider au lieu de ChangeNotifierProvider
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => CardConfigProvider()), // 👈 AJOUT
      ],
      child: MaterialApp(
        title: 'Nafahat Platform',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          textTheme: GoogleFonts.cairoTextTheme(),
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
        home: const ChatbotGlobalWrapper(child: SplashScreen()),
      ),
    );
  }
}

class ChatbotGlobalWrapper extends StatefulWidget {
  final Widget child;

  const ChatbotGlobalWrapper({super.key, required this.child});

  @override
  State<ChatbotGlobalWrapper> createState() => _ChatbotGlobalWrapperState();
}

class _ChatbotGlobalWrapperState extends State<ChatbotGlobalWrapper> {
  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;

    return Stack(
      children: [
        widget.child,
        ChatbotWidget(
          apiBaseUrl: ApiConfig.baseUrl,
          langue: isArabic ? 'ar' : 'fr',
          primaryColor: const Color(0xffd57653),
        ),
      ],
    );
  }
}
