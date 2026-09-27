import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/language_provider.dart';
import '../../services/training_service.dart';
import '../widgets/formateur_section.dart';

class FormateursPage extends StatefulWidget {
  const FormateursPage({super.key});

  @override
  State<FormateursPage> createState() => _FormateursPageState();
}

class _FormateursPageState extends State<FormateursPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _formateurs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFormateurs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFormateurs() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final data = await TrainingService.getFormateurs();
      if (!mounted) return;
      setState(() {
        _formateurs = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _filtered(bool isArabic) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _formateurs;

    return _formateurs.where((formateur) {
      final name = (isArabic
              ? formateur['nom_prenom_ar'] ?? formateur['nom_prenom_fr']
              : formateur['nom_prenom_fr'] ?? formateur['nom_prenom_ar'])
          ?.toString()
          .toLowerCase();
      final category = (isArabic
              ? formateur['categorie_ar'] ?? formateur['categorie_fr']
              : formateur['categorie_fr'] ?? formateur['categorie_ar'])
          ?.toString()
          .toLowerCase();
      return (name?.contains(query) ?? false) ||
          (category?.contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider>().isArabic;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1100;
    final filtered = _filtered(isArabic);

    final columns = isMobile ? 1 : (isTablet ? 2 : 4);

    return Scaffold(
      backgroundColor: const Color(0xFFFCFBFA),
      body: RefreshIndicator(
        onRefresh: _loadFormateurs,
        color: const Color(0xff0D443E),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 36,
                  isMobile ? 20 : 32,
                  isMobile ? 16 : 36,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'المكونون' : 'Nos formateurs',
                      style: GoogleFonts.cairo(
                        fontSize: isMobile ? 25 : 32,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xff0D443E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isArabic
                          ? 'اختر مكوناً لعرض التكوينات الخاصة به.'
                          : 'Choisissez un formateur pour afficher ses formations.',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: isArabic
                            ? 'ابحث عن مكون...'
                            : 'Rechercher un formateur...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xff0D443E),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xff0D443E)),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _MessageState(
                  icon: Icons.error_outline_rounded,
                  title: isArabic ? 'حدث خطأ' : 'Une erreur est survenue',
                  subtitle: _error!,
                  buttonLabel: isArabic ? 'إعادة المحاولة' : 'Réessayer',
                  onPressed: _loadFormateurs,
                ),
              )
            else if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _MessageState(
                  icon: Icons.people_outline_rounded,
                  title: isArabic ? 'لا يوجد مكونون' : 'Aucun formateur trouvé',
                  subtitle: isArabic
                      ? 'لا توجد نتائج مطابقة لبحثك.'
                      : 'Aucun résultat ne correspond à votre recherche.',
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 36,
                  4,
                  isMobile ? 16 : 36,
                  36,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isMobile ? 1.45 : 0.95,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final formateur = filtered[index];
                      final id = formateur['id']?.toString();
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: id == null || id.isEmpty
                              ? null
                              : () => Navigator.pushNamed(
                                    context,
                                    '/formations',
                                    arguments: {'formateurId': id},
                                  ),
                          child: FormateurCard(
                            formateur: formateur,
                            isArabic: isArabic,
                          ),
                        ),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 62, color: const Color(0xffC4A46C)),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: const Color(0xff0D443E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(color: Colors.grey.shade600),
            ),
            if (buttonLabel != null && onPressed != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff0D443E),
                  foregroundColor: Colors.white,
                ),
                child: Text(buttonLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
