// lib/pages/widgets/hero_section.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'slide_item.dart';
import '../../providers/hero_provider.dart';

class HeroSection extends StatefulWidget {
  final bool isArabic;
  const HeroSection({super.key, required this.isArabic});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection>
    with AutomaticKeepAliveClientMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer(HeroProvider heroProvider) {
    _timer?.cancel();
    final slides = heroProvider.slides;
    if (slides.length > 1) {
      _timer = Timer.periodic(
        Duration(milliseconds: (heroProvider.slideDuration * 1000).round()),
        (Timer timer) {
          if (mounted) {
            setState(() {
              _currentPage = (_currentPage + 1) % slides.length;
            });
            if (_pageController.hasClients) {
              _pageController.animateToPage(
                _currentPage,
                duration: Duration(
                  milliseconds: (heroProvider.transitionDuration * 1000).round(),
                ),
                curve: _getAnimationCurve(heroProvider.animationType),
              );
            }
          }
        },
      );
    }
  }

  Curve _getAnimationCurve(String animationType) {
    switch (animationType) {
      case 'fade':
        return Curves.easeInOut;
      case 'slide':
        return Curves.easeOutCubic;
      case 'scroll':
      default:
        return Curves.easeInOutCubic;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    // ✅ Écouter les changements du provider
    final heroProvider = Provider.of<HeroProvider>(context);
    final slides = heroProvider.slides;
    final isArabic = widget.isArabic;
    
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;

    final double sliderHeight = isMobile
        ? screenHeight - 70
        : screenHeight * 0.75;

    // Démarrer le timer si les slides changent
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTimer(heroProvider);
    });

    if (!heroProvider.isInitialized) {
      return Container(
        height: sliderHeight,
        color: Colors.grey[900],
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xffd57653)),
          ),
        ),
      );
    }

    if (slides.isEmpty) {
      return Container(
        height: sliderHeight,
        color: Colors.grey[900],
        child: Center(
          child: Text(
            isArabic ? 'لا توجد شرائح لعرضها' : 'Aucun slide à afficher',
            style: const TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: sliderHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: Stack(
          children: [
            // Carrousel
            PageView.builder(
              controller: _pageController,
              onPageChanged: (int index) {
                setState(() => _currentPage = index);
                _startTimer(heroProvider);
              },
              itemCount: slides.length,
              itemBuilder: (context, index) {
                return _buildSlide(context, index, heroProvider);
              },
              scrollDirection: Axis.horizontal,
              reverse: heroProvider.animationDirection == 'rightToLeft',
            ),

            // Overlay
            Positioned.fill(child: GestureDetector(onTap: () {})),

            // Flèches de navigation
            if (slides.length > 1) ...[
              Positioned(
                left: isMobile ? 4 : 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _buildNavigationButton(
                    icon: isArabic ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
                    isLeft: true,
                    isRtl: isArabic,
                    isMobile: isMobile,
                    onPressed: () => _previousPage(heroProvider),
                  ),
                ),
              ),
              Positioned(
                right: isMobile ? 4 : 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _buildNavigationButton(
                    icon: isArabic ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
                    isLeft: false,
                    isRtl: isArabic,
                    isMobile: isMobile,
                    onPressed: () => _nextPage(heroProvider),
                  ),
                ),
              ),
            ],

            // Indicateurs
            Positioned(
              bottom: isMobile ? 16 : 30,
              right: 20,
              left: 20,
              child: Row(
                mainAxisAlignment: isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [_buildPageIndicators(slides.length)],
              ),
            ),

            // Progression
            Positioned(
              bottom: isMobile ? 16 : 30,
              left: isArabic ? 20 : null,
              right: isArabic ? null : 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentPage + 1} / ${slides.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(BuildContext context, int index, HeroProvider heroProvider) {
    final slide = heroProvider.slides[index];
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isRtl = widget.isArabic;

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackgroundImage(slide, index),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.75),
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3, 0.6],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [Colors.transparent, Colors.black.withOpacity(0.1)],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 60,
              vertical: isMobile ? 20 : 40,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xffd57653).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isRtl ? 'مميز' : 'Featured',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isRtl ? slide.titleAr : slide.titleFr,
                  style: TextStyle(
                    fontSize: isMobile ? 28 : 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                    letterSpacing: isMobile ? 0 : 0.5,
                    shadows: [
                      Shadow(
                        offset: const Offset(2, 2),
                        blurRadius: 10,
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ],
                  ),
                  textAlign: isRtl ? TextAlign.right : TextAlign.left,
                ),
                const SizedBox(height: 8),
                Text(
                  isRtl ? slide.subtitleAr : slide.subtitleFr,
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 22,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                    shadows: [
                      Shadow(
                        offset: const Offset(1, 1),
                        blurRadius: 8,
                        color: Colors.black.withOpacity(0.2),
                      ),
                    ],
                  ),
                  textAlign: isRtl ? TextAlign.right : TextAlign.left,
                ),
                const SizedBox(height: 16),
                _buildActionButton(isMobile, isRtl),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildBackgroundImage(SlideItem slide, int index) {
  try {
    print('🖼️ [Hero] Affichage slide $index: isAsset=${slide.isAsset}, imagePath=${slide.imagePath}, hasBytes=${slide.imageBytes != null}');
    
    if (slide.isAsset) {
      print('📁 [Hero] Image asset: ${slide.imagePath}');
      return Image.asset(
        slide.imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          print('❌ [Hero] Erreur asset: $error');
          return _buildFallbackBackground(index);
        },
      );
    }

    if (slide.imageBytes != null && slide.imageBytes!.isNotEmpty) {
      print('💾 [Hero] Image memory: ${slide.imageBytes!.length} bytes');
      return Image.memory(
        slide.imageBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          print('❌ [Hero] Erreur memory: $error');
          return _buildFallbackBackground(index);
        },
      );
    }

    if (slide.imagePath.startsWith('http')) {
      print('🌐 [Hero] Image network: ${slide.imagePath}');
      return Image.network(
        slide.imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[900],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                color: const Color(0xffd57653),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('❌ [Hero] Erreur network: $error');
          return _buildFallbackBackground(index);
        },
      );
    }

    print('⚠️ [Hero] Aucune image valide, fallback');
    return _buildFallbackBackground(index);
  } catch (e) {
    print('❌ [Hero] Exception: $e');
    return _buildFallbackBackground(index);
  }
}

  Widget _buildFallbackBackground(int index) {
    final List<List<Color>> gradients = [
      [const Color(0xffd57653), const Color(0xff994a2b)],
      [const Color(0xff2c221e), const Color(0xff7c6e68)],
      [const Color(0xff994a2b), const Color(0xff2c221e)],
    ];

    final colors = gradients[index % gradients.length];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          size: 50,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildActionButton(bool isMobile, bool isRtl) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xffd57653), Color(0xffe8987a)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffd57653).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isRtl ? 'اكتشف المزيد' : 'Découvrir plus'),
              backgroundColor: const Color(0xffd57653),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 24 : 36,
            vertical: isMobile ? 14 : 18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isRtl ? 'اكتشف المزيد' : 'Découvrir',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isRtl ? Icons.arrow_back : Icons.arrow_forward,
              size: isMobile ? 16 : 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicators(int slideCount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(slideCount, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: _currentPage == index ? 24 : 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? const Color(0xffd57653)
                : Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required bool isLeft,
    required bool isRtl,
    bool isMobile = false,
    required VoidCallback onPressed,
  }) {
    final double iconSize = isMobile ? 18 : 24;
    final double buttonSize = isMobile ? 36 : 48;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: iconSize),
        onPressed: onPressed,
        padding: EdgeInsets.all(isMobile ? 6 : 10),
        constraints: BoxConstraints(minWidth: buttonSize, minHeight: buttonSize),
        style: IconButton.styleFrom(
          backgroundColor: Colors.transparent,
          hoverColor: const Color(0xffd57653).withOpacity(0.3),
        ),
      ),
    );
  }

  void _nextPage(HeroProvider heroProvider) {
    if (_pageController.hasClients) {
      final int nextPage = (_currentPage + 1) % heroProvider.slides.length;
      _pageController.animateToPage(
        nextPage,
        duration: Duration(milliseconds: (heroProvider.transitionDuration * 1000).round()),
        curve: _getAnimationCurve(heroProvider.animationType),
      );
    }
  }

  void _previousPage(HeroProvider heroProvider) {
    if (_pageController.hasClients) {
      final int prevPage = (_currentPage - 1) % heroProvider.slides.length;
      _pageController.animateToPage(
        prevPage < 0 ? heroProvider.slides.length - 1 : prevPage,
        duration: Duration(milliseconds: (heroProvider.transitionDuration * 1000).round()),
        curve: _getAnimationCurve(heroProvider.animationType),
      );
    }
  }
}