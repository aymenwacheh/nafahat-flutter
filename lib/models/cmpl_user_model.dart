// lib/models/cmpl_user_model.dart

/// Modèle pour les informations complémentaires des utilisateurs
/// pour les formations religieuses (catégorie ID = 1)
class CmplUser {
  final int? id;
  final int adherentId;
  final int formationId;
  final String niveauMemorisation;
  final String? niveauMemorisationAutre;
  final String? souratesOuDjouzMaitrises;
  final String? rythmeMemorisationHebdo;
  final String? rythmeMemorisationHebdoAutre;
  final bool etudeTajwidTheorique;
  final String riwayaSouhaitee;
  final String? riwayaSouhaiteeAutre;
  final String lectureMushaf;
  final bool aIjaza;
  final String? detailsIjaza;
  final String? objectifPrincipal;
  final String? creneauHoraire;
  final String? parcoursPrefere;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CmplUser({
    this.id,
    required this.adherentId,
    required this.formationId,
    this.niveauMemorisation = 'debutant',
    this.niveauMemorisationAutre,
    this.souratesOuDjouzMaitrises,
    this.rythmeMemorisationHebdo,
    this.rythmeMemorisationHebdoAutre,
    this.etudeTajwidTheorique = false,
    this.riwayaSouhaitee = 'hafs',
    this.riwayaSouhaiteeAutre,
    this.lectureMushaf = 'madinah',
    this.aIjaza = false,
    this.detailsIjaza,
    this.objectifPrincipal,
    this.creneauHoraire = 'flexible',
    this.parcoursPrefere = 'dynamique',
    this.createdAt,
    this.updatedAt,
  });

  // ============================================================
  // COPY WITH
  // ============================================================
  CmplUser copyWith({
    int? id,
    int? adherentId,
    int? formationId,
    String? niveauMemorisation,
    String? niveauMemorisationAutre,
    String? souratesOuDjouzMaitrises,
    String? rythmeMemorisationHebdo,
    String? rythmeMemorisationHebdoAutre,
    bool? etudeTajwidTheorique,
    String? riwayaSouhaitee,
    String? riwayaSouhaiteeAutre,
    String? lectureMushaf,
    bool? aIjaza,
    String? detailsIjaza,
    String? objectifPrincipal,
    String? creneauHoraire,
    String? parcoursPrefere,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CmplUser(
      id: id ?? this.id,
      adherentId: adherentId ?? this.adherentId,
      formationId: formationId ?? this.formationId,
      niveauMemorisation: niveauMemorisation ?? this.niveauMemorisation,
      niveauMemorisationAutre:
          niveauMemorisationAutre ?? this.niveauMemorisationAutre,
      souratesOuDjouzMaitrises:
          souratesOuDjouzMaitrises ?? this.souratesOuDjouzMaitrises,
      rythmeMemorisationHebdo:
          rythmeMemorisationHebdo ?? this.rythmeMemorisationHebdo,
      rythmeMemorisationHebdoAutre:
          rythmeMemorisationHebdoAutre ?? this.rythmeMemorisationHebdoAutre,
      etudeTajwidTheorique: etudeTajwidTheorique ?? this.etudeTajwidTheorique,
      riwayaSouhaitee: riwayaSouhaitee ?? this.riwayaSouhaitee,
      riwayaSouhaiteeAutre: riwayaSouhaiteeAutre ?? this.riwayaSouhaiteeAutre,
      lectureMushaf: lectureMushaf ?? this.lectureMushaf,
      aIjaza: aIjaza ?? this.aIjaza,
      detailsIjaza: detailsIjaza ?? this.detailsIjaza,
      objectifPrincipal: objectifPrincipal ?? this.objectifPrincipal,
      creneauHoraire: creneauHoraire ?? this.creneauHoraire,
      parcoursPrefere: parcoursPrefere ?? this.parcoursPrefere,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ============================================================
  // FROM JSON
  // ============================================================
  factory CmplUser.fromJson(Map<String, dynamic> json) {
    return CmplUser(
      id: json['id'],
      adherentId: json['adherent_id'] ?? json['adherentId'] ?? 0,
      formationId: json['formation_id'] ?? json['formationId'] ?? 0,
      niveauMemorisation:
          json['niveau_memorisation'] ??
          json['niveauMemorisation'] ??
          'debutant',
      niveauMemorisationAutre:
          json['niveau_memorisation_autre'] ?? json['niveauMemorisationAutre'],
      souratesOuDjouzMaitrises:
          json['sourates_ou_djouz_maitrises'] ??
          json['souratesOuDjouzMaitrises'],
      rythmeMemorisationHebdo:
          json['rythme_memorisation_hebdo'] ?? json['rythmeMemorisationHebdo'],
      rythmeMemorisationHebdoAutre:
          json['rythme_memorisation_hebdo_autre'] ??
          json['rythmeMemorisationHebdoAutre'],
      etudeTajwidTheorique:
          (json['etude_tajwid_theorique'] ??
              json['etudeTajwidTheorique'] ??
              0) ==
          1,
      riwayaSouhaitee:
          json['riwaya_souhaitee'] ?? json['riwayaSouhaitee'] ?? 'hafs',
      riwayaSouhaiteeAutre:
          json['riwaya_souhaitee_autre'] ?? json['riwayaSouhaiteeAutre'],
      lectureMushaf:
          json['lecture_mushaf'] ?? json['lectureMushaf'] ?? 'madinah',
      aIjaza: (json['a_ijaza'] ?? json['aIjaza'] ?? 0) == 1,
      detailsIjaza: json['details_ijaza'] ?? json['detailsIjaza'],
      objectifPrincipal:
          json['objectif_principal'] ?? json['objectifPrincipal'],
      creneauHoraire:
          json['creneau_horaire'] ?? json['creneauHoraire'] ?? 'flexible',
      parcoursPrefere:
          json['parcours_prefere'] ?? json['parcoursPrefere'] ?? 'dynamique',
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

  // ============================================================
  // TO JSON
  // ============================================================
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'adherentId': adherentId,
      'formationId': formationId,
      'niveauMemorisation': niveauMemorisation,
      'niveauMemorisationAutre': niveauMemorisationAutre,
      'souratesOuDjouzMaitrises': souratesOuDjouzMaitrises,
      'rythmeMemorisationHebdo': rythmeMemorisationHebdo,
      'rythmeMemorisationHebdoAutre': rythmeMemorisationHebdoAutre,
      'etudeTajwidTheorique': etudeTajwidTheorique ? 1 : 0,
      'riwayaSouhaitee': riwayaSouhaitee,
      'riwayaSouhaiteeAutre': riwayaSouhaiteeAutre,
      'lectureMushaf': lectureMushaf,
      'aIjaza': aIjaza ? 1 : 0,
      'detailsIjaza': detailsIjaza,
      'objectifPrincipal': objectifPrincipal,
      'creneauHoraire': creneauHoraire,
      'parcoursPrefere': parcoursPrefere,
    };
  }

  // ============================================================
  // TO JSON POUR LE BACKEND (snake_case)
  // ============================================================
  Map<String, dynamic> toJsonForApi() {
    return {
      'niveauMemorisation': niveauMemorisation,
      'niveauMemorisationAutre': niveauMemorisationAutre,
      'souratesOuDjouzMaitrises': souratesOuDjouzMaitrises,
      'rythmeMemorisationHebdo': rythmeMemorisationHebdo,
      'rythmeMemorisationHebdoAutre': rythmeMemorisationHebdoAutre,
      'etudeTajwidTheorique': etudeTajwidTheorique,
      'riwayaSouhaitee': riwayaSouhaitee,
      'riwayaSouhaiteeAutre': riwayaSouhaiteeAutre,
      'lectureMushaf': lectureMushaf,
      'aIjaza': aIjaza,
      'detailsIjaza': detailsIjaza,
      'objectifPrincipal': objectifPrincipal,
      'creneauHoraire': creneauHoraire,
      'parcoursPrefere': parcoursPrefere,
    };
  }

  // ============================================================
  // MÉTHODES UTILES
  // ============================================================

  /// Vérifie si l'utilisateur a déjà complété ses informations
  bool get isComplete {
    return niveauMemorisation.isNotEmpty &&
        riwayaSouhaitee.isNotEmpty &&
        lectureMushaf.isNotEmpty &&
        creneauHoraire != null &&
        parcoursPrefere != null;
  }

  /// Retourne le libellé du niveau de mémorisation
  String getNiveauMemorisationLabel(bool isArabic) {
    final labels = {
      'debutant': isArabic ? 'مبتدئ' : 'Débutant',
      'moyen': isArabic ? 'متوسط' : 'Moyen',
      'avance': isArabic ? 'متقدم' : 'Avancé',
      'expert': isArabic ? 'خبير' : 'Expert',
      'autre': isArabic ? 'أخرى' : 'Autre',
    };
    return labels[niveauMemorisation] ?? niveauMemorisation;
  }

  /// Retourne le libellé du rythme de mémorisation
  String getRythmeMemorisationLabel(bool isArabic) {
    if (rythmeMemorisationHebdo == null) return '';
    final labels = {
      '1_sourate': isArabic ? 'سورة واحدة' : '1 sourate',
      '2_sourates': isArabic ? 'سورتين' : '2 sourates',
      '3_sourates': isArabic ? '3 سور' : '3 sourates',
      '5_sourates': isArabic ? '5 سور' : '5 sourates',
      '10_sourates': isArabic ? '10 سور' : '10 sourates',
      'juz_par_semaine': isArabic ? 'جزء في الأسبوع' : 'Juz par semaine',
      'autre': isArabic ? 'أخرى' : 'Autre',
    };
    return labels[rythmeMemorisationHebdo!] ?? rythmeMemorisationHebdo!;
  }

  /// Retourne le libellé de la riwaya
  String getRiwayaLabel(bool isArabic) {
    final labels = {
      'hafs': isArabic ? 'حفص عن عاصم' : 'Hafs',
      'warch': isArabic ? 'ورش عن نافع' : 'Warch',
      'qaloun': isArabic ? 'قالون عن نافع' : 'Qaloun',
      'autre': isArabic ? 'أخرى' : 'Autre',
    };
    return labels[riwayaSouhaitee] ?? riwayaSouhaitee;
  }

  /// Retourne le libellé du créneau horaire
  String getCreneauLabel(bool isArabic) {
    if (creneauHoraire == null) return '';
    final labels = {
      'matin_8_10': isArabic ? '8h - 10h' : '8h - 10h',
      'matin_10_12': isArabic ? '10h - 12h' : '10h - 12h',
      'apres_midi_14_16': isArabic ? '14h - 16h' : '14h - 16h',
      'apres_midi_16_18': isArabic ? '16h - 18h' : '16h - 18h',
      'soir_18_20': isArabic ? '18h - 20h' : '18h - 20h',
      'soir_20_22': isArabic ? '20h - 22h' : '20h - 22h',
      'flexible': isArabic ? 'مرن' : 'Flexible',
      'autre': isArabic ? 'أخرى' : 'Autre',
    };
    return labels[creneauHoraire!] ?? creneauHoraire!;
  }

  /// Retourne le libellé du parcours préféré
  String getParcoursLabel(bool isArabic) {
    if (parcoursPrefere == null) return '';
    final labels = {
      'academique': isArabic ? 'أكاديمي' : 'Académique',
      'intensif': isArabic ? 'مكثف' : 'Intensif',
      'dynamique': isArabic ? 'ديناميكي' : 'Dynamique',
      'tranquille': isArabic ? 'هادئ' : 'Tranquille',
      'concentre': isArabic ? 'مركز' : 'Concentré',
    };
    return labels[parcoursPrefere!] ?? parcoursPrefere!;
  }
}
