import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PainterColorPickerField extends StatelessWidget {
  const PainterColorPickerField({
    super.key,
    required this.label,
    required this.color,
    required this.onChanged,
    this.isArabic = false,
  });

  final String label;
  final Color color;
  final ValueChanged<Color> onChanged;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
              fontSize: 13,
            )),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final selected = await showDialog<Color>(
              context: context,
              builder: (_) => _RichPaletteDialog(
                initial: color,
                isArabic: isArabic,
              ),
            );
            if (selected != null) onChanged(selected);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 88,
                  height: 70,
                  child: CustomPaint(
                    painter: _PainterPalettePainter(selected: color),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? 'اضغط لاختيار اللون' : 'Cliquer pour choisir',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                        style: GoogleFonts.cairo(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.dividerColor, width: 2),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded,
                    color: theme.colorScheme.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PainterPalettePainter extends CustomPainter {
  _PainterPalettePainter({required this.selected});
  final Color selected;

  @override
  void paint(Canvas canvas, Size size) {
    final body = Paint()..color = const Color(0xFFF2C982);
    final border = Paint()
      ..color = const Color(0xFFD9A552)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..moveTo(size.width * .16, size.height * .08)
      ..cubicTo(size.width * .60, -3, size.width * .96, size.height * .14,
          size.width * .93, size.height * .52)
      ..cubicTo(size.width * .91, size.height * .75, size.width * .74,
          size.height * .64, size.width * .72, size.height * .86)
      ..cubicTo(size.width * .66, size.height * 1.02, size.width * .32,
          size.height * .96, size.width * .13, size.height * .68)
      ..cubicTo(-2, size.height * .45, 0, size.height * .20,
          size.width * .16, size.height * .08)
      ..close();
    canvas.drawPath(path, body);
    canvas.drawPath(path, border);

    final wells = <Offset>[
      Offset(size.width * .30, size.height * .24),
      Offset(size.width * .54, size.height * .18),
      Offset(size.width * .73, size.height * .34),
      Offset(size.width * .76, size.height * .58),
      Offset(size.width * .26, size.height * .64),
      Offset(size.width * .18, size.height * .42),
    ];
    final colors = <Color>[
      selected,
      Colors.amber,
      Colors.lightGreen,
      Colors.deepOrange,
      Colors.blueGrey.shade100,
      Colors.deepPurple.shade300,
    ];
    for (var i = 0; i < wells.length; i++) {
      canvas.drawCircle(wells[i], size.width * .085,
          Paint()..color = colors[i]);
      canvas.drawCircle(
        wells[i],
        size.width * .085,
        Paint()
          ..color = Colors.black.withOpacity(.16)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
    canvas.drawCircle(
      Offset(size.width * .55, size.height * .70),
      size.width * .10,
      Paint()..color = Colors.white.withOpacity(.96),
    );
  }

  @override
  bool shouldRepaint(covariant _PainterPalettePainter oldDelegate) =>
      oldDelegate.selected != selected;
}

class _RichPaletteDialog extends StatefulWidget {
  const _RichPaletteDialog({required this.initial, required this.isArabic});
  final Color initial;
  final bool isArabic;

  @override
  State<_RichPaletteDialog> createState() => _RichPaletteDialogState();
}

class _RichPaletteDialogState extends State<_RichPaletteDialog> {
  late Color selected = widget.initial;
  late final TextEditingController hex = TextEditingController(
    text: '#${widget.initial.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
  );

  static final List<MaterialColor> families = <MaterialColor>[
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  static const shades = <int>[50,100,200,300,400,500,600,700,800,900];

  void pick(Color c) {
    setState(() {
      selected = c;
      hex.text = '#${c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screen = MediaQuery.of(context).size;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 760,
          maxHeight: screen.height * .86,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 84,
                    height: 66,
                    child: CustomPaint(
                      painter: _PainterPalettePainter(selected: selected),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.isArabic ? 'لوحة ألوان غنية' : 'Palette de couleurs et nuances',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: families.map((family) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: shades.map((shade) {
                            final c = family[shade]!;
                            final active = c.value == selected.value;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: InkWell(
                                  onTap: () => pick(c),
                                  borderRadius: BorderRadius.circular(8),
                                  child: AspectRatio(
                                    aspectRatio: 1.35,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: c,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: active
                                              ? theme.colorScheme.onSurface
                                              : Colors.transparent,
                                          width: active ? 3 : 0,
                                        ),
                                      ),
                                      child: active
                                          ? Icon(Icons.check_rounded,
                                              size: 16,
                                              color: ThemeData.estimateBrightnessForColor(c) == Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black)
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: selected,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.dividerColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: hex,
                      decoration: const InputDecoration(
                        labelText: 'HEX (#RRGGBB)',
                        prefixIcon: Icon(Icons.tag_rounded),
                      ),
                      onSubmitted: (_) => _applyHex(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: () {
                      _applyHex();
                      Navigator.pop(context, selected);
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: Text(widget.isArabic ? 'اختيار' : 'Choisir'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyHex() {
    var raw = hex.text.trim().replaceAll('#', '').replaceAll('0x', '');
    if (raw.length == 6) raw = 'FF$raw';
    final value = int.tryParse(raw, radix: 16);
    if (value != null) pick(Color(value));
  }

  @override
  void dispose() {
    hex.dispose();
    super.dispose();
  }
}
