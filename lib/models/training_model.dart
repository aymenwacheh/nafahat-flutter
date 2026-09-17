// lib/models/training_model.dart
import 'dart:convert';

class TrainingModel {
  final String id;
  final String titleFr;
  final String titleAr;
  final int? idTypeFormation;
  final String typeFormation;
  final String descriptionFr;
  final String descriptionAr;
  final int? idDuree;
  final String typeDuree;
  final String trainer;
  final String target;
  final String period;
  final String dateDebut;
  final String dateFin;
  final String imageUrl;

  final double price;
  final double priceDt;
  final double priceEur;
  final double priceUsd;

  final bool hasDiscount;
  final double? discountValue;
  final bool isPercentageDiscount;
  final String categorieFr;
  final String categorieAr;
  final int? categorieId;
  final int? formateurId;

  final int? cibleId;
  final String cibleNom;
  final String? cibleCh1;
  final String? cibleCh2;
  final String? cibleCh3;

  // ✅ Détails de la durée
  final int nbrHeur;
  final int nbrSeance;
  final int nbrJour;

  // ✅ Types de paiement autorisés
  final List<String> typesPaiementAutorises;

  // ✅ NOUVEAU : Lien externe
  final String? lien;

  TrainingModel({
    required this.id,
    required this.titleFr,
    required this.titleAr,
    this.idTypeFormation,
    this.typeFormation = '',
    required this.descriptionFr,
    required this.descriptionAr,
    this.idDuree,
    this.typeDuree = '',
    required this.trainer,
    required this.target,
    required this.period,
    this.dateDebut = '',
    this.dateFin = '',
    required this.imageUrl,
    required this.price,
    required this.priceDt,
    required this.priceEur,
    required this.priceUsd,
    required this.hasDiscount,
    this.discountValue,
    required this.isPercentageDiscount,
    this.categorieFr = '',
    this.categorieAr = '',
    this.categorieId,
    this.formateurId,
    this.cibleId,
    this.cibleNom = '',
    this.cibleCh1,
    this.cibleCh2,
    this.cibleCh3,
    this.nbrHeur = 0,
    this.nbrSeance = 0,
    this.nbrJour = 0,
    this.typesPaiementAutorises = const ['formation'],
    this.lien,   // ✅ NOUVEAU
  });

  // ============================================================
  // MÉTHODES DE PRIX PAR DEVISE
  // ============================================================

  double getPriceForCurrency(String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'TN':
        return priceDt;
      case 'FR':
      case 'BE':
      case 'CH':
      case 'DE':
      case 'IT':
      case 'ES':
      case 'PT':
      case 'NL':
      case 'LU':
      case 'AT':
      case 'IE':
        return priceEur;
      case 'US':
      case 'CA':
        return priceUsd;
      default:
        return priceDt;
    }
  }

  double getFinalPriceForCurrency(String countryCode) {
    final basePrice = getPriceForCurrency(countryCode);
    if (!hasDiscount || discountValue == null) return basePrice;
    if (isPercentageDiscount) {
      return basePrice - (basePrice * discountValue! / 100);
    } else {
      return basePrice - discountValue!;
    }
  }

  static String getCurrencySymbol(String countryCode) {
    final symbols = {
      'TN': 'DT',
      'FR': '€',
      'BE': '€',
      'CH': 'CHF',
      'DE': '€',
      'IT': '€',
      'ES': '€',
      'PT': '€',
      'NL': '€',
      'LU': '€',
      'AT': '€',
      'IE': '€',
      'US': '\$',
      'CA': 'CA\$',
      'GB': '£',
      'MA': 'DH',
      'DZ': 'DA',
      'EG': 'EGP',
      'SA': 'SAR',
      'AE': 'AED',
      'KW': 'KWD',
      'QA': 'QAR',
      'BH': 'BHD',
      'OM': 'OMR',
      'JO': 'JOD',
      'LB': 'LBP',
      'SY': 'SYP',
      'IQ': 'IQD',
      'YE': 'YER',
      'LY': 'LYD',
      'MR': 'MRU',
      'SN': 'XOF',
      'CI': 'XOF',
      'BF': 'XOF',
      'BJ': 'XOF',
      'NE': 'XOF',
      'TG': 'XOF',
      'ML': 'XOF',
      'CM': 'XAF',
      'CF': 'XAF',
      'CG': 'XAF',
      'GA': 'XAF',
      'GQ': 'XAF',
    };
    return symbols[countryCode.toUpperCase()] ?? 'DT';
  }

  static String getCurrencyName(String countryCode) {
    final names = {
      'TN': 'Dinar Tunisien',
      'FR': 'Euro',
      'BE': 'Euro',
      'CH': 'Franc Suisse',
      'DE': 'Euro',
      'IT': 'Euro',
      'ES': 'Euro',
      'PT': 'Euro',
      'NL': 'Euro',
      'LU': 'Euro',
      'AT': 'Euro',
      'IE': 'Euro',
      'US': 'Dollar US',
      'CA': 'Dollar Canadien',
      'GB': 'Livre Sterling',
      'MA': 'Dirham Marocain',
      'DZ': 'Dinar Algérien',
      'EG': 'Livre Égyptienne',
      'SA': 'Riyal Saoudien',
      'AE': 'Dirham Émirati',
      'KW': 'Dinar Koweïtien',
      'QA': 'Riyal Qatari',
      'BH': 'Dinar Bahreïni',
      'OM': 'Rial Omani',
      'JO': 'Dinar Jordanien',
      'LB': 'Livre Libanaise',
      'SY': 'Livre Syrienne',
      'IQ': 'Dinar Irakien',
      'YE': 'Rial Yéménite',
      'LY': 'Dinar Libyen',
      'MR': 'Ouguiya Mauritanienne',
      'SN': 'Franc CFA',
      'CI': 'Franc CFA',
      'BF': 'Franc CFA',
      'BJ': 'Franc CFA',
      'NE': 'Franc CFA',
      'TG': 'Franc CFA',
      'ML': 'Franc CFA',
      'CM': 'Franc CFA',
      'CF': 'Franc CFA',
      'CG': 'Franc CFA',
      'GA': 'Franc CFA',
      'GQ': 'Franc CFA',
    };
    return names[countryCode.toUpperCase()] ?? 'Dinar Tunisien';
  }

  String getPriceWithSymbol(String countryCode) {
    final price = getPriceForCurrency(countryCode);
    final symbol = getCurrencySymbol(countryCode);
    return '${price.toStringAsFixed(0)} $symbol';
  }

  String getFinalPriceWithSymbol(String countryCode) {
    final price = getFinalPriceForCurrency(countryCode);
    final symbol = getCurrencySymbol(countryCode);
    return '${price.toStringAsFixed(0)} $symbol';
  }

  // ============================================================
  // MÉTHODES DE RÉDUCTION
  // ============================================================

  double get finalPrice {
    if (!hasDiscount || discountValue == null) return price;
    if (isPercentageDiscount) {
      return price - (price * discountValue! / 100);
    } else {
      return price - discountValue!;
    }
  }

  String getDiscountText(bool isArabic) {
    if (!hasDiscount || discountValue == null) return '';
    if (isPercentageDiscount) {
      return isArabic ? 'خصم $discountValue%' : '-$discountValue%';
    } else {
      final symbol = 'DT';
      return isArabic
          ? 'خصم ${discountValue!.toInt()} $symbol'
          : '-${discountValue!.toInt()} $symbol';
    }
  }

  String getDiscountTextForCurrency(String countryCode, bool isArabic) {
    if (!hasDiscount || discountValue == null) return '';
    final symbol = getCurrencySymbol(countryCode);
    if (isPercentageDiscount) {
      return isArabic ? 'خصم $discountValue%' : '-$discountValue%';
    } else {
      final basePrice = getPriceForCurrency(countryCode);
      final originalPrice = getPriceForCurrency('TN');
      final ratio = originalPrice > 0 ? basePrice / originalPrice : 1;
      final discountAmount = discountValue! * ratio;
      return isArabic
          ? 'خصم ${discountAmount.toInt()} $symbol'
          : '-${discountAmount.toInt()} $symbol';
    }
  }

  // ============================================================
  // MÉTHODES DE CIBLE
  // ============================================================

  String getCibleName(bool isArabic) {
    return cibleNom;
  }

  List<String> get cibleDetails {
    return [cibleCh1, cibleCh2, cibleCh3]
        .where((e) => e != null && e.isNotEmpty)
        .map((e) => e!)
        .toList();
  }

  // ============================================================
  // ✅ Types de paiement autorisés
  // ============================================================

  bool isTypePaiementAutorise(String type) {
    return typesPaiementAutorises.contains(type);
  }

  List<Map<String, dynamic>> getTypesPaiementAvecConfig() {
    const allTypes = {
      'formation': {
        'icon': '🎓',
        'labelFr': 'Paiement complet',
        'labelAr': 'دفع كامل',
        'isPeriodic': false,
      },
      'mois': {
        'icon': '📅',
        'labelFr': 'Paiement mensuel',
        'labelAr': 'دفع شهري',
        'isPeriodic': true,
      },
      'semaine': {
        'icon': '📆',
        'labelFr': 'Paiement hebdomadaire',
        'labelAr': 'دفع أسبوعي',
        'isPeriodic': true,
      },
      'trimestre': {
        'icon': '📊',
        'labelFr': 'Paiement trimestriel',
        'labelAr': 'دفع ربع سنوي',
        'isPeriodic': true,
      },
      'annee': {
        'icon': '🗓️',
        'labelFr': 'Paiement annuel',
        'labelAr': 'دفع سنوي',
        'isPeriodic': true,
      },
      'seance': {
        'icon': '🎯',
        'labelFr': 'Paiement par séance',
        'labelAr': 'دفع بالحصة',
        'isPeriodic': true,
      },
      'heure': {
        'icon': '⏰',
        'labelFr': 'Paiement par heure',
        'labelAr': 'دفع بالساعة',
        'isPeriodic': true,
      },
    };

    return typesPaiementAutorises
        .where((t) => allTypes.containsKey(t))
        .map((t) {
          return {
            'value': t,
            ...allTypes[t]!,
          };
        })
        .toList();
  }

  int getNombrePeriodes(String type) {
    switch (type) {
      case 'mois':
        return _calculerNombreMois();
      case 'semaine':
        return _calculerNombreSemaines();
      case 'trimestre':
        return _calculerNombreTrimestres();
      case 'annee':
        return _calculerNombreAnnees();
      case 'seance':
        return nbrSeance > 0 ? nbrSeance : 1;
      case 'heure':
        return nbrHeur > 0 ? nbrHeur : 1;
      default:
        return 1;
    }
  }

  int _calculerNombreMois() {
    if (dateDebut.isEmpty || dateFin.isEmpty) return 1;
    try {
      final debut = DateTime.parse(dateDebut);
      final fin = DateTime.parse(dateFin);
      int mois = (fin.year - debut.year) * 12 + (fin.month - debut.month);
      if (fin.day >= debut.day) mois += 1;
      return mois > 0 ? mois : 1;
    } catch (_) {
      return 1;
    }
  }

  int _calculerNombreSemaines() {
    if (dateDebut.isEmpty || dateFin.isEmpty) return 1;
    try {
      final debut = DateTime.parse(dateDebut);
      final fin = DateTime.parse(dateFin);
      final jours = fin.difference(debut).inDays + 1;
      final semaines = (jours / 7).ceil();
      return semaines > 0 ? semaines : 1;
    } catch (_) {
      return 1;
    }
  }

  int _calculerNombreTrimestres() {
    final mois = _calculerNombreMois();
    final trimestres = (mois / 3).ceil();
    return trimestres > 0 ? trimestres : 1;
  }

  int _calculerNombreAnnees() {
    if (dateDebut.isEmpty || dateFin.isEmpty) return 1;
    try {
      final debut = DateTime.parse(dateDebut);
      final fin = DateTime.parse(dateFin);
      int annees = fin.year - debut.year;
      if (fin.month > debut.month ||
          (fin.month == debut.month && fin.day >= debut.day)) {
        annees += 1;
      }
      return annees > 0 ? annees : 1;
    } catch (_) {
      return 1;
    }
  }

  // ============================================================
  // ✅ Helpers pour le lien
  // ============================================================

  /// Vérifie si un lien est défini
  bool get hasLien => lien != null && lien!.trim().isNotEmpty;

  /// Retourne le type de lien (whatsapp, telegram, mail, autre)
  String get lienType {
    if (!hasLien) return 'none';
    final url = lien!.toLowerCase();
    if (url.contains('wa.me') || url.contains('whatsapp')) return 'whatsapp';
    if (url.contains('t.me') || url.contains('telegram')) return 'telegram';
    if (url.contains('mailto:') || url.contains('@')) return 'email';
    if (url.contains('facebook.com') || url.contains('fb.com')) return 'facebook';
    if (url.contains('instagram.com')) return 'instagram';
    if (url.contains('youtube.com') || url.contains('youtu.be')) return 'youtube';
    if (url.startsWith('http')) return 'website';
    return 'other';
  }

  // ============================================================
  // JSON
  // ============================================================

  Map<String, dynamic> toJson() => {
        'titre_fr': titleFr,
        'titre_ar': titleAr,
        'id_type_formation': idTypeFormation,
        'cible_fr': target,
        'cible_ar': target,
        'id_duree': idDuree,
        'date_debut': dateDebut,
        'date_fin': dateFin,
        'prix_dt': priceDt,
        'prix_eur': priceEur,
        'prix_usd': priceUsd,
        'prix': price,
        'discount': hasDiscount ? 'oui' : 'non',
        'valeur_disc': discountValue,
        'descri_fr': descriptionFr,
        'descri_ar': descriptionAr,
        'id_categorie': categorieId,
        'id_formateur': formateurId,
        'photo': imageUrl,
        'nbr_heur': nbrHeur,
        'nbr_seance': nbrSeance,
        'nbr_jour': nbrJour,
        'types_paiement_autorises': jsonEncode(typesPaiementAutorises),
        'lien': lien,   // ✅ NOUVEAU
      };

  factory TrainingModel.fromJson(Map<String, dynamic> json) {
    return TrainingModel(
      id: json['id'] ?? '',
      titleFr: json['titleFr'] ?? '',
      titleAr: json['titleAr'] ?? '',
      idTypeFormation: json['idTypeFormation'],
      typeFormation: json['typeFormation'] ?? '',
      descriptionFr: json['descriptionFr'] ?? '',
      descriptionAr: json['descriptionAr'] ?? '',
      idDuree: json['idDuree'],
      typeDuree: json['typeDuree'] ?? '',
      trainer: json['trainer'] ?? '',
      target: json['target'] ?? '',
      period: json['period'] ?? '',
      dateDebut: json['dateDebut'] ?? '',
      dateFin: json['dateFin'] ?? '',
      imageUrl: json['imageUrl'] ?? 'https://picsum.photos/800/450',
      price: (json['price'] ?? 0).toDouble(),
      priceDt: (json['priceDt'] ?? 0).toDouble(),
      priceEur: (json['priceEur'] ?? 0).toDouble(),
      priceUsd: (json['priceUsd'] ?? 0).toDouble(),
      hasDiscount: json['hasDiscount'] ?? false,
      discountValue: json['discountValue']?.toDouble(),
      isPercentageDiscount: json['isPercentageDiscount'] ?? true,
      categorieFr: json['categorieFr'] ?? '',
      categorieAr: json['categorieAr'] ?? '',
      categorieId: json['categorieId'],
      formateurId: json['formateurId'],
      cibleId: json['cibleId'],
      cibleNom: json['cibleNom'] ?? '',
      cibleCh1: json['cibleCh1'],
      cibleCh2: json['cibleCh2'],
      cibleCh3: json['cibleCh3'],
      nbrHeur: _toInt(json['nbrHeur']),
      nbrSeance: _toInt(json['nbrSeance']),
      nbrJour: _toInt(json['nbrJour']),
      typesPaiementAutorises: _parseTypesPaiement(json['typesPaiementAutorises']),
      lien: json['lien']?.toString(),   // ✅ NOUVEAU
    );
  }

  factory TrainingModel.fromApiJson(Map<String, dynamic> json) {
    // Traitement de l'image
    String imageUrl;
    String? photoValue = json['photo']?.toString();

    if (photoValue == null || photoValue.isEmpty || photoValue == 'null') {
      photoValue = json['imageUrl']?.toString();
    }

    if (photoValue != null && photoValue.isNotEmpty && photoValue != 'null') {
      String photo = photoValue;

      if (photo.contains('http://www.nafahat-academy.com')) {
        imageUrl = photo;
      } else if (photo.contains('http://localhost:3000')) {
        if (photo.contains('http://localhost:3000http://localhost:3000')) {
          imageUrl = photo.replaceAll(
            'http://localhost:3000http://localhost:3000',
            'http://localhost:3000',
          );
        } else {
          imageUrl = photo;
        }
      } else if (photo.startsWith('http://') || photo.startsWith('https://')) {
        imageUrl = photo;
      } else if (photo.startsWith('/uploads')) {
        imageUrl = 'http://www.nafahat-academy.com$photo';
      } else if (photo.contains('C:\\') || photo.contains('\\')) {
        String fileName = photo.split('\\').last;
        imageUrl =
            'http://www.nafahat-academy.com/uploads/formations/$fileName';
      } else {
        imageUrl = 'http://www.nafahat-academy.com/uploads/formations/$photo';
      }
    } else {
      imageUrl = 'https://picsum.photos/800/450';
    }

    // ✅ Parser les types de paiement autorisés
    List<String> typesPaiement = _parseTypesPaiement(json['types_paiement_autorises']);

    // ✅ Récupérer le lien (peut être null ou vide)
    final String? lienValue = json['lien']?.toString();
    final String? lienFinal =
        (lienValue != null && lienValue.trim().isNotEmpty)
            ? lienValue.trim()
            : null;

    return TrainingModel(
      id: json['id']?.toString() ?? '',
      titleFr: json['titre_fr'] ?? '',
      titleAr: json['titre_ar'] ?? '',
      idTypeFormation: json['id_type_formation'],
      typeFormation: json['type_formation'] ?? '',
      descriptionFr: json['descri_fr'] ?? '',
      descriptionAr: json['descri_ar'] ?? '',
      idDuree: json['id_duree'],
      typeDuree: json['type_duree'] ?? '',
      trainer: json['formateur_nom_fr'] ?? json['trainer'] ?? '',
      target: json['cible_nom'] ?? json['cible_fr'] ?? '',
      period: json['periode'] ?? json['period'] ?? '',
      dateDebut: json['date_debut'] ?? '',
      dateFin: json['date_fin'] ?? '',
      imageUrl: imageUrl,
      price: double.tryParse(json['prix_dt']?.toString() ?? '0') ?? 0,
      priceDt: double.tryParse(json['prix_dt']?.toString() ?? '0') ?? 0,
      priceEur: double.tryParse(json['prix_eur']?.toString() ?? '0') ?? 0,
      priceUsd: double.tryParse(json['prix_usd']?.toString() ?? '0') ?? 0,
      hasDiscount: json['discount'] == 'oui' || json['hasDiscount'] == true,
      discountValue: json['valeur_disc'] != null
          ? double.tryParse(json['valeur_disc'].toString())
          : null,
      isPercentageDiscount: json['isPercentageDiscount'] ?? false,
      categorieFr: json['categorie_fr'] ?? '',
      categorieAr: json['categorie_ar'] ?? '',
      categorieId: json['id_categorie'],
      formateurId: json['id_formateur'],
      cibleId: json['id_cible'],
      cibleNom: json['cible_nom'] ?? '',
      cibleCh1: json['cible_ch1'],
      cibleCh2: json['cible_ch2'],
      cibleCh3: json['cible_ch3'],
      nbrHeur: _toInt(json['nbr_heur']),
      nbrSeance: _toInt(json['nbr_seance']),
      nbrJour: _toInt(json['nbr_jour']),
      typesPaiementAutorises: typesPaiement,
      lien: lienFinal,   // ✅ NOUVEAU
    );
  }

  // ============================================================
  // ✅ UTILITAIRES DE PARSING
  // ============================================================

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  static List<String> _parseTypesPaiement(dynamic rawValue) {
    const defaultTypes = ['formation'];

    if (rawValue == null) return defaultTypes;

    if (rawValue is List) {
      final result = rawValue
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      return result.isEmpty ? defaultTypes : result;
    }

    if (rawValue is String) {
      if (rawValue.isEmpty) return defaultTypes;

      try {
        final parsed = jsonDecode(rawValue);
        if (parsed is List) {
          final result = parsed
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
          return result.isEmpty ? defaultTypes : result;
        }
      } catch (e) {
        return [rawValue];
      }
    }

    return defaultTypes;
  }
}