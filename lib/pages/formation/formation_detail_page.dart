// lib/pages/formation/formation_detail_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/models/training_model.dart';
import 'package:nafahat/services/training_service.dart';
import 'package:nafahat/services/auth_service.dart';
import 'package:nafahat/services/geo_service.dart';
import 'package:nafahat/services/payment_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../landing/widgets/chatbot/chatbot_wrapper.dart';
import '../users/inscription_adherent.dart';
import '../paiement/modalite_paiment.dart'; // ✅ Import de la page des modalités

class FormationDetailPage extends StatefulWidget {
  final String formationId;

  const FormationDetailPage({super.key, required this.formationId});

  @override
  State<FormationDetailPage> createState() => _FormationDetailPageState();
}

class _FormationDetailPageState extends State<FormationDetailPage> {
  // ============================================================
  // ÉTATS
  // ============================================================

  TrainingModel? _training;
  bool _isLoading = true;
  String? _errorMessage;

  // Langue
  bool _isArabic = true;

  // Devise et pays
  String _countryCode = 'TN';
  bool _isLoadingCountry = true;

  // Authentification
  bool _isAuthenticated = false;
  Map<String, dynamic>? _userData;
  bool _isCheckingAuth = true;

  // WhatsApp Dialog
  final TextEditingController _whatsappController = TextEditingController();
  bool _isWhatsappDialogOpen = false;

  // Paiement
  bool _isProcessingPayment = false;
  String? _currentPaymentId; // ✅ Stocker l'ID du paiement en cours

  // ============================================================
  // CYCLE DE VIE
  // ============================================================

  @override
  void initState() {
    super.initState();
    print(
      '🔵 [INIT] Démarrage de FormationDetailPage pour ID: ${widget.formationId}',
    );
    _loadFormation();
    _loadUserLanguage();
    _detectCountry();
    _checkAuthStatus();
  }

  @override
  void dispose() {
    print('🔴 [DISPOSE] Nettoyage de FormationDetailPage');
    _whatsappController.dispose();
    super.dispose();
  }

  // ============================================================
  // CHARGEMENT DES DONNÉES
  // ============================================================

  Future<void> _loadUserLanguage() async {
    print('🟡 [LANGUE] Chargement de la langue...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString('language');
      print('🟡 [LANGUE] Langue sauvegardée: $savedLang');
      setState(() {
        _isArabic = savedLang == 'ar' || savedLang == null;
        print(
          '🟡 [LANGUE] Langue définie: ${_isArabic ? "Arabe" : "Français"}',
        );
      });
    } catch (e) {
      print('❌ [LANGUE] Erreur: $e');
    }
  }

  Future<void> _detectCountry() async {
    print('🟡 [PAYS] Détection du pays...');
    try {
      final prefs = await SharedPreferences.getInstance();
      String? savedCountry = prefs.getString('user_country');
      print('🟡 [PAYS] Pays sauvegardé: $savedCountry');

      if (savedCountry != null && savedCountry.isNotEmpty) {
        setState(() {
          _countryCode = savedCountry;
          _isLoadingCountry = false;
          print('🟡 [PAYS] Pays chargé depuis cache: $_countryCode');
        });
      } else {
        print('🟡 [PAYS] Aucun pays en cache, détection via IP...');
        final countryCode = await GeoService.getUserCountryCode();
        await prefs.setString('user_country', countryCode);
        setState(() {
          _countryCode = countryCode;
          _isLoadingCountry = false;
          print('🟡 [PAYS] Pays détecté et sauvegardé: $_countryCode');
        });
      }
    } catch (e) {
      print('❌ [PAYS] Erreur détection: $e');
      setState(() {
        _countryCode = 'TN';
        _isLoadingCountry = false;
        print('🟡 [PAYS] Pays par défaut: TN');
      });
    }
  }

  Future<void> _checkAuthStatus() async {
    print('🔵 [AUTH] Vérification du statut d\'authentification...');
    setState(() => _isCheckingAuth = true);
    try {
      _isAuthenticated = await AuthService.isAuthenticated();
      print('🔵 [AUTH] Authentifié: $_isAuthenticated');

      if (_isAuthenticated) {
        _userData = await AuthService.getUserData();
        print(
          '🔵 [AUTH] Données utilisateur: ${_userData?['nomPrenom'] ?? 'Inconnu'}',
        );
        print('🔵 [AUTH] ID utilisateur: ${_userData?['id'] ?? 'Non trouvé'}');
      } else {
        print('🔵 [AUTH] Utilisateur non authentifié');
      }
    } catch (e) {
      print('❌ [AUTH] Erreur: $e');
    } finally {
      if (mounted) {
        setState(() => _isCheckingAuth = false);
        print('🔵 [AUTH] Vérification terminée');
      }
    }
  }

  Future<void> _loadFormation() async {
    print('🔵 [FORMATION] Chargement de la formation...');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🟡 [FORMATION] Appel à TrainingService.getTrainings()');
      final trainings = await TrainingService.getTrainings();
      print('🟡 [FORMATION] ${trainings.length} formations récupérées');

      print(
        '🟡 [FORMATION] Recherche de la formation ID: ${widget.formationId}',
      );
      final found = trainings.firstWhere(
        (t) => t.id == widget.formationId,
        orElse: () {
          print('⚠️ [FORMATION] Formation non trouvée');
          throw Exception('Formation non trouvée');
        },
      );

      print(
        '🟢 [FORMATION] Formation trouvée: ${found.titleFr} (ID: ${found.id})',
      );
      print(
        '🟢 [FORMATION] Prix DT: ${found.priceDt}, EUR: ${found.priceEur}, USD: ${found.priceUsd}',
      );

      setState(() {
        _training = found;
        _isLoading = false;
        print('🟢 [FORMATION] Formation chargée avec succès');
      });
    } catch (e) {
      print('❌ [FORMATION] Erreur: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // GESTION DE LA LANGUE
  // ============================================================

  void _toggleLanguage() {
    print(
      '🟡 [LANGUE] Bascule de langue: ${_isArabic ? "Arabe" : "Français"} -> ${_isArabic ? "Français" : "Arabe"}',
    );
    setState(() {
      _isArabic = !_isArabic;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('language', _isArabic ? 'ar' : 'fr');
      print('🟡 [LANGUE] Langue sauvegardée: ${_isArabic ? "ar" : "fr"}');
    });
  }

  // ============================================================
  // NAVIGATION VERS LA PAGE DES MODALITÉS DE PAIEMENT
  // ============================================================

  /// ✅ Navigation vers la page des modalités de paiement
  void _navigateToPaymentPage(String paymentId) {
    print(
      '🔵 [NAVIGATION] Redirection vers ModalitePaimentPage avec ID: $paymentId',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ModalitePaimentPage(
              paymentId: paymentId,
              formationId: _training?.id,
              userId: _userData?['id']?.toString(),
              currency: _countryCode,
            ),
      ),
    );
  }

  // ============================================================
  // GESTION DE L'INSCRIPTION / PAIEMENT
  // ============================================================

  Future<void> _handleInscription() async {
    print('🔵 [INSCRIPTION] Début du processus d\'inscription/paiement');

    if (_training == null) {
      print('❌ [INSCRIPTION] Formation null, annulation');
      return;
    }

    print(
      '🟡 [INSCRIPTION] Formation: ${_training!.titleFr} (ID: ${_training!.id})',
    );
    print('🟡 [INSCRIPTION] Authentifié: $_isAuthenticated');
    print('🟡 [INSCRIPTION] Pays: $_countryCode');

    setState(() => _isProcessingPayment = true);

    try {
      // ==========================================================
      // CAS 1: UTILISATEUR CONNECTÉ
      // ==========================================================
      if (_isAuthenticated) {
        print('🟢 [INSCRIPTION] CAS 1: Utilisateur connecté');
        print('🟡 [INSCRIPTION] Récupération de l\'ID utilisateur...');

        final userId = await AuthService.getUserIdForPayment();
        print('🟡 [INSCRIPTION] ID utilisateur: $userId');

        if (userId != null) {
          print('🟢 [INSCRIPTION] Utilisateur connecté, procède au paiement');
          await _proceedToPayment(userId);
          return;
        } else {
          print('⚠️ [INSCRIPTION] ID utilisateur null, impossible de payer');
          throw Exception('ID utilisateur non trouvé');
        }
      }

      // ==========================================================
      // CAS 2: UTILISATEUR NON CONNECTÉ
      // ==========================================================
      print('🟡 [INSCRIPTION] CAS 2: Utilisateur non connecté');
      print('🟡 [INSCRIPTION] Ouverture du dialogue WhatsApp...');

      final result = await _showWhatsappDialog();
      print('🟡 [INSCRIPTION] Résultat du dialogue WhatsApp: $result');

      if (result != null && result['exists'] == true) {
        // ========================================================
        // CAS 2A: WHATSAPP EXISTE → PAIEMENT DIRECT
        // ========================================================
        print('🟢 [INSCRIPTION] CAS 2A: WhatsApp existe');
        final user = result['user'];
        print(
          '🟡 [INSCRIPTION] Utilisateur trouvé: ${user?['nomPrenom'] ?? 'Inconnu'}',
        );

        if (user != null) {
          final userId =
              user['id']?.toString() ?? user['adherent_id']?.toString();
          print('🟡 [INSCRIPTION] ID utilisateur récupéré: $userId');

          if (userId != null) {
            print('🟢 [INSCRIPTION] Compte existant, procède au paiement');
            await _proceedToPayment(userId);
          } else {
            print('❌ [INSCRIPTION] ID utilisateur null');
            throw Exception('ID utilisateur non trouvé');
          }
        } else {
          print('❌ [INSCRIPTION] Données utilisateur null');
          throw Exception('Données utilisateur non trouvées');
        }
      } else if (result != null && result['exists'] == false) {
        // ========================================================
        // CAS 2B: WHATSAPP N'EXISTE PAS → AFFICHER POPUP
        // ========================================================
        print('🟡 [INSCRIPTION] CAS 2B: WhatsApp n\'existe pas');
        print('🟡 [INSCRIPTION] Affichage du popup "Compte non trouvé"');

        _isWhatsappDialogOpen = false;

        if (mounted) {
          _showAccountNotFoundDialog();
        }
      } else {
        print('🟡 [INSCRIPTION] Dialogue WhatsApp annulé par l\'utilisateur');
      }
    } catch (e) {
      print('❌ [INSCRIPTION] Erreur: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isArabic ? '❌ Erreur: $e' : '❌ Erreur: $e',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
        print('🔵 [INSCRIPTION] Processus terminé');
      }
    }
  }

  // ============================================================
  // POPUP "COMPTE NON TROUVÉ"
  // ============================================================

  void _showAccountNotFoundDialog() {
    if (!mounted) return;

    print(
      '🔵 [POPUP] Affichage du popup "Compte non trouvé" sur FormationDetailPage',
    );
    print('🟡 [POPUP] Langue: ${_isArabic ? "Arabe" : "Français"}');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Colors.orange,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isArabic
                    ? '🔍 لا يوجد حساب بهذا الرقم'
                    : '🔍 Aucun compte trouvé',
                style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isArabic
                    ? 'رقم الواتساب الذي أدخلته غير مسجل في نظامنا.\n\n'
                        '📝 للاستمرار في التسجيل في هذه التكوين، '
                        'يجب عليك إنشاء حساب أولاً.\n\n'
                        '✅ العملية سريعة ومجانية !'
                    : 'Le numéro WhatsApp que vous avez saisi n\'est pas enregistré.\n\n'
                        '📝 Pour continuer votre inscription à cette formation, '
                        'vous devez d\'abord créer un compte.\n\n'
                        '✅ C\'est rapide et gratuit !',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xff0D443E).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xff0D443E).withOpacity(0.1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.school_outlined,
                      color: Color(0xff0D443E),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _isArabic
                            ? '🎯 التكوين: ${_training?.titleAr ?? ''}'
                            : '🎯 Formation: ${_training?.titleFr ?? ''}',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xff0D443E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  print('🔵 [POPUP] Clic sur "Créer un compte et continuer"');
                  Navigator.pop(dialogContext);
                  _redirectToInscriptionAndBack();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff0D443E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_add_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _isArabic
                          ? '📝 إنشاء حساب والمتابعة'
                          : '📝 Créer un compte et continuer',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                print('🔵 [POPUP] Annulation');
                Navigator.pop(dialogContext);
              },
              child: Text(
                _isArabic ? 'إلغاء' : 'Annuler',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DIALOGUE WHATSAPP
  // ============================================================

  Future<Map<String, dynamic>?> _showWhatsappDialog() async {
    print('🔵 [WHATSAPP] Ouverture du dialogue WhatsApp');

    if (_isWhatsappDialogOpen) {
      print('⚠️ [WHATSAPP] Dialogue déjà ouvert, retour null');
      return null;
    }

    _isWhatsappDialogOpen = true;
    String whatsapp = '';
    String? error;
    bool isLoading = false;

    print('🟡 [WHATSAPP] Affichage du dialogue...');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.phone_android_rounded,
                    color: const Color(0xff0D443E),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isArabic ? '📱 رقم الواتساب' : '📱 Numéro WhatsApp',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isArabic
                        ? 'أدخل رقم الواتساب الخاص بك للتحقق من حسابك'
                        : 'Entrez votre numéro WhatsApp pour vérifier votre compte',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _whatsappController,
                    decoration: InputDecoration(
                      labelText: _isArabic ? 'رقم الواتساب' : 'Numéro WhatsApp',
                      hintText: '25 357 461',
                      helperText:
                          _isArabic
                              ? '📌 مثال: 25 357 461 (بدون +216)'
                              : '📌 Exemple: 25 357 461 (sans +216)',
                      helperStyle: GoogleFonts.cairo(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.phone_android_rounded),
                      suffixIcon:
                          isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xff0D443E),
                                  ),
                                ),
                              )
                              : null,
                      errorText: error,
                      errorStyle: GoogleFonts.cairo(
                        fontSize: 13,
                        color: Colors.red[700],
                      ),
                    ),
                    style: GoogleFonts.cairo(),
                    keyboardType: TextInputType.phone,
                    onChanged: (value) {
                      whatsapp = value;
                      if (error != null) {
                        setDialogState(() => error = null);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    print('🔵 [WHATSAPP] Annulation par l\'utilisateur');
                    _isWhatsappDialogOpen = false;
                    Navigator.pop(context, null);
                  },
                  child: Text(
                    _isArabic ? 'إلغاء' : 'Annuler',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      isLoading
                          ? null
                          : () async {
                            print('🔵 [WHATSAPP] Clic sur Vérifier');

                            final cleanWhatsapp = whatsapp.replaceAll(
                              RegExp(r'[\s\-\(\)]'),
                              '',
                            );
                            print(
                              '🟡 [WHATSAPP] Numéro nettoyé: $cleanWhatsapp',
                            );

                            if (cleanWhatsapp.length < 8) {
                              print(
                                '⚠️ [WHATSAPP] Numéro trop court: ${cleanWhatsapp.length} caractères',
                              );
                              setDialogState(() {
                                error =
                                    _isArabic
                                        ? '⚠️ الرجاء إدخال رقم صحيح (8 أرقام على الأقل)'
                                        : '⚠️ Veuillez entrer un numéro valide (8 chiffres minimum)';
                              });
                              return;
                            }

                            setDialogState(() => isLoading = true);
                            print(
                              '🟡 [WHATSAPP] Vérification du numéro: $cleanWhatsapp',
                            );

                            try {
                              final fullWhatsapp = '+216$cleanWhatsapp';
                              print(
                                '🟡 [WHATSAPP] Numéro complet: $fullWhatsapp',
                              );

                              print(
                                '🟡 [WHATSAPP] Appel à AuthService.checkWhatsappExists()...',
                              );
                              final exists =
                                  await AuthService.checkWhatsappExists(
                                    fullWhatsapp,
                                  );
                              print('🟡 [WHATSAPP] Résultat exists: $exists');

                              if (exists) {
                                print(
                                  '🟢 [WHATSAPP] Numéro trouvé, récupération des données...',
                                );
                                final user =
                                    await AuthService.getUserByWhatsapp(
                                      fullWhatsapp,
                                    );
                                print(
                                  '🟢 [WHATSAPP] Utilisateur trouvé: ${user?['nomPrenom'] ?? 'Inconnu'}',
                                );

                                _isWhatsappDialogOpen = false;

                                print(
                                  '🟢 [WHATSAPP] Retour des données utilisateur',
                                );
                                if (mounted) {
                                  Navigator.pop(context, {
                                    'exists': true,
                                    'user': user,
                                  });
                                }
                              } else {
                                print('⚠️ [WHATSAPP] Numéro non trouvé');
                                setDialogState(() => isLoading = false);

                                _isWhatsappDialogOpen = false;
                                if (mounted) {
                                  Navigator.pop(context, {
                                    'exists': false,
                                    'whatsapp': fullWhatsapp,
                                  });
                                }
                              }
                            } catch (e) {
                              print('❌ [WHATSAPP] Erreur: $e');
                              setDialogState(() {
                                isLoading = false;
                                error =
                                    _isArabic
                                        ? '❌ Erreur de vérification'
                                        : '❌ Erreur de vérification';
                              });
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0D443E),
                    foregroundColor: Colors.white,
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
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Text(
                            _isArabic ? '🔍 التحقق' : '🔍 Vérifier',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ],
            );
          },
        );
      },
    );

    _isWhatsappDialogOpen = false;
    print('🔵 [WHATSAPP] Dialogue fermé, résultat: $result');
    return result;
  }

  // ============================================================
  // PAIEMENT - NAVIGATION VERS MODALITE_PAIMENT
  // ============================================================

  Future<void> _proceedToPayment(String userId) async {
    print('🔵 [PAIEMENT] Début du processus de paiement');
    print('🟡 [PAIEMENT] UserId: $userId');
    print('🟡 [PAIEMENT] Formation: ${_training?.titleFr ?? 'Inconnue'}');

    if (_training == null) {
      print('❌ [PAIEMENT] Formation null, annulation');
      return;
    }

    final currency = TrainingModel.getCurrencySymbol(_countryCode);
    print('🟡 [PAIEMENT] Devise: $currency (pays: $_countryCode)');
    print(
      '🟡 [PAIEMENT] Prix: ${_training!.getPriceForCurrency(_countryCode)} $currency',
    );

    try {
      print('🟡 [PAIEMENT] Appel à PaymentService.initiatePayment()...');
      final result = await PaymentService.initiatePayment(
        formationId: _training!.id,
        userId: userId,
        currency: currency,
      );
      print('🟡 [PAIEMENT] Résultat du service: $result');

      if (result['success'] == true) {
        print('🟢 [PAIEMENT] Paiement initié avec succès');

        // ✅ Récupérer le paymentId depuis la réponse
        final paymentId = result['paymentId']?.toString();

        if (paymentId != null && paymentId.isNotEmpty) {
          // ✅ REDIRECTION VERS LA PAGE DES MODALITÉS DE PAIEMENT
          _navigateToPaymentPage(paymentId);
        } else {
          print('❌ [PAIEMENT] paymentId manquant dans la réponse');
          throw Exception('ID de paiement manquant');
        }
      } else {
        print('❌ [PAIEMENT] Échec du paiement: ${result['message']}');
        throw Exception(result['message'] ?? 'Erreur paiement');
      }
    } catch (e) {
      print('❌ [PAIEMENT] Erreur: $e');
      throw Exception(e);
    }
  }

  // ============================================================
  // REDIRECTION VERS L'INSCRIPTION
  // ============================================================

  Future<void> _redirectToInscriptionAndBack() async {
    if (!mounted) return;

    print('🔵 [REDIRECTION] Redirection vers la page d\'inscription');
    print('🟡 [REDIRECTION] Navigation vers InscriptionAdherentPage...');

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                const InscriptionAdherentPage(fromFormationDetail: true),
      ),
    );

    print('🟡 [REDIRECTION] Retour de l\'inscription avec résultat: $result');

    if (!mounted) return;

    if (result is Map && result['success'] == true) {
      final newAdherentId = result['adherentId']?.toString();
      print(
        '🟢 [REDIRECTION] Inscription réussie, ID adhérent: $newAdherentId',
      );

      if (newAdherentId != null && newAdherentId.isNotEmpty) {
        print(
          '🟢 [REDIRECTION] Lancement direct du paiement pour la formation source',
        );
        setState(() => _isProcessingPayment = true);
        try {
          await _proceedToPayment(newAdherentId);
        } catch (e) {
          print('❌ [REDIRECTION] Erreur lors du paiement: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isArabic ? '❌ Erreur: $e' : '❌ Erreur: $e',
                  style: GoogleFonts.cairo(),
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _isProcessingPayment = false);
        }
      } else {
        print(
          '⚠️ [REDIRECTION] Pas d\'ID adhérent reçu, tentative via _checkAuthStatus()',
        );
        await _checkAuthStatus();
        if (_isAuthenticated) {
          await _handleInscription();
        }
      }
    } else if (result == true || result == 'success') {
      print('🟢 [REDIRECTION] Inscription réussie (résultat simple)');
      await _checkAuthStatus();
      if (_isAuthenticated) {
        await _handleInscription();
      }
    } else {
      print('🟡 [REDIRECTION] Inscription annulée ou échouée');
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return ChatbotWrapper(
      apiBaseUrl: 'http://localhost:3000',
      langue: _isArabic ? 'ar' : 'fr',
      primaryColor: const Color(0xffd57653),
      child: Scaffold(
        backgroundColor: const Color(0xfffcfbfa),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xff2c221e),
            ),
            onPressed: () {
              print('🔵 [NAVIGATION] Retour à la page précédente');
              Navigator.pop(context);
            },
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: const Color(0xffd57653).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Text(
                  _isArabic ? '🇫🇷 FR' : '🇸🇦 AR',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: const Color(0xffd57653),
                  ),
                ),
                onPressed: _toggleLanguage,
                tooltip: _isArabic ? 'Français' : 'العربية',
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            if (_isLoading || _isLoadingCountry || _isCheckingAuth)
              const Center(
                child: CircularProgressIndicator(color: Color(0xffd57653)),
              )
            else if (_errorMessage != null)
              _buildErrorWidget()
            else if (_training == null)
              _buildNotFoundWidget()
            else
              _buildDetailContent(isMobile),

            if (_isProcessingPayment)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xffd57653),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isArabic
                              ? '⏳ جاري تحضير الدفع...'
                              : '⏳ Préparation du paiement...',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WIDGETS DE BUILD
  // ============================================================

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            _isArabic ? 'خطأ في التحميل' : 'Erreur de chargement',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: GoogleFonts.poppins(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadFormation,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffd57653),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _isArabic ? 'التكوين غير موجود' : 'Formation non trouvée',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailContent(bool isMobile) {
    final training = _training!;
    final title = _isArabic ? training.titleAr : training.titleFr;
    final description =
        _isArabic ? training.descriptionAr : training.descriptionFr;

    final price = training.getPriceForCurrency(_countryCode);
    final symbol = TrainingModel.getCurrencySymbol(_countryCode);
    final finalPrice = training.getFinalPriceForCurrency(_countryCode);
    final hasDiscount = training.hasDiscount;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCoverImage(training, isMobile),
          Padding(
            padding: EdgeInsets.all(isMobile ? 20 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBadges(training),
                const SizedBox(height: 16),
                _buildTitle(title, isMobile),
                const SizedBox(height: 12),
                _buildDescription(description, isMobile),
                const SizedBox(height: 32),
                _buildInfoSection(training, isMobile),
                const SizedBox(height: 32),
                _buildPaymentSection(
                  training,
                  isMobile,
                  price,
                  symbol,
                  finalPrice,
                  hasDiscount,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage(TrainingModel training, bool isMobile) {
    String imageUrl = training.imageUrl;
    if (imageUrl.contains('C:\\') || imageUrl.contains('assets/')) {
      imageUrl = 'assets/images/${imageUrl.split('/').last}';
    }
    if (imageUrl.isEmpty ||
        imageUrl.startsWith('file://') ||
        (!imageUrl.startsWith('assets/') && !imageUrl.startsWith('http'))) {
      imageUrl = 'https://picsum.photos/seed/${training.id}/1200/500';
    }

    return Container(
      height: isMobile ? 250 : 400,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        image:
            imageUrl.startsWith('assets/')
                ? DecorationImage(
                  image: AssetImage(imageUrl),
                  fit: BoxFit.cover,
                )
                : DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(String title, bool isMobile) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: isMobile ? 24 : 32,
        fontWeight: FontWeight.w800,
        color: const Color(0xff2c221e),
        height: 1.2,
      ),
    );
  }

  Widget _buildDescription(String description, bool isMobile) {
    return Text(
      description,
      style: GoogleFonts.poppins(
        fontSize: isMobile ? 15 : 17,
        fontWeight: FontWeight.w400,
        color: const Color(0xff7c6e68),
        height: 1.6,
      ),
    );
  }

  Widget _buildBadges(TrainingModel training) {
    final typeDisplay =
        training.typeFormation.isNotEmpty
            ? training.typeFormation
            : 'Formation';
    final discountText =
        training.hasDiscount
            ? training.getDiscountTextForCurrency(_countryCode, _isArabic)
            : null;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xffd57653).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.school_outlined,
                size: 14,
                color: Color(0xffd57653),
              ),
              const SizedBox(width: 4),
              Text(
                typeDisplay,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xffd57653),
                ),
              ),
            ],
          ),
        ),
        if (training.categorieFr.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xff0D443E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.category_outlined,
                  size: 14,
                  color: Color(0xff0D443E),
                ),
                const SizedBox(width: 4),
                Text(
                  _isArabic ? training.categorieAr : training.categorieFr,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff0D443E),
                  ),
                ),
              ],
            ),
          ),
        if (discountText != null && discountText.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_offer_outlined,
                  size: 14,
                  color: Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  discountText,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xffd57653).withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xffd57653).withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.public_rounded,
                size: 14,
                color: Color(0xffd57653),
              ),
              const SizedBox(width: 4),
              Text(
                '${TrainingModel.getCurrencySymbol(_countryCode)} ($_countryCode)',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xffd57653),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(TrainingModel training, bool isMobile) {
    final dureeDisplay =
        training.typeDuree.isNotEmpty ? training.typeDuree : 'Non définie';

    String periodeDisplay = '';
    if (training.dateDebut.isNotEmpty && training.dateFin.isNotEmpty) {
      periodeDisplay = '${training.dateDebut} → ${training.dateFin}';
    } else if (training.period.isNotEmpty) {
      periodeDisplay = training.period;
    } else {
      periodeDisplay = 'Non définie';
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffd57653).withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.person_outline_rounded,
            label: _isArabic ? 'المكون' : 'Formateur',
            value: training.trainer,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            icon: Icons.calendar_today_rounded,
            label: _isArabic ? 'الفترة' : 'Période',
            value: periodeDisplay,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            icon: Icons.access_time_rounded,
            label: _isArabic ? 'المدة' : 'Durée',
            value: dureeDisplay,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            icon: Icons.people_outline_rounded,
            label: _isArabic ? 'الجمهور المستهدف' : 'Public cible',
            value: training.target,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xffd57653).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: const Color(0xffd57653)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xff7c6e68),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff2c221e),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection(
    TrainingModel training,
    bool isMobile,
    double price,
    String symbol,
    double finalPrice,
    bool hasDiscount,
  ) {
    final isUserLoggedIn = _isAuthenticated;

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xffd57653).withOpacity(0.05),
            const Color(0xffd57653).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffd57653).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (hasDiscount) ...[
                Text(
                  '${price.toStringAsFixed(0)} $symbol',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                '${finalPrice.toStringAsFixed(0)} $symbol',
                style: GoogleFonts.poppins(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xffd57653),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'TTC',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xff7c6e68),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isArabic
                ? '💰 السعر بـ ${TrainingModel.getCurrencyName(_countryCode)}'
                : '💰 Prix en ${TrainingModel.getCurrencyName(_countryCode)}',
            style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 12),
          if (hasDiscount)
            Text(
              _isArabic
                  ? '🎉 وفر ${(price - finalPrice).toStringAsFixed(0)} $symbol !'
                  : '🎉 Économisez ${(price - finalPrice).toStringAsFixed(0)} $symbol !',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessingPayment ? null : _handleInscription,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffd57653),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child:
                  _isProcessingPayment
                      ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isUserLoggedIn
                                ? Icons.payment_rounded
                                : Icons.person_add_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isUserLoggedIn
                                ? (_isArabic
                                    ? '💳 الدفع الآن'
                                    : '💳 Payer maintenant')
                                : (_isArabic
                                    ? '📝 التسجيل والدفع'
                                    : '📝 S\'inscrire et payer'),
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isUserLoggedIn
                    ? Icons.check_circle_outline_rounded
                    : Icons.info_outline_rounded,
                size: 16,
                color: isUserLoggedIn ? Colors.green[600] : Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                isUserLoggedIn
                    ? (_isArabic ? '✅ أنت متصل' : '✅ Vous êtes connecté')
                    : (_isArabic
                        ? '📱 التحقق عبر واتساب مطلوب'
                        : '📱 Vérification WhatsApp requise'),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isUserLoggedIn ? Colors.green[600] : Colors.grey[500],
                ),
              ),
              if (!isUserLoggedIn) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffd57653).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _isArabic ? 'سريع' : 'Rapide',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xffd57653),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 14,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                _isArabic ? 'دفع آمن' : 'Paiement sécurisé',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.support_agent_outlined,
                size: 14,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                _isArabic ? 'دعم 7/7' : 'Support 7j/7',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
