// hero_section.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nafahat/pages/adminisration/apparence_hero.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'slide_item.dart';

class HeroSection extends StatefulWidget {
  final bool isArabic;
  const HeroSection({super.key, required this.isArabic});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection>
    with AutomaticKeepAliveClientMixin {
  // Contrôleurs
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  // Configuration chargée depuis SharedPreferences
  String _animationType = 'scroll';
  String _animationDirection = 'leftToRight';
  double _slideDuration = 5.0;
  double _transitionDuration = 0.8;

  // Données des slides
  List<SlideItem> _slides = [];
  bool _isLoading = true;

  // Slides par défaut
  final List<SlideItem> _defaultSlides = [
    SlideItem(
      id: 'default_1',
      titleFr: 'Propulsez Votre Carrière Vers l\'Excellence',
      titleAr: 'صمّم مستقبلك بأكاديميّتنا الرقمية',
      subtitleFr: 'Des cursus d\'élite conçus par des experts.',
      subtitleAr: 'برامج تعليمية متميزة مصممة خصيصاً لقادة الغد.',
      imagePath: 'assets/images/slide1.jpg',
      isAsset: true,
    ),
    SlideItem(
      id: 'default_2',
      titleFr: 'Maîtrisez l\'Intelligence Artificielle',
      titleAr: 'أيقظ مهاراتك في الذكاء الاصطناعي',
      subtitleFr: 'Devenez acteur de la révolution technologique.',
      subtitleAr: 'كن جزءاً من الثورة التكنولوجية القادمة.',
      imagePath: 'assets/images/slide2.jpg',
      isAsset: true,
    ),
    SlideItem(
      id: 'default_3',
      titleFr: 'Un Héritage Allié à la Modernité',
      titleAr: 'إبداع مفاهيمي يجمع الأصالة بالحداثة',
      subtitleFr: 'Le design global sous un nouveau prisme.',
      subtitleAr: 'منظور جديد للتصميم الشامل والهندسة الحديثة.',
      imagePath: 'assets/images/slide3.jpg',
      isAsset: true,
    ),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // Charger toutes les données (config + slides)
  Future<void> _loadAllData() async {
    await _loadConfig();
    await _loadSlides();
    setState(() {
      _isLoading = false;
    });
    _startTimer();
  }

  // Charger la configuration
  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _animationType = prefs.getString('hero_animation_type') ?? 'scroll';
        _animationDirection =
            prefs.getString('hero_animation_direction') ?? 'leftToRight';
        _slideDuration = prefs.getDouble('hero_slide_duration') ?? 5.0;
        _transitionDuration =
            prefs.getDouble('hero_transition_duration') ?? 0.8;
      });
    } catch (e) {
      debugPrint('Erreur chargement config: $e');
    }
  }

  // Charger les slides
  //
  // IMPORTANT : cette méthode lit exactement la même clé SharedPreferences
  // ('hero_slides') que apparence_hero.dart, et applique la même logique de
  // décodage des images base64 via SlideItem.resolveImageBytes. Comme ça,
  // toute image uploadée depuis la page d'admin (web) s'affiche aussi ici.
  Future<void> _loadSlides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? slidesJson = prefs.getString('hero_slides');

      if (slidesJson != null && slidesJson.isNotEmpty) {
        final List<dynamic> decoded = json.decode(slidesJson);
        final List<SlideItem> loadedSlides = [];

        for (final item in decoded) {
          SlideItem slide = SlideItem.fromJson(item);
          slide = await SlideItem.resolveImageBytes(slide, prefs);
          loadedSlides.add(slide);
        }

        if (mounted) {
          setState(() {
            _slides = loadedSlides;
          });
        }
      } else {
        // Utiliser les slides par défaut
        if (mounted) {
          setState(() {
            _slides = List.from(_defaultSlides);
          });
        }
        // Sauvegarder les slides par défaut
        await _saveSlidesToPrefs();
      }
    } catch (e) {
      debugPrint('Erreur chargement slides: $e');
      if (mounted) {
        setState(() {
          _slides = List.from(_defaultSlides);
        });
      }
    }
  }

  // Sauvegarder les slides dans SharedPreferences
  Future<void> _saveSlidesToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> jsonList =
          _slides.map((slide) => slide.toJson()).toList();
      await prefs.setString('hero_slides', json.encode(jsonList));
    } catch (e) {
      debugPrint('Erreur sauvegarde slides: $e');
    }
  }

  // Démarrer le timer de défilement automatique
  void _startTimer() {
    _timer?.cancel();
    if (_slides.length > 1) {
      _timer = Timer.periodic(
        Duration(milliseconds: (_slideDuration * 1000).round()),
        (Timer timer) {
          if (mounted) {
            setState(() {
              _currentPage = (_currentPage + 1) % _slides.length;
            });
            if (_pageController.hasClients) {
              _pageController.animateToPage(
                _currentPage,
                duration: Duration(
                  milliseconds: (_transitionDuration * 1000).round(),
                ),
                curve: _getAnimationCurve(),
              );
            }
          }
        },
      );
    }
  }

  // Obtenir la courbe d'animation selon le type
  Curve _getAnimationCurve() {
    switch (_animationType) {
      case 'fade':
        return Curves.easeInOut;
      case 'slide':
        return Curves.easeOutCubic;
      case 'scroll':
      default:
        return Curves.easeInOutCubic;
    }
  }

  // Obtenir la direction d'animation
  double _getAnimationDirection() {
    switch (_animationDirection) {
      case 'rightToLeft':
        return -1.0;
      case 'topToBottom':
        return 1.0;
      case 'bottomToTop':
        return -1.0;
      case 'leftToRight':
      default:
        return 1.0;
    }
  }

  // Construire un slide
  Widget _buildSlide(BuildContext context, int index) {
    final slide = _slides[index];
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isRtl = widget.isArabic;

    return Container(
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image de fond
          _buildBackgroundImage(slide, index),

          // Dégradé sombre
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

          // Overlay décoratif
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [Colors.transparent, Colors.black.withOpacity(0.1)],
              ),
            ),
          ),

          // Contenu textuel
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 50,
              vertical: isMobile ? 16 : 32,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment:
                  isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Badge ou indicateur
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
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

                // Titre
                Text(
                  isRtl ? slide.titleAr : slide.titleFr,
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 42,
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

                // Sous-titre
                Text(
                  isRtl ? slide.subtitleAr : slide.subtitleFr,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 20,
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

                // Bouton d'action (optionnel)
                _buildActionButton(isMobile, isRtl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Construire l'image de fond
  //
  // Ordre de résolution (identique à la logique de apparence_hero.dart) :
  //   1. Asset déclaré dans pubspec.yaml
  //   2. Bytes en mémoire (image uploadée sur le web, décodée depuis base64)
  //   3. Fichier local (mobile/desktop uniquement — dart:io ne fonctionne
  //      pas sur Flutter Web, donc on ne tente JAMAIS ce chemin sur le web)
  //   4. Dégradé de secours
  Widget _buildBackgroundImage(SlideItem slide, int index) {
    try {
      if (slide.isAsset) {
        return Image.asset(
          slide.imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackBackground(index);
          },
        );
      }

      if (slide.imageBytes != null) {
        return Image.memory(
          slide.imageBytes!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackBackground(index);
          },
        );
      }

      if (!kIsWeb) {
        final File file = File(slide.imagePath);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallbackBackground(index);
            },
          );
        }
      }

      return _buildFallbackBackground(index);
    } catch (e) {
      return _buildFallbackBackground(index);
    }
  }

  // Image de fond de remplacement
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

  // Bouton d'action
  Widget _buildActionButton(bool isMobile, bool isRtl) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xffd57653), const Color(0xffe8987a)],
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
          // Action personnalisée
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isRtl ? 'اكتشف المزيد' : 'Découvrir plus',
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
              ),
              backgroundColor: const Color(0xffd57653),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 24 : 32,
            vertical: isMobile ? 12 : 16,
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

  // Indicateurs de page
  Widget _buildPageIndicators() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_slides.length, (index) {
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
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isRtl = widget.isArabic;

    // Hauteur adaptative
    final double sliderHeight = isMobile ? 280 : 450;

    if (_isLoading) {
      return Container(
        height: sliderHeight,
        color: Colors.grey[900],
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(const Color(0xffd57653)),
          ),
        ),
      );
    }

    if (_slides.isEmpty) {
      return Container(
        height: sliderHeight,
        color: Colors.grey[900],
        child: Center(
          child: Text(
            isRtl ? 'لا توجد شرائح لعرضها' : 'Aucun slide à afficher',
            style: const TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return Container(
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
                _startTimer(); // Réinitialiser le timer
              },
              itemCount: _slides.length,
              itemBuilder: (context, index) {
                return _buildSlide(context, index);
              },
              scrollDirection: Axis.horizontal,
              reverse: _animationDirection == 'rightToLeft',
            ),

            // Overlay pour les contrôles
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  // Action au tap (peut être personnalisée)
                },
              ),
            ),

            // Flèches de navigation (uniquement si > 1 slide)
            if (_slides.length > 1) ...[
              Positioned(
                left: isRtl ? null : 8,
                right: isRtl ? 8 : null,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _buildNavigationButton(
                    icon:
                        isRtl ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
                    isLeft: true,
                    isRtl: isRtl,
                  ),
                ),
              ),
              Positioned(
                left: isRtl ? 8 : null,
                right: isRtl ? null : 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _buildNavigationButton(
                    icon:
                        isRtl ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
                    isLeft: false,
                    isRtl: isRtl,
                  ),
                ),
              ),
            ],

            // Indicateurs de page
            Positioned(
              bottom: 20,
              right: 20,
              left: 20,
              child: Row(
                mainAxisAlignment:
                    isRtl ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [_buildPageIndicators()],
              ),
            ),

            // Indicateur de progression (optionnel)
            Positioned(
              bottom: 20,
              left: isRtl ? 20 : null,
              right: isRtl ? null : 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentPage + 1} / ${_slides.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bouton de navigation
  Widget _buildNavigationButton({
    required IconData icon,
    required bool isLeft,
    required bool isRtl,
  }) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: () {
          if (isLeft) {
            _previousPage();
          } else {
            _nextPage();
          }
        },
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        style: IconButton.styleFrom(
          backgroundColor: Colors.transparent,
          hoverColor: const Color(0xffd57653).withOpacity(0.3),
        ),
      ),
    );
  }

  // Navigation
  void _nextPage() {
    if (_pageController.hasClients) {
      final int nextPage = (_currentPage + 1) % _slides.length;
      _pageController.animateToPage(
        nextPage,
        duration: Duration(milliseconds: (_transitionDuration * 1000).round()),
        curve: _getAnimationCurve(),
      );
    }
  }

  void _previousPage() {
    if (_pageController.hasClients) {
      final int prevPage = (_currentPage - 1) % _slides.length;
      _pageController.animateToPage(
        prevPage < 0 ? _slides.length - 1 : prevPage,
        duration: Duration(milliseconds: (_transitionDuration * 1000).round()),
        curve: _getAnimationCurve(),
      );
    }
  }
}
