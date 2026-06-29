import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'landing_page.dart'; // Importe ta page principale pour la redirection

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Redirection automatique vers la LandingPage après 4,5 secondes
    Timer(const Duration(milliseconds: 4500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LandingPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fond blanc cassé chaud (similaire à ta LandingPage)
      backgroundColor: const Color(0xfffcfbfa), 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Conteneur pour le cercle calligraphique
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: const Color(0xffd57653).withOpacity(0.2), // Teinte terracotta
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Directionality(
                textDirection: TextDirection.rtl, // Obligatoire pour l'arabe
                child: AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      'نفحات',
                      textStyle: GoogleFonts.arefRuqaa(
                        fontSize: 65,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff0f3433), // Couleur bleu/vert sombre chic comme ton image
                      ),
                      // Vitesse d'écriture (plus la valeur est basse, plus c'est rapide)
                      speed: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                  ],
                  totalRepeatCount: 1, // On ne l'écrit qu'une seule fois
                  displayFullTextOnTap: true,
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Petit indicateur de chargement discret et élégant
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Color(0xffd57653),
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}