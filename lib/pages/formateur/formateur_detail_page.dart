import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:nafahat/pages/widgets/mobile_bottom_nav_bar.dart';
import 'package:nafahat/pages/widgets/navbar.dart';
import 'package:nafahat/providers/language_provider.dart';
import 'package:nafahat/services/training_service.dart';

class FormateurDetailPage extends StatefulWidget {
  final String formateurId;

  const FormateurDetailPage({
    super.key,
    required this.formateurId,
  });

  @override
  State<FormateurDetailPage> createState() => _FormateurDetailPageState();
}

class _FormateurDetailPageState extends State<FormateurDetailPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, dynamic>? _formateur;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFormateur();
  }

  Future<void> _loadFormateur() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    final data = await TrainingService.getFormateurById(widget.formateurId);
    if (!mounted) return;

    if (data == null) {
      setState(() {
        _isLoading = false;
        _error = 'Formateur introuvable';
      });
      return;
    }

    setState(() {
      _formateur = data;
      _isLoading = false;
    });
  }

  String _localized(
    Map<String, dynamic> data,
    bool isArabic,
    String arKey,
    String frKey,
  ) {
    final primary = data[isArabic ? arKey : frKey]?.toString().trim() ?? '';
    if (primary.isNotEmpty) return primary;
    return data[isArabic ? frKey : arKey]?.toString().trim() ?? '';
  }

  String _photoUrl(Map<String, dynamic> data) {
    final photo = data['photo']?.toString().trim() ?? '';
    if (photo.isEmpty || photo == 'null') return '';
    if (photo.startsWith('http://') || photo.startsWith('https://')) {
      return photo;
    }
    final apiRoot = TrainingService.apiBaseUrl.replaceAll('/api', '');
    return '$apiRoot/uploads/formateurs/$photo';
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider>().isArabic;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final navbar = Navbar(
      isMobile: width < 850,
      scaffoldKey: _scaffoldKey,
    );

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFFCFBFA),
        drawer: width < 850 ? navbar.buildDrawer(context) : null,
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              navbar,
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF0D443E),
                        ),
                      )
                    : _error != null || _formateur == null
                        ? _buildError(isArabic)
                        : _buildContent(
                            _formateur!,
                            isArabic,
                            isMobile,
                          ),
              ),
              const MobileBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(bool isArabic) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_off_outlined,
              size: 62,
              color: Color(0xFFD57653),
            ),
            const SizedBox(height: 12),
            Text(
              isArabic ? 'تعذر تحميل بيانات المكون' : 'Impossible de charger le formateur',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0D443E),
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _loadFormateur,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(isArabic ? 'إعادة المحاولة' : 'Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    Map<String, dynamic> formateur,
    bool isArabic,
    bool isMobile,
  ) {
    final name = _localized(
      formateur,
      isArabic,
      'nom_prenom_ar',
      'nom_prenom_fr',
    );
    final category = _localized(
      formateur,
      isArabic,
      'categorie_ar',
      'categorie_fr',
    );
    final bio = _localized(formateur, isArabic, 'bio_ar', 'bio_fr');
    final email = formateur['email']?.toString().trim() ?? '';
    final telephone = formateur['telephone']?.toString().trim() ?? '';
    final photoUrl = _photoUrl(formateur);

    return RefreshIndicator(
      onRefresh: _loadFormateur,
      color: const Color(0xFF0D443E),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          isMobile ? 16 : 40,
          isMobile ? 22 : 38,
          isMobile ? 16 : 40,
          42,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isMobile ? 20 : 30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE9E3DE)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: isMobile
                      ? Column(
                          children: [
                            _avatar(photoUrl, 112),
                            const SizedBox(height: 18),
                            _identity(name, category, isArabic),
                          ],
                        )
                      : Row(
                          children: [
                            _avatar(photoUrl, 132),
                            const SizedBox(width: 28),
                            Expanded(
                              child: _identity(name, category, isArabic),
                            ),
                          ],
                        ),
                ),
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _sectionCard(
                    icon: Icons.description_outlined,
                    title: isArabic ? 'نبذة عن المكون' : 'À propos du formateur',
                    child: Text(
                      bio,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        height: 1.8,
                        color: const Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ],
                if (email.isNotEmpty || telephone.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _sectionCard(
                    icon: Icons.contact_mail_outlined,
                    title: isArabic ? 'معلومات الاتصال' : 'Coordonnées',
                    child: Column(
                      children: [
                        if (email.isNotEmpty)
                          _infoRow(Icons.email_outlined, email),
                        if (email.isNotEmpty && telephone.isNotEmpty)
                          const Divider(height: 24),
                        if (telephone.isNotEmpty)
                          _infoRow(Icons.phone_outlined, telephone),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: isMobile ? double.infinity : 320,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/formations',
                        arguments: {'formateurId': widget.formateurId},
                      );
                    },
                    icon: const Icon(Icons.school_outlined),
                    label: Text(
                      isArabic
                          ? 'عرض تكوينات هذا المكون'
                          : 'Voir les formations de ce formateur',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D443E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatar(String photoUrl, double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFF8EEE9),
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: photoUrl.isEmpty
            ? Icon(
                Icons.person_rounded,
                size: size * 0.55,
                color: const Color(0xFFD57653),
              )
            : Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.person_rounded,
                  size: size * 0.55,
                  color: const Color(0xFFD57653),
                ),
              ),
      ),
    );
  }

  Widget _identity(String name, String category, bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name.isEmpty ? (isArabic ? 'مكون' : 'Formateur') : name,
          style: GoogleFonts.cairo(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0D443E),
          ),
        ),
        if (category.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.category_outlined,
                size: 18,
                color: Color(0xFFD57653),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  category,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9E3DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFD57653), size: 22),
              const SizedBox(width: 9),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0D443E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFFD57653)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: const Color(0xFF4B5563),
            ),
          ),
        ),
      ],
    );
  }
}
