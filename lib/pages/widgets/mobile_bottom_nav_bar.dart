import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:nafahat/providers/language_provider.dart';
import 'package:nafahat/providers/user_provider.dart';
import 'package:nafahat/services/payment_notification_service.dart';
import 'package:nafahat/services/landing_appearance_manager.dart';

/// Contrôle uniquement la visibilité de la barre inférieure.
///
/// La barre apparaît quand l'utilisateur fait défiler la page vers le bas,
/// et disparaît lorsqu'il remonte ou revient en haut de la page.
class MobileBottomNavController {
  MobileBottomNavController._();

  static final ValueNotifier<bool> visible = ValueNotifier<bool>(false);

  static double _downDistance = 0;

  static bool handleScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    final pixels = notification.metrics.pixels;
    if (pixels <= 20) {
      _downDistance = 0;
      hide();
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;

      if (delta > 0) {
        _downDistance += delta;
        if (_downDistance >= 10) {
          show();
        }
      } else if (delta < 0) {
        _downDistance = 0;
        hide();
      }
    } else if (notification is OverscrollNotification) {
      if (notification.overscroll > 0) {
        _downDistance += notification.overscroll;
        if (_downDistance >= 10) show();
      } else if (notification.overscroll < 0) {
        _downDistance = 0;
        hide();
      }
    }

    return false;
  }

  static void show() {
    if (!visible.value) visible.value = true;
  }

  static void hide() {
    if (visible.value) visible.value = false;
  }

  static void reset() {
    _downDistance = 0;
    hide();
  }
}

/// Barre de navigation mobile inspirée des barres Facebook / Instagram.
///
/// Elle ne modifie aucune route existante : elle utilise uniquement les routes
/// déjà présentes dans l'application.
class MobileBottomNav extends StatefulWidget {
  const MobileBottomNav({super.key});

  @override
  State<MobileBottomNav> createState() => _MobileBottomNavState();
}

class _MobileBottomNavState extends State<MobileBottomNav> {
  Timer? _refreshTimer;
  bool _loadingNotifications = false;
  String? _observedUserId;
  List<PaymentNotification> _notifications = const [];

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => _syncNotifications(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncNotifications();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _syncNotifications() async {
    if (!mounted || _loadingNotifications) return;

    final user = context.read<UserProvider>();
    final userId = user.userId;

    if (!user.isLoggedIn || userId == null || userId.isEmpty) {
      if (_notifications.isNotEmpty && mounted) {
        setState(() => _notifications = const []);
      }
      return;
    }

    _loadingNotifications = true;
    try {
      final values =
          await PaymentNotificationService.getUnreadNotifications(userId);
      if (!mounted || context.read<UserProvider>().userId != userId) return;
      setState(() => _notifications = values);
    } finally {
      _loadingNotifications = false;
    }
  }

  Future<void> _openNotifications() async {
    final user = context.read<UserProvider>();
    final isArabic = context.read<LanguageProvider>().isArabic;
    final userId = user.userId;

    if (!user.isLoggedIn || userId == null || userId.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(isArabic ? 'الإشعارات' : 'Notifications'),
          content: Text(
            isArabic
                ? 'يرجى تسجيل الدخول للاطلاع على إشعارات الدفع.'
                : 'Veuillez vous connecter pour consulter vos notifications de paiement.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(isArabic ? 'إغلاق' : 'Fermer'),
            ),
          ],
        ),
      );
      return;
    }

    await _syncNotifications();
    if (!mounted) return;

    final items = List<PaymentNotification>.from(_notifications);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(
              Icons.notifications_active_rounded,
              color: Color(0xFFD62828),
            ),
            const SizedBox(width: 10),
            Text(isArabic ? 'إشعارات الدفع' : 'Notifications de paiement'),
          ],
        ),
        content: SizedBox(
          width: 430,
          child: items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    isArabic
                        ? 'لا توجد آجال دفع قريبة حالياً.'
                        : 'Aucune échéance de paiement proche actuellement.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 18),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final validated = item.type == 'payment_validated';
                    final formation = item.formationTitle(isArabic);

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          validated
                              ? Icons.verified_rounded
                              : Icons.schedule_rounded,
                          color: validated
                              ? Colors.green.shade700
                              : const Color(0xFFD62828),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                validated
                                    ? (isArabic
                                        ? 'تم تأكيد الدفع'
                                        : 'Paiement validé')
                                    : (isArabic
                                        ? 'يرجى تسوية الدفعة'
                                        : 'Merci de régler votre paiement'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(item.message(isArabic)),
                              if (formation != null) ...[
                                const SizedBox(height: 3),
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
            child: Text(isArabic ? 'إغلاق' : 'Fermer'),
          ),
        ],
      ),
    );

    if (items.isNotEmpty && mounted) {
      await PaymentNotificationService.markAsRead(userId, items);
      if (mounted) setState(() => _notifications = const []);
    }
  }

  void _goTo(String route) {
    MobileBottomNavController.hide();
    Navigator.pushNamed(context, route);
  }

  void _goHome() {
    MobileBottomNavController.hide();
    Navigator.pushNamedAndRemoveUntil(context, '/landing', (route) => false);
  }

  Widget _iconButton({
    required String tooltip,
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: onTap,
            child: SizedBox(
              height: 50,
              child: Center(child: icon),
            ),
          ),
        ),
      ),
    );
  }

  Widget _coloredIcon(IconData icon, Color color) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 25),
    );
  }

  Widget _notificationIcon(Color color, Color surface) {
    final count = _notifications.length;

    return SizedBox(
      width: 42,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          _coloredIcon(Icons.notifications_none_rounded, color),
          if (count > 0)
            Positioned(
              right: 0,
              top: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFD00000),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: surface, width: 1.5),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _profileIcon(UserProvider user, Color primary) {
    final displayName = user.displayName.trim();
    final initial = user.isLoggedIn && displayName.isNotEmpty
        ? displayName.substring(0, 1).toUpperCase()
        : '?';

    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primary.withOpacity(0.12),
        border: Border.all(color: primary, width: 2),
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: primary,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 850) return const SizedBox.shrink();

    final user = context.watch<UserProvider>();
    final isArabic = context.watch<LanguageProvider>().isArabic;
    final appearance = LandingAppearanceManager().config;
    final surface = appearance.sectionBackgroundColor;
    final primary = appearance.primaryColor;
    final accent = appearance.accentColor;
    final muted = appearance.mutedTextColor;

    if (_observedUserId != user.userId) {
      _observedUserId = user.userId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncNotifications();
      });
    }

    return ValueListenableBuilder<bool>(
      valueListenable: MobileBottomNavController.visible,
      builder: (context, visible, _) {
        final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
        final show = visible && !keyboardOpen;

        return IgnorePointer(
          ignoring: !show,
          child: ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 190),
              curve: Curves.easeOutCubic,
              alignment: Alignment.bottomCenter,
              child: show
                  ? SafeArea(
                      top: false,
                      minimum: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Container(
                            height: 62,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: muted.withOpacity(.22),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                    appearance.themeMode == 'dark' ? .28 : .10,
                                  ),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              textDirection: TextDirection.ltr,
                              children: [
                                // 1. Formation
                                _iconButton(
                                  tooltip:
                                      isArabic ? 'التكوينات' : 'Formations',
                                  icon: _coloredIcon(
                                    Icons.school_outlined,
                                    accent,
                                  ),
                                  onTap: () => _goTo('/formations'),
                                ),
                                // 2. Accueil
                                _iconButton(
                                  tooltip: isArabic ? 'الرئيسية' : 'Accueil',
                                  icon: _coloredIcon(
                                    Icons.home_rounded,
                                    primary,
                                  ),
                                  onTap: _goHome,
                                ),
                                // 3. Notifications
                                _iconButton(
                                  tooltip:
                                      isArabic ? 'إشعارات الدفع' : 'Paiements',
                                  icon: _notificationIcon(accent, surface),
                                  onTap: _openNotifications,
                                ),
                                // 4. Profil
                                _iconButton(
                                  tooltip:
                                      isArabic ? 'الملف الشخصي' : 'Profil',
                                  icon: _profileIcon(user, primary),
                                  onTap: () => _goTo(
                                    user.isLoggedIn ? '/profile' : '/auth',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(
                      width: double.infinity,
                      height: 0,
                    ),
            ),
          ),
        );
      },
    );
  }
}
