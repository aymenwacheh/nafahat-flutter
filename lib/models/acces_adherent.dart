class AccesAdherent {
  int? id;
  int adherentId;
  String nomPrenom;
  String whatsapp;
  String motDePasse;
  DateTime? createdAt;
  DateTime? updatedAt;

  AccesAdherent({
    this.id,
    required this.adherentId,
    required this.nomPrenom,
    required this.whatsapp,
    required this.motDePasse,
    this.createdAt,
    this.updatedAt,
  });

  factory AccesAdherent.fromJson(Map<String, dynamic> json) {
    return AccesAdherent(
      id: json['id'],
      adherentId: json['adherent_id'] ?? json['adherentId'] ?? 0,
      nomPrenom: json['nom_prenom'] ?? json['nomPrenom'] ?? '',
      whatsapp: json['whatsapp'] ?? '',
      motDePasse: json['mot_de_passe'] ?? json['motDePasse'] ?? '',
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'adherent_id': adherentId,
    'nom_prenom': nomPrenom,
    'whatsapp': whatsapp,
    'mot_de_passe': motDePasse,
  };
}
