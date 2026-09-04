// lib/pages/paiement/modalite_paiment.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:nafahat/pages/widgets/mobile_bottom_nav_bar.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:nafahat/services/payment_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:html' as html;

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

  Uint8List? _selectedFileBytes;
  File? _selectedFile;
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
    print('🔵 [ModalitePaiment] Page initialisée avec paymentId: ${widget.paymentId}');
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString('language');
      setState(() {
        _isArabic = savedLang == 'ar' || savedLang == null;
      });
    } catch (e) {
      print('❌ [ModalitePaiment] Erreur chargement langue: $e');
    }
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
      print('🔵 [FilePicker-Web] Sélection de fichier pour: $method');

      final input = html.FileUploadInputElement()
        ..accept = '.pdf,.jpg,.jpeg,.png,.doc,.docx';
      input.click();

      await input.onChange.first;

      if (input.files == null || input.files!.isEmpty) {
        print('ℹ️ [FilePicker-Web] Sélection annulée');
        return;
      }

      final file = input.files!.first;
      final ext = file.name.split('.').last.toLowerCase();
      const allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'];
      
      if (!allowedExtensions.contains(ext)) {
        throw Exception(
          _isArabic ? '⚠️ صيغة الملف غير مقبولة' : '⚠️ Format de fichier non accepté',
        );
      }

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;

      final bytes = reader.result as Uint8List;

      if (bytes.length > 5 * 1024 * 1024) {
        throw Exception(
          _isArabic ? '⚠️ الملف كبير جداً (الحد الأقصى 5 ميجابايت)' : '⚠️ Fichier trop volumineux (max 5MB)',
        );
      }

      setState(() {
        _selectedMethod = method;
        _selectedFileName = file.name;
        _selectedFileBytes = bytes;
        _selectedFile = null;
        _errorMessage = null;
      });

      print('✅ [FilePicker-Web] ${file.name} (${bytes.length} bytes)');
      _showFileSelectedSnackBar();
    } catch (e) {
      print('❌ [FilePicker-Web] Erreur: $e');
      _handleFilePickError(e);
    }
  }

  Future<void> _pickFileMobile(String method) async {
    _handleFilePickError(
      Exception(
        _isArabic ? '⚠️ هذه الميزة غير متوفرة على هذه المنصة' : '⚠️ Cette fonctionnalité n\'est pas disponible sur cette plateforme',
      ),
    );
  }

  void _showFileSelectedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isArabic ? '✅ تم اختيار الملف بنجاح' : '✅ Fichier sélectionné avec succès',
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

  bool _hasFile() {
    if (kIsWeb) {
      return _selectedFileBytes != null && _selectedFileName != null;
    } else {
      return _selectedFile != null && _selectedFileName != null;
    }
  }

  // ============================================================
  // SOUMISSION DU PAIEMENT
  // ============================================================

  Future<void> _submitPayment() async {
    if (_selectedPaymentMethod == null) {
      setState(() {
        _errorMessage = _isArabic ? '⚠️ الرجاء اختيار طريقة الدفع' : '⚠️ Veuillez sélectionner un mode de paiement';
      });
      return;
    }

    if (!_hasFile()) {
      setState(() {
        _errorMessage = _isArabic ? '⚠️ الرجاء إرفاق ملف' : '⚠️ Veuillez joindre un fichier';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final confirmResult = await PaymentService.confirmPayment(
        paymentId: widget.paymentId ?? '',
        modalite: _selectedPaymentMethod!,
      );

      if (!confirmResult['success']) {
        throw Exception(confirmResult['message'] ?? 'Erreur de confirmation');
      }

      dynamic fileData;
      if (kIsWeb) {
        fileData = _selectedFileBytes;
      } else {
        fileData = _selectedFile;
      }

      final uploadResult = await PaymentService.uploadQuittance(
        paymentId: widget.paymentId ?? '',
        fileData: fileData,
        fileName: _selectedFileName!,
      );

      if (!uploadResult['success']) {
        throw Exception(uploadResult['message'] ?? 'Erreur lors de l\'upload');
      }

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
  // WIDGETS MODERNISÉS
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
    final isSelected = _selectedPaymentMethod == method && !isDisabled;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
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
          onTap: isDisabled ? _showDisabledDialog : () {
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
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDisabled ? Colors.grey.shade200 : color.withOpacity(0.12),
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
                              color: isDisabled ? Colors.grey.shade500 : Colors.black87,
                            ),
                          ),
                          if (description.isNotEmpty)
                            Text(
                              description,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: isDisabled ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (isDisabled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

                // Bank info (pour bancaire et postal)
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
                          Icon(Icons.info_outline, color: Colors.amber.shade800, size: 18),
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

                // File picker (quand sélectionné)
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
    );
  }

  Widget _buildModernFilePicker() {
    final hasFile = _hasFile();
    final fileName = _selectedFileName ?? (_isArabic ? 'لم يتم اختيار ملف' : 'Aucun fichier sélectionné');
    final isMobile = MediaQuery.of(context).size.width < 600;

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
                        color: hasFile ? Colors.green.shade700 : Colors.grey.shade500,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          fileName,
                          style: GoogleFonts.cairo(
                            color: hasFile ? Colors.black87 : Colors.grey.shade600,
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
                icon: Icon(Icons.upload_file, color: const Color(0xff0D443E), size: 18),
                label: Text(
                  _isArabic ? 'اختيار' : 'Parcourir',
                  style: GoogleFonts.cairo(
                    color: const Color(0xff0D443E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          style: GoogleFonts.cairo(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildModernHeader() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet = MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1200;

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xff0D443E),
            const Color(0xff1a6b60),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff0D443E).withOpacity(0.3),
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
                  _isArabic ? 'اختر طريقة الدفع' : 'Choisissez votre mode de paiement',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 18 : (isTablet ? 22 : 26),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isArabic
                      ? 'قم باختيار طريقة الدفع وإرفاق الوثائق المطلوبة'
                      : 'Sélectionnez un mode de paiement et joignez les justificatifs nécessaires',
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
    final isEnabled = _selectedPaymentMethod != null && _hasFile();
    final isMobile = MediaQuery.of(context).size.width < 600;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: isMobile ? 54 : 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: const Color(0xff0D443E).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : (isEnabled ? _submitPayment : null),
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? const Color(0xff0D443E) : Colors.grey.shade400,
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
                    isEnabled ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEnabled
                        ? (_isArabic ? 'تأكيد الدفع' : 'Valider le paiement')
                        : (_isArabic ? 'اختر طريقة الدفع وأرفق ملفاً' : 'Sélectionnez un mode et joignez un fichier'),
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
          _buildFooterItem(Icons.lock_outline_rounded, _isArabic ? '🔒 دفع آمن' : '🔒 Paiement sécurisé'),
          _buildFooterItem(Icons.support_agent_outlined, _isArabic ? '📞 دعم 7/7' : '📞 Support 7j/7'),
          _buildFooterItem(Icons.shield_outlined, _isArabic ? '🛡️ معلومات مشفرة' : '🛡️ Données chiffrées'),
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
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  void _showDisabledDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade700),
              const SizedBox(width: 12),
              Text(
                _isArabic ? '⚠️ خدمة غير مفعلة' : '⚠️ Service désactivé',
                style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            _isArabic
                ? 'خدمة الدفع عبر الإنترنت غير متوفرة حالياً.\n\nالرجاء استخدام إحدى الطرق الأخرى المتاحة.'
                : 'Le paiement en ligne est temporairement indisponible.\n\nVeuillez utiliser les autres modes de paiement disponibles.',
            style: GoogleFonts.cairo(fontSize: 15, color: Colors.grey.shade700, height: 1.5),
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
                  fontSize: 15,
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
        );
      },
    );
  }

  // ============================================================
  // BUILD PRINCIPAL
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet = MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1200;

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
        backgroundColor: const Color(0xff0D443E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xff0D443E)),
            )
          : Column(
              children: [
                // Contenu principal
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.all(isMobile ? 16 : 32),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 800 : 700,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildModernHeader(),
                          const SizedBox(height: 24),

                          // Bancaire
                          _buildModernPaymentCard(
                            title: _isArabic ? '🏦 تحويل بنكي' : '🏦 Versement Bancaire',
                            icon: Icons.account_balance,
                            color: const Color(0xff1a8a6a),
                            bgColor: const Color(0xff1a8a6a),
                            method: 'bancaire',
                            description: _isArabic
                                ? 'تحويل بنكي عبر حسابنا الجاري'
                                : 'Virement bancaire sur notre compte courant',
                            bankInfo: _isArabic
                                ? '🏦 الرجاء التوجه إلى أقرب فرع لبنك BNA و إيداع المبلغ الجملي للدورات التي قمتم بإختيارها في الحساب الجاري عدد 1000123456789'
                                : '🏦 Veuillez vous rendre à l\'agence BNA la plus proche et déposer le montant total des formations choisies sur le compte courant numéro 1000123456789',
                          ),

                          // Postal
                          _buildModernPaymentCard(
                            title: _isArabic ? '📮 تحويل بريدي' : '📮 Versement Postal',
                            icon: Icons.local_post_office,
                            color: const Color(0xffe88b2a),
                            bgColor: const Color(0xffe88b2a),
                            method: 'postal',
                            description: _isArabic
                                ? 'تحويل بريدي عبر مكتب البريد'
                                : 'Virement postal via le bureau de poste',
                            bankInfo: _isArabic
                                ? '📮 الرجاء التوجه إلى أقرب مكتب بريد و إيداع المبلغ الجملي للدورات التي قمتم بإختيارها في الحساب البريدي عدد 123456789'
                                : '📮 Veuillez vous rendre au bureau de poste le plus proche et déposer le montant total des formations choisies sur le compte postal numéro 123456789',
                          ),

                          // En ligne (désactivé)
                          _buildModernPaymentCard(
                            title: _isArabic ? '💳 دفع عبر الإنترنت' : '💳 Paiement en Ligne',
                            icon: Icons.payment,
                            color: Colors.grey.shade600,
                            bgColor: Colors.grey.shade600,
                            method: 'en_ligne',
                            description: _isArabic
                                ? 'بطاقة بنكية أو عبر المحافظ الإلكترونية'
                                : 'Carte bancaire ou portefeuilles électroniques',
                            bankInfo: '',
                            isDisabled: true,
                          ),

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
                // ============================================================
                // ✅ MOBILE BOTTOM NAVIGATION
                // ============================================================
                const MobileBottomNav(),
              ],
            ),
    );
  }
}