// lib/models/training_model.dart
class TrainingModel {
  final String id;
  final String titleFr;
  final String titleAr;
  final int? idTypeFormation;
  final String typeFormation; // nom du type depuis la table type_formation
  final String descriptionFr;
  final String descriptionAr;
  final int? idDuree;
  final String typeDuree; // nom de la durée depuis la table duree
  final String trainer;
  final String target;
  final String period;
  final String dateDebut;
  final String dateFin;
  final String imageUrl;
  final double price;
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
    required this.hasDiscount,
    this.discountValue,
    required this.isPercentageDiscount,
    this.categorieFr = '',
    this.categorieAr = '',
    this.categorieId,
    this.formateurId,
  });

  Map<String, dynamic> toJson() => {
    'titre_fr': titleFr,
    'titre_ar': titleAr,
    'id_type_formation': idTypeFormation,
    'cible_fr': target,
    'cible_ar': target,
    'id_duree': idDuree,
    'date_debut': dateDebut,
    'date_fin': dateFin,
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
      imageUrl: json['imageUrl'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
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
      price: double.parse(json['prix']?.toString() ?? '0'),
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
