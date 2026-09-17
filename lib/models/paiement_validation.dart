// lib/models/paiement_validation.dart

class PaiementValidation {
  int? id;
  int paiementId;
  int? validePar;
  String statut;
  DateTime? dateValidation;
  DateTime createdAt;
  String? commentaire;

  // Champs de jointure
  String? validateurNom;
  String? validateurWhatsapp;

  // Champs du paiement
  String? adherentNomPrenom;
  String? adherentWhatsapp;
  String? formationTitreFr;
  String? formationTitreAr;
  double formationPrix;
  String? formationDevise;
  String? modalitePaiement;
  double montantPaye;
  String? referencePaiement;
  String? statutPaiement;
  String? numeroQuittance;
  String? urlQuittance;

  // ✅ NOUVEAUX CHAMPS
  String? typePaiement;       // 'mois' ou 'formation'
  double montantAPayer;       // Montant échéance
  int nombreMois;             // Nombre de mois total
  double? montantMensuel;     // Mensualité
  double montantRestant;      // Reste à payer
  int paiementsEffectues;     // Nombre de tranches payées
  DateTime? prochainPaiementDate; // Prochaine date
  double? trancheEnAttente;   // Montant tranche en attente
  String? trancheQuittanceUrl;// Quittance tranche en attente
  int trancheNumero;          // N° de la tranche en attente

  PaiementValidation({
    this.id,
    required this.paiementId,
    this.validePar,
    required this.statut,
    this.dateValidation,
    required this.createdAt,
    this.commentaire,
    this.validateurNom,
    this.validateurWhatsapp,
    this.adherentNomPrenom,
    this.adherentWhatsapp,
    this.formationTitreFr,
    this.formationTitreAr,
    required this.formationPrix,
    this.formationDevise,
    this.modalitePaiement,
    required this.montantPaye,
    this.referencePaiement,
    this.statutPaiement,
    this.numeroQuittance,
    this.urlQuittance,
    // ✅ Nouveaux champs
    this.typePaiement,
    this.montantAPayer = 0.0,
    this.nombreMois = 1,
    this.montantMensuel,
    this.montantRestant = 0.0,
    this.paiementsEffectues = 0,
    this.prochainPaiementDate,
    this.trancheEnAttente,
    this.trancheQuittanceUrl,
    this.trancheNumero = 0,
  });

  factory PaiementValidation.fromJson(Map<String, dynamic> json) {
    return PaiementValidation(
      id: _toIntOrNull(json['id']),
      paiementId: _toInt(json['paiement_id'], defaultValue: 0),
      validePar: _toIntOrNull(json['valide_par']),
      statut: json['statut']?.toString() ?? 'en_attente',
      dateValidation: json['date_validation'] != null
          ? DateTime.tryParse(json['date_validation'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      commentaire: json['commentaire']?.toString(),
      validateurNom: json['validateur_nom']?.toString(),
      validateurWhatsapp: json['validateur_whatsapp']?.toString(),
      adherentNomPrenom: json['adherent_nom_prenom']?.toString(),
      adherentWhatsapp: json['adherent_whatsapp']?.toString(),
      formationTitreFr: json['formation_titre_fr']?.toString(),
      formationTitreAr: json['formation_titre_ar']?.toString(),
      formationPrix: _toDouble(json['formation_prix']),
      formationDevise: json['formation_devise']?.toString() ?? 'TND',
      modalitePaiement: json['modalite_paiement']?.toString(),
      montantPaye: _toDouble(json['montant_paye']),
      referencePaiement: json['reference_paiement']?.toString(),
      statutPaiement: json['statut_paiement']?.toString(),
      numeroQuittance: json['numero_quittance']?.toString(),
      urlQuittance: json['url_quittance']?.toString(),
      // ✅ Nouveaux champs
      typePaiement: json['type_paiement']?.toString() ?? 'formation',
      montantAPayer: _toDouble(json['montant_a_payer']),
      nombreMois: _toInt(json['nombre_mois'], defaultValue: 1),
      montantMensuel: json['montant_mensuel'] != null
          ? _toDouble(json['montant_mensuel'])
          : null,
      montantRestant: _toDouble(json['montant_restant']),
      paiementsEffectues: _toInt(json['paiements_effectues'], defaultValue: 0),
      prochainPaiementDate: json['prochain_paiement_date'] != null
          ? DateTime.tryParse(json['prochain_paiement_date'].toString())
          : null,
      trancheEnAttente: json['tranche_en_attente'] != null
          ? _toDouble(json['tranche_en_attente'])
          : null,
      trancheQuittanceUrl: json['tranche_quittance_url']?.toString(),
      trancheNumero: _toInt(json['tranche_numero'], defaultValue: 0),
    );
  }

  // ============================================================
  // ✅ UTILITAIRES DE CONVERSION ROBUSTES
  // ============================================================

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(',', '.').trim();
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  static int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? defaultValue;
    return defaultValue;
  }

  static int? _toIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  // ============================================================
  // ✅ GETTERS SÉCURISÉS
  // ============================================================

  bool get isMensuel => typePaiement == 'mois';

  bool get aTrancheEnAttente {
    final v = trancheEnAttente;
    return v != null && v > 0;
  }

  bool get estTermine => montantRestant <= 0;

  /// Libellé de la tranche : "2/4" ou "-"
  String get libelleTranche {
    if (!isMensuel) return '-';
    if (estTermine) return 'Payé';
    return '$paiementsEffectues/$nombreMois';
  }

  /// Prochaine tranche à payer
  String get prochaineTrancheLabel {
    if (!isMensuel) return '-';
    if (estTermine) return 'Terminé';
    if (aTrancheEnAttente) {
      return '⏳ $trancheNumero/$nombreMois';
    }
    return '${paiementsEffectues + 1}/$nombreMois';
  }

  Map<String, dynamic> toJson() {
    return {
      'paiement_id': paiementId,
      'valide_par': validePar,
      'statut': statut,
      'commentaire': commentaire,
    };
  }
    // ============================================================
  // ✅ GETTERS POUR LES TYPES DE PAIEMENT
  // ============================================================

  /// Label du type de paiement
  String getTypeLabel(bool isArabic) {
    switch (typePaiement) {
      case 'formation':
        return isArabic ? 'دفع كامل' : 'Paiement complet';
      case 'mois':
        return isArabic ? 'دفع شهري' : 'Paiement mensuel';
      case 'semaine':
        return isArabic ? 'دفع أسبوعي' : 'Paiement hebdomadaire';
      case 'trimestre':
        return isArabic ? 'دفع ربع سنوي' : 'Paiement trimestriel';
      case 'annee':
        return isArabic ? 'دفع سنوي' : 'Paiement annuel';
      case 'seance':
        return isArabic ? 'دفع بالحصة' : 'Paiement par séance';
      default:
        return isArabic ? 'دفع' : 'Paiement';
    }
  }

  /// Icône du type de paiement
  String getTypeIcon() {
    switch (typePaiement) {
      case 'formation':
        return '🎓';
      case 'mois':
        return '📅';
      case 'semaine':
        return '📆';
      case 'trimestre':
        return '📊';
      case 'annee':
        return '🗓️';
      case 'seance':
        return '🎯';
      default:
        return '💳';
    }
  }

  /// Libellé court de la période (mois, semaines, etc.)
  String getPeriodeLabel(bool isArabic) {
    final n = nombreMois > 0 ? nombreMois : 1;
    switch (typePaiement) {
      case 'mois':
        return isArabic ? '$n شهر' : '$n mois';
      case 'semaine':
        return isArabic ? '$n أسبوع' : '$n sem.';
      case 'trimestre':
        return isArabic ? '$n ربع' : '$n trim.';
      case 'annee':
        return isArabic ? '$n سنة' : '$n an';
      case 'seance':
        return isArabic ? '$n حصة' : '$n séance';
      default:
        return '';
    }
  }
}