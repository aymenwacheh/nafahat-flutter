// lib/pages/adminisration/etat_paiement.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:nafahat/pages/adminisration/admin_page_wrapper.dart';
import '../../services/paiement_validation_service.dart';
import '../../models/paiement_validation.dart';
import '../../services/training_service.dart';
import '../../models/training_model.dart';

class EtatPaiementPage extends StatefulWidget {
  const EtatPaiementPage({super.key});

  @override
  State<EtatPaiementPage> createState() => _EtatPaiementPageState();
}

class _EtatPaiementPageState extends State<EtatPaiementPage> {
  final PaiementValidationService _service = PaiementValidationService();
  
  List<PaiementValidation> _validations = [];
  List<TrainingModel> _formations = [];
  bool _isLoading = true;
  bool _isProcessing = false;

  // Filtres
  String _searchQuery = '';
  String _selectedStatus = 'tous';
  String _selectedFormation = 'toutes';
  String _selectedModalite = 'toutes';

  // Pagination
  int _currentPage = 0;
  final int _itemsPerPage = 15;
  int _totalItems = 0;
  int _totalPages = 1;

  // Statistiques
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _modaliteStats = [];
  Map<String, int> _formationStats = {};

  // Responsive
  bool _isMobile = false;
  bool _isTablet = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([_loadFormations(), _loadValidations(), _loadStats()]);
    } catch (e) {
      _showError('Erreur de chargement: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFormations() async {
    try {
      final formations = await TrainingService.getTrainings();
      setState(() {
        _formations = formations;
      });
    } catch (e) {
      print('❌ Erreur chargement formations: $e');
    }
  }

  Future<void> _loadValidations() async {
    try {
      // ✅ Récupérer toutes les validations
      final result = await _service.getPaginated(
        page: _currentPage + 1,
        perPage: _itemsPerPage,
        status: _selectedStatus != 'tous' ? _selectedStatus : null,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      List<PaiementValidation> allValidations = result['data'] ?? [];
      
      // ✅ Filtrer par formation côté client si nécessaire
      if (_selectedFormation != 'toutes') {
        allValidations = allValidations.where((v) {
          // Vérifier si l'ID de la formation correspond
          // La formation est stockée dans formationTitreFr ou formationId
          // On va essayer de faire correspondre par le titre
          final formation = _formations.firstWhere(
            (f) => f.id.toString() == _selectedFormation,
            orElse: () => _formations.first,
          );
          // Filtrer par le titre de la formation
          return v.formationTitreFr == formation.titleFr ||
                 v.formationTitreAr == formation.titleAr;
        }).toList();
      }

      setState(() {
        _validations = allValidations;
        _totalItems = allValidations.length;
        _totalPages = (_totalItems / _itemsPerPage).ceil();
      });
    } catch (e) {
      _showError('Erreur chargement validations: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _service.getStats();
      setState(() {
        _stats = stats['data']['global'] ?? {};
        _modaliteStats = List<Map<String, dynamic>>.from(
          stats['data']['par_modalite'] ?? [],
        );
        _formationStats = Map<String, int>.from(
          stats['data']['par_formation'] ?? {},
        );
      });
    } catch (e) {
      print('Erreur stats: $e');
    }
  }

  Future<void> _updateStatus(
    int paiementId,
    String statut, {
    String? commentaire,
  }) async {
    setState(() => _isProcessing = true);
    try {
      await _service.updateStatus(paiementId, statut, commentaire: commentaire);
      _showSuccess('✅ Statut mis à jour: ${_getStatusLabel(statut)}');
      await _loadValidations();
      await _loadStats();
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'valide': return 'Validé';
      case 'refuse': return 'Refusé';
      case 'annule': return 'Annulé';
      case 'en_attente': return 'En attente';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'valide': return Colors.green;
      case 'refuse': return Colors.red;
      case 'annule': return Colors.grey;
      default: return Colors.orange;
    }
  }

  String _getFormationLabel(String formationId) {
    if (formationId == 'toutes') return 'Toutes formations';
    try {
      final formation = _formations.firstWhere(
        (f) => f.id.toString() == formationId,
      );
      return formation.titleFr.isNotEmpty 
          ? formation.titleFr 
          : (formation.titleAr.isNotEmpty ? formation.titleAr : 'Formation #${formation.id}');
    } catch (e) {
      return 'Formation inconnue';
    }
  }

  // ============================================================
  // DIALOGUES
  // ============================================================

  void _showValidationDialog(PaiementValidation validation) {
    final commentaireController = TextEditingController();
    String? selectedStatus = validation.statutPaiement;

    showDialog(
      context: context,
      barrierDismissible: !_isProcessing,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.gavel, color: const Color(0xFF0D443E)),
                const SizedBox(width: 10),
                const Text('Modification du statut'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(validation.statutPaiement ?? 'en_attente').withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getStatusColor(validation.statutPaiement ?? 'en_attente'),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Statut actuel : ${_getStatusLabel(validation.statutPaiement ?? 'en_attente')}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('👤 Adhérent', validation.adherentNomPrenom ?? 'N/A'),
                  _buildInfoRow('📱 WhatsApp', validation.adherentWhatsapp ?? 'N/A'),
                  _buildInfoRow('📚 Formation', validation.formationTitreFr ?? 'N/A'),
                  _buildInfoRow('💰 Montant', '${validation.montantPaye?.toStringAsFixed(2) ?? '0'} ${validation.formationDevise ?? 'DT'}'),
                  _buildInfoRow('💳 Modalité', validation.modalitePaiement ?? 'N/A'),
                  _buildInfoRow('📝 Référence', validation.referencePaiement ?? 'N/A'),
                  if (validation.numeroQuittance != null)
                    _buildInfoRow('📄 Quittance', validation.numeroQuittance!),
                  if (validation.urlQuittance != null)
                    _buildInfoRow('🔗 Lien', validation.urlQuittance!),
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text('Choisir une action :', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatusButton(
                        label: 'En attente',
                        status: 'en_attente',
                        icon: Icons.hourglass_empty,
                        color: Colors.orange,
                        isSelected: selectedStatus == 'en_attente',
                        onPressed: () => setStateDialog(() => selectedStatus = 'en_attente'),
                      ),
                      _buildStatusButton(
                        label: 'Validé',
                        status: 'valide',
                        icon: Icons.check_circle,
                        color: Colors.green,
                        isSelected: selectedStatus == 'valide',
                        onPressed: () => setStateDialog(() => selectedStatus = 'valide'),
                      ),
                      _buildStatusButton(
                        label: 'Refusé',
                        status: 'refuse',
                        icon: Icons.cancel,
                        color: Colors.red,
                        isSelected: selectedStatus == 'refuse',
                        onPressed: () => setStateDialog(() => selectedStatus = 'refuse'),
                      ),
                      _buildStatusButton(
                        label: 'Annulé',
                        status: 'annule',
                        icon: Icons.block,
                        color: Colors.grey,
                        isSelected: selectedStatus == 'annule',
                        onPressed: () => setStateDialog(() => selectedStatus = 'annule'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentaireController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Commentaire (optionnel)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.comment_outlined),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isProcessing ? null : () => Navigator.pop(context),
                child: const Text('ANNULER'),
              ),
              if (selectedStatus != validation.statutPaiement)
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : () {
                    Navigator.pop(context);
                    _updateStatus(
                      validation.paiementId,
                      selectedStatus!,
                      commentaire: commentaireController.text.isNotEmpty ? commentaireController.text : null,
                    );
                  },
                  icon: Icon(selectedStatus == 'en_attente' ? Icons.refresh : Icons.save, size: 18),
                  label: Text(selectedStatus == 'en_attente' ? 'RÉINITIALISER' : 'APPLIQUER'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedStatus == 'en_attente' ? Colors.orange : const Color(0xFF0D443E),
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusButton({
    required String label,
    required String status,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.grey.shade200,
        foregroundColor: isSelected ? Colors.white : Colors.grey.shade700,
        elevation: isSelected ? 4 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isSelected ? color : Colors.transparent, width: 2),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ $message'), backgroundColor: Colors.red, duration: const Duration(seconds: 3)),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green, duration: const Duration(seconds: 2)),
    );
  }

  // ============================================================
  // QUITTANCE
  // ============================================================

  void _viewQuittance(String url) {
    String cleanUrl = url.replaceAll('\\', '/');
    if (cleanUrl.startsWith('uploads/')) {
      cleanUrl = 'http://localhost:3000/$cleanUrl';
    }
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'http://localhost:3000/$cleanUrl';
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('📄 Aperçu de la quittance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Expanded(child: Center(child: _buildQuittancePreview(cleanUrl))),
              const SizedBox(height: 16),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _downloadQuittance(cleanUrl),
                      icon: const Icon(Icons.download),
                      label: const Text('Télécharger'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openQuittanceInBrowser(cleanUrl),
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Ouvrir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D443E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuittancePreview(String url) {
    final extension = url.split('.').last.toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);
    final isPdf = extension == 'pdf';

    if (isImage) {
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                    color: const Color(0xFF0D443E),
                  ),
                  const SizedBox(height: 16),
                  Text('Chargement de la quittance...', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('Impossible de charger l\'image', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 8),
                Text('Vérifiez que le serveur est accessible', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
              ],
            );
          },
        ),
      );
    } else if (isPdf) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.picture_as_pdf, size: 80, color: Colors.red.shade700),
          const SizedBox(height: 16),
          const Text('Document PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(url.split('/').last, style: TextStyle(fontSize: 12, color: Colors.grey[600]), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _openQuittanceInBrowser(url),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Ouvrir le PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_drive_file, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Type de fichier non pris en charge', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(url.split('/').last, style: TextStyle(fontSize: 12, color: Colors.grey[600]), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _downloadQuittance(url),
            icon: const Icon(Icons.download),
            label: const Text('Télécharger'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D443E),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      );
    }
  }

  void _downloadQuittance(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Impossible de télécharger le fichier'), backgroundColor: Colors.red),
      );
    }
  }

  void _openQuittanceInBrowser(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Impossible d\'ouvrir le lien');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Impossible d\'ouvrir le fichier'), backgroundColor: Colors.red),
      );
    }
  }

  // ============================================================
  // DÉTAILS
  // ============================================================

  void _showDetailsDialog(PaiementValidation v) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📋 Détails du paiement'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('ID Paiement', '${v.paiementId}'),
              _buildInfoRow('ID Validation', '${v.id ?? '-'}'),
              const Divider(),
              _buildInfoRow('👤 Adhérent', v.adherentNomPrenom ?? 'N/A'),
              _buildInfoRow('📱 WhatsApp', v.adherentWhatsapp ?? 'N/A'),
              const Divider(),
              _buildInfoRow('📚 Formation', v.formationTitreFr ?? 'N/A'),
              _buildInfoRow('💰 Montant', '${v.montantPaye?.toStringAsFixed(2) ?? '0'} ${v.formationDevise ?? 'DT'}'),
              _buildInfoRow('💳 Modalité', v.modalitePaiement ?? 'N/A'),
              const Divider(),
              _buildInfoRow('📝 Référence', v.referencePaiement ?? 'N/A'),
              _buildInfoRow('📄 Numéro quittance', v.numeroQuittance ?? '-'),
              _buildInfoRow('📊 Statut', v.statutPaiement ?? 'en_attente'),
              _buildInfoRow('🔐 Validateur', v.validateurNom ?? '-'),
              _buildInfoRow('📅 Date validation', v.dateValidation != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(v.dateValidation!)
                  : '-'),
              _buildInfoRow('📅 Date création', DateFormat('dd/MM/yyyy HH:mm').format(v.createdAt)),
              if (v.commentaire != null) ...[
                const Divider(),
                _buildInfoRow('💬 Commentaire', v.commentaire!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD PRINCIPAL
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    _isMobile = screenWidth < 600;
    _isTablet = screenWidth >= 600 && screenWidth < 1200;

    return AdminPageWrapper(
      title: 'Gestion des paiements',
      titleAr: 'إدارة المدفوعات',
      backgroundColor: const Color(0xFFF8FAFC),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadData,
          tooltip: 'Rafraîchir',
        ),
      ],
      child: Column(
        children: [
          _buildFilters(),
          _buildStats(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _validations.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Aucune validation trouvée', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  )
                : _buildDataTable(),
          ),
          _buildPagination(),
        ],
      ),
    );
  }

  // ============================================================
  // FILTRES RESPONSIVE MODERNES
  // ============================================================

  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _isMobile ? 12 : 20, vertical: _isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Ligne de recherche
          Row(
            children: [
              Expanded(
                flex: _isMobile ? 1 : 3,
                child: _buildSearchField(),
              ),
              if (!_isMobile) ...[
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: _buildFormationDropdown(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: _buildStatusDropdown(),
                ),
              ],
            ],
          ),
          if (_isMobile) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildFormationDropdown()),
                const SizedBox(width: 8),
                Expanded(child: _buildStatusDropdown()),
              ],
            ),
          ],
          // Indicateur de filtres actifs
          if (_searchQuery.isNotEmpty || _selectedStatus != 'tous' || _selectedFormation != 'toutes')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (_selectedFormation != 'toutes')
                    _buildFilterChip(
                      label: _getFormationLabel(_selectedFormation),
                      onDeleted: () {
                        setState(() {
                          _selectedFormation = 'toutes';
                          _currentPage = 0;
                          _loadValidations();
                        });
                      },
                    ),
                  if (_selectedStatus != 'tous')
                    _buildFilterChip(
                      label: _getStatusLabel(_selectedStatus),
                      onDeleted: () {
                        setState(() {
                          _selectedStatus = 'tous';
                          _currentPage = 0;
                          _loadValidations();
                        });
                      },
                    ),
                  if (_searchQuery.isNotEmpty)
                    _buildFilterChip(
                      label: '🔍 $_searchQuery',
                      onDeleted: () {
                        setState(() {
                          _searchQuery = '';
                          _currentPage = 0;
                          _loadValidations();
                        });
                      },
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required VoidCallback onDeleted}) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onDeleted,
      backgroundColor: const Color(0xFF0D443E).withOpacity(0.1),
      labelStyle: TextStyle(color: const Color(0xFF0D443E)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFF0D443E).withOpacity(0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: '🔍 Rechercher...',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          isDense: true,
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _currentPage = 0;
                      _loadValidations();
                    });
                  },
                )
              : null,
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
          _loadValidations();
        },
      ),
    );
  }

  Widget _buildFormationDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
        value: _selectedFormation,
        items: [
          const DropdownMenuItem(value: 'toutes', child: Row(
            children: [
              Icon(Icons.school_outlined, size: 18, color: Colors.grey),
              SizedBox(width: 8),
              Text('📚 Toutes formations'),
            ],
          )),
          ..._formations.map((f) => DropdownMenuItem(
            value: f.id,
            child: Text(f.titleFr.isNotEmpty ? f.titleFr : (f.titleAr.isNotEmpty ? f.titleAr : 'Formation #${f.id}')),
          )),
        ],
        onChanged: (value) {
          setState(() {
            _selectedFormation = value!;
            _currentPage = 0;
            _loadValidations();
          });
        },
        dropdownColor: Colors.white,
        icon: Icon(Icons.arrow_drop_down, color: const Color(0xFF0D443E)),
        style: const TextStyle(color: Colors.black87),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
        value: _selectedStatus,
        items: const [
          DropdownMenuItem(value: 'tous', child: Row(
            children: [
              Icon(Icons.list_alt, size: 18, color: Colors.grey),
              SizedBox(width: 8),
              Text('📊 Tous statuts'),
            ],
          )),
          DropdownMenuItem(value: 'en_attente', child: Text('⏳ En attente')),
          DropdownMenuItem(value: 'valide', child: Text('✅ Validé')),
          DropdownMenuItem(value: 'refuse', child: Text('❌ Refusé')),
          DropdownMenuItem(value: 'annule', child: Text('🚫 Annulé')),
        ],
        onChanged: (value) {
          setState(() {
            _selectedStatus = value!;
            _currentPage = 0;
            _loadValidations();
          });
        },
        dropdownColor: Colors.white,
        icon: Icon(Icons.arrow_drop_down, color: const Color(0xFF0D443E)),
        style: const TextStyle(color: Colors.black87),
      ),
    );
  }

  // ============================================================
  // STATISTIQUES MODERNES
  // ============================================================

  Widget _buildStats() {
    final total = _stats['total_validations'] ?? 0;
    final enAttente = _stats['en_attente'] ?? 0;
    final valides = _stats['valides'] ?? 0;
    final refuses = _stats['refuses'] ?? 0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: _isMobile ? 8 : 20, vertical: _isMobile ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildModernStatItem('📋', '$total', 'Total', Colors.grey[700]!),
            _buildModernStatItem('⏳', '$enAttente', 'En attente', Colors.orange),
            _buildModernStatItem('✅', '$valides', 'Validés', Colors.green),
            _buildModernStatItem('❌', '$refuses', 'Refusés', Colors.red),
            if (_selectedFormation == 'toutes' && _formationStats.isNotEmpty)
              ..._formationStats.entries.take(_isMobile ? 3 : 5).map((e) =>
                _buildModernStatItem('📚', '${e.value}', e.key, Colors.blue)
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernStatItem(String icon, String value, String label, Color color) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: _isMobile ? 6 : 12),
      padding: EdgeInsets.symmetric(horizontal: _isMobile ? 10 : 16, vertical: _isMobile ? 4 : 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: TextStyle(fontSize: _isMobile ? 14 : 18)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: _isMobile ? 16 : 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: _isMobile ? 9 : 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABLEAU MODERNE RESPONSIVE
  // ============================================================

  Widget _buildDataTable() {
    if (_isMobile) {
      return _buildModernMobileCards();
    } else if (_isTablet) {
      return _buildModernTabletCards();
    } else {
      return _buildModernDesktopTable();
    }
  }

  // ✅ VERSION MOBILE - Cartes modernes
  Widget _buildModernMobileCards() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _validations.length,
      itemBuilder: (context, index) {
        final v = _validations[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showDetailsDialog(v),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D443E).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${_currentPage * _itemsPerPage + index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D443E),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                v.adherentNomPrenom ?? 'N/A',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        _buildStatusChip(v.statutPaiement ?? 'en_attente'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactInfo('📚', v.formationTitreFr ?? 'N/A'),
                        ),
                        const SizedBox(width: 8),
                        _buildModaliteChip(v.modalitePaiement ?? 'en_ligne'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCompactInfo(
                          '💰',
                          '${v.montantPaye?.toStringAsFixed(2) ?? '0'} ${v.formationDevise ?? 'DT'}',
                        ),
                        Text(
                          _formatDate(v.createdAt),
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.gavel,
                          color: Colors.orange.shade700,
                          onPressed: () => _showValidationDialog(v),
                          label: 'Statut',
                        ),
                        if (v.urlQuittance != null)
                          _buildActionButton(
                            icon: Icons.picture_as_pdf,
                            color: Colors.blue.shade700,
                            onPressed: () => _viewQuittance(v.urlQuittance!),
                            label: 'Quittance',
                          ),
                        _buildActionButton(
                          icon: Icons.more_vert,
                          color: Colors.grey.shade600,
                          onPressed: () => _showDetailsDialog(v),
                          label: 'Détails',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactInfo(String icon, String value) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String label,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  // ✅ VERSION TABLETTE - Grille moderne
  Widget _buildModernTabletCards() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: _isTablet ? 350 : 280,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: _validations.length,
      itemBuilder: (context, index) {
        final v = _validations[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showDetailsDialog(v),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '#${_currentPage * _itemsPerPage + index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D443E),
                          ),
                        ),
                        _buildStatusChip(v.statutPaiement ?? 'en_attente'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      v.adherentNomPrenom ?? 'N/A',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      v.adherentWhatsapp ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      v.formationTitreFr ?? 'N/A',
                      style: const TextStyle(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${v.montantPaye?.toStringAsFixed(2) ?? '0'} ${v.formationDevise ?? 'DT'}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        _buildModaliteChip(v.modalitePaiement ?? 'en_ligne'),
                      ],
                    ),
                    const Divider(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(Icons.gavel, color: Colors.orange.shade700, size: 22),
                          onPressed: () => _showValidationDialog(v),
                          tooltip: 'Modifier le statut',
                        ),
                        if (v.urlQuittance != null)
                          IconButton(
                            icon: const Icon(Icons.picture_as_pdf, color: Colors.blue, size: 22),
                            onPressed: () => _viewQuittance(v.urlQuittance!),
                            tooltip: 'Voir quittance',
                          ),
                        IconButton(
                          icon: const Icon(Icons.info_outline, color: Colors.grey, size: 22),
                          onPressed: () => _showDetailsDialog(v),
                          tooltip: 'Détails',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ VERSION DESKTOP - Tableau moderne
  Widget _buildModernDesktopTable() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 16,
            headingRowColor: WidgetStatePropertyAll(
              const Color(0xFF0D443E).withOpacity(0.05),
            ),
            headingTextStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF0D443E),
            ),
            dataRowMinHeight: 56,
            dataRowMaxHeight: 72,
            columns: const [
              DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Adhérent', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Formation', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Montant', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Modalité', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Référence', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Validateur', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: _validations.asMap().entries.map((entry) {
              final index = entry.key;
              final v = entry.value;
              return DataRow(
                cells: [
                  DataCell(Text('${_currentPage * _itemsPerPage + index + 1}')),
                  DataCell(
                    Text(
                      v.adherentNomPrenom ?? 'N/A',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  DataCell(Text(v.adherentWhatsapp ?? '')),
                  DataCell(
                    Text(
                      v.formationTitreFr ?? 'N/A',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${v.montantPaye?.toStringAsFixed(2) ?? '0'} ${v.formationDevise ?? 'DT'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataCell(_buildModaliteChip(v.modalitePaiement ?? 'en_ligne')),
                  DataCell(_buildStatusChip(v.statutPaiement ?? 'en_attente')),
                  DataCell(
                    Text(
                      v.referencePaiement ?? '',
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                    ),
                  ),
                  DataCell(Text(v.validateurNom ?? '-', style: const TextStyle(fontSize: 12))),
                  DataCell(Text(_formatDate(v.createdAt), style: const TextStyle(fontSize: 12))),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.gavel, color: Colors.orange.shade700, size: 20),
                          onPressed: () => _showValidationDialog(v),
                          tooltip: 'Modifier le statut',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        if (v.urlQuittance != null)
                          IconButton(
                            icon: const Icon(Icons.picture_as_pdf, color: Colors.blue, size: 20),
                            onPressed: () => _viewQuittance(v.urlQuittance!),
                            tooltip: 'Voir quittance',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        IconButton(
                          icon: const Icon(Icons.info_outline, color: Colors.grey, size: 20),
                          onPressed: () => _showDetailsDialog(v),
                          tooltip: 'Détails',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // COMPOSANTS COMMUNS MODERNES
  // ============================================================

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case 'valide':
        color = Colors.green;
        icon = Icons.check_circle;
        label = 'Validé';
        break;
      case 'refuse':
        color = Colors.red;
        icon = Icons.cancel;
        label = 'Refusé';
        break;
      case 'annule':
        color = Colors.grey;
        icon = Icons.block;
        label = 'Annulé';
        break;
      default:
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        label = 'En attente';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildModaliteChip(String modalite) {
    final Map<String, dynamic> config = {
      'bancaire': {'icon': '🏦', 'color': Colors.purple},
      'postal': {'icon': '📮', 'color': Colors.orange},
      'en_ligne': {'icon': '🌐', 'color': Colors.blue},
      'especes': {'icon': '💵', 'color': Colors.green},
    };

    final c = config[modalite] ?? {'icon': '💳', 'color': Colors.grey};

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (c['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (c['color'] as Color).withOpacity(0.2)),
      ),
      child: Text(
        '${c['icon']} $modalite',
        style: TextStyle(
          color: c['color'] as Color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ============================================================
  // PAGINATION MODERNE
  // ============================================================

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: _isMobile ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
        children: [
          if (!_isMobile)
            Text(
              '${_totalItems} validation(s)',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          Row(
            children: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Icon(Icons.chevron_left, size: 20, color: _currentPage > 0 ? const Color(0xFF0D443E) : Colors.grey[400]),
                ),
                onPressed: _currentPage > 0 && !_isLoading
                    ? () {
                        setState(() => _currentPage--);
                        _loadValidations();
                      }
                    : null,
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D443E).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentPage + 1} / ${_totalPages > 0 ? _totalPages : 1}',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0D443E), fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Icon(Icons.chevron_right, size: 20, color: _currentPage < _totalPages - 1 ? const Color(0xFF0D443E) : Colors.grey[400]),
                ),
                onPressed: _currentPage < _totalPages - 1 && !_isLoading
                    ? () {
                        setState(() => _currentPage++);
                        _loadValidations();
                      }
                    : null,
              ),
            ],
          ),
          if (!_isMobile)
            Text(
              '${_itemsPerPage} par page',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}