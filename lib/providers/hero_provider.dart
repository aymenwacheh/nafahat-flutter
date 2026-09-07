// lib/providers/hero_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../pages/widgets/slide_item.dart';

class HeroProvider extends ChangeNotifier {
  // Configuration
  String _animationType = 'scroll';
  String _animationDirection = 'leftToRight';
  double _slideDuration = 5.0;
  double _transitionDuration = 0.8;
  
  // Slides
  List<SlideItem> _slides = [];
  bool _isInitialized = false;

  // Getters
  String get animationType => _animationType;
  String get animationDirection => _animationDirection;
  double get slideDuration => _slideDuration;
  double get transitionDuration => _transitionDuration;
  List<SlideItem> get slides => _slides;
  bool get isInitialized => _isInitialized;

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

  // Initialisation
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Charger la configuration
      _animationType = prefs.getString('hero_animation_type') ?? 'scroll';
      _animationDirection = prefs.getString('hero_animation_direction') ?? 'leftToRight';
      _slideDuration = prefs.getDouble('hero_slide_duration') ?? 5.0;
      _transitionDuration = prefs.getDouble('hero_transition_duration') ?? 0.8;

      // Charger les slides
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
      } else {
        _slides = List.from(_defaultSlides);
        await _saveSlidesToPrefs();
      }
      
      _isInitialized = true;
      notifyListeners();
      print('✅ HeroProvider initialisé avec ${_slides.length} slides');
    } catch (e) {
      print('❌ Erreur initialisation HeroProvider: $e');
      _slides = List.from(_defaultSlides);
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Mettre à jour la configuration
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
      print('✅ Configuration Hero mise à jour');
    } catch (e) {
      print('❌ Erreur mise à jour config Hero: $e');
    }
  }

  // Mettre à jour les slides
  void updateSlides(List<SlideItem> newSlides) async {
    try {
      _slides = newSlides;
      await _saveSlidesToPrefs();
      notifyListeners();
      print('✅ Slides Hero mis à jour: ${_slides.length} slides');
    } catch (e) {
      print('❌ Erreur mise à jour slides Hero: $e');
    }
  }

  // Sauvegarder les slides dans SharedPreferences
  Future<void> _saveSlidesToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> jsonList = 
          _slides.map((slide) => slide.toJson()).toList();
      await prefs.setString('hero_slides', json.encode(jsonList));
      
      // Sauvegarder les images
      for (var slide in _slides) {
        if (!slide.isAsset && 
            slide.imageBytes != null && 
            slide.imagePath.startsWith('hero_image_')) {
          final String base64Image = base64Encode(slide.imageBytes!);
          await prefs.setString(slide.imagePath, base64Image);
        }
      }
    } catch (e) {
      print('❌ Erreur sauvegarde slides: $e');
    }
  }

  // Réinitialiser à la configuration par défaut
  Future<void> resetToDefault() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Supprimer toutes les données
      await prefs.remove('hero_animation_type');
      await prefs.remove('hero_animation_direction');
      await prefs.remove('hero_slide_duration');
      await prefs.remove('hero_transition_duration');
      await prefs.remove('hero_slides');
      
      // Supprimer les images stockées
      for (var slide in _slides) {
        if (!slide.isAsset && slide.imagePath.startsWith('hero_image_')) {
          await prefs.remove(slide.imagePath);
        }
      }
      
      // Recharger les valeurs par défaut
      _animationType = 'scroll';
      _animationDirection = 'leftToRight';
      _slideDuration = 5.0;
      _transitionDuration = 0.8;
      _slides = List.from(_defaultSlides);
      
      await _saveSlidesToPrefs();
      notifyListeners();
      print('✅ Hero réinitialisé aux valeurs par défaut');
    } catch (e) {
      print('❌ Erreur réinitialisation Hero: $e');
    }
  }
}