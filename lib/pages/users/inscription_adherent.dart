import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/language_provider.dart';
import '../../../src/features/landing/presentation/widgets/navbar.dart';
import '../../services/adherent_service.dart';
import '../../models/adherent.dart';
import '../../models/enfant.dart';

// ----- PAGE PRINCIPALE -----
class InscriptionAdherentPage extends StatefulWidget {
  const InscriptionAdherentPage({super.key});

  @override
  State<InscriptionAdherentPage> createState() =>
      _InscriptionAdherentPageState();
}

class _InscriptionAdherentPageState extends State<InscriptionAdherentPage> {
  bool isLoading = false;
  bool ajouterEnfants = false;

  // Données adhérent
  String _whatsapp = '';
  String _selectedCountryCode = '+216';
  String _nomPrenom = '';
  String _pays = '';
  String _ville = '';
  String _email = '';
  DateTime _dateNaissance = DateTime.now();
  String _genre = 'homme';
  String _sourceConnaissance = 'instagram';
  String? _sourceAutreDetail;
  String? _objectif;
  String? _suggestions;
  bool _accordPublication = false;

  List<Enfant> _enfants = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Service
  final AdherentService _adherentService = AdherentService();

  final List<Map<String, String>> _countryCodes = [
    {'flag': '🇹🇳', 'code': '+216'},
    {'flag': '🇫🇷', 'code': '+33'},
    {'flag': '🇩🇿', 'code': '+213'},
    {'flag': '🇲🇦', 'code': '+212'},
    {'flag': '🇪🇬', 'code': '+20'},
    {'flag': '🇸🇦', 'code': '+966'},
    {'flag': '🇦🇪', 'code': '+971'},
    {'flag': '🇶🇦', 'code': '+974'},
    {'flag': '🇰🇼', 'code': '+965'},
    {'flag': '🇱🇧', 'code': '+961'},
    {'flag': '🇯🇴', 'code': '+962'},
    {'flag': '🇺🇸', 'code': '+1'},
    {'flag': '🇬🇧', 'code': '+44'},
    {'flag': '🇩🇪', 'code': '+49'},
  ];

  // ---- FONCTIONS DE GESTION ----
  void _ajouterEnfant() {
    setState(() {
      _enfants.add(
        Enfant(
          nomPrenom: '',
          dateNaissance: DateTime.now(),
          genre: 'homme',
          niveauTilawa: 'debutant',
        ),
      );
    });
  }

  void _retirerEnfant(int index) {
    setState(() {
      _enfants.removeAt(index);
    });
  }

  void _updateAdherentField(String key, dynamic value) {
    setState(() {
      switch (key) {
        case 'whatsapp':
          _whatsapp = value;
          break;
        case 'nomPrenom':
          _nomPrenom = value;
          break;
        case 'pays':
          _pays = value;
          break;
        case 'ville':
          _ville = value;
          break;
        case 'email':
          _email = value;
          break;
        case 'dateNaissance':
          _dateNaissance = value;
          break;
        case 'genre':
          _genre = value;
          break;
        case 'sourceConnaissance':
          _sourceConnaissance = value;
          break;
        case 'sourceAutreDetail':
          _sourceAutreDetail = value;
          break;
        case 'objectif':
          _objectif = value;
          break;
        case 'suggestions':
          _suggestions = value;
          break;
        case 'accordPublication':
          _accordPublication = value;
          break;
      }
    });
  }

  void _updateEnfantField(int index, String key, dynamic value) {
    setState(() {
      final e = _enfants[index];
      switch (key) {
        case 'nomPrenom':
          e.nomPrenom = value;
          break;
        case 'dateNaissance':
          e.dateNaissance = value;
          break;
        case 'genre':
          e.genre = value;
          break;
        case 'niveauTilawa':
          e.niveauTilawa = value;
          break;
        case 'memorisation':
          e.memorisation = value;
          break;
        case 'memorisationAutreDetail':
          e.memorisationAutreDetail = value;
          break;
        case 'objectif':
          e.objectif = value;
          break;
        case 'accordInscription':
          e.accordInscription = value;
          break;
      }
      _enfants[index] = e;
    });
  }

  // ---- SOUMISSION AVEC SERVICE ET AFFICHAGE DES IDENTIFIANTS ----
  Future<void> _soumettre(bool isArabic) async {
    // Validation
    if (_nomPrenom.isEmpty ||
        _pays.isEmpty ||
        _ville.isEmpty ||
        _email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'يرجى ملء الحقول الإجبارية (*)'
                : 'Veuillez remplir les champs obligatoires (*)',
          ),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final adherent = Adherent(
        whatsapp: '$_selectedCountryCode$_whatsapp',
        nomPrenom: _nomPrenom,
        pays: _pays,
        ville: _ville,
        email: _email,
        dateNaissance: _dateNaissance,
        genre: _genre,
        sourceConnaissance: _sourceConnaissance,
        sourceAutreDetail: _sourceAutreDetail,
        objectif: _objectif,
        suggestions: _suggestions,
        accordPublication: _accordPublication,
      );

      // ✅ Appel du service avec retour des identifiants
      final result = await AdherentService.inscrireAdherent(adherent, _enfants);

      if (mounted) {
        final credentials = result['credentials'];
        final motDePasse = result['motDePasse'];

        // ✅ Afficher les identifiants dans un SnackBar
        final message =
            isArabic
                ? '✅ Inscription réussie !\nIdentifiant: ${credentials['identifiant']}\nMot de passe: $motDePasse'
                : '✅ Inscription réussie !\nIdentifiant: ${credentials['identifiant']}\nMot de passe: $motDePasse';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: GoogleFonts.cairo(fontSize: 14)),
            backgroundColor: const Color(0xff0D443E),
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // ✅ Optionnel : ouvrir WhatsApp automatiquement
        // final whatsappUrl = result['whatsappUrl'];
        // if (whatsappUrl != null && mounted) {
        //   // await launchUrl(Uri.parse(whatsappUrl));
        // }

        // Attendre un peu avant de revenir pour que l'utilisateur voit les identifiants
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Erreur : ${e.toString().replaceFirst('Exception: ', '')}',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ---- BUILD ----
  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isDesktop = screenWidth >= 1200;

    final double horizontalPadding = isMobile ? 16 : (isTablet ? 32 : 64);
    final double verticalPadding = isMobile ? 16 : (isTablet ? 24 : 40);
    final double cardPadding = isMobile ? 16 : 24;
    final double maxWidth = isDesktop ? 800 : double.infinity;
    final double fontSize = isMobile ? 14 : 16;
    final double topMargin = isMobile ? 100 : 90;

    void toggleLanguage() {
      final provider = Provider.of<LanguageProvider>(context, listen: false);
      provider.toggleLanguage();
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            // ---- Contenu principal ----
            Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(top: topMargin),
                  child: Column(
                    children: [
                      Card(
                        elevation: isDesktop ? 4 : 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(cardPadding),
                          child: Column(
                            children: [
                              _buildWhatsAppField(isArabic, isMobile, fontSize),
                              const SizedBox(height: 12),
                              _buildTextField(
                                label:
                                    isArabic
                                        ? 'الاسم واللقب *'
                                        : 'Nom et Prénom *',
                                initialValue: _nomPrenom,
                                onChanged:
                                    (v) => _updateAdherentField('nomPrenom', v),
                                required: true,
                                fontSize: fontSize,
                              ),
                              _buildTextField(
                                label: isArabic ? 'بلد الإقامة *' : 'Pays *',
                                initialValue: _pays,
                                onChanged:
                                    (v) => _updateAdherentField('pays', v),
                                required: true,
                                fontSize: fontSize,
                              ),
                              _buildTextField(
                                label: isArabic ? 'المدينة *' : 'Ville *',
                                initialValue: _ville,
                                onChanged:
                                    (v) => _updateAdherentField('ville', v),
                                required: true,
                                fontSize: fontSize,
                              ),
                              _buildTextField(
                                label:
                                    isArabic
                                        ? 'البريد الإلكتروني - EMAIL *'
                                        : 'E-mail *',
                                initialValue: _email,
                                onChanged:
                                    (v) => _updateAdherentField('email', v),
                                required: true,
                                keyboardType: TextInputType.emailAddress,
                                fontSize: fontSize,
                              ),
                              _buildDatePicker(
                                label:
                                    isArabic
                                        ? 'تاريخ الولادة'
                                        : 'Date de naissance',
                                value: _dateNaissance,
                                onChanged:
                                    (date) => _updateAdherentField(
                                      'dateNaissance',
                                      date,
                                    ),
                                fontSize: fontSize,
                              ),
                              _buildGenderRadio(isArabic, fontSize),
                              _buildSourceRadio(isArabic, fontSize),
                              if (_sourceConnaissance == 'autre')
                                _buildTextField(
                                  label:
                                      isArabic ? 'الرجاء التوضيح' : 'Précisez',
                                  initialValue: _sourceAutreDetail,
                                  onChanged:
                                      (v) => _updateAdherentField(
                                        'sourceAutreDetail',
                                        v,
                                      ),
                                  fontSize: fontSize,
                                ),
                              _buildTextField(
                                label:
                                    isArabic
                                        ? 'ما هو هدفك من الالتحاق بهذه الدورات ؟'
                                        : 'Quel est votre objectif en rejoignant ces cycles ?',
                                initialValue: _objectif,
                                onChanged:
                                    (v) => _updateAdherentField('objectif', v),
                                maxLines: 3,
                                fontSize: fontSize,
                              ),
                              _buildTextField(
                                label:
                                    isArabic
                                        ? 'اقتراحات دورات و مواضيع دروس تريد أن نبرمجها مستقبلا'
                                        : 'Suggestions de cours et sujets à programmer',
                                initialValue: _suggestions,
                                onChanged:
                                    (v) =>
                                        _updateAdherentField('suggestions', v),
                                maxLines: 2,
                                fontSize: fontSize,
                              ),
                              _buildCheckbox(
                                label:
                                    isArabic
                                        ? 'أوافق على نشر محتوى الدورات على صفحات أكاديمية نفحات'
                                        : 'J\'accepte la publication du contenu des cycles sur les pages de Nafahat',
                                value: _accordPublication,
                                onChanged:
                                    (v) => _updateAdherentField(
                                      'accordPublication',
                                      v,
                                    ),
                                fontSize: fontSize,
                              ),
                              _buildToggleEnfants(isArabic, fontSize),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (ajouterEnfants)
                        _buildEnfantsSection(isArabic, fontSize, isMobile),
                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              isLoading ? null : () => _soumettre(isArabic),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: isMobile ? 14 : 18,
                              horizontal: 20,
                            ),
                            backgroundColor: const Color(0xff0D443E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              isLoading
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    isArabic ? 'تسجيل' : 'S\'inscrire',
                                    style: GoogleFonts.cairo(
                                      fontSize: fontSize + 2,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // ---- NAVBAR ----
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Navbar(
                isArabic: isArabic,
                isMobile: isMobile,
                onLanguageToggle: toggleLanguage,
                scaffoldKey: _scaffoldKey,
              ),
            ),

            if (isLoading)
              const Opacity(
                opacity: 0.5,
                child: ModalBarrier(dismissible: false, color: Colors.black),
              ),
            if (isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  // ---- WIDGETS (tous les widgets restent inchangés, avec GoogleFonts.cairo) ----
  Widget _buildWhatsAppField(bool isArabic, bool isMobile, double fontSize) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isMobile ? 100 : 130,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCountryCode,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              items:
                  _countryCodes.map((country) {
                    return DropdownMenuItem<String>(
                      value: country['code'],
                      child: Text('${country['flag']} ${country['code']}'),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCountryCode = value);
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTextField(
            label:
                isArabic
                    ? 'رقم الواتساب (مع رمز البلد)'
                    : 'Numéro WhatsApp (avec indicatif)',
            hint: '+21625357461',
            initialValue: _whatsapp,
            onChanged: (v) => _updateAdherentField('whatsapp', v),
            keyboardType: TextInputType.phone,
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }

  Widget _buildGenderRadio(bool isArabic, double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'الجنس' : 'Genre',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w500,
              fontSize: fontSize,
            ),
          ),
          Row(
            children: [
              _buildRadioOption('homme', isArabic ? 'ذكر' : 'Homme', fontSize),
              _buildRadioOption('femme', isArabic ? 'أنثى' : 'Femme', fontSize),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption(String value, String label, double fontSize) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: _genre,
          onChanged: (v) => _updateAdherentField('genre', v),
          activeColor: const Color(0xff0D443E),
        ),
        Text(label, style: GoogleFonts.cairo(fontSize: fontSize)),
      ],
    );
  }

  Widget _buildSourceRadio(bool isArabic, double fontSize) {
    final List<Map<String, dynamic>> sources = [
      {
        'key': 'instagram',
        'icon': Icons.camera_alt,
        'labelFr': 'Instagram',
        'labelAr': 'إنستغرام',
      },
      {
        'key': 'facebook',
        'icon': Icons.facebook,
        'labelFr': 'Facebook',
        'labelAr': 'فيسبوك',
      },
      {
        'key': 'ami',
        'icon': Icons.people,
        'labelFr': 'Ami(e)',
        'labelAr': 'صديق/ة',
      },
      {
        'key': 'annonce',
        'icon': Icons.ads_click,
        'labelFr': 'Annonce',
        'labelAr': 'إعلان ممول',
      },
      {
        'key': 'autre',
        'icon': Icons.more_horiz,
        'labelFr': 'Autre',
        'labelAr': 'أخرى',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic
                ? 'كيف تعرفت على الأكاديمية؟'
                : 'Comment avez-vous connu l\'académie ?',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w500,
              fontSize: fontSize,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                sources.map((src) {
                  final isSelected = _sourceConnaissance == src['key'];
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          src['icon'],
                          size: 18,
                          color: isSelected ? Colors.white : Colors.black54,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isArabic ? src['labelAr'] : src['labelFr'],
                          style: GoogleFonts.cairo(fontSize: fontSize),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        _updateAdherentField('sourceConnaissance', src['key']);
                      }
                    },
                    selectedColor: const Color(0xff0D443E),
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: GoogleFonts.cairo(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: fontSize,
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleEnfants(bool isArabic, double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic
                ? 'هل تريد تسجيل أطفالك أيضا ؟'
                : 'Voulez-vous aussi inscrire vos enfants ?',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w500,
              fontSize: fontSize,
            ),
          ),
          Row(
            children: [
              _buildToggleOption(true, isArabic ? 'نعم' : 'Oui', fontSize),
              _buildToggleOption(false, isArabic ? 'لا' : 'Non', fontSize),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(bool value, String label, double fontSize) {
    return Row(
      children: [
        Radio<bool>(
          value: value,
          groupValue: ajouterEnfants,
          onChanged: (val) {
            if (val != null) {
              setState(() {
                ajouterEnfants = val;
                if (!val) _enfants.clear();
              });
            }
          },
          activeColor: const Color(0xff0D443E),
        ),
        Text(label, style: GoogleFonts.cairo(fontSize: fontSize)),
      ],
    );
  }

  Widget _buildEnfantsSection(bool isArabic, double fontSize, bool isMobile) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isArabic
                      ? 'معلومات عن الأبناء'
                      : 'Informations sur les enfants',
                  style: GoogleFonts.cairo(
                    fontSize: fontSize + 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _ajouterEnfant,
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_enfants.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Center(
                  child: Text(
                    isArabic
                        ? 'لا يوجد أطفال مسجلين. اضغط على + لإضافة طفل'
                        : 'Aucun enfant enregistré. Appuyez sur + pour en ajouter',
                    style: GoogleFonts.cairo(
                      color: Colors.grey.shade600,
                      fontSize: fontSize,
                    ),
                  ),
                ),
              )
            else
              SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children:
                      _enfants.asMap().entries.map((entry) {
                        int idx = entry.key;
                        Enfant enfant = entry.value;
                        return Column(
                          children: [
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${isArabic ? 'الابن' : 'Enfant'} ${idx + 1}',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                    fontSize: fontSize,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _retirerEnfant(idx),
                                ),
                              ],
                            ),
                            _buildTextField(
                              label:
                                  isArabic
                                      ? 'الاسم واللقب *'
                                      : 'Nom et Prénom *',
                              initialValue: enfant.nomPrenom,
                              onChanged:
                                  (v) =>
                                      _updateEnfantField(idx, 'nomPrenom', v),
                              required: true,
                              fontSize: fontSize,
                            ),
                            _buildDatePicker(
                              label:
                                  isArabic
                                      ? 'تاريخ الولادة'
                                      : 'Date de naissance',
                              value: enfant.dateNaissance,
                              onChanged:
                                  (date) => _updateEnfantField(
                                    idx,
                                    'dateNaissance',
                                    date,
                                  ),
                              fontSize: fontSize,
                            ),
                            _buildEnfantGenderRadio(idx, isArabic, fontSize),
                            _buildDropdown(
                              label:
                                  isArabic
                                      ? 'ما هو مستوى تلاوة طفلك'
                                      : 'Niveau de récitation',
                              value: enfant.niveauTilawa,
                              items:
                                  [
                                    'debutant',
                                    'quelques_sourates',
                                    'avance',
                                  ].map((n) {
                                    String label =
                                        isArabic
                                            ? {
                                              'debutant': 'مبتدئ من الصفر',
                                              'quelques_sourates':
                                                  'يحفظ بعض قصار السور',
                                              'avance':
                                                  'متقدم : حافظ و متقن لأحكام التلاوة',
                                            }[n]!
                                            : n;
                                    return DropdownMenuItem(
                                      value: n,
                                      child: Text(
                                        label,
                                        style: GoogleFonts.cairo(),
                                      ),
                                    );
                                  }).toList(),
                              onChanged:
                                  (v) => _updateEnfantField(
                                    idx,
                                    'niveauTilawa',
                                    v,
                                  ),
                              fontSize: fontSize,
                            ),
                            if (enfant.niveauTilawa == 'avance') ...[
                              _buildDropdown(
                                label:
                                    isArabic
                                        ? 'كم يحفظ من كتاب الله'
                                        : 'Mémorisation',
                                value: enfant.memorisation ?? 'juz_amma',
                                items:
                                    ['juz_amma', 'plus_5_hizbs', 'autre'].map((
                                      m,
                                    ) {
                                      String label =
                                          isArabic
                                              ? {
                                                'juz_amma': 'جزء عم',
                                                'plus_5_hizbs':
                                                    'أكثر من 5 أحزاب',
                                                'autre': 'Autre :',
                                              }[m]!
                                              : m;
                                      return DropdownMenuItem(
                                        value: m,
                                        child: Text(
                                          label,
                                          style: GoogleFonts.cairo(),
                                        ),
                                      );
                                    }).toList(),
                                onChanged:
                                    (v) => _updateEnfantField(
                                      idx,
                                      'memorisation',
                                      v,
                                    ),
                                fontSize: fontSize,
                              ),
                              if (enfant.memorisation == 'autre')
                                _buildTextField(
                                  label:
                                      isArabic ? 'الرجاء التوضيح' : 'Précisez',
                                  initialValue: enfant.memorisationAutreDetail,
                                  onChanged:
                                      (v) => _updateEnfantField(
                                        idx,
                                        'memorisationAutreDetail',
                                        v,
                                      ),
                                  fontSize: fontSize,
                                ),
                            ],
                            _buildTextField(
                              label:
                                  isArabic
                                      ? 'ما هو هدفك من التحاق طفلك بهذه الدورات ؟'
                                      : 'Objectif pour votre enfant',
                              initialValue: enfant.objectif,
                              onChanged:
                                  (v) => _updateEnfantField(idx, 'objectif', v),
                              maxLines: 2,
                              fontSize: fontSize,
                            ),
                            _buildCheckbox(
                              label: isArabic ? 'موافق' : 'J\'accepte',
                              value: enfant.accordInscription ?? false,
                              onChanged:
                                  (v) => _updateEnfantField(
                                    idx,
                                    'accordInscription',
                                    v,
                                  ),
                              fontSize: fontSize,
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnfantGenderRadio(int index, bool isArabic, double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            isArabic ? 'الجنس' : 'Genre',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w500,
              fontSize: fontSize,
            ),
          ),
          const SizedBox(width: 20),
          _buildRadioEnfantOption(
            index,
            'homme',
            isArabic ? 'ذكر' : 'Homme',
            fontSize,
          ),
          _buildRadioEnfantOption(
            index,
            'femme',
            isArabic ? 'أنثى' : 'Femme',
            fontSize,
          ),
        ],
      ),
    );
  }

  Widget _buildRadioEnfantOption(
    int index,
    String value,
    String label,
    double fontSize,
  ) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: _enfants[index].genre,
          onChanged: (v) => _updateEnfantField(index, 'genre', v),
          activeColor: const Color(0xff0D443E),
        ),
        Text(label, style: GoogleFonts.cairo(fontSize: fontSize)),
      ],
    );
  }

  // ---- WIDGETS GÉNÉRIQUES ----
  Widget _buildTextField({
    required String label,
    String? initialValue,
    required Function(String) onChanged,
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
    double fontSize = 14,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          labelStyle: GoogleFonts.cairo(fontSize: fontSize),
          hintStyle: GoogleFonts.cairo(fontSize: fontSize),
        ),
        style: GoogleFonts.cairo(fontSize: fontSize),
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime value,
    required Function(DateTime) onChanged,
    double fontSize = 14,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: InkWell(
        onTap: () async {
          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: value,
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (picked != null) onChanged(picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            labelStyle: GoogleFonts.cairo(fontSize: fontSize),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd/MM/yyyy').format(value),
                style: GoogleFonts.cairo(fontSize: fontSize),
              ),
              Icon(Icons.calendar_today, size: fontSize + 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    double fontSize = 14,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          labelStyle: GoogleFonts.cairo(fontSize: fontSize),
        ),
        style: GoogleFonts.cairo(fontSize: fontSize, color: Colors.black87),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildCheckbox({
    required String label,
    required bool value,
    required Function(bool?) onChanged,
    double fontSize = 14,
  }) {
    return CheckboxListTile(
      title: Text(label, style: GoogleFonts.cairo(fontSize: fontSize)),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
