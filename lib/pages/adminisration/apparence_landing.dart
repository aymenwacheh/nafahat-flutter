import 'package:flutter/material.dart';
import 'package:nafahat/pages/widgets/painter_color_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:nafahat/models/SectionOrderModel.dart';
import 'package:nafahat/providers/language_provider.dart';
import 'package:nafahat/services/SectionOrderService.dart';
import 'package:nafahat/services/landing_appearance_manager.dart';

class ApparitionLandingPage extends StatefulWidget {
  const ApparitionLandingPage({super.key});

  @override
  State<ApparitionLandingPage> createState() => _ApparitionLandingPageState();
}

class _ApparitionLandingPageState extends State<ApparitionLandingPage> {
  final LandingAppearanceManager _appearance = LandingAppearanceManager();

  List<SectionOrderModel> _sections = SectionOrderService.getDefaultSections();
  LandingAppearanceConfig _config =
      LandingAppearanceConfig.defaultConfig();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadWarning;

  static const _fonts = <String>[
    'Cairo',
    'Poppins',
    'Roboto',
    'Montserrat',
    'Tajawal',
    'Lato',
    'Open Sans',
    'Inter',
  ];

  static const _palette = <Color>[
    Color(0xff0D443E),
    Color(0xff1A6B60),
    Color(0xffD57653),
    Color(0xff994A2B),
    Color(0xffC4A46C),
    Color(0xff2C221E),
    Color(0xffFCFBFA),
    Color(0xffF5F1EC),
    Color(0xffFFFFFF),
    Color(0xff111827),
    Color(0xff374151),
    Color(0xff6B7280),
    Color(0xff2563EB),
    Color(0xff0EA5E9),
    Color(0xff7C3AED),
    Color(0xffDB2777),
    Color(0xff16A34A),
    Color(0xffEA580C),
  ];

  final List<Map<String, dynamic>> _availableSections = const [
    {
      'key': PredefinedSections.hero,
      'title': 'Hero Section',
      'titleAr': 'قسم الهيرو',
      'icon': Icons.view_carousel_outlined,
    },
    {
      'key': PredefinedSections.bulls,
      'title': 'Bulls / liens rapides',
      'titleAr': 'الروابط السريعة',
      'icon': Icons.bubble_chart_outlined,
    },
    {
      'key': PredefinedSections.trainings,
      'title': 'Formations',
      'titleAr': 'التكوينات',
      'icon': Icons.school_outlined,
    },
    {
      'key': PredefinedSections.inscription,
      'title': 'Inscription',
      'titleAr': 'التسجيل',
      'icon': Icons.app_registration_outlined,
    },
    {
      'key': PredefinedSections.videos,
      'title': 'Vidéos favorites',
      'titleAr': 'الفيديوهات المفضلة',
      'icon': Icons.video_library_outlined,
    },
    {
      'key': PredefinedSections.formateurs,
      'title': 'Formateurs',
      'titleAr': 'المكونون',
      'icon': Icons.people_outline,
    },
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadWarning = null;
      });
    }

    // Les valeurs par défaut restent toujours disponibles afin que cette page
    // ne soit jamais vide, même si l'API est indisponible.
    var sections = SectionOrderService.getDefaultSections();
    var config = LandingAppearanceConfig.defaultConfig();
    String? warning;

    try {
      await _appearance.load();
      config = _appearance.config.copyWith();
    } catch (e) {
      warning = 'Configuration visuelle chargée localement.';
      debugPrint('ApparenceLanding._load appearance: $e');
    }

    try {
      final loaded = await SectionOrderService.loadSections();
      if (loaded.isNotEmpty) {
        sections = loaded;
      }
    } catch (e) {
      warning = 'Ordre distant indisponible : affichage des sections par défaut.';
      debugPrint('ApparenceLanding._load sections: $e');
    }

    sections.sort((a, b) => a.order.compareTo(b.order));

    if (!mounted) return;
    setState(() {
      _config = config;
      _sections = sections;
      _loadWarning = warning;
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    _normalizeOrders();
    bool sectionsSaved = false;
    bool appearanceSaved = false;

    try {
      sectionsSaved = await SectionOrderService.saveSections(_sections);
      appearanceSaved = await _appearance.save(_config);
    } catch (e) {
      debugPrint('ApparenceLanding._save: $e');
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    final isArabic = context.read<LanguageProvider>().isArabic;
    final allSaved = sectionsSaved && appearanceSaved;
    final localApplied = !allSaved;

    _toast(
      allSaved
          ? (isArabic
              ? 'تم الحفظ وتحديث الصفحة الرئيسية'
              : 'Enregistré : la Landing Page utilise maintenant ces réglages')
          : (isArabic
              ? 'تم تطبيق التغييرات محلياً، لكن الخادم لم يؤكد كل الحفظ'
              : 'Changements appliqués localement, mais le serveur n’a pas confirmé toute la sauvegarde'),
      allSaved ? Colors.green : (localApplied ? Colors.orange : Colors.red),
    );
  }

  Future<void> _reset() async {
    final isArabic = context.read<LanguageProvider>().isArabic;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          isArabic ? 'إعادة الإعدادات الافتراضية' : 'Réinitialiser l’apparence',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        content: Text(
          isArabic
              ? 'سيتم استرجاع ترتيب الأقسام والألوان الافتراضية.'
              : 'L’ordre des sections, les couleurs et les styles par défaut seront restaurés.',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isArabic ? 'إلغاء' : 'Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isArabic ? 'تأكيد' : 'Confirmer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await SectionOrderService.resetToDefault();
    await _appearance.reset();
    await _load();
  }

  void _updateConfig(LandingAppearanceConfig next) {
    setState(() => _config = next);
    // Prévisualisation globale instantanée si la LandingPage est encore montée.
    _appearance.preview(next);
  }

  void _normalizeOrders() {
    for (var i = 0; i < _sections.length; i++) {
      _sections[i] = _sections[i].copyWith(order: i);
    }
  }

  void _addSection(String key) {
    final base = _availableSections.firstWhere((e) => e['key'] == key);
    final count = _sections.where((e) => e.sectionKey == key).length;
    setState(() {
      _sections.add(
        SectionOrderModel(
          id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
          sectionKey: key,
          title: '${base['title']}${count == 0 ? '' : ' ${count + 1}'}',
          titleAr: '${base['titleAr']}${count == 0 ? '' : ' ${count + 1}'}',
          icon: base['icon'] as IconData,
          order: _sections.length,
          isActive: true,
          isDuplicate: count > 0,
        ),
      );
      _normalizeOrders();
    });
  }

  void _removeSection(SectionOrderModel section) {
    if (_sections.where((e) => e.sectionKey == section.sectionKey).length <= 1) {
      _toast('Gardez au moins une instance de cette section.', Colors.orange);
      return;
    }
    setState(() {
      _sections.removeWhere((e) => e.id == section.id);
      _normalizeOrders();
    });
  }

  Future<void> _editSectionTitle(SectionOrderModel section) async {
    final fr = TextEditingController(text: section.title);
    final ar = TextEditingController(text: section.titleAr);
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Titre de la section'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fr,
                decoration: const InputDecoration(
                  labelText: 'Titre français',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ar,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  labelText: 'العنوان العربي',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              {'fr': fr.text.trim(), 'ar': ar.text.trim()},
            ),
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
    if (result == null) return;
    final i = _sections.indexWhere((e) => e.id == section.id);
    if (i < 0) return;
    setState(() {
      _sections[i] = section.copyWith(
        title: result['fr']!.isEmpty ? section.title : result['fr'],
        titleAr: result['ar']!.isEmpty ? section.titleAr : result['ar'],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider>().isArabic;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 760;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          isArabic ? 'مظهر الصفحة الرئيسية' : 'Apparence Landing',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Réinitialiser',
            onPressed: _reset,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: isMobile
                ? IconButton.filled(
                    tooltip: isArabic ? 'حفظ' : 'Enregistrer',
                    onPressed: _isSaving ? null : _save,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xff0D443E),
                      foregroundColor: Colors.white,
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                  )
                : FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(isArabic ? 'حفظ' : 'Enregistrer'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xff0D443E),
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xff0D443E)),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isMobile ? 12 : 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1320),
                    child: Column(
                      children: [
                        if (_loadWarning != null) ...[
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xfffff7ed),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xfffed7aa)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded,
                                    color: Color(0xffc2410c)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _loadWarning!,
                                    style: GoogleFonts.cairo(
                                      color: const Color(0xff9a3412),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Réessayer',
                                  onPressed: _load,
                                  icon: const Icon(Icons.refresh_rounded),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (isMobile) ...[
                          _buildPreview(isArabic),
                          const SizedBox(height: 16),
                          _buildThemePanel(isArabic),
                          const SizedBox(height: 16),
                          _buildTypographyPanel(isArabic),
                          const SizedBox(height: 16),
                          _buildLayoutPanel(isArabic),
                          const SizedBox(height: 16),
                          _buildSectionsPanel(isArabic),
                          const SizedBox(height: 16),
                          _buildPresetPanel(isArabic),
                        ] else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 7,
                                child: Column(
                                  children: [
                                    _buildThemePanel(isArabic),
                                    const SizedBox(height: 16),
                                    _buildTypographyPanel(isArabic),
                                    const SizedBox(height: 16),
                                    _buildLayoutPanel(isArabic),
                                    const SizedBox(height: 16),
                                    _buildSectionsPanel(isArabic),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                flex: 5,
                                child: Column(
                                  children: [
                                    _buildPreview(isArabic),
                                    const SizedBox(height: 16),
                                    _buildPresetPanel(isArabic),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _panel({
    required String title,
    required IconData icon,
    required Widget child,
    String? subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xff0D443E).withOpacity(.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xff0D443E)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xff1F2937),
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildThemePanel(bool isArabic) {
    return _panel(
      title: isArabic ? 'الألوان والثيم' : 'Couleurs & thème',
      subtitle: isArabic
          ? 'اختر الوضع والألوان الأساسية'
          : 'Mode clair/sombre et palette globale',
      icon: Icons.palette_outlined,
      child: Column(
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'light',
                icon: Icon(Icons.light_mode_outlined),
                label: Text('Clair'),
              ),
              ButtonSegment(
                value: 'dark',
                icon: Icon(Icons.dark_mode_outlined),
                label: Text('Sombre'),
              ),
            ],
            selected: {_config.themeMode},
            onSelectionChanged: (value) {
              final mode = value.first;
              final dark = mode == 'dark';
              _updateConfig(
                _config.copyWith(
                  themeMode: mode,
                  pageBackgroundColor:
                      dark ? const Color(0xff0F172A) : const Color(0xffFCFBFA),
                  sectionBackgroundColor:
                      dark ? const Color(0xff172033) : Colors.white,
                  textColor:
                      dark ? const Color(0xffF8FAFC) : const Color(0xff2C221E),
                  mutedTextColor:
                      dark ? const Color(0xff94A3B8) : const Color(0xff7C6E68),
                  titleColor:
                      dark ? const Color(0xffF1C4B3) : const Color(0xff994A2B),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          _colorRow(
            'Arrière-plan',
            _config.pageBackgroundColor,
            (c) => _updateConfig(_config.copyWith(pageBackgroundColor: c)),
          ),
          _colorRow(
            'Surface section',
            _config.sectionBackgroundColor,
            (c) => _updateConfig(_config.copyWith(sectionBackgroundColor: c)),
          ),
          _colorRow(
            'Couleur principale',
            _config.primaryColor,
            (c) => _updateConfig(_config.copyWith(primaryColor: c)),
          ),
          _colorRow(
            'Accent',
            _config.accentColor,
            (c) => _updateConfig(_config.copyWith(accentColor: c)),
          ),
          _colorRow(
            'Titres',
            _config.titleColor,
            (c) => _updateConfig(_config.copyWith(titleColor: c)),
          ),
          _colorRow(
            'Texte',
            _config.textColor,
            (c) => _updateConfig(_config.copyWith(textColor: c)),
          ),
        ],
      ),
    );
  }

  Widget _buildTypographyPanel(bool isArabic) {
    return _panel(
      title: isArabic ? 'الخطوط والعناوين' : 'Typographie des titres',
      icon: Icons.text_fields_rounded,
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _fonts.contains(_config.titleFontFamily)
                ? _config.titleFontFamily
                : 'Cairo',
            decoration: const InputDecoration(
              labelText: 'Police',
              border: OutlineInputBorder(),
            ),
            items: _fonts
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                _updateConfig(_config.copyWith(titleFontFamily: value));
              }
            },
          ),
          const SizedBox(height: 16),
          _slider(
            'Taille des titres',
            _config.titleFontSize,
            18,
            48,
            (v) => _updateConfig(_config.copyWith(titleFontSize: v)),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _config.titleFontWeight.value,
            decoration: const InputDecoration(
              labelText: 'Graisse',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 400, child: Text('Normal 400')),
              DropdownMenuItem(value: 500, child: Text('Medium 500')),
              DropdownMenuItem(value: 600, child: Text('Semi-bold 600')),
              DropdownMenuItem(value: 700, child: Text('Bold 700')),
              DropdownMenuItem(value: 800, child: Text('Extra-bold 800')),
              DropdownMenuItem(value: 900, child: Text('Black 900')),
            ],
            onChanged: (v) {
              if (v == null) return;
              _updateConfig(
                _config.copyWith(titleFontWeight: _weight(v)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutPanel(bool isArabic) {
    return _panel(
      title: isArabic ? 'تنسيق الأقسام' : 'Mise en page des sections',
      icon: Icons.dashboard_customize_outlined,
      child: Column(
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Afficher les sections comme des cartes'),
            subtitle: const Text('Fond, arrondi et espacement par section'),
            value: _config.showSectionCards,
            onChanged: (v) =>
                _updateConfig(_config.copyWith(showSectionCards: v)),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Afficher le titre administrable des sections'),
            value: _config.showSectionTitles,
            onChanged: (v) =>
                _updateConfig(_config.copyWith(showSectionTitles: v)),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ombre des sections'),
            value: _config.enableSectionShadow,
            onChanged: (v) =>
                _updateConfig(_config.copyWith(enableSectionShadow: v)),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mode compact'),
            value: _config.compactMode,
            onChanged: (v) =>
                _updateConfig(_config.copyWith(compactMode: v)),
          ),
          const Divider(height: 28),
          _slider(
            'Espacement entre sections',
            _config.sectionSpacing,
            0,
            56,
            (v) => _updateConfig(_config.copyWith(sectionSpacing: v)),
          ),
          _slider(
            'Marge horizontale',
            _config.horizontalPadding,
            0,
            72,
            (v) => _updateConfig(_config.copyWith(horizontalPadding: v)),
          ),
          _slider(
            'Arrondi des sections',
            _config.sectionRadius,
            0,
            40,
            (v) => _updateConfig(_config.copyWith(sectionRadius: v)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionsPanel(bool isArabic) {
    return _panel(
      title: isArabic ? 'ترتيب الأقسام' : 'Ordre & contenu des sections',
      subtitle: isArabic
          ? 'اسحب لتغيير الترتيب، ويمكنك إخفاء أو تكرار أي قسم.'
          : 'Glissez pour réordonner, désactivez ou dupliquez.',
      icon: Icons.reorder_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_sections.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xffFFF7ED),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                isArabic
                    ? 'لم يتم العثور على أقسام. استخدم زر إعادة التهيئة أو أضف قسماً.'
                    : 'Aucune section trouvée. Réinitialisez ou ajoutez une section.',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _sections.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _sections.removeAt(oldIndex);
                  _sections.insert(newIndex, item);
                  _normalizeOrders();
                });
              },
              itemBuilder: (_, index) {
                final section = _sections[index];
                return LayoutBuilder(
                  key: ValueKey(section.id),
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 620;

                    final drag = ReorderableDragStartListener(
                      index: index,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.grab,
                        child: Tooltip(
                          message: isArabic
                              ? 'اسحب لتغيير الترتيب'
                              : 'Maintenir et glisser pour déplacer',
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.drag_indicator_rounded,
                              size: 25,
                              color: Color(0xff64748B),
                            ),
                          ),
                        ),
                      ),
                    );

                    final identity = Row(
                      children: [
                        drag,
                        const SizedBox(width: 6),
                        CircleAvatar(
                          radius: 19,
                          backgroundColor: _config.accentColor.withOpacity(.12),
                          foregroundColor: _config.accentColor,
                          child: Icon(section.icon, size: 19),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isArabic ? section.titleAr : section.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xff1F2937),
                                ),
                              ),
                              Text(
                                section.sectionKey,
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  color: const Color(0xff64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );

                    final controls = Wrap(
                      spacing: 2,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Switch.adaptive(
                          value: section.isActive,
                          onChanged: (value) {
                            setState(() {
                              _sections[index] =
                                  section.copyWith(isActive: value);
                            });
                          },
                        ),
                        IconButton(
                          tooltip: isArabic ? 'تعديل العنوان' : 'Modifier le titre',
                          onPressed: () => _editSectionTitle(section),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: isArabic ? 'حذف' : 'Supprimer',
                          onPressed: () => _removeSection(section),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    );

                    return Card(
                      elevation: 0,
                      color: const Color(0xffF8FAFC),
                      margin: const EdgeInsets.only(bottom: 8),
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0xffE5E7EB)),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 8 : 12,
                          vertical: 8,
                        ),
                        child: compact
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  identity,
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: isArabic
                                        ? Alignment.centerLeft
                                        : Alignment.centerRight,
                                    child: controls,
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(child: identity),
                                  const SizedBox(width: 10),
                                  controls,
                                ],
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          const SizedBox(height: 12),
          Align(
            alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
            child: PopupMenuButton<String>(
              onSelected: _addSection,
              itemBuilder: (_) => _availableSections
                  .map(
                    (s) => PopupMenuItem<String>(
                      value: s['key'] as String,
                      child: Row(
                        children: [
                          Icon(s['icon'] as IconData, size: 19),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isArabic
                                  ? s['titleAr'] as String
                                  : s['title'] as String,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              child: IgnorePointer(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    isArabic
                        ? 'إضافة / تكرار قسم'
                        : 'Ajouter / dupliquer une section',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetPanel(bool isArabic) {
    final presets = <Map<String, dynamic>>[
      {
        'name': 'Nafahat',
        'bg': const Color(0xffFCFBFA),
        'surface': Colors.white,
        'primary': const Color(0xff0D443E),
        'accent': const Color(0xffD57653),
        'title': const Color(0xff994A2B),
      },
      {
        'name': 'Océan',
        'bg': const Color(0xffF5FAFF),
        'surface': Colors.white,
        'primary': const Color(0xff075985),
        'accent': const Color(0xff0EA5E9),
        'title': const Color(0xff0C4A6E),
      },
      {
        'name': 'Violet',
        'bg': const Color(0xffFAF7FF),
        'surface': Colors.white,
        'primary': const Color(0xff5B21B6),
        'accent': const Color(0xff8B5CF6),
        'title': const Color(0xff4C1D95),
      },
      {
        'name': 'Nuit',
        'bg': const Color(0xff0F172A),
        'surface': const Color(0xff172033),
        'primary': const Color(0xff34D399),
        'accent': const Color(0xffF59E0B),
        'title': const Color(0xffF8FAFC),
      },
    ];

return _panel(
  title: isArabic ? 'قوالب جاهزة' : 'Palettes prêtes',
  icon: Icons.auto_awesome_outlined,
  child: Wrap(
    spacing: 10,
    runSpacing: 10,
    children: presets.map((p) {
      final bool dark = p['name'] == 'Nuit';

      return InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          _updateConfig(
            _config.copyWith(
              themeMode: dark ? 'dark' : 'light',
              pageBackgroundColor: p['bg'] as Color,
              sectionBackgroundColor: p['surface'] as Color,
              primaryColor: p['primary'] as Color,
              accentColor: p['accent'] as Color,
              titleColor: p['title'] as Color,
              textColor: dark
                  ? const Color(0xffF8FAFC)
                  : const Color(0xff2C221E),
              mutedTextColor: dark
                  ? const Color(0xff94A3B8)
                  : const Color(0xff7C6E68),
            ),
          );
        },
        child: Container(
          width: 130,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: p['bg'] as Color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: dark
                  ? const Color(0xff334155)
                  : const Color(0xffE5E7EB),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _dot(p['primary'] as Color),
                  _dot(p['accent'] as Color),
                  _dot(p['title'] as Color),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                p['name'] as String,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w700,
                  color: dark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList(),
  ),
);}

  Widget _buildPreview(bool isArabic) {
    final dark = _config.themeMode == 'dark';
    return _panel(
      title: isArabic ? 'معاينة مباشرة' : 'Aperçu instantané',
      icon: Icons.visibility_outlined,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 330),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _config.pageBackgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          children: [
            Container(
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_config.primaryColor, _config.accentColor],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                isArabic ? 'أكاديمية نفحات' : 'Nafahat Academy',
                style: _config.titleStyle(size: 22).copyWith(
                      color: Colors.white,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            ..._sections
                .where((s) => s.isActive)
                .take(4)
                .map(
                  (s) => Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(
                      bottom: _config.compactMode
                          ? 5
                          : (_config.sectionSpacing / 3).clamp(6, 18).toDouble(),
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _config.showSectionCards
                          ? _config.sectionBackgroundColor
                          : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(_config.sectionRadius),
                      boxShadow: _config.enableSectionShadow
                          ? const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 12,
                                offset: Offset(0, 5),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(s.icon, color: _config.accentColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isArabic ? s.titleAr : s.title,
                            style: _config.titleStyle(size: 15),
                          ),
                        ),
                        Container(
                          width: 64,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _config.primaryColor.withOpacity(.20),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 14),
            Text(
              dark ? 'Dark theme' : 'Light theme',
              style: GoogleFonts.cairo(
                color: _config.mutedTextColor,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorRow(
    String label,
    Color current,
    ValueChanged<Color> onChanged,
  ) {
    final isArabic = context.read<LanguageProvider>().isArabic;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: PainterColorPickerField(
        label: label,
        color: current,
        onChanged: onChanged,
        isArabic: isArabic,
      ),
    );
  }

  Future<void> _showColorDialog(
    Color current,
    ValueChanged<Color> onChanged,
  ) async {
    final controller = TextEditingController(
      text:
          '#${current.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
    );
    final result = await showDialog<Color>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Choisir une couleur'),
          content: SizedBox(
            width: 430,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _palette
                      .map(
                        (c) => InkWell(
                          onTap: () => Navigator.pop(context, c),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: c,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'HEX (#RRGGBB)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.tag),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                var hex = controller.text.trim().replaceAll('#', '');
                if (hex.length == 6) hex = 'FF$hex';
                final value = int.tryParse(hex, radix: 16);
                if (value != null) Navigator.pop(context, Color(value));
              },
              child: const Text('Appliquer'),
            ),
          ],
        ),
      ),
    );
    if (result != null) onChanged(result);
  }

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        final slider = Slider(
          value: value.clamp(min, max).toDouble(),
          min: min,
          max: max,
          divisions: (max - min).round(),
          label: value.toStringAsFixed(0),
          onChanged: onChanged,
        );

        if (compact) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.cairo(fontSize: 12),
                      ),
                    ),
                    Text(
                      value.toStringAsFixed(0),
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                slider,
              ],
            ),
          );
        }

        return Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.cairo(fontSize: 12),
              ),
            ),
            SizedBox(width: 240, child: slider),
            SizedBox(
              width: 42,
              child: Text(
                value.toStringAsFixed(0),
                textAlign: TextAlign.end,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _dot(Color c) => Container(
        width: 18,
        height: 18,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );

  FontWeight _weight(int value) {
    switch (value) {
      case 400:
        return FontWeight.w400;
      case 500:
        return FontWeight.w500;
      case 600:
        return FontWeight.w600;
      case 800:
        return FontWeight.w800;
      case 900:
        return FontWeight.w900;
      default:
        return FontWeight.w700;
    }
  }

  void _toast(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
