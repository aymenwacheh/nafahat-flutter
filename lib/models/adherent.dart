import 'package:intl/intl.dart';

class Adherent {
  int? id;
  String whatsapp, nomPrenom, pays, ville, email, genre, sourceConnaissance;
  DateTime dateNaissance;
  String? sourceAutreDetail, objectif, suggestions;
  bool accordPublication;
  DateTime? createdAt;

  // ✅ Nouveau champ pour les identifiants de connexion
  String? motDePasse;
  int? accesId;

  Adherent({
    this.id,
    required this.whatsapp,
    required this.nomPrenom,
    required this.pays,
    required this.ville,
    required this.email,
    required this.dateNaissance,
    required this.genre,
    required this.sourceConnaissance,
    this.sourceAutreDetail,
    this.objectif,
    this.suggestions,
    required this.accordPublication,
    this.createdAt,
    this.motDePasse,
    this.accesId,
  });

  factory Adherent.fromJson(Map<String, dynamic> json) {
    return Adherent(
      id: json['id'],
      whatsapp: json['whatsapp'] ?? '',
      nomPrenom: json['nom_prenom'] ?? json['nomPrenom'] ?? '',
      pays: json['pays'] ?? '',
      ville: json['ville'] ?? '',
      email: json['email'] ?? '',
      dateNaissance:
          json['date_naissance'] != null
              ? DateTime.parse(json['date_naissance'])
              : DateTime.now(),
      genre: json['genre'] ?? 'homme',
      sourceConnaissance:
          json['source_connaissance'] ??
          json['sourceConnaissance'] ??
          'instagram',
      sourceAutreDetail:
          json['source_autre_detail'] ?? json['sourceAutreDetail'],
      objectif: json['objectif'],
      suggestions: json['suggestions'],
      accordPublication:
          json['accord_publication'] == 1 || json['accordPublication'] == true,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      motDePasse: json['mot_de_passe'],
      accesId: json['acces_id'],
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'whatsapp': whatsapp,
    'nomPrenom': nomPrenom,
    'pays': pays,
    'ville': ville,
    'email': email,
    'dateNaissance': DateFormat('yyyy-MM-dd').format(dateNaissance),
    'genre': genre,
    'sourceConnaissance': sourceConnaissance,
    'sourceAutreDetail': sourceAutreDetail,
    'objectif': objectif,
    'suggestions': suggestions,
    'accordPublication': accordPublication,
    if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
    if (motDePasse != null) 'mot_de_passe': motDePasse,
    if (accesId != null) 'acces_id': accesId,
  };
}
