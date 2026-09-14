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
      id: json['id'],
      paiementId: json['paiement_id'] ?? 0,
      validePar: json['valide_par'],
      statut: json['statut'] ?? 'en_attente',
      dateValidation: json['date_validation'] != null
          ? DateTime.parse(json['date_validation'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      commentaire: json['commentaire'],
      validateurNom: json['validateur_nom'],
      validateurWhatsapp: json['validateur_whatsapp'],
      adherentNomPrenom: json['adherent_nom_prenom'],
      adherentWhatsapp: json['adherent_whatsapp'],
      formationTitreFr: json['formation_titre_fr'],
      formationTitreAr: json['formation_titre_ar'],
      formationPrix: _toDouble(json['formation_prix']),
      formationDevise: json['formation_devise'] ?? 'TND',
      modalitePaiement: json['modalite_paiement'],
      montantPaye: _toDouble(json['montant_paye']),
      referencePaiement: json['reference_paiement'],
      statutPaiement: json['statut_paiement'],
      numeroQuittance: json['numero_quittance'],
      urlQuittance: json['url_quittance'],
      // ✅ Nouveaux champs
      typePaiement: json['type_paiement'] ?? 'formation',
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
      trancheQuittanceUrl: json['tranche_quittance_url'],
      trancheNumero: _toInt(json['tranche_numero'], defaultValue: 0),
    );
  }

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

  // ✅ Getters
  bool get isMensuel => typePaiement == 'mois';
  bool get aTrancheEnAttente =>
      (trancheEnAttente != null && trancheEnAttente! > 0);
  bool get estTermine => montantRestant <= 0;

  /// Libellé de la tranche : "2/4" ou "-"
  String get libelleTranche {
    if (!isMensuel) return '-';
    if (estTermine) return 'Payé';
    return '${paiementsEffectues}/${nombreMois}';
  }

  /// Prochaine tranche à payer
  String get prochaineTrancheLabel {
    if (!isMensuel) return '-';
    if (estTermine) return 'Terminé';
    if (aTrancheEnAttente) {
      return '⏳ ${trancheNumero}/${nombreMois}';
    }
    return '${paiementsEffectues + 1}/${nombreMois}';
  }

  Map<String, dynamic> toJson() {
    return {
      'paiement_id': paiementId,
      'valide_par': validePar,
      'statut': statut,
      'commentaire': commentaire,
    };
  }
}