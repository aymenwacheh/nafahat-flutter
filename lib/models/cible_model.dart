// lib/models/cible_model.dart
class CibleModel {
  final int? id;
  final String nomCible;
  final String? ch1;
  final String? ch2;
  final String? ch3;
  final String? createdAt;
  final String? updatedAt;

  CibleModel({
    this.id,
    required this.nomCible,
    this.ch1,
    this.ch2,
    this.ch3,
    this.createdAt,
    this.updatedAt,
  });

  factory CibleModel.fromJson(Map<String, dynamic> json) {
    return CibleModel(
      id: json['id'],
      nomCible: json['nom_cible'] ?? '',
      ch1: json['ch1'],
      ch2: json['ch2'],
      ch3: json['ch3'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'nom_cible': nomCible, 'ch1': ch1, 'ch2': ch2, 'ch3': ch3};
  }

  List<String> get nonEmptyFields {
    return [
      ch1,
      ch2,
      ch3,
    ].where((f) => f != null && f.isNotEmpty).map((f) => f!).toList();
  }
}
