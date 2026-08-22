// lib/main.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nafahat/pages/landing/widgets/chatbot/chatbot_widget.dart';
import 'package:nafahat/pages/users/inscription_adherent.dart';
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
import 'package:nafahat/pages/users/profile_dashboard_page.dart'; // 👈 AJOUTER CET IMPORT
import 'package:nafahat/pages/adminisration/administration_page.dart';
import 'services/navigation_service.dart';

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
        ChangeNotifierProvider(
          create: (_) => UserProvider(),
        ), // 👈 Le constructeur charge la session
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
            navigatorKey: NavigationService.navigatorKey,
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
            navigatorObservers: [ChatbotRouteObserver()],
            // 👈 ICI on utilise la fonction pour déterminer la page initiale
            home: _getInitialPage(),
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
              '/admin':
                  (context) => const ChatbotGlobalWrapper(
                    hideOnRoute: false,
                    child: AdministrationPage(),
                  ),
            },
            // ✅ ROUTES DYNAMIQUES : lisent les `arguments` passés par
            // Navigator.pushNamed(..., arguments: {...}) au lieu de valeurs figées.
            onGenerateRoute: (settings) {
              if (settings.name == '/login') {
                final args = settings.arguments as Map<String, dynamic>?;
                final returnToPrevious =
                    args?['returnToPrevious'] as bool? ?? false;
                return MaterialPageRoute(
                  settings: settings,
                  builder:
                      (context) => ChatbotGlobalWrapper(
                        hideOnRoute: false,
                        child: AuthPage(returnToPrevious: returnToPrevious),
                      ),
                );
              }

              if (settings.name == '/inscription') {
                final args = settings.arguments as Map<String, dynamic>?;
                final fromFormationDetail =
                    args?['fromFormationDetail'] as bool? ?? false;
                return MaterialPageRoute(
                  settings: settings,
                  builder:
                      (context) => ChatbotGlobalWrapper(
                        hideOnRoute: false,
                        child: InscriptionAdherentPage(
                          fromFormationDetail: fromFormationDetail,
                        ),
                      ),
                );
              }

              return null; // Laisse `onUnknownRoute` gérer le reste
            },
            onUnknownRoute: (settings) {
              print('⚠️ [ROUTE] Route inconnue: ${settings.name}');
              return MaterialPageRoute(
                builder:
                    (context) => const ChatbotGlobalWrapper(
                      hideOnRoute: false,
                      child: AuthPage(),
                    ),
              );
            },
          );
        },
      ),
    );
  }
}

// 👇 OBSERVATEUR DE ROUTE pour mettre à jour le ChatbotProvider
class ChatbotRouteObserver extends NavigatorObserver {
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
    final context = navigator?.context;
    if (context != null) {
      final chatbotProvider = Provider.of<ChatbotProvider>(
        context,
        listen: false,
      );

      final shouldHide = _hideRoutes.contains(routeName);

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

// 📄 PAGE COMING SOON
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
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
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
    const Color orangeColor = Color.fromARGB(255, 180, 5, 20);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/slide1.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.15),
                Colors.black.withOpacity(0.4),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.only(top: 220.0),
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: AbsorbPointer(
                          absorbing: true,
                          child: ElevatedButton.icon(
                            onPressed: null,
                            icon: Icon(
                              Icons.hourglass_empty,
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
                              backgroundColor: Colors.white,
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
  final bool hideOnRoute;

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

    bool showChatbot = chatbotProvider.isVisible;

    if (widget.child is SplashScreen || widget.child is LandingPage) {
      showChatbot = false;
    }

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
