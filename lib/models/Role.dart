// lib/models/role.dart
class Role {
  final int id;
  final String nom;
  final String libelle;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Role({
    required this.id,
    required this.nom,
    required this.libelle,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'],
      nom: json['nom'],
      libelle: json['libelle'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'libelle': libelle,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() => libelle;
}
