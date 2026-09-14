// lib/pages/users/profile_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:nafahat/pages/widgets/mobile_bottom_nav_bar.dart';
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
import 'package:nafahat/pages/paiement/paiement_tranche_page.dart';  // ✅ AJOUTÉ

class ProfileDashboardPage extends StatefulWidget {
  const ProfileDashboardPage({super.key});

  @override
  State<ProfileDashboardPage> createState() => _ProfileDashboardPageState();
}

/// ✅ Classe qui contient les infos d'un paiement + formation
class FormationAvecPaiement {
  final TrainingModel formation;
  final Map<String, dynamic> paiement;

  FormationAvecPaiement({required this.formation, required this.paiement});

  // Type de paiement
  String get typePaiement => paiement['type_paiement'] ?? 'formation';
  bool get isMensuel => typePaiement == 'mois';

  // Statut du paiement
  String get statut => paiement['statut_paiement'] ?? 'en_attente';

  // Montants
  double get montantTotal =>
      double.tryParse(paiement['formation_prix']?.toString() ?? '0') ?? 0;
  double get montantPaye =>
      double.tryParse(paiement['montant_paye']?.toString() ?? '0') ?? 0;
  double get montantRestant =>
      double.tryParse(paiement['montant_restant']?.toString() ?? '0') ?? 0;
  double get montantMensuel =>
      double.tryParse(paiement['montant_mensuel']?.toString() ?? '0') ?? 0;

  // Progression
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

  // ✅ ID du paiement
  String get paymentId => paiement['id']?.toString() ?? '';

  // ✅ URL de la quittance en attente (le cas échéant)
  String? get trancheQuittanceUrl => paiement['tranche_quittance_url'];

  // ✅ Montant en attente de validation
  double get trancheEnAttente {
    final v = paiement['tranche_en_attente'];
    if (v == null) return 0;
    return double.tryParse(v.toString()) ?? 0;
  }

  bool get aTrancheEnAttente => trancheEnAttente > 0;

  // Date du prochain paiement
  DateTime? get prochaineDate {
    final dateStr = paiement['prochain_paiement_date'];
    if (dateStr == null || dateStr.toString().isEmpty) return null;
    try {
      return DateTime.parse(dateStr.toString());
    } catch (_) {
      return null;
    }
  }

  // ✅ Logique métier
  bool get estTermine => montantRestant <= 0;
  bool get estEnRetard {
    if (estTermine || !isMensuel) return false;
    final date = prochaineDate;
    if (date == null) return false;
    return date.isBefore(DateTime.now());
  }

  bool get estPayeComplet => estTermine;

  /// La formation est-elle accessible (débloquée) ?
  bool get estAccessible {
    if (estTermine) return true;
    if (isMensuel && estEnRetard) return false;
    return true;
  }
}

class _ProfileDashboardPageState extends State<ProfileDashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _showEnCours = true;
  bool _showTerminees = false;

  List<FormationAvecPaiement> _formationsEnCours = [];
  List<FormationAvecPaiement> _formationsTerminees = [];
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

      // ✅ On garde les paiements validés OU en attente (pas refusés)
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
          print('❌ Erreur chargement formation $formationId: $e');
        }
      }

      // ✅ Trier : en cours vs terminées
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
    } catch (e) {
      print('❌ Erreur chargement formations: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ============================================================
  // ✅ PAYER UNE TRANCHE → REDIRIGER VERS LA NOUVELLE PAGE
  // ============================================================

  Future<void> _payerTranche(FormationAvecPaiement fp) async {
    final isArabic =
        Provider.of<LanguageProvider>(context, listen: false).isArabic;

    // Vérifier qu'il n'y a pas déjà une tranche en attente
    if (fp.aTrancheEnAttente) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? '⚠️ لديك قسط في انتظار الموافقة'
                : '⚠️ Vous avez une tranche en attente de validation',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Naviguer vers la page de paiement de tranche
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PaiementTranchePage(
          paymentId: fp.paymentId,
          montantTranche: fp.montantMensuel,
          numeroTranche: fp.paiementsEffectues + 1,
          nombreMois: fp.nombreMois,
          montantRestant: fp.montantRestant,
          formationTitre: isArabic
              ? fp.formation.titleAr
              : fp.formation.titleFr,
          montantMensuel: fp.montantMensuel,
        ),
      ),
    );

    // Recharger si succès
    if (result == true && mounted) {
      await _loadUserFormations();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;
    final userProvider = Provider.of<UserProvider>(context);
    final isMobile = MediaQuery.of(context).size.width < 850;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: ChatbotWrapper(
        apiBaseUrl: 'http://localhost:3000',
        langue: isArabic ? 'ar' : 'fr',
        primaryColor: AppColors.primary,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.surface,
          drawer: Navbar(
            isMobile: isMobile,
            scaffoldKey: _scaffoldKey,
          ).buildDrawer(context),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(top: 100),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProfileSection(isArabic, userProvider),
                              const SizedBox(height: 32),

                              _buildSectionHeader(
                                isArabic: isArabic,
                                titleFr: 'Mes Formations en Cours',
                                titleAr: 'تكويناتي الجارية',
                                count: _formationsEnCours.length,
                                isExpanded: _showEnCours,
                                onToggle: () {
                                  setState(() {
                                    _showEnCours = !_showEnCours;
                                    _showTerminees = false;
                                  });
                                },
                              ),
                              if (_showEnCours) ...[
                                const SizedBox(height: 16),
                                _buildFormationsList(
                                  _formationsEnCours,
                                  isArabic,
                                  isMobile,
                                ),
                              ],
                              const SizedBox(height: 24),

                              _buildSectionHeader(
                                isArabic: isArabic,
                                titleFr: 'Mes Formations Terminées',
                                titleAr: 'تكويناتي المنتهية',
                                count: _formationsTerminees.length,
                                isExpanded: _showTerminees,
                                onToggle: () {
                                  setState(() {
                                    _showTerminees = !_showTerminees;
                                    _showEnCours = false;
                                  });
                                },
                              ),
                              if (_showTerminees) ...[
                                const SizedBox(height: 16),
                                _buildFormationsList(
                                  _formationsTerminees,
                                  isArabic,
                                  isMobile,
                                ),
                              ],
                              const SizedBox(height: 60),
                            ],
                          ),
                        ),
                      ),

                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 85,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Navbar(
                            isMobile: isMobile,
                            scaffoldKey: _scaffoldKey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(bool isArabic, UserProvider userProvider) {
    final userName =
        userProvider.isLoggedIn ? userProvider.displayName : 'Utilisateur';
    final userEmail =
        userProvider.isLoggedIn
            ? (userProvider.userEmail ?? 'email@exemple.com')
            : 'email@exemple.com';
    final userRole =
        userProvider.isLoggedIn && userProvider.userRole != null
            ? userProvider.userRole!.libelle
            : '';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              userProvider.isLoggedIn ? userProvider.initials : 'U',
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isArabic ? "مرحباً، $userName" : "Bienvenue, $userName",
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (userRole.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          userRole,
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
                if (userProvider.isLoggedIn &&
                    userProvider.userWhatsapp != null)
                  Text(
                    userProvider.userWhatsapp!,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.textMuted.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.edit_note_rounded,
              color: AppColors.primary,
              size: 28,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(),
                ),
              );
            },
            tooltip: isArabic ? "تعديل الملف الشخصي" : "Modifier le profil",
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required bool isArabic,
    required String titleFr,
    required String titleAr,
    required int count,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color:
              isExpanded ? AppColors.primary.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded ? AppColors.primary : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isArabic ? titleAr : titleFr,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            if (!_isLoading && count > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
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
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormationsList(
    List<FormationAvecPaiement> formations,
    bool isArabic,
    bool isMobile,
  ) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (formations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.school_outlined, size: 60, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                isArabic
                    ? 'لا توجد تكوينات في هذه الفئة'
                    : 'Aucune formation dans cette catégorie',
                style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: formations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildFormationCard(formations[index], isArabic);
      },
    );
  }

  // ============================================================
  // ✅ CARTE DE FORMATION AVEC STATUT DE PAIEMENT
  // ============================================================

  Widget _buildFormationCard(FormationAvecPaiement fp, bool isArabic) {
    final formation = fp.formation;
    final isAccessible = fp.estAccessible;
    final isEnRetard = fp.estEnRetard;
    final isTermine = fp.estTermine;
    final isMensuel = fp.isMensuel;
    final aTrancheEnAttente = fp.aTrancheEnAttente;

    // Couleurs selon le statut
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (aTrancheEnAttente) {
      statusColor = Colors.blue.shade700;
      statusLabel = isArabic
          ? '⏳ قسط في انتظار الموافقة'
          : '⏳ Tranche en attente';
      statusIcon = Icons.hourglass_top;
    } else if (isTermine) {
      statusColor = Colors.green.shade700;
      statusLabel = isArabic ? '✅ مدفوع بالكامل' : '✅ Payé intégralement';
      statusIcon = Icons.check_circle;
    } else if (isEnRetard) {
      statusColor = Colors.red.shade700;
      statusLabel = isArabic ? '⚠️ متأخر' : '⚠️ En retard';
      statusIcon = Icons.warning_amber_rounded;
    } else if (isMensuel) {
      statusColor = Colors.orange.shade700;
      statusLabel = isArabic
          ? '📅 القسط ${fp.paiementsEffectues + 1}/${fp.nombreMois}'
          : '📅 Tranche ${fp.paiementsEffectues + 1}/${fp.nombreMois}';
      statusIcon = Icons.schedule;
    } else {
      statusColor = Colors.blue.shade700;
      statusLabel = isArabic ? '✅ مدفوع' : '✅ Payé';
      statusIcon = Icons.check_circle;
    }

    return AnimatedOpacity(
      opacity: isAccessible ? 1.0 : 0.55,
      duration: const Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEnRetard
                ? Colors.red.shade300
                : (aTrancheEnAttente
                    ? Colors.blue.shade300
                    : (isTermine
                        ? Colors.green.shade200
                        : AppColors.primary.withOpacity(0.15))),
            width: isEnRetard ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isEnRetard
                  ? Colors.red.withOpacity(0.08)
                  : Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
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
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade100,
                          child: formation.imageUrl.isNotEmpty
                              ? Image.network(
                                  formation.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.school_outlined,
                                    color: Colors.grey.shade400,
                                    size: 32,
                                  ),
                                )
                              : Icon(
                                  Icons.school_outlined,
                                  color: Colors.grey.shade400,
                                  size: 32,
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isArabic
                                  ? formation.titleAr
                                  : formation.titleFr,
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    statusIcon,
                                    size: 14,
                                    color: statusColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusLabel,
                                    style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isAccessible)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock_rounded,
                            color: Colors.red.shade700,
                            size: 20,
                          ),
                        ),
                    ],
                  ),

                  // ✅ Section paiement mensuel
                  if (isMensuel && !isTermine) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Barre de progression
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isArabic
                              ? 'التقدم: ${fp.paiementsEffectues}/${fp.nombreMois}'
                              : 'Progression : ${fp.paiementsEffectues}/${fp.nombreMois}',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          '${((fp.paiementsEffectues / fp.nombreMois) * 100).toInt()}%',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fp.paiementsEffectues / fp.nombreMois,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(
                          isEnRetard ? Colors.red.shade600 : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Détails montants
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoBox(
                            isArabic ? 'المدفوع' : 'Payé',
                            '${fp.montantPaye.toStringAsFixed(0)} DT',
                            Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildInfoBox(
                            isArabic ? 'المتبقي' : 'Restant',
                            '${fp.montantRestant.toStringAsFixed(0)} DT',
                            Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),

                    // ✅ Info tranche en attente
                    if (aTrancheEnAttente) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.hourglass_top,
                              color: Colors.blue.shade700,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isArabic
                                    ? '⏳ القسط ${fp.paiementsEffectues + 1} بمبلغ ${fp.trancheEnAttente.toStringAsFixed(0)} DT في انتظار الموافقة'
                                    : '⏳ Tranche ${fp.paiementsEffectues + 1} de ${fp.trancheEnAttente.toStringAsFixed(0)} DT en attente de validation',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]
                    // Date du prochain paiement
                    else if (fp.prochaineDate != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isEnRetard
                              ? Colors.red.shade50
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isEnRetard
                                ? Colors.red.shade200
                                : Colors.blue.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isEnRetard
                                  ? Icons.error_outline
                                  : Icons.event_available,
                              color: isEnRetard
                                  ? Colors.red.shade700
                                  : Colors.blue.shade700,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isEnRetard
                                    ? (isArabic
                                        ? '⚠️ القسط التالي متأخر! كان يجب دفعه قبل ${_formatDate(fp.prochaineDate!)}'
                                        : '⚠️ Tranche en retard ! À payer avant le ${_formatDate(fp.prochaineDate!)}')
                                    : (isArabic
                                        ? '📅 القسط التالي: ${_formatDate(fp.prochaineDate!)}'
                                        : '📅 Prochaine tranche : ${_formatDate(fp.prochaineDate!)}'),
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isEnRetard
                                      ? Colors.red.shade800
                                      : Colors.blue.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ✅ Bouton payer (désactivé si tranche en attente)
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: aTrancheEnAttente
                            ? null
                            : () => _payerTranche(fp),
                        icon: Icon(
                          aTrancheEnAttente
                              ? Icons.hourglass_top
                              : Icons.payment_rounded,
                          size: 18,
                        ),
                        label: Text(
                          aTrancheEnAttente
                              ? (isArabic
                                  ? 'في انتظار الموافقة'
                                  : 'En attente de validation')
                              : (isArabic
                                  ? 'دفع القسط (${fp.montantMensuel.toStringAsFixed(0)} DT)'
                                  : 'Payer la tranche (${fp.montantMensuel.toStringAsFixed(0)} DT)'),
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: aTrancheEnAttente
                              ? Colors.grey.shade400
                              : (isEnRetard
                                  ? Colors.red.shade600
                                  : AppColors.primary),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Info si payé complètement
                  if (isTermine && isMensuel) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            color: Colors.green.shade700,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isArabic
                                  ? '🎉 تم إتمام جميع الأقساط'
                                  : '🎉 Toutes les tranches payées',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Message si verrouillé
                  if (!isAccessible) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            color: Colors.red.shade700,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isArabic
                                  ? '🔒 الوصول معطل - دفع القسط المتأخر للفتح'
                                  : '🔒 Accès verrouillé - Payez la tranche en retard',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade800,
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
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  void _showLockedDialog(bool isArabic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.red.shade700),
            const SizedBox(width: 12),
            Text(
              isArabic ? '🔒 التكوين معطل' : '🔒 Formation verrouillée',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          isArabic
              ? 'لا يمكنك الوصول إلى هذا التكوين حتى تسدد القسط المتأخر.'
              : 'Vous ne pouvez pas accéder à cette formation tant que vous n\'avez pas payé la tranche en retard.',
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: Colors.grey.shade700,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              isArabic ? 'حسناً' : 'OK',
              style: GoogleFonts.cairo(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppColors {
  static const Color surface = Color(0xfffcfbfa);
  static const Color primary = Color(0xffd57653);
  static const Color textDark = Color(0xff2c221e);
  static const Color textMuted = Color(0xff7c6e68);
  static const Color primaryDark = Color(0xff994a2b);
}