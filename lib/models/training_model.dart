// lib/models/training_model.dart
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
  });

  // ============================================================
  // MÉTHODES DE PRIX PAR DEVISE
  // ============================================================

  /// Obtenir le prix selon le pays (code pays ISO)
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
        // Pour les autres pays, utiliser la devise par défaut (DT)
        return priceDt;
    }
  }

  /// Obtenir le prix final avec réduction appliquée
  double getFinalPriceForCurrency(String countryCode) {
    final basePrice = getPriceForCurrency(countryCode);
    if (!hasDiscount || discountValue == null) return basePrice;
    if (isPercentageDiscount) {
      return basePrice - (basePrice * discountValue! / 100);
    } else {
      // Réduction en montant fixe
      return basePrice - discountValue!;
    }
  }

  /// Obtenir le symbole de la devise pour un pays
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

  /// Obtenir le nom complet de la devise
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

  /// Obtenir le prix formaté avec symbole
  String getPriceWithSymbol(String countryCode) {
    final price = getPriceForCurrency(countryCode);
    final symbol = getCurrencySymbol(countryCode);
    return '${price.toStringAsFixed(0)} $symbol';
  }

  /// Obtenir le prix final formaté avec symbole
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
      // Convertir le montant de la réduction pour la devise
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
    return [
      cibleCh1,
      cibleCh2,
      cibleCh3,
    ].where((e) => e != null && e.isNotEmpty).map((e) => e!).toList();
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
      discountValue:
          json['valeur_disc'] != null
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
    );
  }
}
