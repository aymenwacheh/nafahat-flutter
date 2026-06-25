class Enfant {
  int? id;
  int? adherentId;
  String nomPrenom;
  DateTime dateNaissance;
  String genre;
  String niveauTilawa; // 'debutant', 'quelques_sourates', 'avance'
  String? memorisation; // 'juz_amma', 'plus_5_hizbs', 'autre'
  String? memorisationAutreDetail;
  String? objectif;
  bool? accordInscription;

  Enfant({
    this.id,
    this.adherentId,
    required this.nomPrenom,
    required this.dateNaissance,
    required this.genre,
    required this.niveauTilawa,
    this.memorisation,
    this.memorisationAutreDetail,
    this.objectif,
    this.accordInscription,
  });

  Map<String, dynamic> toJson() => {
    'nomPrenom': nomPrenom,
    'dateNaissance': dateNaissance.toIso8601String().split('T')[0],
    'genre': genre,
    'niveauTilawa': niveauTilawa,
    'memorisation': memorisation,
    'memorisationAutreDetail': memorisationAutreDetail,
    'objectif': objectif,
    'accordInscription': accordInscription,
  };
}
