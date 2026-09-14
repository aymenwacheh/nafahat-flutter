// lib/pages/paiement/paiement_tranche_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:typed_data';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nafahat/services/payment_service.dart';
import 'dart:html' as html;

class PaiementTranchePage extends StatefulWidget {
  final String paymentId;
  final double montantTranche;
  final int numeroTranche;
  final int nombreMois;
  final double montantRestant;
  final String formationTitre;
  final double montantMensuel;

  const PaiementTranchePage({
    super.key,
    required this.paymentId,
    required this.montantTranche,
    required this.numeroTranche,
    required this.nombreMois,
    required this.montantRestant,
    required this.formationTitre,
    required this.montantMensuel,
  });

  @override
  State<PaiementTranchePage> createState() => _PaiementTranchePageState();
}

class _PaiementTranchePageState extends State<PaiementTranchePage> {
  bool _isArabic = true;
  String? _selectedPaymentMethod;

  Uint8List? _selectedFileBytes;
  File? _selectedFile;
  String? _selectedFileName;

  bool _isSubmitting = false;
  String? _errorMessage;

  static const Color primaryColor = Color(0xff0D443E);
  static const Color primaryColorLight = Color(0xff1a6b60);

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('language');
    if (mounted) {
      setState(() => _isArabic = lang == 'ar' || lang == null);
    }
  }

  // ============================================================
  // SÉLECTION FICHIER
  // ============================================================

  Future<void> _pickFileWeb() async {
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
        setState(() {
          _errorMessage = _isArabic
              ? '⚠️ صيغة الملف غير مقبولة'
              : '⚠️ Format de fichier non accepté';
        });
        return;
      }

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;

      final bytes = reader.result as Uint8List;

      if (bytes.length > 5 * 1024 * 1024) {
        setState(() {
          _errorMessage = _isArabic
              ? '⚠️ الملف كبير جداً (الحد الأقصى 5 ميجابايت)'
              : '⚠️ Fichier trop volumineux (max 5MB)';
        });
        return;
      }

      setState(() {
        _selectedFileBytes = bytes;
        _selectedFileName = file.name;
        _selectedFile = null;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    }
  }

  bool _hasFile() {
    if (kIsWeb) {
      return _selectedFileBytes != null && _selectedFileName != null;
    }
    return _selectedFile != null && _selectedFileName != null;
  }

  // ============================================================
  // SOUMISSION
  // ============================================================

  Future<void> _submit() async {
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

    try {
      // 1. Upload de la quittance
      dynamic fileData = kIsWeb ? _selectedFileBytes : _selectedFile;

      print('🔵 [PaiementTranche] Upload quittance...');
      final uploadResult = await PaymentService.uploadTrancheQuittance(
        paymentId: widget.paymentId,
        fileData: fileData,
        fileName: _selectedFileName!,
      );

      if (uploadResult['success'] != true) {
        throw Exception(uploadResult['message'] ?? 'Erreur upload quittance');
      }

      final quittanceUrl = uploadResult['url'];
      print('✅ [PaiementTranche] Quittance uploadée: $quittanceUrl');

      // 2. Soumettre la tranche
      print('🔵 [PaiementTranche] Soumission tranche...');
      final result = await PaymentService.soumettreTranche(
        paymentId: widget.paymentId,
        montantTranche: widget.montantTranche,
        quittanceUrl: quittanceUrl,
      );

      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Erreur soumission');
      }

      print('✅ [PaiementTranche] Tranche soumise avec succès');

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      print('❌ [PaiementTranche] Erreur: $e');
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString();
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      appBar: AppBar(
        title: Text(
          _isArabic
              ? 'دفع القسط ${widget.numeroTranche}/${widget.nombreMois}'
              : 'Paiement tranche ${widget.numeroTranche}/${widget.nombreMois}',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 16 : 20,
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildRecapCard(),
                const SizedBox(height: 24),
                _buildPaymentMethods(),
                const SizedBox(height: 24),
                if (_errorMessage != null) ...[
                  _buildError(),
                  const SizedBox(height: 16),
                ],
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
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
            child: const Icon(
              Icons.payment_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isArabic ? 'دفع القسط' : 'Payer la tranche',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.formationTitre,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.85),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RÉCAPITULATIF
  // ============================================================

  Widget _buildRecapCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildRow(
            _isArabic ? 'رقم القسط' : 'Numéro tranche',
            '${widget.numeroTranche}/${widget.nombreMois}',
          ),
          const Divider(height: 20),
          _buildRow(
            _isArabic ? 'المبلغ المطلوب' : 'Montant à payer',
            '${widget.montantTranche.toStringAsFixed(0)} DT',
            isBold: true,
            valueColor: primaryColor,
          ),
          const SizedBox(height: 8),
          _buildRow(
            _isArabic ? 'بعد الدفع يبقى' : 'Reste après paiement',
            '${(widget.montantRestant - widget.montantTranche).clamp(0, double.infinity).toStringAsFixed(0)} DT',
            valueColor: Colors.orange.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: isBold ? 18 : 15,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MÉTHODES DE PAIEMENT
  // ============================================================

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor,
              ),
              child: Center(
                child: Text(
                  '1',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _isArabic ? '💳 اختر طريقة الدفع' : '💳 Mode de paiement',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildMethodCard(
          method: 'bancaire',
          title: _isArabic ? '🏦 تحويل بنكي' : '🏦 Virement bancaire',
          bankInfo: _isArabic
              ? 'حساب BNA: 1000123456789'
              : 'Compte BNA : 1000123456789',
        ),
        const SizedBox(height: 8),
        _buildMethodCard(
          method: 'postal',
          title: _isArabic ? '📮 تحويل بريدي' : '📮 Virement postal',
          bankInfo: _isArabic
              ? 'حساب بريدي: 123456789'
              : 'Compte postal : 123456789',
        ),
        if (_selectedPaymentMethod != null) ...[
          const SizedBox(height: 20),
          _buildFilePickerSection(),
        ],
      ],
    );
  }

  Widget _buildMethodCard({
    required String method,
    required String title,
    required String bankInfo,
  }) {
    final isSelected = _selectedPaymentMethod == method;

    return GestureDetector(
      onTap: () => setState(() {
        _selectedPaymentMethod = method;
        _errorMessage = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 4),
                    Text(
                      bankInfo,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SÉLECTION FICHIER
  // ============================================================

  Widget _buildFilePickerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor,
              ),
              child: Center(
                child: Text(
                  '2',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _isArabic ? '📎 أرفق وثيقة الدفع' : '📎 Joindre le justificatif',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildFilePicker(),
      ],
    );
  }

  Widget _buildFilePicker() {
    final hasFile = _hasFile();
    final fileName = _selectedFileName ??
        (_isArabic ? 'لم يتم اختيار ملف' : 'Aucun fichier sélectionné');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasFile ? Colors.green.shade300 : Colors.grey.shade300,
          width: hasFile ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasFile ? Icons.check_circle : Icons.attach_file,
                color: hasFile ? Colors.green.shade700 : Colors.grey.shade500,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  fileName,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: hasFile ? Colors.green.shade700 : Colors.grey.shade600,
                    fontWeight: hasFile ? FontWeight.w600 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!kIsWeb)
                TextButton.icon(
                  onPressed: null, // Mobile : à implémenter si besoin
                  icon: const Icon(Icons.upload_file, size: 16),
                  label: Text(
                    _isArabic ? 'قريباً' : 'Bientôt',
                    style: GoogleFonts.cairo(fontSize: 12),
                  ),
                )
              else
                TextButton.icon(
                  onPressed: _pickFileWeb,
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: Text(
                    _isArabic ? 'اختيار' : 'Choisir',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                  ),
                ),
            ],
          ),
          if (!hasFile) ...[
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
        ],
      ),
    );
  }

  // ============================================================
  // ERREUR
  // ============================================================

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.cairo(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOUTON SOUMETTRE
  // ============================================================

  Widget _buildSubmitButton() {
    final canSubmit = _selectedPaymentMethod != null && _hasFile();

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting || !canSubmit ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: canSubmit ? primaryColor : Colors.grey.shade400,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: canSubmit ? 4 : 0,
          shadowColor: primaryColor.withOpacity(0.3),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    canSubmit
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_rounded,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isArabic
                        ? 'تأكيد دفع القسط (${widget.montantTranche.toStringAsFixed(0)} DT)'
                        : 'Confirmer (${widget.montantTranche.toStringAsFixed(0)} DT)',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ============================================================
  // DIALOG DE SUCCÈS
  // ============================================================

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
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
                size: 60,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isArabic ? '✅ تم إرسال القسط' : '✅ Tranche envoyée',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isArabic
                  ? 'سيتم التحقق من الدفع من قبل الإدارة.\nستصلك رسالة تأكيد قريباً.'
                  : 'Votre paiement sera vérifié par l\'administration.\nVous recevrez une confirmation bientôt.',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _isArabic
                    ? 'القسط ${widget.numeroTranche}/${widget.nombreMois}'
                    : 'Tranche ${widget.numeroTranche}/${widget.nombreMois}',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Fermer dialog
                Navigator.pop(context, true); // Retourner true
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isArabic ? 'حسناً' : 'OK',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}