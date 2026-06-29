import 'dart:async';
import 'package:flutter/material.dart';

class HeroSection extends StatefulWidget {
  final bool isArabic;
  const HeroSection({super.key, required this.isArabic});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, String>> _slideData = [
    {
      "titleFr": "Propulsez Votre Carrière Vers l'Excellence",
      "titleAr": "صمّم مستقبلك بأكاديميّتنا الرقمية",
      "subtitleFr": "Des cursus d'élite conçus par des experts.",
      "subtitleAr": "برامج تعليمية متميزة مصممة خصيصاً لقادة الغد.",
      "image": "assets/images/slide1.png",
    },
    {
      "titleFr": "Maîtrisez l'Intelligence Artificielle",
      "titleAr": "أيقظ مهاراتك في الذكاء الاصطناعي",
      "subtitleFr": "Devenez acteur de la révolution technologique.",
      "subtitleAr": "كن جزءاً من الثورة التكنولوجية القادمة.",
      "image": "assets/images/slide2.jpg",
    },
    {
      "titleFr": "Un Héritage Allié à la Modernité",
      "titleAr": "إبداع مفاهيمي يجمع الأصالة بالحداثة",
      "subtitleFr": "Le design global sous un nouveau prisme.",
      "subtitleAr": "منظور جديد للتصميم الشامل والهندسة الحديثة.",
      "image": "assets/images/slide3.jpg",
    },
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < _slideData.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Hauteur adaptative
    final double sliderHeight = isMobile ? 280 : 450;

    return Container(
      width: double.infinity, // ✅ Pleine largeur
      height: sliderHeight,
      margin: EdgeInsets.zero, // ✅ Plus de marge
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.zero, // ✅ Coins droits sur toute la largeur
        child: Stack(
          children: [
            // Carrousel
            PageView.builder(
              controller: _pageController,
              onPageChanged:
                  (int index) => setState(() => _currentPage = index),
              itemCount: _slideData.length,
              itemBuilder: (context, index) {
                final slide = _slideData[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      slide["image"]!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors:
                                  index == 0
                                      ? [
                                        const Color(0xffd57653),
                                        const Color(0xff994a2b),
                                      ]
                                      : index == 1
                                      ? [
                                        const Color(0xff2c221e),
                                        const Color(0xff7c6e68),
                                      ]
                                      : [
                                        const Color(0xff994a2b),
                                        const Color(0xff2c221e),
                                      ],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "Impossible de charger : ${slide["image"]}",
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        );
                      },
                    ),
                    // Dégradé sombre
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.75),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    // Textes
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 20 : 50,
                        vertical: 24,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isArabic
                                ? slide["titleAr"]!
                                : slide["titleFr"]!,
                            style: TextStyle(
                              fontSize: isMobile ? 22 : 38,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.isArabic
                                ? slide["subtitleAr"]!
                                : slide["subtitleFr"]!,
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 18,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            // Indicateurs (dots)
            Positioned(
              bottom: 20,
              right: widget.isArabic ? null : 20,
              left: widget.isArabic ? 20 : null,
              child: Row(
                children: List.generate(_slideData.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentPage == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color:
                          _currentPage == index
                              ? const Color(0xffd57653)
                              : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
