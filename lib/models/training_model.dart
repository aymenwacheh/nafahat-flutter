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

  // ✅ ANCIEN CHAMP (conservé pour compatibilité)
  final double price;

  // ✅ NOUVEAUX CHAMPS PRIX MULTI-DEVISES
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
  });

  // ✅ METHODE POUR OBTENIR LE PRIX SELON LA DEVISE
  double getPriceForCurrency(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'TN':
        return priceDt;
      case 'FR':
        return priceEur;
      case 'BE':
        return priceEur;
      case 'CH':
        return priceEur;
      case 'US':
        return priceUsd;
      case 'CA':
        return priceUsd;
      default:
        return priceDt;
    }
  }

  // ✅ METHODE POUR OBTENIR LE SYMBOLE DE LA DEVISE
  // ⚠️ Utilisation d'une méthode statique (non const) pour éviter l'erreur
  static String getCurrencySymbol(String countryCode) {
    // Map non-const car on ne peut pas avoir de const avec des symboles comme '$'
    final symbols = {
      'TN': 'DT',
      'FR': '€',
      'BE': '€',
      'CH': 'CHF',
      'US': '\$', // ✅ Échappement du $ avec \
      'CA': 'CA\$', // ✅ Échappement du $ avec \
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

  // ✅ METHODE POUR OBTENIR LE PRIX AVEC SYMBOLE
  String getPriceWithSymbol(String countryCode) {
    final price = getPriceForCurrency(countryCode);
    final symbol = TrainingModel.getCurrencySymbol(countryCode);
    return '${price.toInt()} $symbol';
  }

  Map<String, dynamic> toJson() => {
    'titre_fr': titleFr,
    'titre_ar': titleAr,
    'id_type_formation': idTypeFormation,
    'cible_fr': target,
    'cible_ar': target,
    'id_duree': idDuree,
    'date_debut': dateDebut,
    'date_fin': dateFin,
    // ✅ Envoyer les 3 prix
    'prix_dt': priceDt,
    'prix_eur': priceEur,
    'prix_usd': priceUsd,
    'prix': price, // Pour compatibilité
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
      imageUrl: json['imageUrl'] ?? '',
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
    );
  }

  factory TrainingModel.fromApiJson(Map<String, dynamic> json) {
    return TrainingModel(
      id: json['id'].toString(),
      titleFr: json['titre_fr'] ?? '',
      titleAr: json['titre_ar'] ?? '',
      idTypeFormation: json['id_type_formation'],
      typeFormation: json['type_formation'] ?? '',
      descriptionFr: json['descri_fr'] ?? '',
      descriptionAr: json['descri_ar'] ?? '',
      idDuree: json['id_duree'],
      typeDuree: json['type_duree'] ?? '',
      trainer: json['formateur_nom_fr'] ?? '',
      target: json['cible_fr'] ?? '',
      period: json['periode'] ?? '',
      dateDebut: json['date_debut'] ?? '',
      dateFin: json['date_fin'] ?? '',
      imageUrl:
          json['photo'] != null
              ? 'http://localhost:3000${json['photo']}'
              : 'https://picsum.photos/800/450',
      // ✅ Lire les 3 prix depuis l'API
      price: double.parse(json['prix_dt']?.toString() ?? '0'),
      priceDt: double.parse(json['prix_dt']?.toString() ?? '0'),
      priceEur: double.parse(json['prix_eur']?.toString() ?? '0'),
      priceUsd: double.parse(json['prix_usd']?.toString() ?? '0'),
      hasDiscount: json['discount'] == 'oui',
      discountValue:
          json['valeur_disc'] != null
              ? double.parse(json['valeur_disc'].toString())
              : null,
      isPercentageDiscount: false,
      categorieFr: json['categorie_fr'] ?? '',
      categorieAr: json['categorie_ar'] ?? '',
      categorieId: json['id_categorie'],
      formateurId: json['id_formateur'],
    );
  }

  double get finalPrice {
    if (!hasDiscount || discountValue == null) return price;
    if (isPercentageDiscount) {
      return price - (price * discountValue! / 100);
    } else {
      return price - discountValue!;
    }
  }

  // ✅ PRIX FINAL PAR DEVISE
  double getFinalPriceForCurrency(String currencyCode) {
    final basePrice = getPriceForCurrency(currencyCode);
    if (!hasDiscount || discountValue == null) return basePrice;
    if (isPercentageDiscount) {
      return basePrice - (basePrice * discountValue! / 100);
    } else {
      return basePrice - discountValue!;
    }
  }

  String getDiscountText(bool isArabic) {
    if (!hasDiscount || discountValue == null) return '';
    if (isPercentageDiscount) {
      return isArabic ? 'خصم $discountValue%' : '-$discountValue%';
    } else {
      return isArabic
          ? 'خصم ${discountValue!.toInt()} د.م'
          : '-${discountValue!.toInt()} DH';
    }
  }
}
