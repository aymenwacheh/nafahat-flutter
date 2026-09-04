// lib/pages/formations/formations_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/models/training_model.dart';
import 'package:nafahat/services/training_service.dart';
import 'package:nafahat/pages/widgets/training_card_section.dart';
import 'package:nafahat/pages/widgets/navbar.dart';
import 'package:nafahat/providers/language_provider.dart';
import 'package:provider/provider.dart';

class FormationsPage extends StatefulWidget {
  final String? categorieId;
  final String? formateurId;

  const FormationsPage({
    super.key,
    this.categorieId,
    this.formateurId,
  });

  @override
  State<FormationsPage> createState() => _FormationsPageState();
}

class _FormationsPageState extends State<FormationsPage> {
  List<TrainingModel> _trainings = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Clé pour le scaffold (nécessaire pour le drawer)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadTrainings();
  }

  Future<void> _loadTrainings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<TrainingModel> trainings = await TrainingService.getTrainings();
      
      if (widget.categorieId != null && widget.categorieId!.isNotEmpty) {
        trainings = trainings.where((t) => 
          t.categorieId == widget.categorieId
        ).toList();
      }
      
      if (widget.formateurId != null && widget.formateurId!.isNotEmpty) {
        trainings = trainings.where((t) => 
          t.formateurId == widget.formateurId
        ).toList();
      }

      setState(() {
        _trainings = trainings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getPageTitle() {
    final isArabic = Provider.of<LanguageProvider>(context, listen: false).isArabic;
    
    if (widget.categorieId != null) {
      return isArabic ? 'التكوينات حسب التصنيف' : 'Formations par catégorie';
    }
    if (widget.formateurId != null) {
      return isArabic ? 'التكوينات حسب المكون' : 'Formations par formateur';
    }
    return isArabic ? 'جميع التكوينات' : 'Toutes les formations';
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    // Créer une instance unique du Navbar
    final navbar = Navbar(
      isMobile: isMobile,
      scaffoldKey: _scaffoldKey,
    );

    return Scaffold(
      key: _scaffoldKey,
      // ============================================================
      // DRAWER MOBILE - AJOUTÉ POUR QUE LE MENU FONCTIONNE
      // ============================================================
      drawer: navbar.buildDrawer(context),
      body: Column(
        children: [
          // ============================================================
          // NAVBAR (responsif mobile/web)
          // ============================================================
          navbar,
          // ============================================================
          // CONTENU PRINCIPAL
          // ============================================================
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xffd57653),
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isArabic ? 'حدث خطأ' : 'Une erreur est survenue',
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage!,
                              style: GoogleFonts.cairo(
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadTrainings,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xffd57653),
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                isArabic ? 'إعادة المحاولة' : 'Réessayer',
                              ),
                            ),
                          ],
                        ),
                      )
                    : _trainings.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.school_outlined,
                                  size: 80,
                                  color: const Color(0xffd57653).withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  isArabic
                                      ? 'لا توجد تكوينات مطابقة'
                                      : 'Aucune formation correspondante',
                                  style: GoogleFonts.cairo(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isArabic
                                      ? 'جرب تغيير الفلتر أو العودة للصفحة الرئيسية'
                                      : 'Essayez de changer le filtre ou revenez à l\'accueil',
                                  style: GoogleFonts.cairo(
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xffd57653),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(
                                    isArabic ? 'العودة للرئيسية' : 'Retour à l\'accueil',
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Padding(
                            padding: EdgeInsets.all(isMobile ? 12 : 24),
                            child: GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isMobile ? 1 : 3,
                                childAspectRatio: isMobile ? 0.7 : 0.85,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: _trainings.length,
                              itemBuilder: (context, index) {
                                return TrainingCard(
                                  training: _trainings[index],
                                  isArabic: isArabic,
                                  onRefresh: _loadTrainings,
                                  isMobile: isMobile,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}