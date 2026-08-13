// lib/models/about_model.dart
import 'dart:convert'; // 👈 AJOUTER CET IMPORT

class AboutModel {
  final int? id;
  final String titleFr;
  final String titleAr;
  final String sloganFr;
  final String sloganAr;
  final String subtitleFr;
  final String subtitleAr;
  final String descriptionFr;
  final String descriptionAr;
  final String ctaFr;
  final String ctaAr;
  final String? visionFr;
  final String? visionAr;
  final String? missionFr;
  final String? missionAr;
  final List<String> values;
  final String stat1Value;
  final String stat1LabelFr;
  final String stat1LabelAr;
  final String stat2Value;
  final String stat2LabelFr;
  final String stat2LabelAr;
  final String stat3Value;
  final String stat3LabelFr;
  final String stat3LabelAr;
  final String stat4Value;
  final String stat4LabelFr;
  final String stat4LabelAr;
  final String email;
  final String phone;
  final String addressFr;
  final String addressAr;
  final String? facebookUrl;
  final String? youtubeUrl;
  final String? telegramUrl;
  final String? instagramUrl;
  final List<TeamMember> teamMembers;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AboutModel({
    this.id,
    required this.titleFr,
    required this.titleAr,
    required this.sloganFr,
    required this.sloganAr,
    required this.subtitleFr,
    required this.subtitleAr,
    required this.descriptionFr,
    required this.descriptionAr,
    required this.ctaFr,
    required this.ctaAr,
    this.visionFr,
    this.visionAr,
    this.missionFr,
    this.missionAr,
    this.values = const [],
    this.stat1Value = '50+',
    this.stat1LabelFr = 'Cours religieux',
    this.stat1LabelAr = 'دورة دينية',
    this.stat2Value = '1200+',
    this.stat2LabelFr = 'Étudiants',
    this.stat2LabelAr = 'طالب',
    this.stat3Value = '25+',
    this.stat3LabelFr = 'Enseignants',
    this.stat3LabelAr = 'مدرس',
    this.stat4Value = '95%',
    this.stat4LabelFr = 'Satisfaction étudiants',
    this.stat4LabelAr = 'رضا الطلاب',
    required this.email,
    required this.phone,
    required this.addressFr,
    required this.addressAr,
    this.facebookUrl,
    this.youtubeUrl,
    this.telegramUrl,
    this.instagramUrl,
    this.teamMembers = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory AboutModel.fromJson(Map<String, dynamic> json) {
    List<String> values = [];
    if (json['values_json'] != null &&
        json['values_json'].toString().isNotEmpty) {
      try {
        // 👈 CORRECTION: Utiliser jsonDecode au lieu de json.decode
        final decoded = jsonDecode(json['values_json']);
        if (decoded is List) {
          values = List<String>.from(decoded);
        }
      } catch (_) {}
    }

    List<TeamMember> teamMembers = [];
    if (json['team_members_json'] != null &&
        json['team_members_json'].toString().isNotEmpty) {
      try {
        // 👈 CORRECTION: Utiliser jsonDecode au lieu de json.decode
        final List<dynamic> members = jsonDecode(json['team_members_json']);
        teamMembers = members.map((m) => TeamMember.fromJson(m)).toList();
      } catch (_) {}
    }

    return AboutModel(
      id: json['id'],
      titleFr: json['title_fr'] ?? '',
      titleAr: json['title_ar'] ?? '',
      sloganFr: json['slogan_fr'] ?? '',
      sloganAr: json['slogan_ar'] ?? '',
      subtitleFr: json['subtitle_fr'] ?? '',
      subtitleAr: json['subtitle_ar'] ?? '',
      descriptionFr: json['description_fr'] ?? '',
      descriptionAr: json['description_ar'] ?? '',
      ctaFr: json['cta_fr'] ?? '',
      ctaAr: json['cta_ar'] ?? '',
      visionFr: json['vision_fr'],
      visionAr: json['vision_ar'],
      missionFr: json['mission_fr'],
      missionAr: json['mission_ar'],
      values: values,
      stat1Value: json['stat1_value'] ?? '50+',
      stat1LabelFr: json['stat1_label_fr'] ?? 'Cours religieux',
      stat1LabelAr: json['stat1_label_ar'] ?? 'دورة دينية',
      stat2Value: json['stat2_value'] ?? '1200+',
      stat2LabelFr: json['stat2_label_fr'] ?? 'Étudiants',
      stat2LabelAr: json['stat2_label_ar'] ?? 'طالب',
      stat3Value: json['stat3_value'] ?? '25+',
      stat3LabelFr: json['stat3_label_fr'] ?? 'Enseignants',
      stat3LabelAr: json['stat3_label_ar'] ?? 'مدرس',
      stat4Value: json['stat4_value'] ?? '95%',
      stat4LabelFr: json['stat4_label_fr'] ?? 'Satisfaction étudiants',
      stat4LabelAr: json['stat4_label_ar'] ?? 'رضا الطلاب',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      addressFr: json['address_fr'] ?? '',
      addressAr: json['address_ar'] ?? '',
      facebookUrl: json['facebook_url'],
      youtubeUrl: json['youtube_url'],
      telegramUrl: json['telegram_url'],
      instagramUrl: json['instagram_url'],
      teamMembers: teamMembers,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title_fr': titleFr,
      'title_ar': titleAr,
      'slogan_fr': sloganFr,
      'slogan_ar': sloganAr,
      'subtitle_fr': subtitleFr,
      'subtitle_ar': subtitleAr,
      'description_fr': descriptionFr,
      'description_ar': descriptionAr,
      'cta_fr': ctaFr,
      'cta_ar': ctaAr,
      'vision_fr': visionFr,
      'vision_ar': visionAr,
      'mission_fr': missionFr,
      'mission_ar': missionAr,
      'values_json':
          values.isNotEmpty
              ? jsonEncode(values)
              : null, // 👈 CORRECTION: utiliser jsonEncode
      'stat1_value': stat1Value,
      'stat1_label_fr': stat1LabelFr,
      'stat1_label_ar': stat1LabelAr,
      'stat2_value': stat2Value,
      'stat2_label_fr': stat2LabelFr,
      'stat2_label_ar': stat2LabelAr,
      'stat3_value': stat3Value,
      'stat3_label_fr': stat3LabelFr,
      'stat3_label_ar': stat3LabelAr,
      'stat4_value': stat4Value,
      'stat4_label_fr': stat4LabelFr,
      'stat4_label_ar': stat4LabelAr,
      'email': email,
      'phone': phone,
      'address_fr': addressFr,
      'address_ar': addressAr,
      'facebook_url': facebookUrl,
      'youtube_url': youtubeUrl,
      'telegram_url': telegramUrl,
      'instagram_url': instagramUrl,
      'team_members_json':
          teamMembers.isNotEmpty
              ? jsonEncode(
                teamMembers.map((m) => m.toJson()).toList(),
              ) // 👈 CORRECTION: utiliser jsonEncode
              : null,
    };
  }

  // Méthode pour les valeurs par défaut
  static AboutModel defaultValues() {
    return AboutModel(
      titleFr: 'Nafahat – Académie Islamique Numérique',
      titleAr: 'نفحات – أكاديمية إسلامية رقمية',
      sloganFr: '✨ Votre voyage vers la proximité d\'Allah ✨',
      sloganAr: '✨ رحلتك للقرب من الله ✨',
      subtitleFr: '📖 Cours religieux à distance',
      subtitleAr: '📖 دورات دينية عن بعد',
      descriptionFr:
          'Nafahat est une académie islamique numérique qui vise à rapprocher les musulmans de leur religion à travers des cours éducatifs à distance de qualité. Nous croyons que l\'apprentissage continu des sciences religieuses est la clé de la proximité avec Allah, et nous nous efforçons de proposer un contenu religieux authentique dans un style moderne et simplifié adapté à tous les âges.',
      descriptionAr:
          'نفحات هي أكاديمية إسلامية رقمية تهدف إلى تقريب المسلمين من دينهم من خلال دورات تعليمية متميزة عن بعد. نؤمن بأن التعلم المستمر للعلوم الشرعية هو مفتاح القرب من الله تعالى، ونسعى لتقديم محتوى ديني أصيل بأسلوب عصري مبسط يناسب جميع الفئات العمرية.',
      ctaFr:
          '💚 Rejoignez-nous et commencez votre voyage avec la bonne compagnie aujourd\'hui',
      ctaAr: '💚 انظم لنا وابدأ رحلتك مع الصحبة الصالحة اليوم',
      visionFr:
          'Devenir la référence en matière d\'éducation islamique numérique en Tunisie et dans le monde arabe.',
      visionAr:
          'أن نصبح المرجع في التعليم الإسلامي الرقمي في تونس والعالم العربي.',
      missionFr:
          'Offrir un contenu islamique authentique et accessible à tous, en utilisant les technologies modernes pour faciliter l\'apprentissage et la compréhension des sciences religieuses.',
      missionAr:
          'تقديم محتوى إسلامي أصيل ومتاح للجميع، باستخدام التقنيات الحديثة لتسهيل تعلم وفهم العلوم الشرعية.',
      values: [
        '📖 Saint Coran',
        '🕌 Sirah Nabawiya',
        '📚 Fiqh Islamique',
        '💚 Tazkiyah et Morale',
        '🌙 Sciences Islamiques',
      ],
      email: 'contact@nafahat.academy.com',
      phone: '+216 XX XXX XXX',
      addressFr: 'Tunis, Tunisie',
      addressAr: 'تونس، تونس',
      facebookUrl: 'https://www.facebook.com/profile.php?id=61586649359844',
      youtubeUrl: 'https://www.youtube.com',
      telegramUrl: 'https://t.me',
      instagramUrl: 'https://www.instagram.com',
      teamMembers: [
        TeamMember(
          name: 'Dr. Ahmed Ben Ali',
          roleFr: 'Directeur Général',
          roleAr: 'المدير العام',
        ),
        TeamMember(
          name: 'Ust. Fatima Zohra',
          roleFr: 'Directrice des Programmes Religieux',
          roleAr: 'مديرة البرامج الدينية',
        ),
        TeamMember(
          name: 'Ust. Karim Laaroussi',
          roleFr: 'Développeur du Contenu Religieux',
          roleAr: 'مطور المحتوى الديني',
        ),
      ],
    );
  }
}

// Modèle pour les membres de l'équipe
class TeamMember {
  final String name;
  final String roleFr;
  final String roleAr;

  TeamMember({required this.name, required this.roleFr, required this.roleAr});

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      name: json['name'] ?? '',
      roleFr: json['roleFr'] ?? '',
      roleAr: json['roleAr'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'roleFr': roleFr, 'roleAr': roleAr};
  }
}
