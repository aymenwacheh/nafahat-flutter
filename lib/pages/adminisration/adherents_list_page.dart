// lib/pages/adminisration/adherents_list_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/pages/adminisration/admin_page_wrapper.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:nafahat/providers/language_provider.dart';
import 'package:nafahat/services/training_service.dart';
import 'package:nafahat/models/adherent.dart';
import 'package:nafahat/pages/users/edit_profile_page.dart';

class AdherentsListPage extends StatefulWidget {
  const AdherentsListPage({super.key});

  @override
  State<AdherentsListPage> createState() => _AdherentsListPageState();
}

class _AdherentsListPageState extends State<AdherentsListPage> {
  List<Adherent> _adherents = [];
  bool _isLoading = true;
  bool _isProcessing = false;

  // Filtres
  String _searchQuery = '';
  String _selectedGenre = 'tous';

  // Pagination
  int _currentPage = 0;
  final int _itemsPerPage = 20;
  int _totalItems = 0;
  int _totalPages = 1;

  // Tri
  String _sortColumn = 'id';
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadAdherents();
  }

  // ✅ Méthode pour mapper les colonnes triables
  int? _getSortColumnIndex(String column) {
    final columns = [
      'id',
      'nom_prenom',
      'whatsapp',
      'email',
      'pays',
      'ville',
      'genre',
    ];
    final index = columns.indexOf(column);
    return index >= 0 ? index : null;
  }

  Future<void> _loadAdherents() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
          '${TrainingService.apiBaseUrl}/adherents?page=${_currentPage + 1}&limit=$_itemsPerPage&search=$_searchQuery&genre=$_selectedGenre&sort=$_sortColumn&order=${_sortAscending ? 'asc' : 'desc'}',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          final List<dynamic> list = data['data'] ?? [];
          _adherents = list.map((json) => Adherent.fromJson(json)).toList();
          _totalItems = data['count'] ?? 0;
          _totalPages = data['totalPages'] ?? 1;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showError('Erreur de chargement des adhérents');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur: $e');
    }
  }

  Future<void> _deleteAdherent(int id, String nom) async {
    final isArabic =
        Provider.of<LanguageProvider>(context, listen: false).isArabic;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isArabic ? 'تأكيد الحذف' : 'Confirmer la suppression'),
            content: Text(
              isArabic
                  ? 'Êtes-vous sûr de vouloir supprimer l\'adhérent "$nom" ?'
                  : 'Êtes-vous sûr de vouloir supprimer l\'adhérent "$nom" ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(isArabic ? 'إلغاء' : 'Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(isArabic ? 'حذف' : 'Supprimer'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      setState(() => _isProcessing = true);
      try {
        final response = await http.delete(
          Uri.parse('${TrainingService.apiBaseUrl}/adherents/$id'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          _showSuccess(
            isArabic ? '✅ Adhérent supprimé' : '✅ Adhérent supprimé',
          );
          _loadAdherents();
        } else {
          _showError(
            isArabic
                ? 'Erreur lors de la suppression'
                : 'Erreur lors de la suppression',
          );
        }
      } catch (e) {
        _showError('Erreur: $e');
      } finally {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message', style: GoogleFonts.cairo()),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
      _currentPage = 0;
      _loadAdherents();
    });
  }

  String _getGenreLabel(String genre, bool isArabic) {
    if (genre == 'homme') return isArabic ? 'ذكر' : 'Homme';
    if (genre == 'femme') return isArabic ? 'أنثى' : 'Femme';
    return genre;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return AdminPageWrapper(
      title: 'Gestion des adhérents',
      titleAr: 'إدارة المنخرطين',
      backgroundColor: Colors.grey.shade50,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadAdherents,
          tooltip: isArabic ? 'تحديث' : 'Rafraîchir',
        ),
      ],
      child: Column(
        children: [
          _buildFilters(isArabic, isMobile),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _adherents.isEmpty
                    ? _buildEmptyState(isArabic)
                    : isMobile
                    ? _buildMobileCards(isArabic)
                    : _buildDesktopTable(isArabic),
          ),
          _buildPagination(isArabic, isMobile),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isArabic, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 12 : 16,
      ),
      color: Colors.white,
      child:
          isMobile
              ? Column(
                children: [
                  Row(children: [Expanded(child: _buildSearchField(isArabic))]),
                  const SizedBox(height: 8),
                  Row(children: [Expanded(child: _buildGenreFilter(isArabic))]),
                ],
              )
              : Row(
                children: [
                  Expanded(flex: 3, child: _buildSearchField(isArabic)),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _buildGenreFilter(isArabic)),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isArabic
                          ? 'الإجمالي: $_totalItems'
                          : 'Total: $_totalItems',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff0D443E),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildSearchField(bool isArabic) {
    return TextField(
      decoration: InputDecoration(
        hintText: isArabic ? '🔍 بحث...' : '🔍 Rechercher...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        isDense: true,
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon:
            _searchQuery.isNotEmpty
                ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _currentPage = 0;
                      _loadAdherents();
                    });
                  },
                )
                : null,
      ),
      onChanged: (value) {
        setState(() => _searchQuery = value);
        _currentPage = 0;
        _loadAdherents();
      },
    );
  }

  Widget _buildGenreFilter(bool isArabic) {
    final genres = [
      {'value': 'tous', 'label': isArabic ? 'الكل' : 'Tous'},
      {'value': 'homme', 'label': isArabic ? 'ذكر' : 'Homme'},
      {'value': 'femme', 'label': isArabic ? 'أنثى' : 'Femme'},
    ];

    return DropdownButtonFormField<String>(
      value: _selectedGenre,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: isArabic ? 'الجنس' : 'Genre',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        isDense: true,
        prefixIcon: const Icon(Icons.person, size: 20),
      ),
      items:
          genres.map((genre) {
            return DropdownMenuItem(
              value: genre['value'],
              child: Text(genre['label']!),
            );
          }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedGenre = value!;
          _currentPage = 0;
          _loadAdherents();
        });
      },
    );
  }

  Widget _buildEmptyState(bool isArabic) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            isArabic ? 'لا يوجد منخرطين' : 'Aucun adhérent trouvé',
            style: GoogleFonts.cairo(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            isArabic
                ? 'Essayez de modifier les filtres de recherche'
                : 'Essayez de modifier les filtres de recherche',
            style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VERSION DESKTOP - Tableau
  // ============================================================
  Widget _buildDesktopTable(bool isArabic) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(
            const Color(0xff0D443E).withOpacity(0.05),
          ),
          columnSpacing: 12,
          sortColumnIndex: _getSortColumnIndex(_sortColumn),
          sortAscending: _sortAscending,
          columns: [
            DataColumn(
              label: const Text(
                'ID',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onSort: (_, __) => _onSort('id'),
            ),
            DataColumn(
              label: Text(
                isArabic ? 'الاسم الكامل' : 'Nom complet',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onSort: (_, __) => _onSort('nom_prenom'),
            ),
            DataColumn(
              label: Text(
                isArabic ? 'واتساب' : 'WhatsApp',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onSort: (_, __) => _onSort('whatsapp'),
            ),
            DataColumn(
              label: Text(
                isArabic ? 'البريد الإلكتروني' : 'Email',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onSort: (_, __) => _onSort('email'),
            ),
            DataColumn(
              label: Text(
                isArabic ? 'الدولة' : 'Pays',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onSort: (_, __) => _onSort('pays'),
            ),
            DataColumn(
              label: Text(
                isArabic ? 'المدينة' : 'Ville',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onSort: (_, __) => _onSort('ville'),
            ),
            DataColumn(
              label: Text(
                isArabic ? 'الجنس' : 'Genre',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onSort: (_, __) => _onSort('genre'),
            ),
            DataColumn(
              label: Text(
                isArabic ? 'تاريخ التسجيل' : 'Date inscription',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                isArabic ? 'الإجراءات' : 'Actions',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows:
              _adherents.map((adherent) {
                return DataRow(
                  cells: [
                    DataCell(Text('${adherent.id}')),
                    DataCell(
                      Text(
                        adherent.nomPrenom,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    DataCell(Text(adherent.whatsapp)),
                    DataCell(Text(adherent.email)),
                    DataCell(Text(adherent.pays)),
                    DataCell(Text(adherent.ville)),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              adherent.genre == 'homme'
                                  ? Colors.blue.shade50
                                  : Colors.pink.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getGenreLabel(adherent.genre, isArabic),
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                adherent.genre == 'homme'
                                    ? Colors.blue.shade700
                                    : Colors.pink.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        adherent.createdAt != null
                            ? '${adherent.createdAt!.day}/${adherent.createdAt!.month}/${adherent.createdAt!.year}'
                            : '-',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message: isArabic ? 'تعديل' : 'Modifier',
                            child: IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Color(0xffd57653),
                                size: 20,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => EditProfilePage(
                                          adherentId: adherent.id.toString(),
                                          adherentData: adherent,
                                        ),
                                  ),
                                ).then((_) => _loadAdherents());
                              },
                            ),
                          ),
                          Tooltip(
                            message: isArabic ? 'حذف' : 'Supprimer',
                            child: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed:
                                  _isProcessing
                                      ? null
                                      : () => _deleteAdherent(
                                        adherent.id!,
                                        adherent.nomPrenom,
                                      ),
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
  // VERSION MOBILE - Cartes
  // ============================================================
  Widget _buildMobileCards(bool isArabic) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _adherents.length,
      itemBuilder: (context, index) {
        final adherent = _adherents[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        adherent.nomPrenom,
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff0D443E),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            adherent.genre == 'homme'
                                ? Colors.blue.shade50
                                : Colors.pink.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getGenreLabel(adherent.genre, isArabic),
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              adherent.genre == 'homme'
                                  ? Colors.blue.shade700
                                  : Colors.pink.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.phone_android,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(adherent.whatsapp),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.email, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        adherent.email,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text('${adherent.pays}, ${adherent.ville}'),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => EditProfilePage(
                                  adherentId: adherent.id.toString(),
                                  adherentData: adherent,
                                ),
                          ),
                        ).then((_) => _loadAdherents());
                      },
                      icon: const Icon(
                        Icons.edit,
                        color: Color(0xffd57653),
                        size: 18,
                      ),
                      label: Text(
                        isArabic ? 'تعديل' : 'Modifier',
                        style: const TextStyle(color: Color(0xffd57653)),
                      ),
                    ),
                    TextButton.icon(
                      onPressed:
                          _isProcessing
                              ? null
                              : () => _deleteAdherent(
                                adherent.id!,
                                adherent.nomPrenom,
                              ),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 18,
                      ),
                      label: Text(
                        isArabic ? 'حذف' : 'Supprimer',
                        style: const TextStyle(color: Colors.red),
                      ),
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

  // ============================================================
  // PAGINATION
  // ============================================================
  Widget _buildPagination(bool isArabic, bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child:
          isMobile
              ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed:
                        _currentPage > 0 && !_isLoading
                            ? () {
                              setState(() => _currentPage--);
                              _loadAdherents();
                            }
                            : null,
                  ),
                  Text(
                    '${_currentPage + 1} / ${_totalPages > 0 ? _totalPages : 1}',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w500),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed:
                        _currentPage < _totalPages - 1 && !_isLoading
                            ? () {
                              setState(() => _currentPage++);
                              _loadAdherents();
                            }
                            : null,
                  ),
                ],
              )
              : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_totalItems} ${isArabic ? 'منخرط' : 'adhérent(s)'}',
                    style: GoogleFonts.cairo(color: Colors.grey[600]),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed:
                            _currentPage > 0 && !_isLoading
                                ? () {
                                  setState(() => _currentPage--);
                                  _loadAdherents();
                                }
                                : null,
                      ),
                      Text(
                        '${_currentPage + 1} / ${_totalPages > 0 ? _totalPages : 1}',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w500),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed:
                            _currentPage < _totalPages - 1 && !_isLoading
                                ? () {
                                  setState(() => _currentPage++);
                                  _loadAdherents();
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
}
