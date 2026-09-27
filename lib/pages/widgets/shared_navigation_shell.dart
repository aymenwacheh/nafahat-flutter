import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:nafahat/providers/language_provider.dart';
import 'package:nafahat/providers/user_provider.dart';
import 'package:nafahat/services/payment_notification_service.dart';

import 'nafahat_scroll_bar.dart';
import 'navbar.dart';
import 'shared_navigation_scope.dart';

/// Route commune, y compris pour les pages ouvertes sans nom de route.
class NafahatPageRoute<T> extends MaterialPageRoute<T> {
  NafahatPageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) : super(
          builder: (context) => SharedNavigationShell(child: builder(context)),
          settings: settings,
          maintainState: maintainState,
          fullscreenDialog: fullscreenDialog,
        );
}

class SharedNavigationShell extends StatefulWidget {
  const SharedNavigationShell({super.key, required this.child});

  final Widget child;

  @override
  State<SharedNavigationShell> createState() => _SharedNavigationShellState();
}

class _SharedNavigationShellState extends State<SharedNavigationShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _visible = ValueNotifier<bool>(false);
  ScrollPosition? _position;
  double _distance = 0;

  Timer? _notificationTimer;
  bool _notificationRequestInProgress = false;
  String? _observedUserId;
  List<PaymentNotification> _notifications = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncNotifications());
    _notificationTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => _syncNotifications(),
    );
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    _visible.dispose();
    super.dispose();
  }

  Future<void> _syncNotifications() async {
    if (!mounted || _notificationRequestInProgress) return;

    final user = context.read<UserProvider>();
    final userId = user.userId;

    if (!user.isLoggedIn || userId == null || userId.isEmpty) {
      if (_notifications.isNotEmpty && mounted) {
        setState(() => _notifications = const []);
      }
      return;
    }

    _notificationRequestInProgress = true;
    try {
      final unread = await PaymentNotificationService.getUnreadNotifications(
        userId,
      );
      if (!mounted || context.read<UserProvider>().userId != userId) return;
      setState(() => _notifications = unread);
    } finally {
      _notificationRequestInProgress = false;
    }
  }

  bool _onScroll(ScrollNotification event) {
    if (event.depth != 0 || event.metrics.axis != Axis.vertical) return false;
    if (event.context != null) {
      _position = Scrollable.maybeOf(event.context!)?.position;
    }
    final offset = event.metrics.pixels;
    if (offset <= 24) {
      _distance = 0;
      _visible.value = false;
      return false;
    }
    if (event is ScrollUpdateNotification) {
      final delta = event.scrollDelta ?? 0;
      if (delta == 0 || offset > event.metrics.maxScrollExtent) return false;
      if ((_distance > 0 && delta < 0) || (_distance < 0 && delta > 0)) {
        _distance = 0;
      }
      _distance += delta;
      if (offset >= 80 && _distance >= 12) _visible.value = true;
      if (_distance <= -12) _visible.value = false;
    }
    return false;
  }

  String get _routeName => ModalRoute.of(context)?.settings.name ?? '';

  int? get _selectedIndex {
    final name = widget.child.runtimeType.toString();
    if (_routeName == '/landing' || name == 'LandingPage') return 0;
    if (_routeName == '/videos' || name == 'AllVideoPage') return 1;
    if (_routeName == '/formateurs' || name == 'FormateursPage') return 2;
    if (_routeName == '/formations' || name == 'FormationsPage') return 3;
    if (_routeName == '/profile' || name == 'ProfileDashboardPage') return 5;
    return null;
  }

  Future<void> _showNotifications() async {
    final user = context.read<UserProvider>();
    final ar = context.read<LanguageProvider>().isArabic;
    final userId = user.userId;

    if (!user.isLoggedIn || userId == null || userId.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(ar ? 'الإشعارات' : 'Notifications'),
          content: Text(
            ar
                ? 'سجّل الدخول لعرض إشعارات الدفع.'
                : 'Connectez-vous pour consulter vos notifications de paiement.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(ar ? 'إغلاق' : 'Fermer'),
            ),
          ],
        ),
      );
      return;
    }

    await _syncNotifications();
    if (!mounted) return;

    final items = List<PaymentNotification>.from(_notifications);

    if (items.isNotEmpty) {
      await PaymentNotificationService.markAsRead(userId, items);
      if (mounted) setState(() => _notifications = const []);
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
        contentPadding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
        actionsPadding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        title: Row(
          children: [
            const Icon(Icons.notifications_active_outlined),
            const SizedBox(width: 10),
            Text(ar ? 'الإشعارات' : 'Notifications'),
          ],
        ),
        content: SizedBox(
          width: 430,
          child: items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    ar
                        ? 'لا توجد إشعارات دفع جديدة.'
                        : 'Aucune nouvelle notification de paiement.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 18),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final formation = item.formationTitle(ar);
                    final validated = item.type == 'payment_validated';
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: validated
                                ? Colors.green.withOpacity(0.10)
                                : Colors.orange.withOpacity(0.10),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            validated
                                ? Icons.verified_outlined
                                : Icons.schedule_rounded,
                            size: 21,
                            color: validated
                                ? Colors.green.shade700
                                : Colors.orange.shade800,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title(ar),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(item.message(ar)),
                              if (formation != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  formation,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(ar ? 'إغلاق' : 'Fermer'),
          ),
        ],
      ),
    );
  }

  void _navigate(int index) {
    final navigator = Navigator.of(context);
    if (index == 0) {
      if (_selectedIndex == 0 && _position != null && _position!.hasPixels) {
        _visible.value = false;
        _position!.animateTo(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      } else {
        navigator.pushNamedAndRemoveUntil('/landing', (route) => false);
      }
    } else if (index == 1) {
      if (_selectedIndex != 1) navigator.pushNamed('/videos');
    } else if (index == 2) {
      if (_selectedIndex != 2) navigator.pushNamed('/formateurs');
    } else if (index == 3) {
      if (_selectedIndex != 3) navigator.pushNamed('/formations');
    } else if (index == 4) {
      _showNotifications();
    } else {
      if (_selectedIndex != 5) {
        navigator.pushNamed(
          context.read<UserProvider>().isLoggedIn ? '/profile' : '/auth',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Le splash conserve sa présentation de démarrage, sans navigation.
    if (SharedNavigationScope.contains(context) ||
        widget.child.runtimeType.toString() == 'SplashScreen') {
      return widget.child;
    }

    final ar = context.watch<LanguageProvider>().isArabic;
    final user = context.watch<UserProvider>();
    final currentUserId = user.userId;

    if (_observedUserId != currentUserId) {
      _observedUserId = currentUserId;
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncNotifications());
    }

    final mobile = MediaQuery.of(context).size.width < 850;
    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFFCFBFA),
        drawer: mobile
            ? Navbar(isMobile: true, scaffoldKey: _scaffoldKey)
                .buildDrawer(context)
            : null,
        body: SafeArea(
          child: Column(
            children: [
              // Cette navbar est hors du scope : les copies dans les pages sont masquées.
              Navbar(isMobile: mobile, scaffoldKey: _scaffoldKey),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: _onScroll,
                  child: SharedNavigationScope(
                    child: MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      removeBottom: true,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
              if (mobile)
                ValueListenableBuilder<bool>(
                  valueListenable: _visible,
                  builder: (context, requested, _) {
                    final show = requested &&
                        MediaQuery.of(context).viewInsets.bottom == 0;
                    final name = user.displayName.trim();
                    return ClipRect(
                      child: AnimatedSize(
                        duration: MediaQuery.of(context).disableAnimations
                            ? Duration.zero
                            : const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.bottomCenter,
                        child: show
                            ? NafahatScrollBar(
                                selectedIndex: _selectedIndex,
                                isArabic: ar,
                                initial: user.isLoggedIn && name.isNotEmpty
                                    ? name.characters.first.toUpperCase()
                                    : '?',
                                notificationCount: _notifications.length,
                                onSelected: _navigate,
                              )
                            : const SizedBox(
                                width: double.infinity,
                                height: 0,
                              ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
