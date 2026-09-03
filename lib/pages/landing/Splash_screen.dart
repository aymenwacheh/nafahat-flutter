import 'dart:async';
import 'package:flutter/material.dart';
import 'landing_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bgScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<Offset> _textSlideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // 1. Fond : zoom-out doux
    _bgScaleAnimation = Tween<double>(begin: 1.08, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Logo : Fondu + Scale
    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.6, curve: Curves.easeIn),
      ),
    );
    _logoScaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOutBack),
      ),
    );

    // 3. Texte : Fondu + Glissement
    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.9, curve: Curves.easeIn),
      ),
    );
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();

    Timer(const Duration(milliseconds: 4500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LandingPage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final isTablet = screenSize.width >= 600 && screenSize.width < 1200;
    
    // ✅ TAILLES AGRANDIES
    double logoWidth;
    double textWidth;
    
    if (isMobile) {
      // Mobile : 65% de la largeur
      logoWidth = screenSize.width * 0.65;
      textWidth = screenSize.width * 0.80;
    } else if (isTablet) {
      // Tablette : 50% de la largeur
      logoWidth = screenSize.width * 0.45;
      textWidth = screenSize.width * 0.55;
    } else {
      // Desktop : 35% de la largeur
      logoWidth = screenSize.width * 0.30;
      textWidth = screenSize.width * 0.40;
    }
    
    // ✅ Limites maximales pour éviter que ce soit trop grand
    final double maxLogoWidth = isMobile ? 350 : 500;
    final double maxTextWidth = isMobile ? 500 : 700;
    
    logoWidth = logoWidth > maxLogoWidth ? maxLogoWidth : logoWidth;
    textWidth = textWidth > maxTextWidth ? maxTextWidth : textWidth;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background (4.jpg)
          AnimatedBuilder(
            animation: _bgScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _bgScaleAnimation.value,
                child: child,
              );
            },
            child: Image.asset(
              'assets/splash/4.png',
              fit: BoxFit.cover,
            ),
          ),

          // Calques Logo et Texte
          SafeArea(
            child: Stack(
              children: [
                // ✅ LOGO - plus grand et plus haut
                Positioned.fill(
                  child: Align(
                    alignment: const Alignment(0.0, -0.25), // ✅ Décalé vers le haut
                    child: FadeTransition(
                      opacity: _logoOpacityAnimation,
                      child: ScaleTransition(
                        scale: _logoScaleAnimation,
                        child: Image.asset(
                          'assets/splash/2.png',
                          width: logoWidth,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),

                // ✅ TEXTE - plus grand et légèrement plus haut
                Positioned.fill(
                  child: Align(
                    alignment: const Alignment(0.0, 0.35), // ✅ Positionné plus haut
                    child: FadeTransition(
                      opacity: _textOpacityAnimation,
                      child: SlideTransition(
                        position: _textSlideAnimation,
                        child: Image.asset(
                          'assets/splash/3.png',
                          width: textWidth,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}