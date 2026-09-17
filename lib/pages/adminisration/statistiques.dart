// lib/pages/adminisration/statistiques_paiements.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nafahat/pages/adminisration/admin_page_wrapper.dart';
import '../../services/paiement_validation_service.dart';
import '../../services/training_service.dart';
import '../../models/paiement_validation.dart';
import '../../models/training_model.dart';

class StatistiquesPaiementsPage extends StatefulWidget {
  const StatistiquesPaiementsPage({super.key});

  @override
  State<StatistiquesPaiementsPage> createState() =>
      _StatistiquesPaiementsPageState();
}

class _StatistiquesPaiementsPageState extends State<StatistiquesPaiementsPage> {
  final PaiementValidationService _service = PaiementValidationService();

  // Données brutes
  List<PaiementValidation> _allValidations = [];
  List<TrainingModel> _formations = [];

  // Données agrégées
  List<FormationStatRow> _filteredRows = [];
  List<PaiementValidation> _allFilteredValidations = [];

  // États
  bool _isLoading = true;
  String? _error;

  // Responsive
  bool _isMobile = false;

  // Filtres repliables
  bool _filtersExpanded = false;

  // ============================================================
  // FILTRES
  // ============================================================
  String _searchQuery = '';
  String _selectedFormation = 'toutes';
  String _selectedStatut = 'tous';
  String _selectedType = 'tous';
  String _selectedModalite = 'toutes';
  String _selectedDevise = 'toutes';
  DateTime? _dateDebut;
  DateTime? _dateFin;
  RangeValues? _montantRange;

  double _montantMin = 0;
  double _montantMax = 10000;

  // ============================================================
  // TRI
  // ============================================================
  String _sortField = 'formationTitre';
  bool _sortAscending = true;

  final Map<String, String> _colonnesDisponibles = {
    'formationTitre': 'Formation',
    'totalInscrits': 'Inscrits',
    'totalPaye': 'Total payé',
    'totalRestant': 'Reste à payer',
    'totalAttente': 'En attente',
    'totalValide': 'Validés',
    'totalRefuse': 'Refusés',
    'totalAnnule': 'Annulés',
    'totalTranchesAttente': 'Tranches',
    'tauxRecouvrement': 'Taux %',
    'montantMoyen': 'Montant moyen',
    'derniereDate': 'Dernière activité',
  };

  // ============================================================
  // PAGINATION
  // ============================================================
  int _currentPage = 1;
  int _rowsPerPage = 15;
  final List<int> _rowsPerPageOptions = [10, 15, 25, 50, 100];

  // ============================================================
  // MODE
  // ============================================================
  String _viewMode = 'formation'; // 'formation' ou 'paiement'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ============================================================
  // CHARGEMENT
  // ============================================================

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final formations = await TrainingService.getTrainings();
      final validations = await _fetchAllValidations();

      if (!mounted) return;

      double minM = double.infinity;
      double maxM = 0;
      for (final v in validations) {
        if (v.montantPaye < minM) minM = v.montantPaye;
        if (v.montantPaye > maxM) maxM = v.montantPaye;
      }
      if (minM == double.infinity) minM = 0;
      if (maxM <= minM) maxM = minM + 100;

      setState(() {
        _formations = formations;
        _allValidations = validations;
        _montantMin = minM.floorToDouble();
        _montantMax = maxM.ceilToDouble();
        _montantRange = RangeValues(_montantMin, _montantMax);
        _isLoading = false;
      });

      _recalculerTout();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<List<PaiementValidation>> _fetchAllValidations() async {
    final List<PaiementValidation> all = [];
    int page = 1;
    const perPage = 200;
    bool hasMore = true;

    while (hasMore && page < 50) {
      final result = await _service.getPaginated(
        page: page,
        perPage: perPage,
      );
      final List<PaiementValidation> batch =
          (result['data'] as List?)?.cast<PaiementValidation>() ?? [];
      all.addAll(batch);
      if (batch.length < perPage) {
        hasMore = false;
      } else {
        page++;
      }
    }
    return all;
  }

  // ============================================================
  // AGRÉGATION
  // ============================================================

  void _recalculerTout() {
    final filtered = _applyFiltersToValidations(_allValidations);
    _allFilteredValidations = filtered;

    final Map<String, FormationStatRow> map = {};

    for (final f in _formations) {
      final key = _formationKeyFromModel(f);
      if (key.isEmpty) continue;
      map[key] = FormationStatRow(
        formationId: f.id.toString(),
        formationTitre: key,
        formationTitreAr: f.titleAr,
        devise: 'TND',
      );
    }

    for (final v in filtered) {
      final key = _formationKeyFromValidation(v);
      if (key.isEmpty) continue;

      final row = map.putIfAbsent(
        key,
        () => FormationStatRow(
          formationId: v.paiementId.toString(),
          formationTitre: key,
          formationTitreAr: v.formationTitreAr,
          devise: v.formationDevise ?? 'TND',
        ),
      );

      row.devise = v.formationDevise ?? row.devise;
      row.totalPaiements += 1;
      row.totalPaye += v.montantPaye;
      row.totalRestant += v.montantRestant;
      row.totalFacture += v.formationPrix;

      if (v.trancheEnAttente != null && v.trancheEnAttente! > 0) {
        row.totalAttente += v.trancheEnAttente!;
        row.totalTranchesAttente += 1;
      }

      switch (v.statutPaiement ?? v.statut) {
        case 'valide':
          row.totalValide += 1;
          break;
        case 'refuse':
          row.totalRefuse += 1;
          break;
        case 'annule':
          row.totalAnnule += 1;
          break;
        default:
          row.totalEnAttenteCount += 1;
      }

      final adhKey = v.adherentWhatsapp ?? v.adherentNomPrenom ?? '';
      if (adhKey.isNotEmpty) row.adherentsUniques.add(adhKey);

      final date = v.dateValidation ?? v.createdAt;
      if (row.derniereDate == null || date.isAfter(row.derniereDate!)) {
        row.derniereDate = date;
      }
    }

    for (final row in map.values) {
      row.totalInscrits = row.adherentsUniques.length;
      row.montantMoyen =
          row.totalPaiements > 0 ? row.totalPaye / row.totalPaiements : 0;
      row.tauxRecouvrement = row.totalFacture > 0
          ? (row.totalPaye / row.totalFacture) * 100
          : 0;
    }

    final rows = map.values.toList();
    _sortRows(rows);

    setState(() {
      _filteredRows = rows;
      _currentPage = 1;
    });
  }

  void _sortRows(List<FormationStatRow> rows) {
    rows.sort((a, b) {
      int cmp;
      switch (_sortField) {
        case 'formationTitre':
          cmp = a.formationTitre
              .toLowerCase()
              .compareTo(b.formationTitre.toLowerCase());
          break;
        case 'totalInscrits':
          cmp = a.totalInscrits.compareTo(b.totalInscrits);
          break;
        case 'totalPaye':
          cmp = a.totalPaye.compareTo(b.totalPaye);
          break;
        case 'totalRestant':
          cmp = a.totalRestant.compareTo(b.totalRestant);
          break;
        case 'totalAttente':
          cmp = a.totalAttente.compareTo(b.totalAttente);
          break;
        case 'totalValide':
          cmp = a.totalValide.compareTo(b.totalValide);
          break;
        case 'totalRefuse':
          cmp = a.totalRefuse.compareTo(b.totalRefuse);
          break;
        case 'totalAnnule':
          cmp = a.totalAnnule.compareTo(b.totalAnnule);
          break;
        case 'totalTranchesAttente':
          cmp = a.totalTranchesAttente.compareTo(b.totalTranchesAttente);
          break;
        case 'tauxRecouvrement':
          cmp = a.tauxRecouvrement.compareTo(b.tauxRecouvrement);
          break;
        case 'montantMoyen':
          cmp = a.montantMoyen.compareTo(b.montantMoyen);
          break;
        case 'derniereDate':
          final da = a.derniereDate ?? DateTime(1900);
          final db = b.derniereDate ?? DateTime(1900);
          cmp = da.compareTo(db);
          break;
        default:
          cmp = 0;
      }
      return _sortAscending ? cmp : -cmp;
    });
  }

  String _formationKeyFromModel(TrainingModel f) {
    if (f.titleFr.isNotEmpty) return f.titleFr;
    if (f.titleAr.isNotEmpty) return f.titleAr;
    return '';
  }

  String _formationKeyFromValidation(PaiementValidation v) {
    if ((v.formationTitreFr ?? '').isNotEmpty) return v.formationTitreFr!;
    if ((v.formationTitreAr ?? '').isNotEmpty) return v.formationTitreAr!;
    return 'Inconnue';
  }

  // ============================================================
  // FILTRES APPLIQUÉS
  // ============================================================

  List<PaiementValidation> _applyFiltersToValidations(
      List<PaiementValidation> source) {
    Iterable<PaiementValidation> iter = source;

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      iter = iter.where((v) =>
          (v.adherentNomPrenom ?? '').toLowerCase().contains(q) ||
          (v.adherentWhatsapp ?? '').toLowerCase().contains(q) ||
          (v.formationTitreFr ?? '').toLowerCase().contains(q) ||
          (v.formationTitreAr ?? '').toLowerCase().contains(q) ||
          (v.referencePaiement ?? '').toLowerCase().contains(q) ||
          (v.numeroQuittance ?? '').toLowerCase().contains(q));
    }

    if (_selectedFormation != 'toutes') {
      iter = iter.where(
          (v) => _formationKeyFromValidation(v) == _selectedFormation);
    }

    if (_selectedStatut != 'tous') {
      iter = iter.where(
          (v) => (v.statutPaiement ?? v.statut) == _selectedStatut);
    }

    if (_selectedType != 'tous') {
      iter = iter.where((v) => (v.typePaiement ?? 'formation') == _selectedType);
    }

    if (_selectedModalite != 'toutes') {
      iter = iter.where((v) => v.modalitePaiement == _selectedModalite);
    }

    if (_selectedDevise != 'toutes') {
      iter = iter.where((v) => (v.formationDevise ?? 'TND') == _selectedDevise);
    }

    if (_dateDebut != null || _dateFin != null) {
      iter = iter.where((v) {
        final d = v.dateValidation ?? v.createdAt;
        if (_dateDebut != null && d.isBefore(_dateDebut!)) return false;
        if (_dateFin != null &&
            d.isAfter(_dateFin!.add(const Duration(days: 1)))) {
          return false;
        }
        return true;
      });
    }

    if (_montantRange != null) {
      iter = iter.where((v) =>
          v.montantPaye >= _montantRange!.start &&
          v.montantPaye <= _montantRange!.end);
    }

    return iter.toList();
  }

  void _resetFiltres() {
    setState(() {
      _searchQuery = '';
      _selectedFormation = 'toutes';
      _selectedStatut = 'tous';
      _selectedType = 'tous';
      _selectedModalite = 'toutes';
      _selectedDevise = 'toutes';
      _dateDebut = null;
      _dateFin = null;
      _montantRange = RangeValues(_montantMin, _montantMax);
    });
    _recalculerTout();
  }

  int get _activeFilterCount {
    int c = 0;
    if (_searchQuery.isNotEmpty) c++;
    if (_selectedFormation != 'toutes') c++;
    if (_selectedStatut != 'tous') c++;
    if (_selectedType != 'tous') c++;
    if (_selectedModalite != 'toutes') c++;
    if (_selectedDevise != 'toutes') c++;
    if (_dateDebut != null) c++;
    if (_montantRange != null &&
        (_montantRange!.start > _montantMin ||
            _montantRange!.end < _montantMax)) {
      c++;
    }
    return c;
  }

  List<String> get _formationsDisponibles {
    final set = <String>{};
    for (final v in _allValidations) {
      final k = _formationKeyFromValidation(v);
      if (k.isNotEmpty) set.add(k);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<String> get _devisesDisponibles {
    final set = <String>{};
    for (final v in _allValidations) {
      set.add(v.formationDevise ?? 'TND');
    }
    return set.toList()..sort();
  }

  // ============================================================
  // EXPORT CSV
  // ============================================================

  String _exportCSV() {
    final buffer = StringBuffer();
    if (_viewMode == 'formation') {
      buffer.writeln(_colonnesDisponibles.values.map((e) => '"$e"').join(','));
      for (final row in _filteredRows) {
        buffer.writeln([
          '"${row.formationTitre}"',
          row.totalInscrits,
          row.totalPaye.toStringAsFixed(2),
          row.totalRestant.toStringAsFixed(2),
          row.totalAttente.toStringAsFixed(2),
          row.totalValide,
          row.totalRefuse,
          row.totalAnnule,
          row.totalTranchesAttente,
          row.tauxRecouvrement.toStringAsFixed(1),
          row.montantMoyen.toStringAsFixed(2),
          '"${row.derniereDate != null ? DateFormat('dd/MM/yyyy').format(row.derniereDate!) : '-'}"',
        ].join(','));
      }
    } else {
      buffer.writeln(
          '"Adhérent","WhatsApp","Formation","Type","Statut","Montant payé","Reste","Devise","Modalité","Référence","Date"');
      for (final v in _allFilteredValidations) {
        buffer.writeln([
          '"${v.adherentNomPrenom ?? ''}"',
          '"${v.adherentWhatsapp ?? ''}"',
          '"${v.formationTitreFr ?? ''}"',
          '"${v.typePaiement ?? 'formation'}"',
          '"${v.statutPaiement ?? v.statut}"',
          v.montantPaye.toStringAsFixed(2),
          v.montantRestant.toStringAsFixed(2),
          '"${v.formationDevise ?? 'TND'}"',
          '"${v.modalitePaiement ?? ''}"',
          '"${v.referencePaiement ?? ''}"',
          '"${DateFormat('dd/MM/yyyy').format(v.dateValidation ?? v.createdAt)}"',
        ].join(','));
      }
    }
    return buffer.toString();
  }

  void _showExportDialog() {
    final csv = _exportCSV();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('📄 Export CSV'),
        content: SizedBox(
          width: 700,
          height: 500,
          child: SingleChildScrollView(
            child: SelectableText(
              csv.isEmpty ? 'Aucune donnée' : csv,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
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

    return AdminPageWrapper(
      title: 'Statistiques des paiements',
      titleAr: 'إحصائيات المدفوعات',
      backgroundColor: const Color(0xFFF8FAFC),
      actions: [
        IconButton(
          icon: const Icon(Icons.download_outlined),
          onPressed: _showExportDialog,
          tooltip: 'Exporter CSV',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadData,
          tooltip: 'Rafraîchir',
        ),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('❌ $_error',
                        style: const TextStyle(color: Colors.red)),
                  ),
                )
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _isMobile ? _buildMobileFilterBar() : _buildDesktopFilterBar(),
        _buildSummaryBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: _buildContent(),
          ),
        ),
        _buildPagination(),
      ],
    );
  }

  // ============================================================
  // BARRE FILTRES MOBILE
  // ============================================================

  Widget _buildMobileFilterBar() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Recherche + toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Rechercher...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                        prefixIcon: const Icon(Icons.search,
                            size: 20, color: Colors.grey),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  setState(() => _searchQuery = '');
                                  _recalculerTout();
                                },
                              )
                            : null,
                      ),
                      onChanged: (v) {
                        _searchQuery = v;
                        _recalculerTout();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Stack(
                  children: [
                    Material(
                      color: _filtersExpanded
                          ? const Color(0xFF0D443E)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setState(
                            () => _filtersExpanded = !_filtersExpanded),
                        child: Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.tune,
                            size: 20,
                            color: _filtersExpanded
                                ? Colors.white
                                : const Color(0xFF0D443E),
                          ),
                        ),
                      ),
                    ),
                    if (_activeFilterCount > 0)
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xffd57653),
                            shape: BoxShape.circle,
                          ),
                          constraints:
                              const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            '${_activeFilterCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Mode toggle + Reset (avec Flexible pour éviter overflow)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(flex: 3, child: _buildModeToggle(compact: true)),
                const SizedBox(width: 8),
                Flexible(flex: 2, child: _buildResetButton(compact: true)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Filtres repliables
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _buildMobileFilterFields(),
            crossFadeState: _filtersExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildMobileFilterFields() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      child: Column(
        children: [
          _buildCompactDropdown(
            label: 'Formation',
            icon: Icons.school_outlined,
            value: _selectedFormation,
            options: ['toutes', ..._formationsDisponibles],
            display: (v) => v == 'toutes' ? 'Toutes' : v,
            onChanged: (v) {
              setState(() => _selectedFormation = v);
              _recalculerTout();
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCompactDropdown(
                  label: 'Statut',
                  icon: Icons.filter_alt_outlined,
                  value: _selectedStatut,
                  options: const [
                    'tous',
                    'en_attente',
                    'valide',
                    'refuse',
                    'annule',
                  ],
                  display: _statusLabel,
                  onChanged: (v) {
                    setState(() => _selectedStatut = v);
                    _recalculerTout();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactDropdown(
                  label: 'Type',
                  icon: Icons.category_outlined,
                  value: _selectedType,
                  options: const [
                    'tous',
                    'formation',
                    'mois',
                    'semaine',
                    'trimestre',
                    'annee',
                    'seance',
                  ],
                  display: _typeLabel,
                  onChanged: (v) {
                    setState(() => _selectedType = v);
                    _recalculerTout();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCompactDropdown(
                  label: 'Modalité',
                  icon: Icons.payment_outlined,
                  value: _selectedModalite,
                  options: const [
                    'toutes',
                    'bancaire',
                    'postal',
                    'en_ligne',
                    'especes',
                  ],
                  display: _modaliteLabel,
                  onChanged: (v) {
                    setState(() => _selectedModalite = v);
                    _recalculerTout();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactDropdown(
                  label: 'Devise',
                  icon: Icons.attach_money,
                  value: _selectedDevise,
                  options: ['toutes', ..._devisesDisponibles],
                  display: (v) => v == 'toutes' ? 'Toutes' : v,
                  onChanged: (v) {
                    setState(() => _selectedDevise = v);
                    _recalculerTout();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: _buildDateRangeButton(),
          ),
          const SizedBox(height: 8),
          _buildMontantSlider(),
          const SizedBox(height: 8),
          _buildSortRow(compact: true),
        ],
      ),
    );
  }

  // ============================================================
  // BARRE FILTRES DESKTOP
  // ============================================================

  Widget _buildDesktopFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 340,
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher (adhérent, formation, réf...)',
                      prefixIcon: const Icon(Icons.search,
                          size: 20, color: Colors.grey),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                setState(() => _searchQuery = '');
                                _recalculerTout();
                              },
                            )
                          : null,
                    ),
                    onChanged: (v) {
                      _searchQuery = v;
                      _recalculerTout();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildModeToggle()),
              const SizedBox(width: 12),
              _buildResetButton(),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _buildDesktopDropdown(
                label: 'Formation',
                value: _selectedFormation,
                options: ['toutes', ..._formationsDisponibles],
                display: (v) => v == 'toutes' ? 'Toutes' : v,
                onChanged: (v) {
                  setState(() => _selectedFormation = v);
                  _recalculerTout();
                },
              ),
              _buildDesktopDropdown(
                label: 'Statut',
                value: _selectedStatut,
                options: const [
                  'tous',
                  'en_attente',
                  'valide',
                  'refuse',
                  'annule',
                ],
                display: _statusLabel,
                onChanged: (v) {
                  setState(() => _selectedStatut = v);
                  _recalculerTout();
                },
              ),
              _buildDesktopDropdown(
                label: 'Type',
                value: _selectedType,
                options: const [
                  'tous',
                  'formation',
                  'mois',
                  'semaine',
                  'trimestre',
                  'annee',
                  'seance',
                ],
                display: _typeLabel,
                onChanged: (v) {
                  setState(() => _selectedType = v);
                  _recalculerTout();
                },
              ),
              _buildDesktopDropdown(
                label: 'Modalité',
                value: _selectedModalite,
                options: const [
                  'toutes',
                  'bancaire',
                  'postal',
                  'en_ligne',
                  'especes',
                ],
                display: _modaliteLabel,
                onChanged: (v) {
                  setState(() => _selectedModalite = v);
                  _recalculerTout();
                },
              ),
              _buildDesktopDropdown(
                label: 'Devise',
                value: _selectedDevise,
                options: ['toutes', ..._devisesDisponibles],
                display: (v) => v == 'toutes' ? 'Toutes' : v,
                onChanged: (v) {
                  setState(() => _selectedDevise = v);
                  _recalculerTout();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildDateRangeButton(),
              SizedBox(width: 340, child: _buildMontantSlider()),
              _buildSortRow(),
              _buildRowsPerPage(),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGETS FILTRES COMMUNS
  // ============================================================

  Widget _buildModeToggle({bool compact = false}) {
    return Container(
      height: compact ? 42 : 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(child: _modeButton('formation', '📊 Formation', compact)),
          Expanded(child: _modeButton('paiement', '📋 Paiement', compact)),
        ],
      ),
    );
  }

  Widget _modeButton(String mode, String label, bool compact) {
    final selected = _viewMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() => _viewMode = mode);
        _recalculerTout();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0D443E) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: compact ? 12 : 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResetButton({bool compact = false}) {
    return SizedBox(
      height: compact ? 42 : 44,
      child: OutlinedButton.icon(
        onPressed: _resetFiltres,
        icon: Icon(Icons.refresh, size: compact ? 16 : 18),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            compact ? 'Reset' : 'Réinitialiser',
            style: TextStyle(fontSize: compact ? 12 : 13),
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xffd57653),
          side: BorderSide(color: const Color(0xffd57653).withOpacity(0.4)),
          padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> options,
    required String Function(String) display,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0D443E)),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                isDense: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                items: options
                    .map((o) => DropdownMenuItem(
                          value: o,
                          child: Text(
                            display(o),
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopDropdown({
    required String label,
    required String value,
    required List<String> options,
    required String Function(String) display,
    required ValueChanged<String> onChanged,
  }) {
    return SizedBox(
      width: 200,
      height: 44,
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12),
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
        style: const TextStyle(fontSize: 13, color: Colors.black87),
        items: options
            .map((o) => DropdownMenuItem(
                  value: o,
                  child: Text(display(o),
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }

  Widget _buildDateRangeButton() {
    final hasDates = _dateDebut != null && _dateFin != null;
    return SizedBox(
      height: _isMobile ? 46 : 44,
      child: OutlinedButton.icon(
        onPressed: () async {
          final range = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
            initialDateRange: hasDates
                ? DateTimeRange(start: _dateDebut!, end: _dateFin!)
                : null,
          );
          if (range != null) {
            setState(() {
              _dateDebut = range.start;
              _dateFin = range.end;
            });
            _recalculerTout();
          }
        },
        icon: const Icon(Icons.date_range, size: 18),
        label: Text(
          hasDates
              ? '${DateFormat('dd/MM/yy').format(_dateDebut!)} → ${DateFormat('dd/MM/yy').format(_dateFin!)}'
              : 'Période',
          style: const TextStyle(fontSize: 12),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor:
              hasDates ? const Color(0xFF0D443E) : Colors.grey[700],
          side: BorderSide(
            color: hasDates ? const Color(0xFF0D443E) : Colors.grey[300]!,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildMontantSlider() {
    final double currentStart = _montantRange?.start ?? _montantMin;
    final double currentEnd = _montantRange?.end ?? _montantMax;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '💵 Montant : ${currentStart.round()} - ${currentEnd.round()}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: const Color(0xFF0D443E),
            thumbColor: const Color(0xFF0D443E),
            inactiveTrackColor: const Color(0xFF0D443E).withOpacity(0.15),
          ),
          child: RangeSlider(
            min: _montantMin,
            max: _montantMax == _montantMin ? _montantMin + 1 : _montantMax,
            divisions: ((_montantMax - _montantMin) / 10).clamp(1, 100).toInt(),
            values: _montantRange ?? RangeValues(_montantMin, _montantMax),
            labels: RangeLabels(
              currentStart.round().toString(),
              currentEnd.round().toString(),
            ),
            onChanged: (v) => setState(() => _montantRange = v),
            onChangeEnd: (_) => _recalculerTout(),
          ),
        ),
      ],
    );
  }

  Widget _buildSortRow({bool compact = false}) {
    return Row(
      children: [
        Icon(Icons.sort, size: compact ? 16 : 18, color: Colors.grey[700]),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            height: compact ? 42 : 44,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortField,
                isExpanded: true,
                isDense: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                items: _colonnesDisponibles.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _sortField = v);
                  _recalculerTout();
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Material(
          color: const Color(0xFF0D443E).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() => _sortAscending = !_sortAscending);
              _recalculerTout();
            },
            child: Container(
              width: compact ? 42 : 44,
              height: compact ? 42 : 44,
              alignment: Alignment.center,
              child: Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                color: const Color(0xFF0D443E),
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRowsPerPage() {
    return SizedBox(
      height: 44,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Lignes :',
              style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _rowsPerPage,
                isDense: true,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                items: _rowsPerPageOptions
                    .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _rowsPerPage = v;
                    _currentPage = 1;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LIBELLÉS
  // ============================================================

  String _statusLabel(String v) {
    switch (v) {
      case 'tous':
        return 'Tous statuts';
      case 'en_attente':
        return 'En attente';
      case 'valide':
        return 'Validé';
      case 'refuse':
        return 'Refusé';
      case 'annule':
        return 'Annulé';
      default:
        return v;
    }
  }

  String _typeLabel(String v) {
    switch (v) {
      case 'tous':
        return 'Tous types';
      case 'formation':
        return 'Complet';
      case 'mois':
        return 'Mensuel';
      case 'semaine':
        return 'Hebdo';
      case 'trimestre':
        return 'Trim.';
      case 'annee':
        return 'Annuel';
      case 'seance':
        return 'Séance';
      default:
        return v;
    }
  }

  String _modaliteLabel(String v) {
    switch (v) {
      case 'toutes':
        return 'Toutes modalités';
      case 'bancaire':
        return 'Bancaire';
      case 'postal':
        return 'Postal';
      case 'en_ligne':
        return 'En ligne';
      case 'especes':
        return 'Espèces';
      default:
        return v;
    }
  }

  // ============================================================
  // RÉSUMÉ
  // ============================================================

  Widget _buildSummaryBar() {
    final totalPaye = _filteredRows.fold<double>(0, (s, r) => s + r.totalPaye);
    final totalRestant =
        _filteredRows.fold<double>(0, (s, r) => s + r.totalRestant);
    final totalAttente =
        _filteredRows.fold<double>(0, (s, r) => s + r.totalAttente);
    final totalValides =
        _filteredRows.fold<int>(0, (s, r) => s + r.totalValide);
    final totalRefuses =
        _filteredRows.fold<int>(0, (s, r) => s + r.totalRefuse);
    final totalInscrits =
        _filteredRows.fold<int>(0, (s, r) => s + r.totalInscrits);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _isMobile ? 10 : 20,
        vertical: 8,
      ),
      color: const Color(0xFF0D443E).withOpacity(0.04),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _summaryChip(Icons.school_outlined, '${_filteredRows.length}',
                'Formations', Colors.blueGrey),
            _summaryChip(Icons.people_outline, '$totalInscrits', 'Inscrits',
                Colors.indigo),
            _summaryChip(Icons.payments_outlined, _fmtMoney(totalPaye), 'Payé',
                Colors.green),
            _summaryChip(Icons.pending_actions_outlined,
                _fmtMoney(totalRestant), 'Reste', Colors.orange),
            _summaryChip(Icons.hourglass_top, _fmtMoney(totalAttente),
                'Attente', Colors.deepOrange),
            _summaryChip(Icons.check_circle_outline, '$totalValides',
                'Validés', Colors.green),
            _summaryChip(
                Icons.cancel_outlined, '$totalRefuses', 'Refusés', Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(
      IconData icon, String value, String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: EdgeInsets.symmetric(
        horizontal: _isMobile ? 10 : 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _isMobile ? 14 : 16, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: _isMobile ? 13 : 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: _isMobile ? 10 : 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtMoney(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  // ============================================================
  // CONTENU
  // ============================================================

  Widget _buildContent() {
    if (_viewMode == 'formation') {
      if (_filteredRows.isEmpty) return _emptyState();
      return _isMobile ? _buildMobileFormationCards() : _buildFormationTable();
    } else {
      if (_allFilteredValidations.isEmpty) return _emptyState();
      return _isMobile ? _buildMobilePaiementCards() : _buildPaiementTable();
    }
  }

  Widget _emptyState() {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('Aucune donnée pour ces filtres',
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------- TABLEAU FORMATION (desktop) ----------

  Widget _buildFormationTable() {
    final total = _filteredRows.length;
    final start = (_currentPage - 1) * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, total);
    final pageData = _filteredRows.sublist(start, end);

    final columnKeys = _colonnesDisponibles.keys.toList();
    final sortIndex = columnKeys.indexOf(_sortField);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
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
                const Color(0xFF0D443E).withOpacity(0.06),
              ),
              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D443E),
                fontSize: 12,
              ),
              dataRowMinHeight: 48,
              dataRowMaxHeight: 60,
              sortColumnIndex: sortIndex >= 0 ? sortIndex : null,
              sortAscending: _sortAscending,
              columns: _colonnesDisponibles.entries.map((e) {
                return DataColumn(
                  label: Text(e.value),
                  numeric:
                      e.key != 'formationTitre' && e.key != 'derniereDate',
                  onSort: (_, __) {
                    setState(() {
                      if (_sortField == e.key) {
                        _sortAscending = !_sortAscending;
                      } else {
                        _sortField = e.key;
                        _sortAscending = true;
                      }
                    });
                    _recalculerTout();
                  },
                );
              }).toList(),
              rows: pageData.map((row) {
                return DataRow(
                  cells: [
                    DataCell(SizedBox(
                      width: 200,
                      child: Text(
                        row.formationTitre,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                    DataCell(_numBadge(row.totalInscrits, Colors.indigo)),
                    DataCell(
                        _moneyText(row.totalPaye, row.devise, Colors.green)),
                    DataCell(
                        _moneyText(row.totalRestant, row.devise, Colors.orange)),
                    DataCell(_moneyText(
                        row.totalAttente, row.devise, Colors.deepOrange)),
                    DataCell(_countChip(row.totalValide, Colors.green)),
                    DataCell(_countChip(row.totalRefuse, Colors.red)),
                    DataCell(_countChip(row.totalAnnule, Colors.grey)),
                    DataCell(_countChip(row.totalTranchesAttente, Colors.blue)),
                    DataCell(_tauxBar(row.tauxRecouvrement)),
                    DataCell(Text(
                      '${row.montantMoyen.toStringAsFixed(0)} ${row.devise}',
                      style: const TextStyle(fontSize: 12),
                    )),
                    DataCell(Text(
                      row.derniereDate != null
                          ? DateFormat('dd/MM/yy').format(row.derniereDate!)
                          : '-',
                      style: const TextStyle(fontSize: 11),
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- TABLEAU PAIEMENT (desktop) ----------

  Widget _buildPaiementTable() {
    final total = _allFilteredValidations.length;
    final start = (_currentPage - 1) * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, total);
    final pageData = _allFilteredValidations.sublist(start, end);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
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
              columnSpacing: 14,
              headingRowColor: WidgetStatePropertyAll(
                const Color(0xFF0D443E).withOpacity(0.06),
              ),
              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D443E),
                fontSize: 12,
              ),
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('Adhérent')),
                DataColumn(label: Text('WhatsApp')),
                DataColumn(label: Text('Formation')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Payé')),
                DataColumn(label: Text('Reste')),
                DataColumn(label: Text('Statut')),
                DataColumn(label: Text('Modalité')),
                DataColumn(label: Text('Date')),
              ],
              rows: pageData.asMap().entries.map((e) {
                final i = e.key;
                final v = e.value;
                return DataRow(cells: [
                  DataCell(Text('${start + i + 1}')),
                  DataCell(Text(v.adherentNomPrenom ?? 'N/A',
                      style: const TextStyle(fontWeight: FontWeight.w500))),
                  DataCell(Text(v.adherentWhatsapp ?? '',
                      style: const TextStyle(fontSize: 12))),
                  DataCell(SizedBox(
                    width: 180,
                    child: Text(
                      v.formationTitreFr ?? 'N/A',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  )),
                  DataCell(Text(
                    '${v.getTypeIcon()} ${v.getTypeLabel(false)}',
                    style: const TextStyle(fontSize: 11),
                  )),
                  DataCell(_moneyText(
                      v.montantPaye, v.formationDevise ?? 'TND', Colors.green)),
                  DataCell(_moneyText(v.montantRestant,
                      v.formationDevise ?? 'TND', Colors.orange)),
                  DataCell(_statusChip(v.statutPaiement ?? v.statut)),
                  DataCell(Text(v.modalitePaiement ?? '-',
                      style: const TextStyle(fontSize: 11))),
                  DataCell(Text(
                    DateFormat('dd/MM/yy')
                        .format(v.dateValidation ?? v.createdAt),
                    style: const TextStyle(fontSize: 11),
                  )),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- MOBILE : CARDS FORMATION ----------

  Widget _buildMobileFormationCards() {
    final total = _filteredRows.length;
    final start = (_currentPage - 1) * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, total);
    final pageData = _filteredRows.sublist(start, end);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      itemCount: pageData.length,
      itemBuilder: (_, i) {
        final row = pageData[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      row.formationTitre,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _tauxColor(row.tauxRecouvrement).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${row.tauxRecouvrement.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _tauxColor(row.tauxRecouvrement),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _countChip(row.totalInscrits, Colors.indigo, prefix: '👥 '),
                  _countChip(row.totalValide, Colors.green, prefix: '✅ '),
                  _countChip(row.totalRefuse, Colors.red, prefix: '❌ '),
                  if (row.totalTranchesAttente > 0)
                    _countChip(row.totalTranchesAttente, Colors.blue,
                        prefix: '⏳ '),
                ],
              ),
              const Divider(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _amountBlock(
                      'Payé',
                      row.totalPaye,
                      row.devise,
                      Colors.green,
                    ),
                  ),
                  Container(width: 1, height: 32, color: Colors.grey[200]),
                  Expanded(
                    child: _amountBlock(
                      'Reste',
                      row.totalRestant,
                      row.devise,
                      Colors.orange,
                    ),
                  ),
                  if (row.totalAttente > 0) ...[
                    Container(width: 1, height: 32, color: Colors.grey[200]),
                    Expanded(
                      child: _amountBlock(
                        'Attente',
                        row.totalAttente,
                        row.devise,
                        Colors.deepOrange,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (row.tauxRecouvrement / 100).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[200],
                  color: _tauxColor(row.tauxRecouvrement),
                  minHeight: 5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _tauxColor(double taux) {
    if (taux >= 80) return Colors.green;
    if (taux >= 50) return Colors.orange;
    return Colors.red;
  }

  Widget _amountBlock(
      String label, double value, String devise, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${value.toStringAsFixed(0)} $devise',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // ---------- MOBILE : CARDS PAIEMENT ----------

  Widget _buildMobilePaiementCards() {
    final total = _allFilteredValidations.length;
    final start = (_currentPage - 1) * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, total);
    final pageData = _allFilteredValidations.sublist(start, end);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      itemCount: pageData.length,
      itemBuilder: (_, i) {
        final v = pageData[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      v.adherentNomPrenom ?? 'N/A',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _statusChip(v.statutPaiement ?? v.statut),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                v.formationTitreFr ?? 'N/A',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _countChip(1, Colors.blue, prefix: v.getTypeIcon()),
                  _moneyChip(
                      v.montantPaye, v.formationDevise ?? 'TND', Colors.green),
                  if (v.montantRestant > 0)
                    _moneyChip(v.montantRestant, v.formationDevise ?? 'TND',
                        Colors.orange),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // WIDGETS UTILITAIRES
  // ============================================================

  Widget _numBadge(int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$value',
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _countChip(int value, Color color, {String prefix = ''}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        '$prefix$value',
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _moneyChip(double v, String devise, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${v.toStringAsFixed(0)} $devise',
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _moneyText(double v, String devise, Color color) {
    return Text(
      '${v.toStringAsFixed(2)} $devise',
      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
    );
  }

  Widget _tauxBar(double taux) {
    final double t = taux.clamp(0.0, 100.0);
    final Color c = _tauxColor(t);
    return SizedBox(
      width: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${t.toStringAsFixed(1)}%',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: c)),
          const SizedBox(height: 3),
          LinearProgressIndicator(
            value: (t / 100).clamp(0.0, 1.0),
            backgroundColor: Colors.grey[200],
            color: c,
            minHeight: 5,
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'valide':
        color = Colors.green;
        label = '✅ Validé';
        break;
      case 'refuse':
        color = Colors.red;
        label = '❌ Refusé';
        break;
      case 'annule':
        color = Colors.grey;
        label = '🚫 Annulé';
        break;
      default:
        color = Colors.orange;
        label = '⏳ En attente';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w600, fontSize: 11)),
    );
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  Widget _buildPagination() {
    final total = _viewMode == 'formation'
        ? _filteredRows.length
        : _allFilteredValidations.length;
    final totalPages = total == 0 ? 1 : (total / _rowsPerPage).ceil();

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 8,
        horizontal: _isMobile ? 10 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _navBtn(
            Icons.chevron_left,
            _currentPage > 1 ? () => setState(() => _currentPage--) : null,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0D443E).withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$_currentPage / $totalPages',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D443E),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _navBtn(
            Icons.chevron_right,
            _currentPage < totalPages
                ? () => setState(() => _currentPage++)
                : null,
          ),
          if (!_isMobile) ...[
            const SizedBox(width: 20),
            Text(
              '$total ligne(s)',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback? onTap) {
    return Material(
      color: onTap != null
          ? const Color(0xFF0D443E).withOpacity(0.08)
          : Colors.grey[100],
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 20,
            color: onTap != null ? const Color(0xFF0D443E) : Colors.grey[400],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MODÈLE LIGNE AGRÉGÉE
// ============================================================

class FormationStatRow {
  final String formationId;
  final String formationTitre;
  final String? formationTitreAr;
  String devise;

  int totalPaiements = 0;
  int totalInscrits = 0;
  double totalPaye = 0;
  double totalRestant = 0;
  double totalAttente = 0;
  double totalFacture = 0;

  int totalValide = 0;
  int totalRefuse = 0;
  int totalAnnule = 0;
  int totalEnAttenteCount = 0;
  int totalTranchesAttente = 0;

  double montantMoyen = 0;
  double tauxRecouvrement = 0;

  DateTime? derniereDate;

  final Set<String> adherentsUniques = {};

  FormationStatRow({
    required this.formationId,
    required this.formationTitre,
    this.formationTitreAr,
    this.devise = 'TND',
  });
}