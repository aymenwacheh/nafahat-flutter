// lib/services/navigation_service.dart
import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Naviguer vers une route
  static Future<void> navigateTo(String routeName, {Object? arguments}) async {
    await navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
  }

  // Naviguer en remplaçant la page actuelle
  static Future<void> navigateToReplacement(
    String routeName, {
    Object? arguments,
  }) async {
    await navigatorKey.currentState?.pushReplacementNamed(
      routeName,
      arguments: arguments,
    );
  }

  // Naviguer et supprimer toutes les pages précédentes
  static Future<void> navigateToAndRemoveUntil(
    String routeName, {
    Object? arguments,
  }) async {
    await navigatorKey.currentState?.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  // Revenir en arrière
  static void goBack({dynamic result}) {
    navigatorKey.currentState?.pop(result);
  }

  // Revenir vers la page d'accueil (Landing)
  static void goBackToLanding() {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/landing',
      (route) => false,
    );
  }

  // Revenir vers la page d'administration
  static void goBackToAdmin() {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/admin',
      (route) => false,
    );
  }
}
