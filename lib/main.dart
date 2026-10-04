import 'package:nafahat/pages/widgets/shared_navigation_shell.dart';
import 'package:nafahat/pages/widgets/mobile_bottom_nav_bar.dart';
// lib/main.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nafahat/pages/formation/formations_page.dart';
import 'package:nafahat/pages/formateur/formateurs_page.dart';
import 'package:nafahat/pages/widgets/chatbot/chatbot_widget.dart';
import 'package:nafahat/pages/users/inscription_adherent.dart';
import 'package:provider/provider.dart';
import 'package:nafahat/pages/landing/splash_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/pages/users/auth_page.dart';
import 'package:nafahat/providers/language_provider.dart';
import 'package:nafahat/providers/chatbot_provider.dart';
import 'package:nafahat/providers/user_provider.dart';
import 'package:nafahat/providers/about_provider.dart';
import 'package:nafahat/providers/hero_provider.dart';
import 'pages/widgets/chatbot/chatbot_widget.dart';
import 'package:nafahat/config/api_config.dart';
import 'pages/landing/landing_page.dart';
import 'package:nafahat/pages/users/profile_dashboard_page.dart';
import 'package:nafahat/pages/adminisration/administration_page.dart';
import 'package:nafahat/pages/cart/cart_page.dart';
import 'services/navigation_service.dart';
import 'services/cart_service.dart';
import 'services/card_config_manager.dart';
import 'services/landing_appearance_manager.dart';
import 'package:nafahat/pages/widgets/all_video_page.dart';
import 'pages/formation/formation_detail_page.dart';
import 'package:nafahat/pages/users/reset_password_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  CartService.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isInitialized = false;
  CardConfigManager? _cardConfigManager;
  HeroProvider? _heroProvider;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    print('🚀 Début initialisation...');
    
    // Initialiser CardConfigManager
    _cardConfigManager = CardConfigManager();
    await _cardConfigManager!.init();
    print('✅ CardConfigManager initialisé');
    
    // Initialiser HeroProvider
    _heroProvider = HeroProvider();
    await _heroProvider!.init();
    print('✅ HeroProvider initialisé avec ${_heroProvider!.slides.length} slides');

    // Charger le thème global sauvegardé dans Apparence Landing.
    // Le même manager pilote maintenant toute l'application.
    await LandingAppearanceManager().load();
    print('✅ Thème global chargé');
    
    setState(() {
      _isInitialized = true;
    });
    print('🚀 Initialisation terminée');
  }

  Widget _getInitialPage() {
    if (!kIsWeb) {
      return ChatbotGlobalWrapper(child: const SplashScreen());
    }

    final Uri uri = Uri.base;
    final String path = uri.path;

    if (path == '/' || path.isEmpty) {
      return const ComingSoonPage();
    } else if (path == '/project') {
      return ChatbotGlobalWrapper(child: const SplashScreen());
    } else if (path == '/reset-password') {
      return const ChatbotGlobalWrapper(
        hideOnRoute: false,
        child: ResetPasswordPage(),
      );
    } else {
      return const ComingSoonPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Color(0xffd57653)),
                const SizedBox(height: 20),
                Text(
                  'Chargement...',
                  style: GoogleFonts.cairo(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ChatbotProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AboutProvider()),
        // ✅ Utiliser les instances déjà initialisées
        ChangeNotifierProvider<CardConfigManager>.value(
          value: _cardConfigManager!,
        ),
        ChangeNotifierProvider<HeroProvider>.value(
          value: _heroProvider!,
        ),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          print('📍 Langue actuelle: ${languageProvider.languageCode}');
          
          // Vérifier les providers
          final cardConfigManager = Provider.of<CardConfigManager>(context);
          final heroProvider = Provider.of<HeroProvider>(context);
          
          print('📍 Config chargée: ${cardConfigManager.isInitialized}');
          print('📍 Hero chargé: ${heroProvider.isInitialized} - ${heroProvider.slides.length} slides');

          return AnimatedBuilder(
            animation: LandingAppearanceManager(),
            builder: (context, _) {
              final appearance = LandingAppearanceManager().config;
              final brightness = appearance.themeMode == 'dark'
                  ? Brightness.dark
                  : Brightness.light;

              final colorScheme = ColorScheme.fromSeed(
                seedColor: appearance.primaryColor,
                brightness: brightness,
              ).copyWith(
                primary: appearance.primaryColor,
                secondary: appearance.accentColor,
                surface: appearance.sectionBackgroundColor,
              );

              final baseTextTheme = GoogleFonts.cairoTextTheme(
                ThemeData(brightness: brightness).textTheme,
              ).apply(
                bodyColor: appearance.textColor,
                displayColor: appearance.titleColor,
              );

              return MaterialApp(
            title: 'Nafahat Platform',
            debugShowCheckedModeBanner: false,
            locale: languageProvider.locale,
            navigatorKey: NavigationService.navigatorKey,
            theme: ThemeData(
              useMaterial3: true,
              brightness: brightness,
              colorScheme: colorScheme,
              scaffoldBackgroundColor: appearance.pageBackgroundColor,
              canvasColor: appearance.pageBackgroundColor,
              cardColor: appearance.sectionBackgroundColor,
              dialogBackgroundColor: appearance.sectionBackgroundColor,
              dividerColor: appearance.mutedTextColor.withOpacity(.22),
              disabledColor: appearance.mutedTextColor.withOpacity(.45),
              textTheme: baseTextTheme,
              iconTheme: IconThemeData(color: appearance.primaryColor),
              appBarTheme: AppBarTheme(
                backgroundColor: appearance.sectionBackgroundColor,
                foregroundColor: appearance.textColor,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                iconTheme: IconThemeData(color: appearance.primaryColor),
                titleTextStyle: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: appearance.titleColor,
                ),
                toolbarTextStyle: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: appearance.textColor,
                ),
              ),
              navigationBarTheme: NavigationBarThemeData(
                backgroundColor: appearance.sectionBackgroundColor,
                indicatorColor: appearance.primaryColor.withOpacity(.12),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  return IconThemeData(
                    color: states.contains(WidgetState.selected)
                        ? appearance.primaryColor
                        : appearance.mutedTextColor,
                  );
                }),
                labelTextStyle: WidgetStatePropertyAll(
                  GoogleFonts.cairo(color: appearance.textColor),
                ),
              ),
              bottomNavigationBarTheme: BottomNavigationBarThemeData(
                backgroundColor: appearance.sectionBackgroundColor,
                selectedItemColor: appearance.primaryColor,
                unselectedItemColor: appearance.mutedTextColor,
              ),
              drawerTheme: DrawerThemeData(
                backgroundColor: appearance.sectionBackgroundColor,
                surfaceTintColor: Colors.transparent,
              ),
              listTileTheme: ListTileThemeData(
                textColor: appearance.textColor,
                iconColor: appearance.primaryColor,
                selectedColor: appearance.primaryColor,
                selectedTileColor: appearance.primaryColor.withOpacity(.08),
                tileColor: Colors.transparent,
              ),
              menuTheme: MenuThemeData(
                style: MenuStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    appearance.sectionBackgroundColor,
                  ),
                
                  surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
                ),
              ),
              popupMenuTheme: PopupMenuThemeData(
                color: appearance.sectionBackgroundColor,
                surfaceTintColor: Colors.transparent,
                textStyle: GoogleFonts.cairo(color: appearance.textColor),
              ),
              dropdownMenuTheme: DropdownMenuThemeData(
                textStyle: GoogleFonts.cairo(color: appearance.textColor),
                menuStyle: MenuStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    appearance.sectionBackgroundColor,
                  ),
                ),
              ),
              chipTheme: ChipThemeData(
                backgroundColor: appearance.sectionBackgroundColor,
                selectedColor: appearance.primaryColor.withOpacity(.14),
                disabledColor: appearance.mutedTextColor.withOpacity(.10),
                side: BorderSide(color: appearance.mutedTextColor.withOpacity(.20)),
                labelStyle: GoogleFonts.cairo(color: appearance.textColor),
                secondaryLabelStyle: GoogleFonts.cairo(color: appearance.primaryColor),
                iconTheme: IconThemeData(color: appearance.primaryColor),
              ),
              checkboxTheme: CheckboxThemeData(
                fillColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.selected)
                        ? appearance.primaryColor
                        : Colors.transparent),
                checkColor: WidgetStatePropertyAll(
                  ThemeData.estimateBrightnessForColor(appearance.primaryColor) == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
                side: BorderSide(color: appearance.mutedTextColor),
              ),
              radioTheme: RadioThemeData(
                fillColor: WidgetStatePropertyAll(appearance.primaryColor),
              ),
              switchTheme: SwitchThemeData(
                thumbColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.selected)
                        ? appearance.primaryColor
                        : appearance.mutedTextColor),
                trackColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.selected)
                        ? appearance.primaryColor.withOpacity(.28)
                        : appearance.mutedTextColor.withOpacity(.18)),
              ),
              tabBarTheme: TabBarThemeData(
                labelColor: appearance.primaryColor,
                unselectedLabelColor: appearance.mutedTextColor,
                indicatorColor: appearance.accentColor,
                dividerColor: appearance.mutedTextColor.withOpacity(.18),
                labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                unselectedLabelStyle: GoogleFonts.cairo(),
              ),
              tooltipTheme: TooltipThemeData(
                decoration: BoxDecoration(
                  color: appearance.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: GoogleFonts.cairo(
                  color: ThemeData.estimateBrightnessForColor(appearance.primaryColor) == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
              dividerTheme: DividerThemeData(
                color: appearance.mutedTextColor.withOpacity(.18),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: appearance.sectionBackgroundColor,
                labelStyle: TextStyle(color: appearance.mutedTextColor),
                hintStyle: TextStyle(color: appearance.mutedTextColor),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: appearance.mutedTextColor.withOpacity(.25),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: appearance.primaryColor,
                    width: 1.5,
                  ),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: appearance.primaryColor,
                  foregroundColor: Colors.white,
                  textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                ),
              ),
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  backgroundColor: appearance.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: appearance.primaryColor,
                ),
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: appearance.accentColor,
                foregroundColor: Colors.white,
              ),
              snackBarTheme: SnackBarThemeData(
                backgroundColor: appearance.primaryColor,
                contentTextStyle: GoogleFonts.cairo(color: Colors.white),
                behavior: SnackBarBehavior.floating,
              ),
              progressIndicatorTheme: ProgressIndicatorThemeData(
                color: appearance.accentColor,
              ),
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
            builder: (context, child) {
              return NotificationListener<ScrollNotification>(
                onNotification: MobileBottomNavController.handleScroll,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: _getInitialPage(),
            routes: {
              '/landing': (context) => const ChatbotGlobalWrapper(
                hideOnRoute: true,
                child: LandingPage(),
              ),
              '/splash': (context) => const ChatbotGlobalWrapper(
                hideOnRoute: true,
                child: SplashScreen(),
              ),
              '/auth': (context) => const ChatbotGlobalWrapper(
                hideOnRoute: false,
                child: AuthPage(),
              ),
              '/admin': (context) => const ChatbotGlobalWrapper(
                hideOnRoute: false,
                child: AdministrationPage(),
              ),
              '/cart': (context) => const ChatbotGlobalWrapper(
                hideOnRoute: false,
                child: CartPage(),
              ),
              '/formateurs': (context) => const ChatbotGlobalWrapper(
                hideOnRoute: false,
                child: FormateursPage(),
              ),
              '/reset-password': (context) => const ChatbotGlobalWrapper(
                hideOnRoute: false,
                child: ResetPasswordPage(),
              ),
            },
            onGenerateRoute: (settings) {
              print('📍 [ROUTE] Navigation vers: ${settings.name}');
              
              if (settings.name == '/login') {
                final args = settings.arguments as Map<String, dynamic>?;
                final returnToPrevious = args?['returnToPrevious'] as bool? ?? false;
                return NafahatPageRoute(
                  settings: settings,
                  builder: (context) => ChatbotGlobalWrapper(
                    hideOnRoute: false,
                    child: AuthPage(returnToPrevious: returnToPrevious),
                  ),
                );
              }

              if (settings.name == '/inscription') {
                final args = settings.arguments as Map<String, dynamic>?;
                final fromFormationDetail = args?['fromFormationDetail'] as bool? ?? false;
                return NafahatPageRoute(
                  settings: settings,
                  builder: (context) => ChatbotGlobalWrapper(
                    hideOnRoute: false,
                    child: InscriptionAdherentPage(
                      fromFormationDetail: fromFormationDetail,
                    ),
                  ),
                );
              }

              if (settings.name == '/reset-password') {
                return NafahatPageRoute(
                  settings: settings,
                  builder: (context) => const ChatbotGlobalWrapper(
                    hideOnRoute: false,
                    child: ResetPasswordPage(),
                  ),
                );
              }

              if (settings.name == '/formations') {
                final args = settings.arguments as Map<String, String>?;
                return NafahatPageRoute(
                  settings: settings,
                  builder: (context) => ChatbotGlobalWrapper(
                    hideOnRoute: false,
                    child: FormationsPage(
                      categorieId: args?['categorieId'],
                      formateurId: args?['formateurId'],
                    ),
                  ),
                );
              }

              if (settings.name != null && settings.name!.startsWith('/formation/')) {
                final formationId = settings.name!.replaceAll('/formation/', '');
                return NafahatPageRoute(
                  settings: settings,
                  builder: (context) => ChatbotGlobalWrapper(
                    hideOnRoute: false,
                    child: FormationDetailPage(formationId: formationId),
                  ),
                );
              }

              if (settings.name != null && settings.name!.startsWith('/video/')) {
                return NafahatPageRoute(
                  settings: settings,
                  builder: (context) => ChatbotGlobalWrapper(
                    hideOnRoute: false,
                    child: AllVideoPage(),
                  ),
                );
              }

              if (settings.name == '/cart') {
                return NafahatPageRoute(
                  settings: settings,
                  builder: (context) => const ChatbotGlobalWrapper(
                    hideOnRoute: false,
                    child: CartPage(),
                  ),
                );
              }

              if (settings.name == '/profile') {
                return NafahatPageRoute(
                  settings: settings,
                  builder: (context) => ChatbotGlobalWrapper(
                    hideOnRoute: false,
                    child: ProfileDashboardPage(),
                  ),
                );
              }

              if (settings.name == '/videos') {
                return NafahatPageRoute(
                  settings: settings,
                  builder: (context) => ChatbotGlobalWrapper(
                    hideOnRoute: false,
                    child: AllVideoPage(),
                  ),
                );
              }

              return null;
            },
            onUnknownRoute: (settings) {
              print('⚠️ [ROUTE] Route inconnue: ${settings.name}');
              return NafahatPageRoute(
                builder: (context) => const ChatbotGlobalWrapper(
                  hideOnRoute: false,
                  child: AuthPage(),
                ),
              );
            },
              );
            },
          );
        },
      ),
    );
  }
}

// 👇 OBSERVATEUR DE ROUTE
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
    MobileBottomNavController.reset();
    final context = navigator?.context;
    if (context != null) {
      final chatbotProvider = Provider.of<ChatbotProvider>(context, listen: false);
      final shouldHide = _hideRoutes.contains(routeName);
      if (shouldHide) {
        chatbotProvider.hide();
      } else {
        chatbotProvider.show();
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
                            icon: Icon(Icons.hourglass_empty, size: 28, color: orangeColor),
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
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                                side: const BorderSide(color: orangeColor, width: 2),
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
  const ChatbotGlobalWrapper({super.key, required this.child, this.hideOnRoute = false});

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

    if (widget.child is SplashScreen) return widget.child;

    return Stack(
      children: [
        widget.child,
        if (showChatbot)
          ChatbotWidget(
            apiBaseUrl: ApiConfig.apiUrl,
            langue: isArabic ? 'ar' : 'fr',
            primaryColor: LandingAppearanceManager().config.accentColor,
          ),
      ],
    );
  }
}