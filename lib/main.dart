// lib/main.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nafahat/pages/landing/widgets/chatbot/chatbot_widget.dart';
import 'package:provider/provider.dart';
import '/pages/landing/splash_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/pages/users/auth_page.dart';
import 'package:nafahat/providers/language_provider.dart';
import 'package:nafahat/providers/card_config_provider.dart';
import 'pages/landing/widgets/chatbot/chatbot_widget.dart';
import 'package:nafahat/config/api_config.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Fonction pour déterminer la page à afficher
  Widget _getInitialPage() {
    // Si ce n'est pas le web, on affiche le projet normalement
    if (!kIsWeb) {
      return const ChatbotGlobalWrapper(child: SplashScreen());
    }

    // Récupération de l'URL complète
    final Uri uri = Uri.base;
    final String path = uri.path;

    // Si le chemin est "/" ou vide -> Page Coming Soon
    // Si le chemin est "/project" -> Projet normal (SplashScreen)
    if (path == '/' || path.isEmpty) {
      return const ComingSoonPage();
    } else if (path == '/project') {
      return const ChatbotGlobalWrapper(child: SplashScreen());
    } else {
      // Par défaut, si l'URL est inconnue -> Coming Soon
      return const ComingSoonPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => CardConfigProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          print('📍 Langue actuelle: ${languageProvider.languageCode}');
          print('📍 Locale: ${languageProvider.locale}');
          return MaterialApp(
            title: 'Nafahat Platform',
            debugShowCheckedModeBanner: false,
            locale: languageProvider.locale,
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
              Locale('ar', 'AR'),
              Locale('fr', 'FR'),
              Locale('en', 'US'),
            ],
            localeResolutionCallback: (deviceLocale, supportedLocales) {
              return const Locale('ar');
            },
            // 👈 ICI on utilise la fonction pour déterminer la page initiale
            home: _getInitialPage(),
          );
        },
      ),
    );
  }
}

// 📄 PAGE COMING SOON avec bouton non cliquable et effet de rebondissement
class ComingSoonPage extends StatefulWidget {
  const ComingSoonPage({super.key});

  @override
  State<ComingSoonPage> createState() => _ComingSoonPageState();
}

class _ComingSoonPageState extends State<ComingSoonPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Configuration de l'animation de rebondissement plus prononcée
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200), // Plus rapide
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.12, // Rebondissement plus prononcé
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Couleur orange utilisée dans le bouton
    const Color orangeColor = const Color.fromARGB(255, 180, 5, 20);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: const AssetImage(
              'assets/images/slide1.png',
            ), // Remplacez par votre image
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.15), // Plus clair
                Colors.black.withOpacity(0.4), // Plus clair
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const SizedBox(height: 40),
                // Bouton avec animation de rebondissement et non cliquable
                Padding(
                  padding: const EdgeInsets.only(top: 220.0),
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: AbsorbPointer(
                          absorbing: true, // Rend le bouton non cliquable
                          child: ElevatedButton.icon(
                            onPressed: null, // null = non cliquable
                            icon: Icon(
                              Icons.hourglass_empty, // Icône sablier
                              size: 28,
                              color: const Color.fromARGB(
                                255,
                                180,
                                5,
                                20,
                              ), // Couleur orange
                            ),
                            label: Text(
                              'Coming Soon',
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                color: const Color.fromARGB(255, 180, 5, 20),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white, // Fond blanc
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                                side: const BorderSide(
                                  color: orangeColor,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
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
