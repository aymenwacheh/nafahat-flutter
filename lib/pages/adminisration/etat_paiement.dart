// lib/views/administration/etat_paiement.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../../services/paiement_validation_service.dart';
import '../../models/paiement_validation.dart';

class EtatPaiementPage extends StatefulWidget {
  const EtatPaiementPage({super.key});

  @override
  State<EtatPaiementPage> createState() => _EtatPaiementPageState();
}

class _EtatPaiementPageState extends State<EtatPaiementPage> {
  final PaiementValidationService _service = PaiementValidationService();
  List<PaiementValidation> _validations = [];
  bool _isLoading = true;
  bool _isProcessing = false;

  // Filtres
  String _searchQuery = '';
  String _selectedStatus = 'tous';
  String _selectedModalite = 'toutes';

  // Pagination
  int _currentPage = 0;
  final int _itemsPerPage = 15;
  int _totalItems = 0;
  int _totalPages = 1;

  // Statistiques
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _modaliteStats = [];

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
      await Future.wait([_loadValidations(), _loadStats()]);
    } catch (e) {
      _showError('Erreur de chargement: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadValidations() async {
    try {
      final result = await _service.getPaginated(
        page: _currentPage + 1,
        perPage: _itemsPerPage,
        status: _selectedStatus != 'tous' ? _selectedStatus : null,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      setState(() {
        _validations = result['data'] ?? [];
        _totalItems = result['pagination']['total'] ?? 0;
        _totalPages = result['pagination']['totalPages'] ?? 1;
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
      print('🔄 [updateStatus] Paiement $paiementId -> $statut');
      await _service.updateStatus(paiementId, statut, commentaire: commentaire);
      _showSuccess('✅ Statut mis à jour: ${_getStatusLabel(statut)}');
      await _loadValidations();
      await _loadStats();
    } catch (e) {
      print('❌ [updateStatus] Erreur: $e');
      _showError('Erreur: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'valide':
        return 'Validé';
      case 'refuse':
        return 'Refusé';
      case 'annule':
        return 'Annulé';
      case 'en_attente':
        return 'En attente';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'valide':
        return Colors.green;
      case 'refuse':
        return Colors.red;
      case 'annule':
        return Colors.grey;
      default:
        return Colors.orange;
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
      builder:
          (context) => StatefulBuilder(
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
                          color: _getStatusColor(
                            validation.statutPaiement ?? 'en_attente',
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getStatusColor(
                              validation.statutPaiement ?? 'en_attente',
                            ),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Statut actuel : ${_getStatusLabel(validation.statutPaiement ?? 'en_attente')}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        '👤 Adhérent',
                        validation.adherentNomPrenom ?? 'N/A',
                      ),
                      _buildInfoRow(
                        '📱 WhatsApp',
                        validation.adherentWhatsapp ?? 'N/A',
                      ),
                      _buildInfoRow(
                        '📚 Formation',
                        validation.formationTitreFr ?? 'N/A',
                      ),
                      _buildInfoRow(
                        '💰 Montant',
                        '${validation.montantPaye?.toStringAsFixed(2) ?? '0'} ${validation.formationDevise ?? 'DT'}',
                      ),
                      _buildInfoRow(
                        '💳 Modalité',
                        validation.modalitePaiement ?? 'N/A',
                      ),
                      _buildInfoRow(
                        '📝 Référence',
                        validation.referencePaiement ?? 'N/A',
                      ),
                      if (validation.numeroQuittance != null)
                        _buildInfoRow(
                          '📄 Quittance',
                          validation.numeroQuittance!,
                        ),
                      if (validation.urlQuittance != null)
                        _buildInfoRow('🔗 Lien', validation.urlQuittance!),
                      const SizedBox(height: 16),
                      const Divider(),
                      const Text(
                        'Choisir une action :',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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
                            onPressed: () {
                              setStateDialog(() {
                                selectedStatus = 'en_attente';
                              });
                            },
                          ),
                          _buildStatusButton(
                            label: 'Validé',
                            status: 'valide',
                            icon: Icons.check_circle,
                            color: Colors.green,
                            isSelected: selectedStatus == 'valide',
                            onPressed: () {
                              setStateDialog(() {
                                selectedStatus = 'valide';
                              });
                            },
                          ),
                          _buildStatusButton(
                            label: 'Refusé',
                            status: 'refuse',
                            icon: Icons.cancel,
                            color: Colors.red,
                            isSelected: selectedStatus == 'refuse',
                            onPressed: () {
                              setStateDialog(() {
                                selectedStatus = 'refuse';
                              });
                            },
                          ),
                          _buildStatusButton(
                            label: 'Annulé',
                            status: 'annule',
                            icon: Icons.block,
                            color: Colors.grey,
                            isSelected: selectedStatus == 'annule',
                            onPressed: () {
                              setStateDialog(() {
                                selectedStatus = 'annule';
                              });
                            },
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
                    onPressed:
                        _isProcessing ? null : () => Navigator.pop(context),
                    child: const Text('ANNULER'),
                  ),
                  if (selectedStatus != validation.statutPaiement)
                    ElevatedButton.icon(
                      onPressed:
                          _isProcessing
                              ? null
                              : () {
                                Navigator.pop(context);
                                _updateStatus(
                                  validation.paiementId,
                                  selectedStatus!,
                                  commentaire:
                                      commentaireController.text.isNotEmpty
                                          ? commentaireController.text
                                          : null,
                                );
                              },
                      icon: Icon(
                        selectedStatus == 'en_attente'
                            ? Icons.refresh
                            : Icons.save,
                        size: 18,
                      ),
                      label: Text(
                        selectedStatus == 'en_attente'
                            ? 'RÉINITIALISER'
                            : 'APPLIQUER',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            selectedStatus == 'en_attente'
                                ? Colors.orange
                                : const Color(0xFF0D443E),
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
          side: BorderSide(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
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
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
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

    print('📄 [Quittance] URL: $cleanUrl');

    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
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
                      const Text(
                        '📄 Aperçu de la quittance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Center(child: _buildQuittancePreview(cleanUrl)),
                  ),
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
    final isImage = [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'bmp',
    ].contains(extension);
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
                    value:
                        loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                    color: const Color(0xFF0D443E),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chargement de la quittance...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
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
                Text(
                  'Impossible de charger l\'image',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vérifiez que le serveur est accessible',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
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
          const Text(
            'Document PDF',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            url.split('/').last,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
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
          Text(
            'Type de fichier non pris en charge',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            url.split('/').last,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
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
      print('❌ Erreur téléchargement: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Impossible de télécharger le fichier'),
          backgroundColor: Colors.red,
        ),
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
      print('❌ Erreur ouverture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Impossible d\'ouvrir le fichier'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // DÉTAILS
  // ============================================================

  void _showDetailsDialog(PaiementValidation v) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
                  _buildInfoRow(
                    '💰 Montant',
                    '${v.montantPaye?.toStringAsFixed(2) ?? '0'} ${v.formationDevise ?? 'DT'}',
                  ),
                  _buildInfoRow('💳 Modalité', v.modalitePaiement ?? 'N/A'),
                  const Divider(),
                  _buildInfoRow('📝 Référence', v.referencePaiement ?? 'N/A'),
                  _buildInfoRow(
                    '📄 Numéro quittance',
                    v.numeroQuittance ?? '-',
                  ),
                  _buildInfoRow('📊 Statut', v.statutPaiement ?? 'en_attente'),
                  _buildInfoRow('🔐 Validateur', v.validateurNom ?? '-'),
                  _buildInfoRow(
                    '📅 Date validation',
                    v.dateValidation != null
                        ? DateFormat(
                          'dd/MM/yyyy HH:mm',
                        ).format(v.dateValidation!)
                        : '-',
                  ),
                  _buildInfoRow(
                    '📅 Date création',
                    DateFormat('dd/MM/yyyy HH:mm').format(v.createdAt),
                  ),
                  if (v.commentaire != null) ...[
                    const Divider(),
                    _buildInfoRow('💬 Commentaire', v.commentaire!),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
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
    final screenWidth = MediaQuery.of(context).size.width;
    _isMobile = screenWidth < 600;
    _isTablet = screenWidth >= 600 && screenWidth < 1200;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.verified,
              color: Colors.white,
              size: _isMobile ? 20 : 24,
            ),
            const SizedBox(width: 10),
            Text(
              'Gestion des paiements',
              style: TextStyle(
                fontSize: _isMobile ? 16 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0D443E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildStats(),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _validations.isEmpty
                    ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Aucune validation trouvée',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
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
  // FILTRES RESPONSIVE
  // ============================================================

  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _isMobile ? 8 : 16,
        vertical: _isMobile ? 8 : 10,
      ),
      color: Colors.grey[50],
      child:
          _isMobile
              ? Column(
                children: [
                  Row(children: [Expanded(child: _buildSearchField())]),
                  const SizedBox(height: 8),
                  Row(children: [Expanded(child: _buildStatusDropdown())]),
                ],
              )
              : Row(
                children: [
                  Expanded(flex: 3, child: _buildSearchField()),
                  const SizedBox(width: 10),
                  Expanded(flex: 2, child: _buildStatusDropdown()),
                ],
              ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: '🔍 Rechercher...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        isDense: true,
        suffixIcon:
            _searchQuery.isNotEmpty
                ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
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
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        isDense: true,
      ),
      value: _selectedStatus,
      items: const [
        DropdownMenuItem(value: 'tous', child: Text('📊 Tous statuts')),
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
    );
  }

  // ============================================================
  // STATISTIQUES RESPONSIVE
  // ============================================================

  Widget _buildStats() {
    final total = _stats['total_validations'] ?? 0;
    final enAttente = _stats['en_attente'] ?? 0;
    final valides = _stats['valides'] ?? 0;
    final refuses = _stats['refuses'] ?? 0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _isMobile ? 8 : 16,
        vertical: _isMobile ? 6 : 8,
      ),
      color: const Color(0xFFF5F5F5),
      child:
          _isMobile
              ? Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 4,
                children: [
                  _buildStatItem('📋', '$total', Colors.grey[700], small: true),
                  _buildStatItem('⏳', '$enAttente', Colors.orange, small: true),
                  _buildStatItem('✅', '$valides', Colors.green, small: true),
                  _buildStatItem('❌', '$refuses', Colors.red, small: true),
                  if (_modaliteStats.isNotEmpty)
                    ..._modaliteStats
                        .map(
                          (m) => _buildStatItem(
                            _getModaliteIcon(m['modalite_paiement'] ?? ''),
                            '${m['valides'] ?? 0}',
                            Colors.blue,
                            small: true,
                          ),
                        )
                        .toList(),
                ],
              )
              : Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('📋 Total', '$total', Colors.grey[700]),
                  _buildStatItem('⏳ En attente', '$enAttente', Colors.orange),
                  _buildStatItem('✅ Validés', '$valides', Colors.green),
                  _buildStatItem('❌ Refusés', '$refuses', Colors.red),
                  if (_modaliteStats.isNotEmpty)
                    ..._modaliteStats
                        .map(
                          (m) => _buildStatItem(
                            _getModaliteIcon(m['modalite_paiement'] ?? ''),
                            '${m['valides'] ?? 0}',
                            Colors.blue,
                          ),
                        )
                        .toList(),
                ],
              ),
    );
  }

  String _getModaliteIcon(String modalite) {
    switch (modalite) {
      case 'bancaire':
        return '🏦';
      case 'postal':
        return '📮';
      case 'en_ligne':
        return '🌐';
      case 'especes':
        return '💵';
      default:
        return '💳';
    }
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color? color, {
    bool small = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: small ? 10 : 12, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: small ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TABLEAU RESPONSIVE
  // ============================================================

  Widget _buildDataTable() {
    if (_isMobile) {
      return _buildMobileCards();
    } else if (_isTablet) {
      return _buildTabletCards();
    } else {
      return _buildDesktopTable();
    }
  }

  // ✅ VERSION MOBILE - Cartes
  Widget _buildMobileCards() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _validations.length,
      itemBuilder: (context, index) {
        final v = _validations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const Divider(),
                _buildMobileInfoRow(
                  '👤 Adhérent',
                  v.adherentNomPrenom ?? 'N/A',
                ),
                _buildMobileInfoRow('📱 WhatsApp', v.adherentWhatsapp ?? 'N/A'),
                _buildMobileInfoRow(
                  '📚 Formation',
                  v.formationTitreFr ?? 'N/A',
                ),
                _buildMobileInfoRow(
                  '💰 Montant',
                  '${v.montantPaye?.toStringAsFixed(2) ?? '0'} ${v.formationDevise ?? 'DT'}',
                ),
                _buildMobileInfoRow('💳 Modalité', v.modalitePaiement ?? 'N/A'),
                _buildMobileInfoRow('📝 Réf.', v.referencePaiement ?? 'N/A'),
                _buildMobileInfoRow('🔐 Validateur', v.validateurNom ?? '-'),
                _buildMobileInfoRow('📅 Date', _formatDate(v.createdAt)),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(Icons.gavel, color: Colors.orange.shade700),
                      onPressed:
                          _isProcessing ? null : () => _showValidationDialog(v),
                      tooltip: 'Modifier le statut',
                    ),
                    if (v.urlQuittance != null)
                      IconButton(
                        icon: const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.blue,
                        ),
                        onPressed: () => _viewQuittance(v.urlQuittance!),
                        tooltip: 'Voir quittance',
                      ),
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.grey),
                      onPressed: () => _showDetailsDialog(v),
                      tooltip: 'Détails',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ VERSION TABLETTE - Cartes légèrement plus grandes
  Widget _buildTabletCards() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _validations.length,
      itemBuilder: (context, index) {
        final v = _validations[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
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
                const Divider(height: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTabletInfoRow('👤', v.adherentNomPrenom ?? 'N/A'),
                      _buildTabletInfoRow('📱', v.adherentWhatsapp ?? 'N/A'),
                      _buildTabletInfoRow('📚', v.formationTitreFr ?? 'N/A'),
                      _buildTabletInfoRow(
                        '💰',
                        '${v.montantPaye?.toStringAsFixed(2) ?? '0'} ${v.formationDevise ?? 'DT'}',
                      ),
                      _buildTabletInfoRow('💳', v.modalitePaiement ?? 'N/A'),
                    ],
                  ),
                ),
                const Divider(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.gavel,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      onPressed:
                          _isProcessing ? null : () => _showValidationDialog(v),
                      tooltip: 'Modifier le statut',
                    ),
                    if (v.urlQuittance != null)
                      IconButton(
                        icon: const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.blue,
                          size: 20,
                        ),
                        onPressed: () => _viewQuittance(v.urlQuittance!),
                        tooltip: 'Voir quittance',
                      ),
                    IconButton(
                      icon: const Icon(
                        Icons.info_outline,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: () => _showDetailsDialog(v),
                      tooltip: 'Détails',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabletInfoRow(String icon, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ VERSION DESKTOP - Tableau complet
  Widget _buildDesktopTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 12,
          headingRowColor: WidgetStatePropertyAll(
            const Color(0xFF0D443E).withOpacity(0.08),
          ),
          columns: const [
            DataColumn(
              label: Text('#', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text(
                'Adhérent',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Formation',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Montant',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Modalité',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Statut',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Référence',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Validateur',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Date',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Actions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows:
              _validations.asMap().entries.map((entry) {
                final index = entry.key;
                final v = entry.value;
                return DataRow(
                  cells: [
                    DataCell(
                      Text('${_currentPage * _itemsPerPage + index + 1}'),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v.adherentNomPrenom ?? 'N/A',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            v.adherentWhatsapp ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.formationTitreFr ?? 'N/A'),
                          if (v.formationTitreAr != null)
                            Text(
                              v.formationTitreAr!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        '${v.montantPaye?.toStringAsFixed(2) ?? '0'} ${v.formationDevise ?? 'DT'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(
                      _buildModaliteChip(v.modalitePaiement ?? 'en_ligne'),
                    ),
                    DataCell(
                      _buildStatusChip(v.statutPaiement ?? 'en_attente'),
                    ),
                    DataCell(
                      Text(
                        v.referencePaiement ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        v.validateurNom ?? '-',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Text(
                        _formatDate(v.createdAt),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message: 'Modifier le statut',
                            child: IconButton(
                              icon: Icon(
                                Icons.gavel,
                                color: Colors.orange.shade700,
                              ),
                              onPressed:
                                  _isProcessing
                                      ? null
                                      : () => _showValidationDialog(v),
                              iconSize: 22,
                            ),
                          ),
                          if (v.urlQuittance != null)
                            Tooltip(
                              message: 'Voir quittance',
                              child: IconButton(
                                icon: const Icon(
                                  Icons.picture_as_pdf,
                                  color: Colors.blue,
                                ),
                                onPressed:
                                    () => _viewQuittance(v.urlQuittance!),
                                iconSize: 22,
                              ),
                            ),
                          Tooltip(
                            message: 'Détails',
                            child: IconButton(
                              icon: const Icon(
                                Icons.info_outline,
                                color: Colors.grey,
                              ),
                              onPressed: () => _showDetailsDialog(v),
                              iconSize: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }

  // ============================================================
  // COMPOSANTS COMMUNS
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (c['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (c['color'] as Color).withOpacity(0.2)),
      ),
      child: Text(
        '${c['icon']} $modalite',
        style: TextStyle(
          color: c['color'] as Color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
        color: Colors.grey[50],
      ),
      child:
          _isMobile
              ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed:
                        _currentPage > 0 && !_isLoading
                            ? () {
                              setState(() => _currentPage--);
                              _loadValidations();
                            }
                            : null,
                  ),
                  Text(
                    '${_currentPage + 1} / ${_totalPages > 0 ? _totalPages : 1}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed:
                        _currentPage < _totalPages - 1 && !_isLoading
                            ? () {
                              setState(() => _currentPage++);
                              _loadValidations();
                            }
                            : null,
                  ),
                ],
              )
              : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_totalItems} validation(s)',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed:
                            _currentPage > 0 && !_isLoading
                                ? () {
                                  setState(() => _currentPage--);
                                  _loadValidations();
                                }
                                : null,
                      ),
                      Text(
                        'Page ${_currentPage + 1} / ${_totalPages > 0 ? _totalPages : 1}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed:
                            _currentPage < _totalPages - 1 && !_isLoading
                                ? () {
                                  setState(() => _currentPage++);
                                  _loadValidations();
                                }
                                : null,
                      ),
                    ],
                  ),
                  const SizedBox(width: 40),
                ],
              ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}
