// lib/models/formateur.dart
class Formateur {
  final int id;
  final String nomPrenomFr;
  final String nomPrenomAr;
  final String? email;
  final String? telephone;
  final String? bioFr;
  final String? bioAr;
  final int? idCategorie;
  final String? photo;
  final String? categorieFr;
  final String? categorieAr;

  Formateur({
    required this.id,
    required this.nomPrenomFr,
    required this.nomPrenomAr,
    this.email,
    this.telephone,
    this.bioFr,
    this.bioAr,
    this.idCategorie,
    this.photo,
    this.categorieFr,
    this.categorieAr,
  });

  factory Formateur.fromJson(Map<String, dynamic> json) {
    return Formateur(
      id: json['id'] ?? 0,
      nomPrenomFr: json['nom_prenom_fr'] ?? '',
      nomPrenomAr: json['nom_prenom_ar'] ?? '',
      email: json['email'],
      telephone: json['telephone'],
      bioFr: json['bio_fr'],
      bioAr: json['bio_ar'],
      idCategorie: json['id_categorie'],
      photo: json['photo'],
      categorieFr: json['categorie_fr'],
      categorieAr: json['categorie_ar'],
    );
  }
}
