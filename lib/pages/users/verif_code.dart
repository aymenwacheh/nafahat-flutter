// lib/pages/users/verif_code.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/language_provider.dart';
import '../../services/verification_service.dart';
import '../landing/widgets/navbar.dart';
import '../../models/adherent.dart';
import '../../models/enfant.dart';
import '../landing/widgets/chatbot/chatbot_wrapper.dart';

class VerifCodePage extends StatefulWidget {
  final String email;
  final String whatsapp;
  final String nomPrenom;
  final Adherent adherent;
  final List<Enfant> enfants;
  final bool fromFormationDetail;

  const VerifCodePage({
    super.key,
    required this.email,
    required this.whatsapp,
    required this.nomPrenom,
    required this.adherent,
    required this.enfants,
    this.fromFormationDetail = false,
  });

  @override
  State<VerifCodePage> createState() => _VerifCodePageState();
}

class _VerifCodePageState extends State<VerifCodePage> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isResending = false;
  int _countdown = 60;
  Timer? _countdownTimer;

  String? _errorMessage;
  bool _isCodeValid = false;

  // Couleurs
  static const Color nafahatGreen = Color(0xff0D443E);
  static const Color nafahatGold = Color(0xffC4A46C);

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _codeFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocusNode.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  bool get _isArabic =>
      Provider.of<LanguageProvider>(context, listen: false).isArabic;

  void _startCountdown() {
    setState(() => _countdown = 60);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_countdown > 0) {
            _countdown--;
          } else {
            timer.cancel();
          }
        });
      }
    });
  }

  Future<void> _resendCode() async {
    if (_isResending || _countdown > 0) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      await VerificationService.sendVerificationCode(
        email: widget.email,
        whatsapp: widget.whatsapp,
        nomPrenom: widget.nomPrenom,
      );

      _startCountdown();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isArabic
                  ? '📧 Code renvoyé à ${widget.email}'
                  : '📧 Code renvoyé à ${widget.email}',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: nafahatGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();

    if (code.isEmpty || code.length != 6) {
      setState(() {
        _errorMessage =
            _isArabic
                ? '⚠️ Veuillez entrer un code à 6 chiffres'
                : '⚠️ Veuillez entrer un code à 6 chiffres';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await VerificationService.verifyCodeAndCreateUser(
        email: widget.email,
        code: code,
        adherent: widget.adherent,
        enfants: widget.enfants,
      );

      if (mounted && result['success'] == true) {
        _showSuccessPopup(
          context,
          _isArabic,
          result['credentials']['identifiant'],
          result['motDePasse'],
          result['adherentId'],
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessPopup(
    BuildContext context,
    bool isArabic,
    String identifiant,
    String motDePasse,
    dynamic adherentId,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext dialogContext) {
        final screenSize = MediaQuery.of(context).size;
        return Dialog(
          alignment: Alignment.center,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: screenSize.width > 500 ? 440 : double.infinity,
            constraints: BoxConstraints(maxHeight: screenSize.height * 0.85),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff0D443E).withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xff0D443E), Color(0xff1a6b5e)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff0D443E).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 42,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isArabic
                        ? '🎉 تم التسجيل بنجاح'
                        : '🎉 Inscription réussie !',
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff0D443E),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isArabic
                        ? 'مرحباً بك في أكاديمية نفحات'
                        : 'Bienvenue à l\'Académie Nafahat',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xff0D443E).withOpacity(0.05),
                          const Color(0xff0D443E).withOpacity(0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xff0D443E).withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          isArabic ? '📱 Identifiant' : '📱 Identifiant',
                          identifiant,
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          isArabic ? '🔑 Mot de passe' : '🔑 Mot de passe',
                          motDePasse,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          isArabic
                              ? '⚠️ Conservez ces informations précieusement'
                              : '⚠️ Conservez ces informations précieusement',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);

                        if (widget.fromFormationDetail) {
                          Navigator.pop(context, {
                            'success': true,
                            'adherentId': adherentId?.toString(),
                          });
                        } else {
                          Navigator.pushReplacementNamed(context, '/');
                        }
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
                      child: Text(
                        widget.fromFormationDetail
                            ? (isArabic
                                ? 'متابعة الدفع'
                                : 'Continuer vers le paiement')
                            : (isArabic
                                ? 'الذهاب إلى الصفحة الرئيسية'
                                : 'Aller à l\'accueil'),
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade600),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xff0D443E).withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xff0D443E).withOpacity(0.15),
            ),
          ),
          child: Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xff0D443E),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return ChatbotWrapper(
      apiBaseUrl: 'http://localhost:3000',
      langue: isArabic ? 'ar' : 'fr',
      primaryColor: nafahatGreen,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: SafeArea(
          top: false,
          child: Stack(
            children: [
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding: EdgeInsets.all(isMobile ? 20 : 32),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(top: isMobile ? 120 : 100),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isMobile ? 24 : 36),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icône
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: nafahatGreen.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.email_rounded,
                                size: 48,
                                color: nafahatGreen,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Titre
                            Text(
                              isArabic
                                  ? '📧 التحقق من البريد الإلكتروني'
                                  : '📧 Vérification par email',
                              style: GoogleFonts.cairo(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xff2c221e),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Message
                            Text(
                              isArabic
                                  ? 'أدخل الرمز المكون من 6 أرقام الذي تم إرساله إلى'
                                  : 'Entrez le code à 6 chiffres envoyé à',
                              style: GoogleFonts.cairo(
                                fontSize: 15,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: nafahatGreen.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: nafahatGreen.withOpacity(0.1),
                                ),
                              ),
                              child: Text(
                                widget.email,
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: nafahatGreen,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Champ du code
                            TextField(
                              controller: _codeController,
                              focusNode: _codeFocusNode,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 6,
                              autofocus: true,
                              decoration: InputDecoration(
                                labelText:
                                    isArabic
                                        ? 'رمز التحقق'
                                        : 'Code de vérification',
                                hintText: '123456',
                                counterText: '',
                                prefixIcon: Icon(
                                  Icons.security_rounded,
                                  color: nafahatGreen,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color:
                                        _errorMessage != null
                                            ? Colors.red.shade300
                                            : Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: nafahatGreen,
                                    width: 2,
                                  ),
                                ),
                                errorText: _errorMessage,
                                errorStyle: GoogleFonts.cairo(
                                  fontSize: 13,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              style: GoogleFonts.cairo(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 8,
                              ),
                              onChanged: (value) {
                                if (_errorMessage != null) {
                                  setState(() => _errorMessage = null);
                                }
                                if (value.length == 6) {
                                  _verifyCode();
                                }
                              },
                            ),
                            const SizedBox(height: 16),

                            // Bouton de vérification
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _verifyCode,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: nafahatGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                                child:
                                    _isLoading
                                        ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.check_rounded),
                                            const SizedBox(width: 8),
                                            Text(
                                              isArabic
                                                  ? 'تحقق من الرمز'
                                                  : 'Vérifier le code',
                                              style: GoogleFonts.cairo(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Renvoyer le code
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isArabic
                                      ? 'لم تتلق الرمز؟'
                                      : 'Vous n\'avez pas reçu le code ?',
                                  style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                _countdown > 0
                                    ? Text(
                                      '${_countdown}s',
                                      style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: nafahatGreen,
                                      ),
                                    )
                                    : TextButton(
                                      onPressed:
                                          _isResending ? null : _resendCode,
                                      style: TextButton.styleFrom(
                                        foregroundColor: nafahatGreen,
                                        padding: EdgeInsets.zero,
                                      ),
                                      child:
                                          _isResending
                                              ? const SizedBox(
                                                height: 16,
                                                width: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Color(0xff0D443E),
                                                    ),
                                              )
                                              : Text(
                                                isArabic
                                                    ? 'إعادة إرسال الرمز'
                                                    : 'Renvoyer le code',
                                                style: GoogleFonts.cairo(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                    ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // NAVBAR
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Navbar(
                  isMobile: isMobile,
                  scaffoldKey: GlobalKey<ScaffoldState>(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
