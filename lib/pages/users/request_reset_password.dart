// lib/pages/users/request_reset_password.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';
import '../../providers/language_provider.dart';
import '../widgets/navbar.dart';

class RequestResetPasswordPage extends StatefulWidget {
  const RequestResetPasswordPage({super.key});

  @override
  State<RequestResetPasswordPage> createState() => _RequestResetPasswordPageState();
}

class _RequestResetPasswordPageState extends State<RequestResetPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const Color nafahatGreen = Color(0xff0D443E);

  Future<void> _requestReset() async {
    final email = _emailController.text.trim();
    final isArabic = Provider.of<LanguageProvider>(context, listen: false).isArabic;

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = isArabic ? 'Veuillez entrer un email valide' : 'Veuillez entrer un email valide';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/adherents/request-password-reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = data['error'] ?? (isArabic ? 'Une erreur est survenue' : 'Une erreur est survenue');
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = isArabic 
            ? 'Erreur de connexion au serveur' 
            : 'Erreur de connexion au serveur';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      key: _scaffoldKey,
      drawer: isMobile ? Navbar(isMobile: true, scaffoldKey: _scaffoldKey).buildDrawer(context) : null,
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Navbar(isMobile: isMobile, scaffoldKey: _scaffoldKey),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 450),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Icône
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: nafahatGreen.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock_reset_rounded,
                            size: 40,
                            color: nafahatGreen,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          isArabic ? '🔑 Réinitialiser le mot de passe' : '🔑 Réinitialiser le mot de passe',
                          style: GoogleFonts.cairo(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff2c221e),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isArabic 
                              ? 'Entrez votre email pour recevoir un lien de réinitialisation'
                              : 'Entrez votre email pour recevoir un lien de réinitialisation',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),

                        if (_emailSent) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.check_circle, size: 48, color: Colors.green.shade700),
                                const SizedBox(height: 12),
                                Text(
                                  isArabic 
                                      ? '✅ Un email de réinitialisation vous a été envoyé'
                                      : '✅ Un email de réinitialisation vous a été envoyé',
                                  style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isArabic
                                      ? 'Vérifiez votre boîte de réception (et vos spams)'
                                      : 'Vérifiez votre boîte de réception (et vos spams)',
                                  style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    color: Colors.green.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: nafahatGreen,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    isArabic ? 'Retour à la connexion' : 'Retour à la connexion',
                                    style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // Champ email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: isArabic ? 'Adresse email' : 'Adresse email',
                              hintText: 'exemple@email.com',
                              prefixIcon: Icon(Icons.email_outlined, color: nafahatGreen),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: nafahatGreen, width: 2),
                              ),
                              errorText: _errorMessage,
                              errorStyle: GoogleFonts.cairo(color: Colors.red.shade700),
                            ),
                            style: GoogleFonts.cairo(fontSize: 16),
                            onChanged: (_) {
                              if (_errorMessage != null) {
                                setState(() => _errorMessage = null);
                              }
                            },
                          ),
                          const SizedBox(height: 20),

                          // Bouton d'envoi
                          ElevatedButton(
                            onPressed: _isLoading ? null : _requestReset,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: nafahatGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    isArabic ? 'Envoyer le lien' : 'Envoyer le lien',
                                    style: GoogleFonts.cairo(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),

                          // Lien retour
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              isArabic ? '← Retour à la connexion' : '← Retour à la connexion',
                              style: GoogleFonts.cairo(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}