// lib/pages/paiement/modalite_paiment.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:typed_data';
import 'package:nafahat/services/payment_service.dart';
import 'package:nafahat/services/training_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:html' as html;

class ModalitePaimentPage extends StatefulWidget {
  final String? paymentId;
  final String? formationId;
  final String? userId;
  final String? currency;
  final double? montantTotal;

  const ModalitePaimentPage({
    super.key,
    this.paymentId,
    this.formationId,
    this.userId,
    this.currency,
    this.montantTotal,
  });

  @override
  State<ModalitePaimentPage> createState() => _ModalitePaimentPageState();
}

class _ModalitePaimentPageState extends State<ModalitePaimentPage> {
  // ============================================================
  // ÉTATS
  // ============================================================

  bool _isArabic = true;
  String? _selectedPaymentMethod;
  String? _selectedPaymentType;

  // Données de la formation
  double _montantTotal = 0.0;
  DateTime? _dateDebut;
  DateTime? _dateFin;

  // ✅ NOUVEAU : Compteurs de la formation
  int _nbrHeur = 0;
  int _nbrSeance = 0;
  int _nbrJour = 0;

  // ✅ NOUVEAU : Types de paiement autorisés pour cette formation
  List<String> _typesPaiementAutorises = ['formation'];

  // ✅ Types de paiement avec config (filtrés selon la formation)
  List<Map<String, dynamic>> _paymentTypes = [];

  // Nombre de périodes selon le type sélectionné
  int _nombrePeriodes = 1;

  Uint8List? _selectedFileBytes;
  File? _selectedFile;
  String? _selectedFileName;
  String? _selectedMethod;

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  static const Color primaryColor = Color(0xff0D443E);
  static const Color primaryColorLight = Color(0xff1a6b60);

  // ============================================================
  // CONFIGURATION DES 7 TYPES DE PAIEMENT
  // ============================================================
  
  static const Map<String, Map<String, dynamic>> _allTypeConfigs = {
    'formation': {
      'icon': '🎓',
      'labelFr': 'Paiement complet',
      'labelAr': 'دفع كامل',
      'isPeriodic': false,
    },
    'mois': {
      'icon': '📅',
      'labelFr': 'Paiement mensuel',
      'labelAr': 'دفع شهري',
      'isPeriodic': true,
    },
    'semaine': {
      'icon': '📆',
      'labelFr': 'Paiement hebdomadaire',
      'labelAr': 'دفع أسبوعي',
      'isPeriodic': true,
    },
    'trimestre': {
      'icon': '📊',
      'labelFr': 'Paiement trimestriel',
      'labelAr': 'دفع ربع سنوي',
      'isPeriodic': true,
    },
    'annee': {
      'icon': '🗓️',
      'labelFr': 'Paiement annuel',
      'labelAr': 'دفع سنوي',
      'isPeriodic': true,
    },
    'seance': {
      'icon': '🎯',
      'labelFr': 'Paiement par séance',
      'labelAr': 'دفع بالحصة',
      'isPeriodic': true,
    },
    'heure': {
      'icon': '⏰',
      'labelFr': 'Paiement par heure',
      'labelAr': 'دفع بالساعة',
      'isPeriodic': true,
    },
  };

  // ============================================================
  // GETTERS CALCULÉS
  // ============================================================

  Map<String, dynamic>? get _currentTypeConfig {
    if (_selectedPaymentType == null) return null;
    return _allTypeConfigs[_selectedPaymentType];
  }

  bool get _isPeriodic {
    final config = _currentTypeConfig;
    return config?['isPeriodic'] == true;
  }

  double get _montantAPayer {
    final total = _montantTotal;
    if (_isPeriodic && _nombrePeriodes > 0) {
      return total / _nombrePeriodes;
    }
    return total;
  }

  bool get _canSubmit =>
      _selectedPaymentType != null &&
      _selectedPaymentMethod != null &&
      _hasFile();

  // ============================================================
  // CYCLE DE VIE
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _loadData();
    print('🔵 [ModalitePaiment] Page initialisée - paymentId: ${widget.paymentId}');
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString('language');
      if (mounted) {
        setState(() {
          _isArabic = savedLang == 'ar' || savedLang == null;
        });
      }
    } catch (e) {
      print('❌ [ModalitePaiment] Erreur chargement langue: $e');
    }
  }

  /// ✅ Charger d'abord la formation (récupère les types autorisés)
  /// puis filtrer les types de paiement disponibles
  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // ÉTAPE 1 : Charger la formation (pour avoir les types autorisés)
      await _loadFormationData();

      // ÉTAPE 2 : Construire les types filtrés
      _buildFilteredPaymentTypes();
    } catch (e) {
      print('❌ [ModalitePaiment] Erreur chargement: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ============================================================
  // ✅ CONSTRUCTION DES TYPES FILTRÉS
  // ============================================================

  void _buildFilteredPaymentTypes() {
    final List<Map<String, dynamic>> filtered = [];

    for (final typeKey in _typesPaiementAutorises) {
      final config = _allTypeConfigs[typeKey];
      if (config == null) continue;

      // ✅ Vérifier que le type est cohérent (ex: séance nécessite nbr_seance > 0)
      if (typeKey == 'seance' && _nbrSeance <= 0) continue;
      if (typeKey == 'heure' && _nbrHeur <= 0) continue;

      filtered.add({
        'value': typeKey,
        ...config,
      });
    }

    // ✅ Sécurité : au moins "formation" disponible
    if (filtered.isEmpty) {
      filtered.add({
        'value': 'formation',
        ..._allTypeConfigs['formation']!,
      });
    }

    if (mounted) {
      setState(() {
        _paymentTypes = filtered;
      });
    }

    print('✅ [ModalitePaiment] ${filtered.length} types disponibles: '
        '${filtered.map((e) => e['value']).join(', ')}');
  }

  // ============================================================
  // CHARGEMENT DES DONNÉES DE LA FORMATION
  // ============================================================

  Future<void> _loadFormationData() async {
    try {
      if (widget.montantTotal != null && widget.montantTotal! > 0) {
        setState(() {
          _montantTotal = widget.montantTotal!.toDouble();
        });
      }

      if (widget.formationId != null && widget.formationId!.isNotEmpty) {
        print('🔵 [ModalitePaiment] Chargement formation: ${widget.formationId}');

        final formationData = await TrainingService.getFormationById(
          widget.formationId!,
        );

        if (formationData != null) {
          print('✅ [ModalitePaiment] Formation chargée');

          final double? montant = _extractMontant(formationData);
          final DateTime? dateDebut = _parseDate(formationData['date_debut']);
          final DateTime? dateFin = _parseDate(formationData['date_fin']);

          // ✅ Récupérer les compteurs
          final int nbrHeur = _toInt(formationData['nbr_heur']);
          final int nbrSeance = _toInt(formationData['nbr_seance']);
          final int nbrJour = _toInt(formationData['nbr_jour']);

          // ✅ Récupérer les types autorisés
          final List<String> typesAutorises = _parseTypesPaiement(
            formationData['types_paiement_autorises'],
          );

          if (mounted) {
            setState(() {
              if (montant != null && montant > 0) {
                _montantTotal = montant;
              }
              _dateDebut = dateDebut;
              _dateFin = dateFin;
              _nbrHeur = nbrHeur;
              _nbrSeance = nbrSeance;
              _nbrJour = nbrJour;
              _typesPaiementAutorises = typesAutorises;
            });
          }

          print('✅ [ModalitePaiment] Montant: $_montantTotal');
          print('✅ [ModalitePaiment] Période: $_dateDebut → $_dateFin');
          print('✅ [ModalitePaiment] Heures: $_nbrHeur, Séances: $_nbrSeance');
          print('✅ [ModalitePaiment] Types autorisés: $_typesPaiementAutorises');
        }
      }

      // Fallback via paymentId
      if (_montantTotal == 0 &&
          widget.paymentId != null &&
          widget.paymentId!.isNotEmpty) {
        final payment = await PaymentService.getPaymentById(widget.paymentId!);
        if (payment != null) {
          final double? montantFromPayment = _extractMontant(payment);
          if (montantFromPayment != null && montantFromPayment > 0) {
            if (mounted) {
              setState(() {
                _montantTotal = montantFromPayment;
              });
            }
          }
        }
      }
    } catch (e) {
      print('❌ [ModalitePaiment] Erreur chargement formation: $e');
    }
  }

  double? _extractMontant(Map<String, dynamic> data) {
    final currency = (widget.currency ?? 'DT').toUpperCase();

    dynamic value;

    if (currency.contains('EUR') || currency.contains('€')) {
      value = data['prix_eur'] ?? data['prixEur'];
    } else if (currency.contains('USD') || currency.contains('\$')) {
      value = data['prix_usd'] ?? data['prixUsd'];
    } else {
      value = data['prix_dt'] ?? data['prixDt'] ?? data['prix'];
    }

    if (value == null) {
      value = data['prix_dt'] ??
          data['prixDt'] ??
          data['prix'] ??
          data['prix_eur'] ??
          data['prixEur'] ??
          data['prix_usd'] ??
          data['prixUsd'];
    }

    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      return null;
    }
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  /// ✅ Parser les types de paiement autorisés
  List<String> _parseTypesPaiement(dynamic rawValue) {
    const defaultTypes = ['formation'];

    if (rawValue == null) return defaultTypes;

    // Cas 1 : List
    if (rawValue is List) {
      final result = rawValue
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      return result.isEmpty ? defaultTypes : result;
    }

    // Cas 2 : String JSON
    if (rawValue is String && rawValue.isNotEmpty) {
      try {
        final parsed = jsonDecode(rawValue);
        if (parsed is List) {
          final result = parsed
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
          return result.isEmpty ? defaultTypes : result;
        }
      } catch (e) {
        return [rawValue];
      }
    }

    return defaultTypes;
  }

  // ============================================================
  // ✅ CALCUL DU NOMBRE DE PÉRIODES
  // ============================================================

  int _calculerNombrePeriodes(String type) {
    switch (type) {
      case 'seance':
        // ✅ Utiliser nbr_seance de la formation
        return _nbrSeance > 0 ? _nbrSeance : 1;

      case 'heure':
        // ✅ Utiliser nbr_heur de la formation
        return _nbrHeur > 0 ? _nbrHeur : 1;

      case 'mois':
        return _calculerNombreMois();

      case 'semaine':
        return _calculerNombreSemaines();

      case 'trimestre':
        return _calculerNombreTrimestres();

      case 'annee':
        return _calculerNombreAnnees();

      default:
        return 1;
    }
  }

  int _calculerNombreMois() {
    if (_dateDebut == null || _dateFin == null) return 1;
    final debut = _dateDebut!;
    final fin = _dateFin!;
    if (fin.isBefore(debut)) return 1;
    int mois = (fin.year - debut.year) * 12 + (fin.month - debut.month);
    if (fin.day >= debut.day) mois += 1;
    return mois > 0 ? mois : 1;
  }

  int _calculerNombreSemaines() {
    if (_dateDebut == null || _dateFin == null) return 1;
    final debut = _dateDebut!;
    final fin = _dateFin!;
    if (fin.isBefore(debut)) return 1;
    final jours = fin.difference(debut).inDays + 1;
    final semaines = (jours / 7).ceil();
    return semaines > 0 ? semaines : 1;
  }

  int _calculerNombreTrimestres() {
    final mois = _calculerNombreMois();
    final trimestres = (mois / 3).ceil();
    return trimestres > 0 ? trimestres : 1;
  }

  int _calculerNombreAnnees() {
    if (_dateDebut == null || _dateFin == null) return 1;
    final debut = _dateDebut!;
    final fin = _dateFin!;
    int annees = fin.year - debut.year;
    if (fin.month > debut.month ||
        (fin.month == debut.month && fin.day >= debut.day)) {
      annees += 1;
    }
    return annees > 0 ? annees : 1;
  }

  /// Libellé du nombre de périodes selon le type
  String _getPeriodeLabel(int nombre, String type) {
    if (_isArabic) {
      switch (type) {
        case 'mois':
          return nombre > 1 ? '$nombre أشهر' : 'شهر';
        case 'semaine':
          return nombre > 1 ? '$nombre أسابيع' : 'أسبوع';
        case 'trimestre':
          return nombre > 1 ? '$nombre أرباع' : 'ربع';
        case 'annee':
          return nombre > 1 ? '$nombre سنوات' : 'سنة';
        case 'seance':
          return nombre > 1 ? '$nombre حصص' : 'حصة';
        case 'heure':
          return nombre > 1 ? '$nombre ساعات' : 'ساعة';
        default:
          return '';
      }
    } else {
      switch (type) {
        case 'mois':
          return nombre > 1 ? '$nombre mois' : 'mois';
        case 'semaine':
          return nombre > 1 ? '$nombre semaines' : 'semaine';
        case 'trimestre':
          return nombre > 1 ? '$nombre trimestres' : 'trimestre';
        case 'annee':
          return nombre > 1 ? '$nombre années' : 'année';
        case 'seance':
          return nombre > 1 ? '$nombre séances' : 'séance';
        case 'heure':
          return nombre > 1 ? '$nombre heures' : 'heure';
        default:
          return '';
      }
    }
  }

  /// Symbole de la devise
  String _getCurrencySymbol() {
    final currency = (widget.currency ?? 'DT').toUpperCase();
    if (currency.contains('EUR') || currency.contains('€')) return '€';
    if (currency.contains('USD') || currency.contains('\$')) return '\$';
    return 'DT';
  }

  // ============================================================
  // SÉLECTION DE FICHIER
  // ============================================================

  Future<void> _pickFile(String method) async {
    if (kIsWeb) {
      return _pickFileWeb(method);
    }
    return _pickFileMobile(method);
  }

  Future<void> _pickFileWeb(String method) async {
    try {
      final input = html.FileUploadInputElement()
        ..accept = '.pdf,.jpg,.jpeg,.png,.doc,.docx';
      input.click();

      await input.onChange.first;
      if (input.files == null || input.files!.isEmpty) return;

      final file = input.files!.first;
      final ext = file.name.split('.').last.toLowerCase();
      const allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'];

      if (!allowedExtensions.contains(ext)) {
        throw Exception(
          _isArabic ? '⚠️ صيغة الملف غير مقبولة' : '⚠️ Format non accepté',
        );
      }

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;

      final bytes = reader.result as Uint8List;

      if (bytes.length > 5 * 1024 * 1024) {
        throw Exception(
          _isArabic ? '⚠️ الملف كبير جداً' : '⚠️ Fichier trop volumineux',
        );
      }

      setState(() {
        _selectedMethod = method;
        _selectedFileName = file.name;
        _selectedFileBytes = bytes;
        _selectedFile = null;
        _errorMessage = null;
      });

      _showFileSelectedSnackBar();
    } catch (e) {
      _handleFilePickError(e);
    }
  }

  Future<void> _pickFileMobile(String method) async {
    _handleFilePickError(
      Exception(
        _isArabic
            ? '⚠️ Cette fonctionnalité n\'est pas disponible'
            : '⚠️ Cette fonctionnalité n\'est pas disponible',
      ),
    );
  }

  void _showFileSelectedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isArabic ? '✅ تم اختيار الملف' : '✅ Fichier sélectionné',
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleFilePickError(Object e) {
    setState(() {
      _selectedFile = null;
      _selectedFileBytes = null;
      _selectedFileName = null;
      _errorMessage = e.toString();
    });
  }

  bool _hasFile() {
    if (kIsWeb) {
      return _selectedFileBytes != null && _selectedFileName != null;
    }
    return _selectedFile != null && _selectedFileName != null;
  }

  // ============================================================
  // SOUMISSION DU PAIEMENT
  // ============================================================

  Future<void> _submitPayment() async {
    if (_selectedPaymentType == null) {
      setState(() {
        _errorMessage = _isArabic
            ? '⚠️ الرجاء اختيار نوع الدفع'
            : '⚠️ Veuillez sélectionner un type';
      });
      return;
    }

    if (_selectedPaymentMethod == null) {
      setState(() {
        _errorMessage = _isArabic
            ? '⚠️ الرجاء اختيار طريقة الدفع'
            : '⚠️ Veuillez sélectionner un mode';
      });
      return;
    }

    if (!_hasFile()) {
      setState(() {
        _errorMessage = _isArabic
            ? '⚠️ الرجاء إرفاق ملف'
            : '⚠️ Veuillez joindre un fichier';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final double montantParPeriode = _isPeriodic ? _montantAPayer : 0.0;

      print('🔵 [ModalitePaiment] Envoi:');
      print('   - Type: $_selectedPaymentType');
      print('   - Périodes: $_nombrePeriodes');
      print('   - Montant/période: $montantParPeriode');
      print('   - Montant à payer: $_montantAPayer');

      // ✅ Envoi au backend
      final confirmResult = await PaymentService.confirmPayment(
        paymentId: widget.paymentId ?? '',
        modalite: _selectedPaymentMethod!,
        typePaiement: _selectedPaymentType,
        montantAPayer: _montantAPayer,
        nombreMois: _selectedPaymentType == 'mois' ? _nombrePeriodes : 1,
        montantMensuel:
            _selectedPaymentType == 'mois' ? montantParPeriode : null,
      );

      if (confirmResult['success'] != true) {
        throw Exception(confirmResult['message'] ?? 'Erreur de confirmation');
      }

      print('✅ [ModalitePaiment] Paiement confirmé');

      // Upload de la quittance
      dynamic fileData = kIsWeb ? _selectedFileBytes : _selectedFile;

      final uploadResult = await PaymentService.uploadQuittance(
        paymentId: widget.paymentId ?? '',
        fileData: fileData,
        fileName: _selectedFileName!,
      );

      if (uploadResult['success'] != true) {
        throw Exception(uploadResult['message'] ?? 'Erreur upload');
      }

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      print('❌ [ModalitePaiment] Erreur: $e');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  // ============================================================
  // WIDGET : SÉLECTION DU TYPE DE PAIEMENT (FILTRÉ)
  // ============================================================

  Widget _buildPaymentTypeSelector() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    // ✅ Si aucun type disponible
    if (_paymentTypes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.orange.shade700, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isArabic
                    ? 'لا توجد أنواع دفع متاحة لهذه الدورة'
                    : 'Aucun type de paiement disponible',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isArabic ? '💰 نوع الدفع' : '💰 Type de paiement',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      _isArabic
                          ? 'اختر الطريقة التي تناسبك'
                          : 'Choisissez votre modalité',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ✅ Afficher les types filtrés
          ..._paymentTypes.asMap().entries.map((entry) {
            final index = entry.key;
            final type = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < _paymentTypes.length - 1 ? 10 : 0,
              ),
              child: _buildPaymentTypeOption(type),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeOption(Map<String, dynamic> type) {
    final value = type['value'] as String;
    final icon = type['icon'] as String? ?? '💳';
    final labelFr = type['labelFr'] as String? ?? value;
    final labelAr = type['labelAr'] as String? ?? value;
    final isPeriodic = type['isPeriodic'] == true;

    final isSelected = _selectedPaymentType == value;
    final symbol = _getCurrencySymbol();

    final nombrePeriodes = isPeriodic ? _calculerNombrePeriodes(value) : 1;

    final double montantAffiche = isPeriodic && nombrePeriodes > 0
        ? _montantTotal / nombrePeriodes
        : _montantTotal;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentType = value;
          _nombrePeriodes = nombrePeriodes;
          _errorMessage = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.06)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Emoji
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),

            // Texte
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isArabic ? labelAr : labelFr,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPeriodic
                        ? _getPeriodeLabel(nombrePeriodes, value)
                        : (_isArabic ? 'دفعة واحدة' : 'En une fois'),
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Montant
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${montantAffiche.toStringAsFixed(0)} $symbol',
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                if (isPeriodic && nombrePeriodes > 1)
                  Text(
                    _isArabic ? 'لكل فترة' : 'par période',
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WIDGET : RÉCAPITULATIF
  // ============================================================

  Widget _buildAmountSummary() {
    if (_selectedPaymentType == null) return const SizedBox.shrink();

    final isPeriodic = _isPeriodic;
    final symbol = _getCurrencySymbol();
    final config = _currentTypeConfig;
    final labelFr = config?['labelFr'] as String? ?? '';
    final labelAr = config?['labelAr'] as String? ?? '';
    final icon = config?['icon'] as String? ?? '';
    final typeLabel = _isArabic ? labelAr : labelFr;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.08),
            primaryColor.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Période formation
          if (_dateDebut != null && _dateFin != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isArabic ? '📅 فترة التكوين' : '📅 Période',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  '${_formatDate(_dateDebut!)} → ${_formatDate(_dateFin!)}',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Type
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isArabic ? 'نوع الدفع' : 'Type',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '$icon $typeLabel',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Montant total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isArabic ? 'المبلغ الإجمالي' : 'Montant total',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '${_montantTotal.toStringAsFixed(0)} $symbol',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),

          // Nombre de périodes
          if (isPeriodic && _nombrePeriodes > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isArabic ? 'عدد الفترات' : 'Nombre de périodes',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  _getPeriodeLabel(_nombrePeriodes, _selectedPaymentType!),
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],

          const Divider(height: 20),

          // Montant à payer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isPeriodic
                    ? (_isArabic ? 'المبلغ لكل فترة' : 'Montant par période')
                    : (_isArabic ? 'المبلغ الواجب دفعه' : 'Montant à payer'),
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${_montantAPayer.toStringAsFixed(0)} $symbol',
                style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ============================================================
  // WIDGETS MODERNISÉS (identiques)
  // ============================================================

  Widget _buildModernPaymentCard({
    required String title,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String method,
    required String description,
    required String bankInfo,
    bool isDisabled = false,
  }) {
    final bool isSelected = _selectedPaymentMethod == method && !isDisabled;
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final bool isLocked = _selectedPaymentType == null;

    return AnimatedOpacity(
      opacity: isLocked ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 250),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : bgColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (isDisabled || isLocked)
                ? () {
                    if (isDisabled) {
                      _showDisabledDialog();
                    } else {
                      _showSelectTypeFirstDialog();
                    }
                  }
                : () {
                    setState(() {
                      _selectedPaymentMethod = method;
                      _errorMessage = null;
                    });
                  },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDisabled
                              ? Colors.grey.shade200
                              : color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          icon,
                          color: isDisabled ? Colors.grey.shade500 : color,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDisabled
                                    ? Colors.grey.shade500
                                    : Colors.black87,
                              ),
                            ),
                            if (description.isNotEmpty)
                              Text(
                                description,
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: isDisabled
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      if (isDisabled)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _isArabic ? 'غير مفعل' : 'Désactivé',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      if (isSelected && !isDisabled)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.green.shade700,
                            size: 28,
                          ),
                        ),
                    ],
                  ),

                  if (!isDisabled && bankInfo.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.amber.shade800,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                bankInfo,
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  color: Colors.amber.shade900,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (isSelected && !isDisabled) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    _buildModernFilePicker(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernFilePicker() {
    final hasFile = _hasFile();
    final fileName = _selectedFileName ??
        (_isArabic ? 'لم يتم اختيار ملف' : 'Aucun fichier sélectionné');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isArabic ? '📎 إرفاق وثيقة الدفع' : '📎 Joindre un justificatif',
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Icon(
                        hasFile ? Icons.file_present : Icons.attach_file,
                        color: hasFile
                            ? Colors.green.shade700
                            : Colors.grey.shade500,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          fileName,
                          style: GoogleFonts.cairo(
                            color: hasFile
                                ? Colors.black87
                                : Colors.grey.shade600,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasFile)
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade600,
                          size: 18,
                        ),
                    ],
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _pickFile(_selectedPaymentMethod!),
                icon: const Icon(
                  Icons.upload_file,
                  color: primaryColor,
                  size: 18,
                ),
                label: Text(
                  _isArabic ? 'اختيار' : 'Parcourir',
                  style: GoogleFonts.cairo(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isArabic
              ? '📌 الصيغ المقبولة: PDF, JPG, PNG, DOC (الحد الأقصى 5 ميجابايت)'
              : '📌 Formats acceptés : PDF, JPG, PNG, DOC (max 5Mo)',
          style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildModernHeader() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet = MediaQuery.of(context).size.width >= 600 &&
        MediaQuery.of(context).size.width < 1200;

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, primaryColorLight],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.payment_rounded,
              color: Colors.white,
              size: isMobile ? 28 : 36,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isArabic
                      ? 'اختر طريقة الدفع'
                      : 'Choisissez votre mode de paiement',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 18 : (isTablet ? 22 : 26),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isArabic
                      ? 'قم باختيار طريقة الدفع وإرفاق الوثائق'
                      : 'Sélectionnez un mode et joignez les justificatifs',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 13 : (isTablet ? 14 : 15),
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.cairo(
                color: Colors.red.shade700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernValidateButton() {
    final isEnabled = _canSubmit;
    final isMobile = MediaQuery.of(context).size.width < 600;

    String buttonText;
    if (!isEnabled) {
      if (_selectedPaymentType == null) {
        buttonText = _isArabic ? 'اختر نوع الدفع' : 'Sélectionnez un type';
      } else if (_selectedPaymentMethod == null) {
        buttonText = _isArabic ? 'اختر طريقة الدفع' : 'Sélectionnez un mode';
      } else {
        buttonText = _isArabic ? 'أرفق ملفاً' : 'Joignez un fichier';
      }
    } else {
      buttonText = _isArabic ? 'تأكيد الدفع' : 'Valider le paiement';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: isMobile ? 54 : 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : (isEnabled ? _submitPayment : null),
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? primaryColor : Colors.grey.shade400,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isEnabled
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_rounded,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    buttonText,
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildModernFooter() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          _buildFooterItem(
            Icons.lock_outline_rounded,
            _isArabic ? '🔒 دفع آمن' : '🔒 Paiement sécurisé',
          ),
          _buildFooterItem(
            Icons.support_agent_outlined,
            _isArabic ? '📞 دعم 7/7' : '📞 Support 7j/7',
          ),
          _buildFooterItem(
            Icons.shield_outlined,
            _isArabic ? '🛡️ معلومات مشفرة' : '🛡️ Données chiffrées',
          ),
        ],
      ),
    );
  }

  Widget _buildFooterItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // ============================================================
  // DIALOGUES
  // ============================================================

  void _showDisabledDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            Text(
              _isArabic ? '⚠️ خدمة غير مفعلة' : '⚠️ Service désactivé',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          _isArabic
              ? 'خدمة الدفع عبر الإنترنت غير متوفرة حالياً.'
              : 'Le paiement en ligne est temporairement indisponible.',
          style: GoogleFonts.cairo(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _isArabic ? 'حسناً' : 'OK',
              style: const TextStyle(color: primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showSelectTypeFirstDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isArabic
              ? '⚠️ الرجاء اختيار نوع الدفع أولاً'
              : '⚠️ Veuillez d\'abord choisir un type',
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade700,
                size: 64,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isArabic ? '✅ تم الدفع بنجاح' : '✅ Paiement réussi',
              style: GoogleFonts.cairo(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
        content: Text(
          _isArabic
              ? 'تم تسجيل عملية الدفع.\n\n'
                  '📧 ستصلك رسالة تأكيد قريباً.\n\n'
                  '📋 رقم المرجع: ${widget.paymentId ?? "N/A"}'
              : 'Votre paiement a été enregistré.\n\n'
                  '📧 Vous recevrez une confirmation bientôt.\n\n'
                  '📋 Référence: ${widget.paymentId ?? "N/A"}',
          style: GoogleFonts.cairo(fontSize: 15, height: 1.6),
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _isArabic ? 'العودة' : 'Retour',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD PRINCIPAL
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet = MediaQuery.of(context).size.width >= 600 &&
        MediaQuery.of(context).size.width < 1200;

    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      appBar: AppBar(
        title: Text(
          _isArabic ? 'طرق الدفع' : 'Modalités de Paiement',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 18 : 22,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.all(isMobile ? 16 : 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isTablet ? 800 : 700),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildModernHeader(),
                      const SizedBox(height: 24),

                      // ÉTAPE 1 : Type
                      _buildStepIndicator(
                        step: 1,
                        isActive: true,
                        isCompleted: _selectedPaymentType != null,
                        label: _isArabic
                            ? 'اختر نوع الدفع'
                            : 'Type de paiement',
                      ),
                      const SizedBox(height: 12),
                      _buildPaymentTypeSelector(),
                      const SizedBox(height: 24),

                      // ÉTAPE 2 : Mode
                      _buildStepIndicator(
                        step: 2,
                        isActive: _selectedPaymentType != null,
                        isCompleted: _selectedPaymentMethod != null,
                        label: _isArabic
                            ? 'اختر طريقة الدفع'
                            : 'Mode de paiement',
                      ),
                      const SizedBox(height: 12),

                      _buildModernPaymentCard(
                        title: _isArabic
                            ? '🏦 تحويل بنكي'
                            : '🏦 Versement Bancaire',
                        icon: Icons.account_balance,
                        color: const Color(0xff1a8a6a),
                        bgColor: const Color(0xff1a8a6a),
                        method: 'bancaire',
                        description: _isArabic
                            ? 'تحويل بنكي عبر حسابنا الجاري'
                            : 'Virement bancaire',
                        bankInfo: _isArabic
                            ? '🏦 حساب BNA: 1000123456789'
                            : '🏦 Compte BNA : 1000123456789',
                      ),

                      _buildModernPaymentCard(
                        title: _isArabic
                            ? '📮 تحويل بريدي'
                            : '📮 Versement Postal',
                        icon: Icons.local_post_office,
                        color: const Color(0xffe88b2a),
                        bgColor: const Color(0xffe88b2a),
                        method: 'postal',
                        description: _isArabic
                            ? 'تحويل بريدي عبر مكتب البريد'
                            : 'Virement postal',
                        bankInfo: _isArabic
                            ? '📮 حساب بريدي: 123456789'
                            : '📮 Compte postal : 123456789',
                      ),

                      _buildModernPaymentCard(
                        title: _isArabic
                            ? '💳 دفع عبر الإنترنت'
                            : '💳 Paiement en Ligne',
                        icon: Icons.payment,
                        color: Colors.grey.shade600,
                        bgColor: Colors.grey.shade600,
                        method: 'en_ligne',
                        description: _isArabic
                            ? 'بطاقة بنكية'
                            : 'Carte bancaire',
                        bankInfo: '',
                        isDisabled: true,
                      ),

                      const SizedBox(height: 16),
                      _buildAmountSummary(),
                      const SizedBox(height: 24),

                      if (_errorMessage != null) ...[
                        _buildModernErrorMessage(),
                        const SizedBox(height: 16),
                      ],

                      _buildModernValidateButton(),
                      const SizedBox(height: 20),
                      _buildModernFooter(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildStepIndicator({
    required int step,
    required bool isActive,
    required bool isCompleted,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? Colors.green.shade600
                : (isActive ? primaryColor : Colors.grey.shade300),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '$step',
                    style: GoogleFonts.cairo(
                      color: isActive ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.black87 : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}