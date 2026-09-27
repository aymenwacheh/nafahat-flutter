import 'package:flutter/material.dart';

/// Barre capsule de navigation affichée pendant le défilement sur mobile.
class NafahatScrollBar extends StatelessWidget {
  const NafahatScrollBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.initial,
    required this.isArabic,
    this.notificationCount = 0,
  });

  final int? selectedIndex;
  final ValueChanged<int> onSelected;
  final String initial;
  final bool isArabic;
  final int notificationCount;

  List<String> get labels => isArabic
      ? ['الرئيسية', 'الفيديوهات', 'المكونون', 'التكوينات', 'الإشعارات', 'الملف الشخصي']
      : ['Accueil', 'Vidéos', 'Formateurs', 'Formations', 'Notifications', 'Profil'];

  Widget _buildIcon(int index, bool selected) {
    if (index == 5) {
      return Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFEDE0D3),
          border: Border.all(
            color: selected ? const Color(0xFF0866FF) : const Color(0xFF08090B),
            width: 2.5,
          ),
        ),
        child: Text(
          initial,
          maxLines: 1,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF20252B),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final icon = CustomPaint(
      size: const Size(27, 27),
      painter: _TopIcon(index, selected),
    );

    if (index != 4 || notificationCount <= 0) return icon;

    final badgeText = notificationCount > 99 ? '99+' : notificationCount.toString();
    return SizedBox(
      width: 38,
      height: 34,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          icon,
          Positioned(
            right: 0,
            top: -2,
            child: Container(
              constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                badgeText,
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

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: const Color(0xFFEDF0F2)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 14,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Row(
                  textDirection: TextDirection.ltr,
                  children: List.generate(6, (i) {
                    final selected = selectedIndex == i;
                    return Expanded(
                      child: Semantics(
                        button: true,
                        selected: selected,
                        label: labels[i],
                        child: Tooltip(
                          message: labels[i],
                          child: Material(
                            color: selected
                                ? const Color(0xFFDCEEFF)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(100),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(100),
                              onTap: () => onSelected(i),
                              child: SizedBox(
                                height: 48,
                                child: Center(
                                  child: ExcludeSemantics(
                                    child: _buildIcon(i, selected),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      );
}

class _TopIcon extends CustomPainter {
  const _TopIcon(this.index, this.selected);
  final int index;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 32, size.height / 32);
    final p = Paint()
      ..color = selected ? const Color(0xFF0866FF) : const Color(0xFF08090B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (index == 0) {
      final path = Path()
        ..moveTo(4, 13)
        ..lineTo(14, 4)
        ..quadraticBezierTo(16, 2.5, 18, 4)
        ..lineTo(28, 13)
        ..lineTo(28, 26)
        ..quadraticBezierTo(28, 29, 25, 29)
        ..lineTo(19, 29)
        ..lineTo(19, 19)
        ..lineTo(13, 19)
        ..lineTo(13, 29)
        ..lineTo(7, 29)
        ..quadraticBezierTo(4, 29, 4, 26)
        ..close();
      if (selected) p.style = PaintingStyle.fill;
      canvas.drawPath(path, p);
    } else if (index == 1) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(4, 4, 24, 25),
          const Radius.circular(6),
        ),
        p,
      );
      canvas.drawPath(
        Path()
          ..moveTo(4, 12)
          ..lineTo(28, 12)
          ..moveTo(10, 4)
          ..lineTo(14, 12)
          ..moveTo(19, 4)
          ..lineTo(23, 12),
        p,
      );
      p.style = PaintingStyle.fill;
      canvas.drawPath(
        Path()
          ..moveTo(13, 17)
          ..lineTo(20, 21)
          ..lineTo(13, 25)
          ..close(),
        p,
      );
    } else if (index == 2) {
      canvas.drawCircle(const Offset(22, 7), 4, p);
      canvas.drawCircle(const Offset(10, 13), 4, p);
      canvas.drawPath(
        Path()
          ..moveTo(18, 16)
          ..lineTo(24, 16)
          ..quadraticBezierTo(30, 16, 30, 22)
          ..lineTo(30, 24)
          ..lineTo(22, 24),
        p,
      );
      canvas.drawPath(
        Path()
          ..moveTo(2, 28)
          ..lineTo(2, 26)
          ..quadraticBezierTo(2, 20, 9, 20)
          ..lineTo(11, 20)
          ..quadraticBezierTo(18, 20, 18, 26)
          ..lineTo(18, 28)
          ..close(),
        p,
      );
    } else if (index == 3) {
      canvas.drawPath(
        Path()
          ..moveTo(5, 14)
          ..lineTo(5, 26)
          ..quadraticBezierTo(5, 29, 8, 29)
          ..lineTo(24, 29)
          ..quadraticBezierTo(27, 29, 27, 26)
          ..lineTo(27, 14)
          ..moveTo(12, 29)
          ..lineTo(12, 21)
          ..lineTo(20, 21)
          ..lineTo(20, 29),
        p,
      );
      canvas.drawPath(
        Path()
          ..moveTo(4, 5)
          ..lineTo(28, 5)
          ..lineTo(30, 12)
          ..quadraticBezierTo(30, 17, 25, 17)
          ..quadraticBezierTo(22, 17, 20.5, 14)
          ..quadraticBezierTo(19, 17, 15.5, 17)
          ..quadraticBezierTo(12, 17, 10.5, 14)
          ..quadraticBezierTo(9, 17, 6, 17)
          ..quadraticBezierTo(1, 17, 2, 12)
          ..close(),
        p,
      );
    } else if (index == 4) {
      canvas.drawPath(
        Path()
          ..moveTo(5, 24)
          ..quadraticBezierTo(8, 19, 8, 13)
          ..cubicTo(8, 2.3, 24, 2.3, 24, 13)
          ..quadraticBezierTo(24, 19, 27, 24)
          ..close(),
        p,
      );
      canvas.drawPath(
        Path()
          ..moveTo(12, 25)
          ..cubicTo(12, 30.3, 20, 30.3, 20, 25),
        p,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TopIcon oldDelegate) =>
      index != oldDelegate.index || selected != oldDelegate.selected;
}
