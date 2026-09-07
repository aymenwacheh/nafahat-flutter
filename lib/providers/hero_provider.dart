// lib/providers/hero_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../pages/widgets/slide_item.dart';

class HeroProvider extends ChangeNotifier {
  String _animationType = 'scroll';
  String _animationDirection = 'leftToRight';
  double _slideDuration = 5.0;
  double _transitionDuration = 0.8;
  List<SlideItem> _slides = [];
  bool _isInitialized = false;

  String get animationType => _animationType;
  String get animationDirection => _animationDirection;
  double get slideDuration => _slideDuration;
  double get transitionDuration => _transitionDuration;
  List<SlideItem> get slides => _slides;
  bool get isInitialized => _isInitialized;

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

  Future<void> init() async {
    try {
      print('🔄 [HeroProvider] Début initialisation...');
      final prefs = await SharedPreferences.getInstance();
      
      _animationType = prefs.getString('hero_animation_type') ?? 'scroll';
      _animationDirection = prefs.getString('hero_animation_direction') ?? 'leftToRight';
      _slideDuration = prefs.getDouble('hero_slide_duration') ?? 5.0;
      _transitionDuration = prefs.getDouble('hero_transition_duration') ?? 0.8;

      final String? slidesJson = prefs.getString('hero_slides');
      
      if (slidesJson != null && slidesJson.isNotEmpty) {
        final List<dynamic> decoded = json.decode(slidesJson);
        final List<SlideItem> loadedSlides = [];
        
        for (final item in decoded) {
          SlideItem slide = SlideItem.fromJson(item);
          slide = await SlideItem.resolveImageBytes(slide, prefs);
          loadedSlides.add(slide);
        }
        _slides = loadedSlides;
        print('✅ [HeroProvider] ${_slides.length} slides chargés depuis SharedPreferences');
      } else {
        _slides = List.from(_defaultSlides);
        await _saveSlidesToPrefs();
        print('✅ [HeroProvider] Slides par défaut chargés');
      }
      
      _isInitialized = true;
      print('✅ [HeroProvider] Initialisation terminée, notifyListeners()');
      notifyListeners();
    } catch (e) {
      print('❌ [HeroProvider] Erreur: $e');
      _slides = List.from(_defaultSlides);
      _isInitialized = true;
      notifyListeners();
    }
  }

  void updateConfig({
    String? animationType,
    String? animationDirection,
    double? slideDuration,
    double? transitionDuration,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (animationType != null) {
        _animationType = animationType;
        await prefs.setString('hero_animation_type', animationType);
      }
      if (animationDirection != null) {
        _animationDirection = animationDirection;
        await prefs.setString('hero_animation_direction', animationDirection);
      }
      if (slideDuration != null) {
        _slideDuration = slideDuration;
        await prefs.setDouble('hero_slide_duration', slideDuration);
      }
      if (transitionDuration != null) {
        _transitionDuration = transitionDuration;
        await prefs.setDouble('hero_transition_duration', transitionDuration);
      }
      
      notifyListeners();
      print('✅ [HeroProvider] Config mise à jour');
    } catch (e) {
      print('❌ [HeroProvider] Erreur updateConfig: $e');
    }
  }

  void updateSlides(List<SlideItem> newSlides) async {
    try {
      _slides = newSlides;
      await _saveSlidesToPrefs();
      notifyListeners();
      print('✅ [HeroProvider] ${_slides.length} slides mis à jour');
    } catch (e) {
      print('❌ [HeroProvider] Erreur updateSlides: $e');
    }
  }

  Future<void> _saveSlidesToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> jsonList = 
          _slides.map((slide) => slide.toJson()).toList();
      await prefs.setString('hero_slides', json.encode(jsonList));
      
      for (var slide in _slides) {
        if (!slide.isAsset && 
            slide.imageBytes != null && 
            slide.imagePath.startsWith('hero_image_')) {
          final String base64Image = base64Encode(slide.imageBytes!);
          await prefs.setString(slide.imagePath, base64Image);
        }
      }
    } catch (e) {
      print('❌ [HeroProvider] Erreur saveSlides: $e');
    }
  }

  Future<void> resetToDefault() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove('hero_animation_type');
      await prefs.remove('hero_animation_direction');
      await prefs.remove('hero_slide_duration');
      await prefs.remove('hero_transition_duration');
      await prefs.remove('hero_slides');
      
      for (var slide in _slides) {
        if (!slide.isAsset && slide.imagePath.startsWith('hero_image_')) {
          await prefs.remove(slide.imagePath);
        }
      }
      
      _animationType = 'scroll';
      _animationDirection = 'leftToRight';
      _slideDuration = 5.0;
      _transitionDuration = 0.8;
      _slides = List.from(_defaultSlides);
      
      await _saveSlidesToPrefs();
      notifyListeners();
      print('✅ [HeroProvider] Réinitialisé');
    } catch (e) {
      print('❌ [HeroProvider] Erreur reset: $e');
    }
  }
}