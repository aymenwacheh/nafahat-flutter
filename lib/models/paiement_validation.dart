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

  // Champs du paiement (pour affichage)
  String? adherentNomPrenom;
  String? adherentWhatsapp;
  String? formationTitreFr;
  String? formationTitreAr;
  double formationPrix; // ✅ Changé en double (non nullable)
  String? formationDevise;
  String? modalitePaiement;
  double montantPaye; // ✅ Changé en double (non nullable)
  String? referencePaiement;
  String? statutPaiement;
  String? numeroQuittance;
  String? urlQuittance;

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
    required this.formationPrix, // ✅ Changé en required
    this.formationDevise,
    this.modalitePaiement,
    required this.montantPaye, // ✅ Changé en required
    this.referencePaiement,
    this.statutPaiement,
    this.numeroQuittance,
    this.urlQuittance,
  });

  factory PaiementValidation.fromJson(Map<String, dynamic> json) {
    return PaiementValidation(
      id: json['id'],
      paiementId: json['paiement_id'] ?? 0,
      validePar: json['valide_par'],
      statut: json['statut'] ?? 'en_attente',
      dateValidation:
          json['date_validation'] != null
              ? DateTime.parse(json['date_validation'])
              : null,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      commentaire: json['commentaire'],
      validateurNom: json['validateur_nom'],
      validateurWhatsapp: json['validateur_whatsapp'],
      adherentNomPrenom: json['adherent_nom_prenom'],
      adherentWhatsapp: json['adherent_whatsapp'],
      formationTitreFr: json['formation_titre_fr'],
      formationTitreAr: json['formation_titre_ar'],
      // ✅ Convertir les prix String → double
      formationPrix: _toDouble(json['formation_prix']),
      formationDevise: json['formation_devise'] ?? 'TND',
      modalitePaiement: json['modalite_paiement'],
      // ✅ Convertir les montants String → double
      montantPaye: _toDouble(json['montant_paye']),
      referencePaiement: json['reference_paiement'],
      statutPaiement: json['statut_paiement'],
      numeroQuittance: json['numero_quittance'],
      urlQuittance: json['url_quittance'],
    );
  }

  // ✅ Fonction utilitaire pour convertir en double
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

  Map<String, dynamic> toJson() {
    return {
      'paiement_id': paiementId,
      'valide_par': validePar,
      'statut': statut,
      'commentaire': commentaire,
    };
  }
}
