import 'package:flutter/widgets.dart';

/// Marqueur qui empêche d'empiler plusieurs navigations pour une même page.
class SharedNavigationScope extends InheritedWidget {
  const SharedNavigationScope({super.key, required super.child});
  static bool contains(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SharedNavigationScope>() != null;
  @override
  bool updateShouldNotify(SharedNavigationScope oldWidget) => false;
}
