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
import 'package:nafahat/providers/chatbot_provider.dart';
import 'package:nafahat/providers/user_provider.dart';
import 'package:nafahat/providers/about_provider.dart';
import 'pages/landing/widgets/chatbot/chatbot_widget.dart';
import 'package:nafahat/config/api_config.dart';
import 'pages/landing/landing_page.dart';
import 'package:nafahat/models/card_config_model.dart';

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
        ChangeNotifierProvider(create: (_) => ChatbotProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AboutProvider()),
        // Ajouter d'autres providers si nécessaire
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
            // 👇 Navigation avec route observer pour contrôler le chatbot
            navigatorObservers: [ChatbotRouteObserver()],
            // 👈 ICI on utilise la fonction pour déterminer la page initiale
            home: _getInitialPage(),
            // 👇 Routes nommées pour un meilleur contrôle
            routes: {
              '/landing':
                  (context) => const ChatbotGlobalWrapper(
                    hideOnRoute: true,
                    child: LandingPage(),
                  ),
              '/splash':
                  (context) => const ChatbotGlobalWrapper(
                    hideOnRoute: true,
                    child: SplashScreen(),
                  ),
              '/auth':
                  (context) => const ChatbotGlobalWrapper(
                    hideOnRoute: false,
                    child: AuthPage(),
                  ),
            },
          );
        },
      ),
    );
  }
}

// 👇 OBSERVATEUR DE ROUTE pour mettre à jour le ChatbotProvider
class ChatbotRouteObserver extends NavigatorObserver {
  // Liste des routes où le chatbot doit être caché
  static const List<String> _hideRoutes = ['/splash', '/landing'];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _updateChatbotVisibility(route.settings.name);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _updateChatbotVisibility(previousRoute?.settings.name);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _updateChatbotVisibility(newRoute?.settings.name);
  }

  void _updateChatbotVisibility(String? routeName) {
    // Récupérer le contexte du navigateur
    final context = navigator?.context;
    if (context != null) {
      // Récupérer le ChatbotProvider
      final chatbotProvider = Provider.of<ChatbotProvider>(
        context,
        listen: false,
      );

      // Vérifier si la route actuelle doit cacher le chatbot
      final shouldHide = _hideRoutes.contains(routeName);

      // Mettre à jour la visibilité
      if (shouldHide) {
        chatbotProvider.hide();
        print('🔍 Chatbot CACHÉ sur la route: $routeName');
      } else {
        chatbotProvider.show();
        print('🔍 Chatbot VISIBLE sur la route: $routeName');
      }
    }
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
    const Color orangeColor = Color.fromARGB(255, 180, 5, 20);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
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
                              color: orangeColor,
                            ),
                            label: Text(
                              'Coming Soon',
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                color: orangeColor,
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

// ✅ WRAPPER avec ChatbotProvider
class ChatbotGlobalWrapper extends StatefulWidget {
  final Widget child;
  final bool hideOnRoute; // 👈 Paramètre pour cacher sur une route spécifique

  const ChatbotGlobalWrapper({
    super.key,
    required this.child,
    this.hideOnRoute = false,
  });

  @override
  State<ChatbotGlobalWrapper> createState() => _ChatbotGlobalWrapperState();
}

class _ChatbotGlobalWrapperState extends State<ChatbotGlobalWrapper> {
  @override
  void initState() {
    super.initState();
    // Si hideOnRoute est true, cacher le chatbot immédiatement
    if (widget.hideOnRoute) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = Provider.of<ChatbotProvider>(context, listen: false);
        provider.hide();
        print('🔍 Chatbot caché sur cette page');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;
    final chatbotProvider = Provider.of<ChatbotProvider>(context);

    // Vérifier si le chatbot doit être caché via le provider
    bool showChatbot = chatbotProvider.isVisible;

    // Vérification supplémentaire via le type du widget enfant
    if (widget.child is SplashScreen || widget.child is LandingPage) {
      showChatbot = false;
    }

    // Vérification via le nom de la route
    final route = ModalRoute.of(context);
    final routeName = route?.settings.name ?? '';
    if (routeName == '/splash' || routeName == '/landing') {
      showChatbot = false;
    }

    print(
      '🔍 Chatbot sur $routeName: ${showChatbot ? '✅ VISIBLE' : '❌ CACHÉ'}',
    );

    return Stack(
      children: [
        widget.child,
        // 👇 Afficher le chatbot SEULEMENT si showChatbot est true
        if (showChatbot)
          ChatbotWidget(
            apiBaseUrl: ApiConfig.baseUrl,
            langue: isArabic ? 'ar' : 'fr',
            primaryColor: const Color(0xffd57653),
          ),
      ],
    );
  }
}
