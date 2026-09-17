// lib/pages/users/profile_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/pages/users/edit_profile_page.dart';
import 'package:nafahat/pages/widgets/navbar.dart' show Navbar;
import 'package:nafahat/providers/language_provider.dart';
import 'package:nafahat/providers/user_provider.dart';
import 'package:nafahat/pages/widgets/chatbot/chatbot_wrapper.dart';
import 'package:nafahat/models/training_model.dart';
import 'package:nafahat/services/payment_service.dart';
import 'package:nafahat/services/training_service.dart';
import 'package:nafahat/pages/formation/formation_detail_page.dart';
import 'package:nafahat/pages/paiement/paiement_tranche_page.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================================
// PALETTE MODERNE
// ============================================================
class UXColors {
  static const Color bgStart = Color(0xFFF8FAFC);
  static const Color bgEnd = Color(0xFFEEF2F7);
  static const Color surface = Colors.white;
  static const Color primary = Color(0xFF0D443E);
  static const Color primaryLight = Color(0xFF1A6B60);
  static const Color primarySoft = Color(0xFFE6F0EE);
  static const Color accent = Color(0xFFD57653);
  static const Color accentLight = Color(0xFFF4A484);
  static const Color accentSoft = Color(0xFFFDF2EC);
  static const Color success = Color(0xFF10B981);
  static const Color successSoft = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerSoft = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoSoft = Color(0xFFDBEAFE);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
}

// ============================================================
// MODÈLE
// ============================================================
class FormationAvecPaiement {
  final TrainingModel formation;
  final Map<String, dynamic> paiement;

  FormationAvecPaiement({required this.formation, required this.paiement});

  String get typePaiement => paiement['type_paiement'] ?? 'formation';
  bool get isMensuel => typePaiement == 'mois';
  String get statut => paiement['statut_paiement'] ?? 'en_attente';

  double get montantTotal =>
      double.tryParse(paiement['formation_prix']?.toString() ?? '0') ?? 0;
  double get montantPaye =>
      double.tryParse(paiement['montant_paye']?.toString() ?? '0') ?? 0;
  double get montantRestant =>
      double.tryParse(paiement['montant_restant']?.toString() ?? '0') ?? 0;
  double get montantMensuel =>
      double.tryParse(paiement['montant_mensuel']?.toString() ?? '0') ?? 0;

  int get paiementsEffectues {
    final v = paiement['paiements_effectues'];
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '0') ?? 0;
  }

  int get nombreMois {
    final v = paiement['nombre_mois'];
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '1') ?? 1;
  }

  String get paymentId => paiement['id']?.toString() ?? '';

  double get trancheEnAttente {
    final v = paiement['tranche_en_attente'];
    if (v == null) return 0;
    return double.tryParse(v.toString()) ?? 0;
  }

  bool get aTrancheEnAttente => trancheEnAttente > 0;

  DateTime? get prochaineDate {
    final dateStr = paiement['prochain_paiement_date'];
    if (dateStr == null || dateStr.toString().isEmpty) return null;
    try {
      return DateTime.parse(dateStr.toString());
    } catch (_) {
      return null;
    }
  }

  bool get estTermine => montantRestant <= 0;

  bool get estEnRetard {
    if (estTermine || !isMensuel) return false;
    final date = prochaineDate;
    if (date == null) return false;
    return date.isBefore(DateTime.now());
  }

  bool get estAccessible {
    if (estTermine) return true;
    if (isMensuel && estEnRetard) return false;
    return true;
  }

  int? get joursRestants {
    final date = prochaineDate;
    if (date == null) return null;
    return date.difference(DateTime.now()).inDays;
  }

  double get progression {
    if (montantTotal <= 0) return 0;
    return (montantPaye / montantTotal).clamp(0.0, 1.0);
  }
}

// ============================================================
// PAGE PRINCIPALE
// ============================================================
class ProfileDashboardPage extends StatefulWidget {
  const ProfileDashboardPage({super.key});

  @override
  State<ProfileDashboardPage> createState() => _ProfileDashboardPageState();
}

class _ProfileDashboardPageState extends State<ProfileDashboardPage>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _showEnCours = true;
  bool _showTerminees = false;
  bool _showHistorique = false;

  List<FormationAvecPaiement> _formationsEnCours = [];
  List<FormationAvecPaiement> _formationsTerminees = [];
  List<Map<String, dynamic>> _historiquePayments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserFormations();
  }

  Future<void> _loadUserFormations() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (!userProvider.isLoggedIn || userProvider.userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final userId = userProvider.userId!.toString();
      final payments = await PaymentService.getUserPayments(userId);

      final acceptedPayments = payments.where((p) {
        final statut = p['statut_paiement'] ?? '';
        return statut == 'valide' || statut == 'en_attente';
      }).toList();

      List<FormationAvecPaiement> formationsAvecPaiement = [];

      for (var payment in acceptedPayments) {
        final formationId = payment['formation_id'];
        if (formationId == null) continue;

        try {
          final training = await TrainingService.getTraining(
            formationId.toString(),
          );
          if (training != null) {
            formationsAvecPaiement.add(
              FormationAvecPaiement(formation: training, paiement: payment),
            );
          }
        } catch (e) {
          debugPrint('❌ Erreur chargement formation $formationId: $e');
        }
      }

      final now = DateTime.now();
      _formationsEnCours = formationsAvecPaiement.where((f) {
        if (f.formation.dateFin.isEmpty) return true;
        try {
          final dateFin = DateTime.parse(f.formation.dateFin);
          return dateFin.isAfter(now);
        } catch (_) {
          return true;
        }
      }).toList();

      _formationsTerminees = formationsAvecPaiement.where((f) {
        if (f.formation.dateFin.isEmpty) return false;
        try {
          final dateFin = DateTime.parse(f.formation.dateFin);
          return dateFin.isBefore(now);
        } catch (_) {
          return false;
        }
      }).toList();

      _historiquePayments = payments.take(20).toList();
    } catch (e) {
      debugPrint('❌ Erreur chargement formations: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ============================================================
  // LIEN EXTERNE
  // ============================================================

  Future<void> _ouvrirLien(String url) async {
    try {
      String cleanUrl = url.trim();
      if (!cleanUrl.startsWith('http://') &&
          !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }
      final uri = Uri.parse(cleanUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Impossible d\'ouvrir le lien');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${e.toString()}', style: GoogleFonts.cairo()),
            backgroundColor: UXColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  IconData _getLienIcon(String lien) {
    final url = lien.toLowerCase();
    if (url.contains('wa.me') || url.contains('whatsapp')) {
      return Icons.chat_bubble_rounded;
    }
    if (url.contains('t.me') || url.contains('telegram')) {
      return Icons.send_rounded;
    }
    if (url.contains('mailto:') || url.contains('@')) {
      return Icons.email_rounded;
    }
    if (url.contains('facebook') || url.contains('fb.com')) {
      return Icons.facebook_rounded;
    }
    if (url.contains('instagram')) {
      return Icons.camera_alt_rounded;
    }
    if (url.contains('youtube') || url.contains('youtu.be')) {
      return Icons.play_circle_fill_rounded;
    }
    return Icons.link_rounded;
  }

  Color _getLienColor(String lien) {
    final url = lien.toLowerCase();
    if (url.contains('wa.me') || url.contains('whatsapp')) {
      return const Color(0xff25D366);
    }
    if (url.contains('t.me') || url.contains('telegram')) {
      return const Color(0xff0088cc);
    }
    if (url.contains('mailto:') || url.contains('@')) {
      return UXColors.warning;
    }
    if (url.contains('facebook') || url.contains('fb.com')) {
      return const Color(0xff1877f2);
    }
    if (url.contains('instagram')) {
      return const Color(0xffe1306c);
    }
    if (url.contains('youtube') || url.contains('youtu.be')) {
      return const Color(0xffff0000);
    }
    return UXColors.primary;
  }

  String _getLienLabel(String lien, bool isArabic) {
    final url = lien.toLowerCase();
    if (url.contains('wa.me') || url.contains('whatsapp')) {
      return isArabic ? 'انضم لمجموعة واتساب' : 'Rejoindre WhatsApp';
    }
    if (url.contains('t.me') || url.contains('telegram')) {
      return isArabic ? 'انضم لتليجرام' : 'Rejoindre Telegram';
    }
    if (url.contains('mailto:')) {
      return isArabic ? 'إرسال بريد' : 'Envoyer un email';
    }
    if (url.contains('facebook')) {
      return isArabic ? 'زيارة فيسبوك' : 'Visiter Facebook';
    }
    if (url.contains('instagram')) {
      return isArabic ? 'زيارة إنستغرام' : 'Visiter Instagram';
    }
    if (url.contains('youtube') || url.contains('youtu.be')) {
      return isArabic ? 'مشاهدة الفيديو' : 'Regarder la vidéo';
    }
    return isArabic ? 'فتح الرابط' : 'Ouvrir le lien';
  }

  // ============================================================
  // PAIEMENT TRANCHE
  // ============================================================

  Future<void> _payerTranche(FormationAvecPaiement fp) async {
    final isArabic =
        Provider.of<LanguageProvider>(context, listen: false).isArabic;

    if (fp.aTrancheEnAttente) {
      _showSnack(
        isArabic
            ? '⚠️ لديك قسط في انتظار الموافقة'
            : '⚠️ Vous avez une tranche en attente',
        UXColors.warning,
      );
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PaiementTranchePage(
          paymentId: fp.paymentId,
          montantTranche: fp.montantMensuel,
          numeroTranche: fp.paiementsEffectues + 1,
          nombreMois: fp.nombreMois,
          montantRestant: fp.montantRestant,
          formationTitre:
              isArabic ? fp.formation.titleAr : fp.formation.titleFr,
          montantMensuel: fp.montantMensuel,
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadUserFormations();
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ============================================================
  // STATISTIQUES GLOBALES
  // ============================================================

  Map<String, dynamic> _computeStats() {
    final all = [..._formationsEnCours, ..._formationsTerminees];
    double totalPaye = 0;
    double totalRestant = 0;
    int actives = 0;
    int enRetard = 0;
    int terminees = 0;

    for (var f in all) {
      totalPaye += f.montantPaye;
      totalRestant += f.montantRestant;
      if (f.estTermine) {
        terminees++;
      } else {
        actives++;
        if (f.estEnRetard) enRetard++;
      }
    }

    return {
      'total': all.length,
      'actives': actives,
      'terminees': terminees,
      'enRetard': enRetard,
      'totalPaye': totalPaye,
      'totalRestant': totalRestant,
    };
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;
    final userProvider = Provider.of<UserProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: ChatbotWrapper(
        apiBaseUrl: 'http://localhost:3000',
        langue: isArabic ? 'ar' : 'fr',
        primaryColor: UXColors.accent,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: UXColors.bgStart,
          drawer: Navbar(
            isMobile: isMobile,
            scaffoldKey: _scaffoldKey,
          ).buildDrawer(context),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                // ============================================================
                // ✅ NAVBAR EN HAUT (JAMAIS RECOUVERT, TOUJOURS CLIQUABLE)
                // ============================================================
                Material(
                  color: Colors.white,
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.08),
                  child: SizedBox(
                    height: 85,
                    child: Navbar(
                      isMobile: isMobile,
                      scaffoldKey: _scaffoldKey,
                    ),
                  ),
                ),

                // ============================================================
                // ✅ CONTENU SCROLLABLE (SOUS LE NAVBAR)
                // ============================================================
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [UXColors.bgStart, UXColors.bgEnd],
                      ),
                    ),
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: UXColors.primary,
                            ),
                          )
                        : SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(
                              top: 20,
                              bottom: 60,
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      isMobile ? double.infinity : 1100,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 16 : 32,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildHeroProfile(
                                          isArabic, userProvider),
                                      const SizedBox(height: 24),
                                      _buildStatsRow(isArabic),
                                      const SizedBox(height: 32),
                                      _buildSection(
                                        isArabic: isArabic,
                                        titleFr:
                                            'Mes Formations en Cours',
                                        titleAr: 'تكويناتي الجارية',
                                        icon: Icons.school_rounded,
                                        color: UXColors.info,
                                        count:
                                            _formationsEnCours.length,
                                        isExpanded: _showEnCours,
                                        onToggle: () => setState(() {
                                          _showEnCours = !_showEnCours;
                                          _showTerminees = false;
                                          _showHistorique = false;
                                        }),
                                        child: _buildFormationsGrid(
                                          _formationsEnCours,
                                          isArabic,
                                          isMobile,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildSection(
                                        isArabic: isArabic,
                                        titleFr:
                                            'Mes Formations Terminées',
                                        titleAr: 'تكويناتي المنتهية',
                                        icon: Icons.verified_rounded,
                                        color: UXColors.success,
                                        count:
                                            _formationsTerminees.length,
                                        isExpanded: _showTerminees,
                                        onToggle: () => setState(() {
                                          _showTerminees =
                                              !_showTerminees;
                                          _showEnCours = false;
                                          _showHistorique = false;
                                        }),
                                        child: _buildFormationsGrid(
                                          _formationsTerminees,
                                          isArabic,
                                          isMobile,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildSection(
                                        isArabic: isArabic,
                                        titleFr:
                                            'Historique des paiements',
                                        titleAr: 'سجل المدفوعات',
                                        icon: Icons.history_rounded,
                                        color: UXColors.accent,
                                        count:
                                            _historiquePayments.length,
                                        isExpanded: _showHistorique,
                                        onToggle: () => setState(() {
                                          _showHistorique =
                                              !_showHistorique;
                                          _showEnCours = false;
                                          _showTerminees = false;
                                        }),
                                        child: _buildHistorique(
                                            isArabic, isMobile),
                                      ),
                                      const SizedBox(height: 40),
                                    ],
                                  ),
                                ),
                              ),
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

  // ============================================================
  // HERO PROFILE
  // ============================================================

  Widget _buildHeroProfile(bool isArabic, UserProvider userProvider) {
    final userName =
        userProvider.isLoggedIn ? userProvider.displayName : 'Utilisateur';
    final userEmail = userProvider.isLoggedIn
        ? (userProvider.userEmail ?? 'email@exemple.com')
        : 'email@exemple.com';
    final userRole =
        userProvider.isLoggedIn && userProvider.userRole != null
            ? userProvider.userRole!.libelle
            : '';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [UXColors.primary, UXColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: UXColors.primary.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Cercles décoratifs
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          // Contenu
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: UXColors.accent,
                  child: Text(
                    userProvider.isLoggedIn ? userProvider.initials : 'U',
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            isArabic
                                ? "مرحباً، $userName"
                                : "Bienvenue, $userName",
                            style: GoogleFonts.cairo(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (userRole.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              userRole,
                              style: GoogleFonts.cairo(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.email_rounded,
                            size: 14,
                            color: Colors.white.withOpacity(0.8)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            userEmail,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (userProvider.isLoggedIn &&
                        userProvider.userWhatsapp != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone_rounded,
                              size: 14,
                              color: Colors.white.withOpacity(0.8)),
                          const SizedBox(width: 6),
                          Text(
                            userProvider.userWhatsapp!,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfilePage(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATISTIQUES
  // ============================================================

  Widget _buildStatsRow(bool isArabic) {
    final stats = _computeStats();
    final isMobile = MediaQuery.of(context).size.width < 850;

    final items = [
      {
        'icon': Icons.school_rounded,
        'value': '${stats['total']}',
        'label': isArabic ? 'التكوينات' : 'Formations',
        'color': UXColors.info,
        'bg': UXColors.infoSoft,
      },
      {
        'icon': Icons.trending_up_rounded,
        'value': '${stats['actives']}',
        'label': isArabic ? 'جارية' : 'En cours',
        'color': UXColors.warning,
        'bg': UXColors.warningSoft,
      },
      {
        'icon': Icons.verified_rounded,
        'value': '${stats['terminees']}',
        'label': isArabic ? 'منتهية' : 'Terminées',
        'color': UXColors.success,
        'bg': UXColors.successSoft,
      },
      {
        'icon': Icons.warning_amber_rounded,
        'value': '${stats['enRetard']}',
        'label': isArabic ? 'متأخرة' : 'En retard',
        'color': UXColors.danger,
        'bg': UXColors.dangerSoft,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14, left: 4),
          child: Text(
            isArabic ? '📊 نظرة عامة' : '📊 Vue d\'ensemble',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: UXColors.textDark,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 2 : 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: isMobile ? 1.4 : 1.6,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            return _buildStatCard(
              icon: item['icon'] as IconData,
              value: item['value'] as String,
              label: item['label'] as String,
              color: item['color'] as Color,
              bg: item['bg'] as Color,
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: UXColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: UXColors.textDark,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: UXColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION REPLIABLE
  // ============================================================

  Widget _buildSection({
    required bool isArabic,
    required String titleFr,
    required String titleAr,
    required IconData icon,
    required Color color,
    required int count,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isExpanded ? color.withOpacity(0.4) : UXColors.border,
          width: isExpanded ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpanded
                ? color.withOpacity(0.08)
                : Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isArabic ? titleAr : titleFr,
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: UXColors.textDark,
                        ),
                      ),
                    ),
                    if (count > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$count',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: color,
                        size: 26,
                      ),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: child,
                  ),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GRILLE FORMATIONS
  // ============================================================

  Widget _buildFormationsGrid(
    List<FormationAvecPaiement> formations,
    bool isArabic,
    bool isMobile,
  ) {
    if (formations.isEmpty) {
      return _buildEmptyState(isArabic);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        int cols = 1;
        if (screenWidth >= 1200) {
          cols = 3;
        } else if (screenWidth >= 850) {
          cols = 2;
        }

        if (cols == 1) {
          return Column(
            children: formations
                .map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildFormationCard(f, isArabic),
                    ))
                .toList(),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: formations.length,
          itemBuilder: (context, index) =>
              _buildFormationCard(formations[index], isArabic),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: UXColors.bgStart,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: UXColors.border, style: BorderStyle.solid),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: UXColors.infoSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_outlined,
                size: 40,
                color: UXColors.info,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isArabic
                  ? 'لا توجد تكوينات في هذه الفئة'
                  : 'Aucune formation dans cette catégorie',
              style: GoogleFonts.cairo(
                color: UXColors.textMuted,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CARTE FORMATION MODERNE
  // ============================================================

  Widget _buildFormationCard(FormationAvecPaiement fp, bool isArabic) {
    final formation = fp.formation;
    final isAccessible = fp.estAccessible;
    final isEnRetard = fp.estEnRetard;
    final isTermine = fp.estTermine;
    final isMensuel = fp.isMensuel;
    final aTrancheEnAttente = fp.aTrancheEnAttente;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (aTrancheEnAttente) {
      statusColor = UXColors.info;
      statusLabel = isArabic ? 'في انتظار الموافقة' : 'En attente';
      statusIcon = Icons.hourglass_top_rounded;
    } else if (isTermine) {
      statusColor = UXColors.success;
      statusLabel = isArabic ? 'مدفوع بالكامل' : 'Payé intégralement';
      statusIcon = Icons.verified_rounded;
    } else if (isEnRetard) {
      statusColor = UXColors.danger;
      statusLabel = isArabic ? 'متأخر' : 'En retard';
      statusIcon = Icons.warning_amber_rounded;
    } else if (isMensuel) {
      statusColor = UXColors.warning;
      statusLabel = isArabic
          ? 'القسط ${fp.paiementsEffectues + 1}/${fp.nombreMois}'
          : 'Tranche ${fp.paiementsEffectues + 1}/${fp.nombreMois}';
      statusIcon = Icons.schedule_rounded;
    } else {
      statusColor = UXColors.info;
      statusLabel = isArabic ? 'مدفوع' : 'Payé';
      statusIcon = Icons.check_circle_rounded;
    }

    return _HoverCard(
      onTap: isAccessible
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FormationDetailPage(
                    formationId: formation.id.toString(),
                  ),
                ),
              );
            }
          : () => _showLockedDialog(isArabic),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isEnRetard
                ? UXColors.danger.withOpacity(0.5)
                : (isTermine
                    ? UXColors.success.withOpacity(0.4)
                    : UXColors.border),
            width: isEnRetard ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isEnRetard
                  ? UXColors.danger.withOpacity(0.15)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    color: UXColors.primarySoft,
                    child: formation.imageUrl.isNotEmpty
                        ? Image.network(
                            formation.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(
                                Icons.school_rounded,
                                color: UXColors.primary.withOpacity(0.4),
                                size: 50,
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.school_rounded,
                              color: UXColors.primary.withOpacity(0.4),
                              size: 50,
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon,
                                size: 13, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel,
                              style: GoogleFonts.cairo(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (!isAccessible)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: UXColors.danger,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: UXColors.danger.withOpacity(0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            // Contenu
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? formation.titleAr : formation.titleFr,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: UXColors.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_rounded,
                          size: 13, color: UXColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          formation.trainer,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: UXColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // ✅ Lien externe
                  if (isAccessible &&
                      !aTrancheEnAttente &&
                      formation.hasLien) ...[
                    const SizedBox(height: 12),
                    _buildLienButton(formation.lien!, isArabic),
                  ],

                  // ⚠️ Rappel de paiement
                  if (!isAccessible && isMensuel) ...[
                    const SizedBox(height: 12),
                    _buildRappelPaiement(isArabic),
                  ],

                  // Progression
                  if (isMensuel && !isTermine) ...[
                    const SizedBox(height: 14),
                    _buildProgressSection(fp, isArabic, isEnRetard),
                    const SizedBox(height: 12),
                    _buildMontantsRow(fp, isArabic),
                    const SizedBox(height: 12),
                    _buildEcheanceInfo(
                        fp, isArabic, isEnRetard, aTrancheEnAttente),
                    const SizedBox(height: 12),
                    _buildPayButton(fp, isArabic, isEnRetard, aTrancheEnAttente),
                  ],

                  // Terminé
                  if (isTermine && isMensuel) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: UXColors.successSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: UXColors.success.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.emoji_events_rounded,
                              color: UXColors.success, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isArabic
                                  ? '🎉 تم إتمام جميع الأقساط'
                                  : '🎉 Toutes les tranches payées',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: UXColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Verrouillé
                  if (!isAccessible) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: UXColors.dangerSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_rounded,
                              color: UXColors.danger, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isArabic
                                  ? 'الوصول معطل - دفع القسط المتأخر'
                                  : 'Accès verrouillé - Payez la tranche',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: UXColors.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PROGRESSION
  // ============================================================

  Widget _buildProgressSection(
      FormationAvecPaiement fp, bool isArabic, bool isEnRetard) {
    final color = isEnRetard ? UXColors.danger : UXColors.primary;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isArabic ? 'التقدم' : 'Progression',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: UXColors.textMuted,
                    ),
                  ),
                  Text(
                    '${(fp.progression * 100).toInt()}%',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: fp.progression,
                  minHeight: 8,
                  backgroundColor: UXColors.border,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMontantsRow(FormationAvecPaiement fp, bool isArabic) {
    return Row(
      children: [
        Expanded(
          child: _buildMiniInfoCard(
            Icons.arrow_downward_rounded,
            isArabic ? 'المدفوع' : 'Payé',
            '${fp.montantPaye.toStringAsFixed(0)} DT',
            UXColors.success,
            UXColors.successSoft,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMiniInfoCard(
            Icons.arrow_upward_rounded,
            isArabic ? 'المتبقي' : 'Restant',
            '${fp.montantRestant.toStringAsFixed(0)} DT',
            UXColors.warning,
            UXColors.warningSoft,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniInfoCard(
    IconData icon,
    String label,
    String value,
    Color color,
    Color bg,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 9,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEcheanceInfo(
    FormationAvecPaiement fp,
    bool isArabic,
    bool isEnRetard,
    bool aTrancheEnAttente,
  ) {
    if (aTrancheEnAttente) {
      return _buildInfoBanner(
        Icons.hourglass_top_rounded,
        isArabic
            ? 'القسط ${fp.paiementsEffectues + 1} (${fp.trancheEnAttente.toStringAsFixed(0)} DT) في انتظار الموافقة'
            : 'Tranche ${fp.paiementsEffectues + 1} (${fp.trancheEnAttente.toStringAsFixed(0)} DT) en attente',
        UXColors.info,
        UXColors.infoSoft,
      );
    }

    if (fp.prochaineDate != null) {
      if (isEnRetard) {
        final joursRetard =
            fp.prochaineDate!.difference(DateTime.now()).inDays.abs();
        return _buildInfoBanner(
          Icons.error_outline_rounded,
          isArabic
              ? 'متأخر بـ $joursRetard يوم - كان يجب الدفع قبل ${_formatDate(fp.prochaineDate!)}'
              : 'En retard de $joursRetard j - avant le ${_formatDate(fp.prochaineDate!)}',
          UXColors.danger,
          UXColors.dangerSoft,
        );
      }
      final jours = fp.joursRestants ?? 0;
      return _buildInfoBanner(
        Icons.event_available_rounded,
        isArabic
            ? 'القسط القادم بعد $jours يوم (${_formatDate(fp.prochaineDate!)})'
            : 'Prochaine échéance dans $jours j (${_formatDate(fp.prochaineDate!)})',
        UXColors.info,
        UXColors.infoSoft,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildInfoBanner(
    IconData icon,
    String text,
    Color color,
    Color bg,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton(
    FormationAvecPaiement fp,
    bool isArabic,
    bool isEnRetard,
    bool aTrancheEnAttente,
  ) {
    final color = aTrancheEnAttente
        ? UXColors.textLight
        : (isEnRetard ? UXColors.danger : UXColors.primary);

    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: aTrancheEnAttente ? null : () => _payerTranche(fp),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: UXColors.border,
          disabledForegroundColor: UXColors.textLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: aTrancheEnAttente ? 0 : 3,
          shadowColor: color.withOpacity(0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              aTrancheEnAttente
                  ? Icons.hourglass_top_rounded
                  : Icons.payments_rounded,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              aTrancheEnAttente
                  ? (isArabic ? 'في انتظار الموافقة' : 'En attente')
                  : (isArabic
                      ? 'دفع ${fp.montantMensuel.toStringAsFixed(0)} DT'
                      : 'Payer ${fp.montantMensuel.toStringAsFixed(0)} DT'),
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOUTON LIEN MODERNE
  // ============================================================

  Widget _buildLienButton(String lien, bool isArabic) {
    final color = _getLienColor(lien);
    final icon = _getLienIcon(lien);
    final label = _getLienLabel(lien, isArabic);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _ouvrirLien(lien),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.15),
                color.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // RAPPEL DE PAIEMENT
  // ============================================================

  Widget _buildRappelPaiement(bool isArabic) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [UXColors.warningSoft, UXColors.dangerSoft],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: UXColors.warning.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: UXColors.warning,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: UXColors.warning.withOpacity(0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.priority_high_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'يرجى دفع القسط' : 'Paiement requis',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: UXColors.textDark,
                  ),
                ),
                Text(
                  isArabic
                      ? 'الرابط غير متوفر حتى تسدد القسط'
                      : 'Lien indisponible avant paiement',
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    color: UXColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HISTORIQUE
  // ============================================================

  Widget _buildHistorique(bool isArabic, bool isMobile) {
    if (_historiquePayments.isEmpty) {
      return _buildEmptyState(isArabic);
    }

    return Column(
      children: _historiquePayments.map((p) {
        final statut = p['statut_paiement'] ?? 'en_attente';
        Color statutColor;
        String statutLabel;

        switch (statut) {
          case 'valide':
            statutColor = UXColors.success;
            statutLabel = isArabic ? 'مقبول' : 'Validé';
            break;
          case 'refuse':
            statutColor = UXColors.danger;
            statutLabel = isArabic ? 'مرفوض' : 'Refusé';
            break;
          case 'annule':
            statutColor = UXColors.textLight;
            statutLabel = isArabic ? 'ملغى' : 'Annulé';
            break;
          default:
            statutColor = UXColors.warning;
            statutLabel = isArabic ? 'في انتظار' : 'En attente';
        }

        final montant =
            double.tryParse(p['montant_paye']?.toString() ?? '0') ?? 0;
        final formationTitre = isArabic
            ? (p['formation_titre_ar'] ?? 'N/A')
            : (p['formation_titre_fr'] ?? 'N/A');

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: UXColors.bgStart,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: UXColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statutColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: statutColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formationTitre,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: UXColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p['reference_paiement'] ?? '',
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: UXColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${montant.toStringAsFixed(0)} DT',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: UXColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statutColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statutLabel,
                      style: GoogleFonts.cairo(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // UTILITAIRES
  // ============================================================

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  void _showLockedDialog(bool isArabic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: UXColors.dangerSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded,
                  color: UXColors.danger, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              isArabic ? 'التكوين معطل' : 'Formation verrouillée',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          isArabic
              ? 'لا يمكنك الوصول إلى هذا التكوين حتى تسدد القسط المتأخر.'
              : 'Vous ne pouvez pas accéder à cette formation tant que vous n\'avez pas payé la tranche en retard.',
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: UXColors.textMuted,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              isArabic ? 'حسناً' : 'OK',
              style: GoogleFonts.cairo(
                color: UXColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// WIDGET HOVER (pour cartes interactives)
// ============================================================

class _HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _HoverCard({required this.child, this.onTap});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
          child: widget.child,
        ),
      ),
    );
  }
}