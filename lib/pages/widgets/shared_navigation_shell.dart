import 'package:flutter/material.dart';

/// Route compatible avec l'architecture existante.
/// Elle se comporte comme un MaterialPageRoute standard et n'ajoute aucun
/// layout/navigation autour des pages.
class NafahatPageRoute<T> extends MaterialPageRoute<T> {
  NafahatPageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) : super(
          builder: builder,
          settings: settings,
          maintainState: maintainState,
          fullscreenDialog: fullscreenDialog,
        );
}

/// Conservé uniquement pour compatibilité avec d'anciens imports.
/// Aucun layout n'est ajouté : le widget retourne directement son enfant.
class SharedNavigationShell extends StatelessWidget {
  const SharedNavigationShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
