// lib/pages/paiement/modalite_paiment.dart

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:typed_data';
import 'package:nafahat/services/payment_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

class ModalitePaimentPage extends StatefulWidget {
  final String? paymentId;
  final String? formationId;
  final String? userId;
  final String? currency;

  const ModalitePaimentPage({
    super.key,
    this.paymentId,
    this.formationId,
    this.userId,
    this.currency,
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

  // ✅ Variables unifiées pour le fichier
  Uint8List? _selectedFileBytes; // Pour Web
  File? _selectedFile; // Pour Mobile/Desktop
  String? _selectedFileName;
  String? _selectedMethod;

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  // ============================================================
  // CYCLE DE VIE
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _checkPermissions();
    print('🔵 [ModalitePaiment] Page initialisée avec paymentId: ${widget.paymentId}');
  }

  // ============================================================
  // PERMISSIONS (Android & iOS)
  // ============================================================

  Future<void> _checkPermissions() async {
    if (!kIsWeb) {
      print('🔵 [Permissions] Vérification des permissions...');
      
      // Pour Android 13+ et iOS
      final status = await Permission.storage.request();
      
      if (status.isGranted) {
        print('✅ [Permissions] Accès au stockage accordé');
      } else if (status.isDenied) {
        print('⚠️ [Permissions] Accès au stockage refusé');
        // Demander à nouveau
        final newStatus = await Permission.storage.request();
        if (newStatus.isGranted) {
          print('✅ [Permissions] Accès au stockage accordé (2ème tentative)');
        } else {
          print('❌ [Permissions] Accès au stockage définitivement refusé');
          setState(() {
            _errorMessage = _isArabic 
                ? '⚠️ Veuillez autoriser l\'accès au stockage dans les paramètres'
                : '⚠️ Veuillez autoriser l\'accès au stockage dans les paramètres';
          });
        }
      } else if (status.isPermanentlyDenied) {
        print('❌ [Permissions] Accès au stockage définitivement refusé');
        // Ouvrir les paramètres
        _showPermissionDialog();
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isArabic ? '🔒 Permission requise' : '🔒 Permission requise'),
        content: Text(
          _isArabic 
              ? 'Pour joindre un justificatif, veuillez autoriser l\'accès au stockage dans les paramètres de l\'application.'
              : 'Pour joindre un justificatif, veuillez autoriser l\'accès au stockage dans les paramètres de l\'application.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_isArabic ? 'Annuler' : 'Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text(
              _isArabic ? 'Ouvrir les paramètres' : 'Ouvrir les paramètres',
              style: TextStyle(color: const Color(0xff0D443E)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString('language');
      setState(() {
        _isArabic = savedLang == 'ar' || savedLang == null;
      });
      print('🟡 [ModalitePaiment] Langue: ${_isArabic ? "Arabe" : "Français"}');
    } catch (e) {
      print('❌ [ModalitePaiment] Erreur chargement langue: $e');
    }
  }

  // ============================================================
  // SÉLECTION DE FICHIER (UNIFIÉE) - CORRIGÉE
  // ============================================================

  Future<void> _pickFile() async {
    try {
      // Vérifier les permissions avant de sélectionner
      if (!kIsWeb) {
        final status = await Permission.storage.status;
        if (!status.isGranted) {
          final newStatus = await Permission.storage.request();
          if (!newStatus.isGranted) {
            _showPermissionDialog();
            return;
          }
        }
      }

      print('🔵 [FilePicker] Sélection de fichier');
      print('   📋 Plateforme: ${kIsWeb ? "Web" : "Mobile/Desktop"}');

      // Vérifier qu'une méthode de paiement est sélectionnée
      if (_selectedPaymentMethod == null) {
        setState(() {
          _errorMessage = _isArabic 
              ? '⚠️ الرجاء اختيار طريقة الدفع أولاً' 
              : '⚠️ Veuillez sélectionner un mode de paiement d\'abord';
        });
        return;
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        // ✅ Important: allowMultiple false par défaut
      );

      if (result != null) {
        final file = result.files.single;
        
        print('📄 Fichier sélectionné: ${file.name}');
        print('📄 Taille: ${file.size} bytes');
        print('📄 Path: ${file.path}');
        print('📄 Bytes: ${file.bytes != null ? "Disponible" : "Non disponible"}');

        // Vérifier la taille
        if (file.size > 5 * 1024 * 1024) {
          throw Exception(_isArabic 
              ? 'الملف كبير جداً (الحد الأقصى 5 ميجابايت)' 
              : 'Fichier trop volumineux (max 5MB)');
        }

        setState(() {
          _selectedMethod = _selectedPaymentMethod;
          _selectedFileName = file.name;
          _errorMessage = null;
          
          // Réinitialiser les anciens fichiers
          _selectedFile = null;
          _selectedFileBytes = null;
        });

        if (kIsWeb) {
          // ✅ WEB: Utiliser les bytes
          if (file.bytes != null) {
            setState(() {
              _selectedFileBytes = file.bytes;
            });
            print('✅ [FilePicker] Web: ${file.name} (${file.bytes!.length} bytes)');
          } else {
            throw Exception('Fichier Web sans données');
          }
        } else {
          // ✅ MOBILE/DESKTOP: Utiliser le path avec vérification
          if (file.path != null) {
            final fileObj = File(file.path!);
            
            // Vérifier que le fichier existe
            if (!await fileObj.exists()) {
              throw Exception('Le fichier n\'existe pas');
            }
            
            final fileSize = await fileObj.length();
            
            if (fileSize > 5 * 1024 * 1024) {
              throw Exception('Fichier trop volumineux (max 5MB)');
            }
            
            if (fileSize == 0) {
              throw Exception('Fichier vide');
            }

            setState(() {
              _selectedFile = fileObj;
            });
            print('✅ [FilePicker] Mobile: ${file.name} ($fileSize bytes)');
            print('   📍 Chemin: ${file.path}');
          } else {
            throw Exception('Fichier Mobile sans chemin');
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isArabic 
                  ? '✅ تم اختيار الملف بنجاح' 
                  : '✅ Fichier sélectionné avec succès',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        print('ℹ️ [FilePicker] Sélection annulée');
      }
    } catch (e) {
      print('❌ [FilePicker] Erreur: $e');
      setState(() {
        _selectedFile = null;
        _selectedFileBytes = null;
        _selectedFileName = null;
        _errorMessage = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isArabic ? '❌ خطأ: ${e.toString()}' : '❌ Erreur: ${e.toString()}',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ============================================================
  // VÉRIFICATION SI UN FICHIER EST SÉLECTIONNÉ
  // ============================================================

  bool _hasFile() {
    if (kIsWeb) {
      return _selectedFileBytes != null && _selectedFileName != null;
    } else {
      // Vérifier que le fichier existe toujours sur mobile
      if (_selectedFile != null && _selectedFileName != null) {
        try {
          return _selectedFile!.existsSync();
        } catch (e) {
          print('⚠️ Erreur vérification fichier: $e');
          return false;
        }
      }
      return false;
    }
  }

  // ============================================================
  // SOUMISSION DU PAIEMENT - CORRIGÉE
  // ============================================================

  Future<void> _submitPayment() async {
    // Vérifications
    if (_selectedPaymentMethod == null) {
      setState(() {
        _errorMessage = _isArabic 
            ? '⚠️ الرجاء اختيار طريقة الدفع' 
            : '⚠️ Veuillez sélectionner un mode de paiement';
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

    print('🔵 [ModalitePaiment] Soumission du paiement...');
    print('   📋 PaymentId: ${widget.paymentId}');
    print('   📋 Modalité: $_selectedPaymentMethod');
    print('   📋 Fichier: $_selectedFileName');
    print('   📋 Plateforme: ${kIsWeb ? "Web" : "Mobile"}');

    try {
      // 1. Confirmer la modalité de paiement
      final confirmResult = await PaymentService.confirmPayment(
        paymentId: widget.paymentId ?? '',
        modalite: _selectedPaymentMethod!,
      );

      print('🟡 [ModalitePaiment] Résultat confirmation: $confirmResult');

      if (confirmResult['success'] == false) {
        throw Exception(confirmResult['message'] ?? 'Erreur de confirmation');
      }

      // 2. Préparer les données du fichier pour l'upload
      dynamic fileData;
      
      if (kIsWeb) {
        // Web: utiliser les bytes
        fileData = _selectedFileBytes;
        if (fileData == null) {
          throw Exception('Fichier Web non disponible');
        }
      } else {
        // Mobile/Desktop: utiliser le File
        fileData = _selectedFile;
        if (fileData == null) {
          throw Exception('Fichier Mobile non disponible');
        }
        
        // Vérifier que le fichier existe toujours
        if (!await (fileData as File).exists()) {
          throw Exception('Le fichier a été supprimé ou déplacé');
        }
        
        // Vérifier la taille
        final fileSize = await (fileData as File).length();
        if (fileSize == 0) {
          throw Exception('Le fichier est vide');
        }
        print('📄 Taille du fichier avant upload: $fileSize bytes');
      }

      // 3. Uploader la quittance
      final uploadResult = await PaymentService.uploadQuittance(
        paymentId: widget.paymentId ?? '',
        fileData: fileData,
        fileName: _selectedFileName!,
      );

      print('🟡 [ModalitePaiment] Résultat upload: $uploadResult');

      if (uploadResult['success'] == false) {
        throw Exception(uploadResult['message'] ?? 'Erreur lors de l\'upload');
      }

      // Succès !
      setState(() {
        _isSubmitting = false;
      });
      _showSuccessDialog();
      
    } catch (e) {
      print('❌ [ModalitePaiment] Erreur: $e');
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isArabic ? '❌ خطأ: ${e.toString()}' : '❌ Erreur: ${e.toString()}',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // WIDGETS DE BUILD
  // ============================================================

  Widget _buildFilePickerSection() {
    final hasFile = _hasFile();
    final fileName = _selectedFileName ?? 
        (_isArabic ? 'لم يتم اختيار ملف' : 'Aucun fichier sélectionné');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isArabic ? '📎 إرفاق الوثيقة' : '📎 Joindre un justificatif',
          style: GoogleFonts.cairo(
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8.0),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    fileName,
                    style: GoogleFonts.cairo(
                      color: hasFile ? Colors.black87 : Colors.grey.shade600,
                      fontSize: 13.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _pickFile, // ✅ Plus de paramètre
                icon: Icon(Icons.attach_file, color: const Color(0xff0D443E)),
                label: Text(
                  _isArabic ? 'اختيار' : 'Parcourir',
                  style: GoogleFonts.cairo(
                    color: const Color(0xff0D443E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                ),
              ),
            ],
          ),
        ),
        if (hasFile) ...[
          const SizedBox(height: 8.0),
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green.shade700,
                size: 16.0,
              ),
              const SizedBox(width: 4.0),
              Text(
                _isArabic 
                    ? '✅ الملف جاهز للإرسال' 
                    : '✅ Fichier prêt à être envoyé',
                style: GoogleFonts.cairo(
                  fontSize: 12.0,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          // ✅ Afficher la taille du fichier sur mobile
          if (!kIsWeb && _selectedFile != null)
            FutureBuilder<int>(
              future: _selectedFile!.length(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final size = snapshot.data!;
                  final sizeStr = size > 1024 * 1024 
                      ? '${(size / (1024 * 1024)).toStringAsFixed(2)} MB'
                      : '${(size / 1024).toStringAsFixed(1)} KB';
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '📊 Taille: $sizeStr',
                      style: GoogleFonts.cairo(
                        fontSize: 11.0,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
        ],
        const SizedBox(height: 4.0),
        Text(
          _isArabic 
              ? '📌 الصيغ المقبولة: PDF, JPG, PNG, DOC (الحد الأقصى 5 ميجابايت)' 
              : '📌 Formats acceptés : PDF, JPG, PNG, DOC (max 5Mo)',
          style: GoogleFonts.cairo(
            fontSize: 11.0,
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
        if (kIsWeb)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '🌐 Mode Web - Fichier chargé en mémoire',
              style: GoogleFonts.cairo(
                fontSize: 10.0,
                color: Colors.blue.shade600,
              ),
            ),
          ),
        if (!kIsWeb)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '📱 Mode Mobile - Fichier local',
              style: GoogleFonts.cairo(
                fontSize: 10.0,
                color: Colors.green.shade600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentCard({
    required String title,
    required IconData icon,
    required Color color,
    required String method,
    bool isDisabled = false,
    required double width,
  }) {
    final isSelected = _selectedPaymentMethod == method && !isDisabled;

    return SizedBox(
      width: width,
      child: Card(
        elevation: isSelected ? 8.0 : 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 3.0 : 1.0,
          ),
        ),
        child: InkWell(
          onTap: isDisabled
              ? _showDisabledDialog
              : () {
                setState(() {
                  _selectedPaymentMethod = method;
                  _errorMessage = null;
                });
              },
          borderRadius: BorderRadius.circular(16.0),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: isDisabled
                            ? Colors.grey.shade200
                            : color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Icon(
                        icon,
                        color: isDisabled ? Colors.grey.shade500 : color,
                        size: 28.0,
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.cairo(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                          color: isDisabled
                              ? Colors.grey.shade500
                              : Colors.black87,
                        ),
                      ),
                    ),
                    if (isDisabled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          _isArabic ? 'غير مفعل' : 'Désactivé',
                          style: TextStyle(
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    if (isSelected && !isDisabled)
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade700,
                        size: 24.0,
                      ),
                  ],
                ),
                if (!isDisabled && isSelected) ...[
                  const SizedBox(height: 16.0),
                  Divider(color: Colors.grey.shade300),
                  const SizedBox(height: 12.0),
                  _buildFilePickerSection(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentGrid(bool isMobile, bool isTablet) {
    final isWide = !isMobile || isTablet;

    if (isWide) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return Wrap(
            spacing: 16.0,
            runSpacing: 16.0,
            alignment: WrapAlignment.start,
            children: [
              _buildPaymentCard(
                title: _isArabic ? 'تحويل بنكي' : 'Versement Bancaire',
                icon: Icons.account_balance,
                color: Colors.green.shade700,
                method: 'bancaire',
                width: (constraints.maxWidth - 16.0) / 2,
              ),
              _buildPaymentCard(
                title: _isArabic ? 'دفع عبر الإنترنت' : 'Paiement en Ligne',
                icon: Icons.payment,
                color: Colors.grey.shade600,
                method: 'en_ligne',
                isDisabled: true,
                width: (constraints.maxWidth - 16.0) / 2,
              ),
              _buildPaymentCard(
                title: _isArabic ? 'تحويل بريدي' : 'Versement Postal',
                icon: Icons.local_post_office,
                color: Colors.orange.shade700,
                method: 'postal',
                width: (constraints.maxWidth - 16.0) / 2,
              ),
            ],
          );
        },
      );
    } else {
      return Column(
        children: [
          _buildPaymentCard(
            title: _isArabic ? 'تحويل بنكي' : 'Versement Bancaire',
            icon: Icons.account_balance,
            color: Colors.green.shade700,
            method: 'bancaire',
            width: double.infinity,
          ),
          const SizedBox(height: 16.0),
          _buildPaymentCard(
            title: _isArabic ? 'دفع عبر الإنترنت' : 'Paiement en Ligne',
            icon: Icons.payment,
            color: Colors.grey.shade600,
            method: 'en_ligne',
            isDisabled: true,
            width: double.infinity,
          ),
          const SizedBox(height: 16.0),
          _buildPaymentCard(
            title: _isArabic ? 'تحويل بريدي' : 'Versement Postal',
            icon: Icons.local_post_office,
            color: Colors.orange.shade700,
            method: 'postal',
            width: double.infinity,
          ),
        ],
      );
    }
  }

  Widget _buildHeader(bool isMobile, bool isTablet) {
    final double fontSizeTitle = isMobile ? 16.0 : (isTablet ? 18.0 : 20.0);
    final double fontSizeSubtitle = isMobile ? 13.0 : (isTablet ? 14.0 : 15.0);

    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xff0D443E).withOpacity(0.08),
            const Color(0xff0D443E).withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xff0D443E).withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: const Color(0xff0D443E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: const Color(0xff0D443E),
              size: isMobile ? 24.0 : 32.0,
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isArabic
                      ? 'اختر طريقة الدفع'
                      : 'Choisissez votre mode de paiement',
                  style: GoogleFonts.cairo(
                    fontSize: fontSizeTitle,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff0D443E),
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  _isArabic
                      ? 'قم باختيار طريقة الدفع وإرفاق الوثائق المطلوبة'
                      : 'Sélectionnez un mode de paiement et joignez les justificatifs nécessaires.',
                  style: GoogleFonts.cairo(
                    fontSize: fontSizeSubtitle,
                    color: const Color(0xff0D443E).withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(double fontSizeBody) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.cairo(
                color: Colors.red.shade700,
                fontSize: fontSizeBody,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isMobile, double fontSizeBody) {
    final double fontSize = isMobile ? 12.0 : 14.0;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 16.0,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8.0),
          Text(
            _isArabic ? '🔒 دفع آمن ومشفر' : '🔒 Paiement sécurisé et chiffré',
            style: GoogleFonts.cairo(
              fontSize: fontSize,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 20.0),
          Icon(
            Icons.support_agent_outlined,
            size: 16.0,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8.0),
          Text(
            _isArabic ? '📞 دعم 7/7' : '📞 Support 7j/7',
            style: GoogleFonts.cairo(
              fontSize: fontSize,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidateButton(
    bool isMobile,
    double height,
    double fontSizeBody,
  ) {
    final isEnabled = _selectedPaymentMethod != null && _hasFile();
    final double buttonFontSize = isMobile ? 16.0 : 18.0;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : (isEnabled ? _submitPayment : null),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isEnabled ? const Color(0xff0D443E) : Colors.grey.shade400,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: isEnabled ? 4.0 : 0.0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 24.0,
                width: 24.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color: Colors.white,
                ),
              )
            : Text(
                isEnabled
                    ? (_isArabic ? '✅ تأكيد الدفع' : '✅ Valider le paiement')
                    : (_isArabic
                        ? '⚠️ اختر طريقة الدفع وأرفق ملفاً'
                        : '⚠️ Sélectionnez un mode et joignez un fichier'),
                style: GoogleFonts.cairo(
                  fontSize: buttonFontSize,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
      ),
    );
  }

  void _showDisabledDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade700),
              const SizedBox(width: 12.0),
              Text(
                _isArabic ? '⚠️ خدمة غير مفعلة' : '⚠️ Service désactivé',
                style: GoogleFonts.cairo(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            _isArabic
                ? 'خدمة الدفع عبر الإنترنت غير متوفرة حالياً.\n'
                    'الرجاء استخدام إحدى الطرق الأخرى المتاحة.'
                : 'Le paiement en ligne est temporairement indisponible.\n'
                    'Veuillez utiliser les autres modes de paiement disponibles.',
            style: GoogleFonts.cairo(
              fontSize: 15.0,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                _isArabic ? 'حسناً' : 'OK',
                style: TextStyle(
                  color: const Color(0xff0D443E),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green.shade700,
                  size: 64.0,
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                _isArabic ? '✅ تم الدفع بنجاح' : '✅ Paiement réussi',
                style: GoogleFonts.cairo(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
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
                    ? 'تم تسجيل عملية الدفع الخاصة بك بنجاح.\n\n'
                        '📧 ستصلك رسالة تأكيد عبر البريد الإلكتروني قريباً.\n\n'
                        '📋 رقم المرجع: ${widget.paymentId ?? "N/A"}'
                    : 'Votre paiement a été enregistré avec succès.\n\n'
                        '📧 Vous recevrez un email de confirmation prochainement.\n\n'
                        '📋 Référence: ${widget.paymentId ?? "N/A"}',
                style: GoogleFonts.cairo(
                  fontSize: 15.0,
                  color: Colors.grey.shade700,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ],
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
                  backgroundColor: const Color(0xff0D443E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: Text(
                  _isArabic ? 'العودة' : 'Retour',
                  style: GoogleFonts.cairo(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // BUILD PRINCIPAL
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;

    final double fontSizeTitle = isMobile ? 18.0 : (isTablet ? 22.0 : 26.0);
    final double fontSizeBody = isMobile ? 14.0 : (isTablet ? 16.0 : 18.0);
    final double buttonHeight = isMobile ? 50.0 : 60.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isArabic ? 'طرق الدفع' : 'Modalités de Paiement',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: fontSizeTitle,
          ),
        ),
        backgroundColor: const Color(0xff0D443E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(isMobile, isTablet, buttonHeight, fontSizeBody),
    );
  }

  Widget _buildBody(
    bool isMobile,
    bool isTablet,
    double buttonHeight,
    double fontSizeBody,
  ) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xff0D443E)),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 800.0 : double.infinity,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isMobile, isTablet),
            const SizedBox(height: 24),
            _buildPaymentGrid(isMobile, isTablet),
            const SizedBox(height: 30),
            if (_errorMessage != null) ...[
              _buildErrorMessage(fontSizeBody),
              const SizedBox(height: 16),
            ],
            _buildValidateButton(isMobile, buttonHeight, fontSizeBody),
            const SizedBox(height: 20),
            _buildFooter(isMobile, fontSizeBody),
          ],
        ),
      ),
    );
  }
}