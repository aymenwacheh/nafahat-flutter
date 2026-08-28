// lib/pages/adminisration/users_list_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafahat/pages/adminisration/admin_page_wrapper.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:nafahat/providers/language_provider.dart';
import 'package:nafahat/services/training_service.dart';

class UsersListPage extends StatefulWidget {
  const UsersListPage({super.key});

  @override
  State<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  bool _isProcessing = false;

  // Filtres
  String _searchQuery = '';
  String _selectedRole = 'tous';

  // Pagination
  int _currentPage = 0;
  final int _itemsPerPage = 20;
  int _totalItems = 0;
  int _totalPages = 1;

  // Tri
  String _sortColumn = 'id';
  bool _sortAscending = false;

  // Liste des rôles disponibles
  List<String> _availableRoles = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  // ✅ Méthode pour mapper les colonnes triables
  int? _getSortColumnIndex(String column) {
    final columns = ['id', 'nom_prenom', 'role_libelle', 'whatsapp', 'email'];
    final index = columns.indexOf(column);
    return index >= 0 ? index : null; // Retourne null si non trouvé
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
          '${TrainingService.apiBaseUrl}/admin/users?page=${_currentPage + 1}&limit=$_itemsPerPage&search=$_searchQuery&role=$_selectedRole&sort=$_sortColumn&order=${_sortAscending ? 'asc' : 'desc'}',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _users = List<Map<String, dynamic>>.from(data['data'] ?? []);
          _totalItems = data['count'] ?? 0;
          _totalPages = data['totalPages'] ?? 1;
          _availableRoles = List<String>.from(data['roles'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showError('Erreur de chargement des utilisateurs');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur: $e');
    }
  }

  Future<void> _deleteUser(int userId) async {
    final isArabic =
        Provider.of<LanguageProvider>(context, listen: false).isArabic;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isArabic ? 'تأكيد الحذف' : 'Confirmer la suppression'),
            content: Text(
              isArabic
                  ? 'Êtes-vous sûr de vouloir supprimer cet utilisateur ?'
                  : 'Êtes-vous sûr de vouloir supprimer cet utilisateur ?',
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
          Uri.parse('${TrainingService.apiBaseUrl}/admin/users/$userId'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          _showSuccess(
            isArabic ? '✅ Utilisateur supprimé' : '✅ Utilisateur supprimé',
          );
          _loadUsers();
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

  Future<void> _toggleUserStatus(int userId, bool isActive) async {
    final isArabic =
        Provider.of<LanguageProvider>(context, listen: false).isArabic;

    setState(() => _isProcessing = true);
    try {
      final response = await http.put(
        Uri.parse('${TrainingService.apiBaseUrl}/admin/users/$userId/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'active': !isActive}),
      );

      if (response.statusCode == 200) {
        _showSuccess(
          isArabic
              ? (isActive ? '✅ Utilisateur désactivé' : '✅ Utilisateur activé')
              : (isActive ? '✅ Utilisateur désactivé' : '✅ Utilisateur activé'),
        );
        _loadUsers();
      } else {
        _showError(
          isArabic
              ? 'Erreur lors du changement de statut'
              : 'Erreur lors du changement de statut',
        );
      }
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      setState(() => _isProcessing = false);
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
      _loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return AdminPageWrapper(
      title: 'Liste des utilisateurs',
      titleAr: 'قائمة المستعملين',
      backgroundColor: Colors.grey.shade50,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadUsers,
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
                    : _users.isEmpty
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
                  Row(children: [Expanded(child: _buildRoleFilter(isArabic))]),
                ],
              )
              : Row(
                children: [
                  Expanded(flex: 3, child: _buildSearchField(isArabic)),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _buildRoleFilter(isArabic)),
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
                      _loadUsers();
                    });
                  },
                )
                : null,
      ),
      onChanged: (value) {
        setState(() => _searchQuery = value);
        _currentPage = 0;
        _loadUsers();
      },
    );
  }

  Widget _buildRoleFilter(bool isArabic) {
    final roles = ['tous', ..._availableRoles];
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: isArabic ? 'الدور' : 'Rôle',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        isDense: true,
        prefixIcon: const Icon(Icons.admin_panel_settings_rounded, size: 20),
      ),
      items:
          roles.map((role) {
            final label = role == 'tous' ? (isArabic ? 'الكل' : 'Tous') : role;
            return DropdownMenuItem(value: role, child: Text(label));
          }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedRole = value!;
          _currentPage = 0;
          _loadUsers();
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
            isArabic ? 'لا يوجد مستخدمين' : 'Aucun utilisateur trouvé',
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
          columnSpacing: 20,
          // ✅ CORRECTION ICI
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
                isArabic ? 'الدور' : 'Rôle',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onSort: (_, __) => _onSort('role_libelle'),
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
                isArabic ? 'الحالة' : 'Statut',
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
              _users.map((user) {
                // ✅ Correction: conversion int -> bool
                final isActive = (user['active'] ?? 1) == 1;
                final roleName =
                    user['role_libelle'] ?? user['role_nom'] ?? 'N/A';
                return DataRow(
                  color: WidgetStatePropertyAll(
                    isActive
                        ? Colors.transparent
                        : Colors.red.withOpacity(0.03),
                  ),
                  cells: [
                    DataCell(Text('${user['id']}')),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['nom_prenom'] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: isActive ? null : Colors.grey[600],
                            ),
                          ),
                          if (!isActive)
                            Text(
                              isArabic ? 'غير نشط' : 'Inactif',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          roleName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(user['whatsapp'] ?? '')),
                    DataCell(Text(user['email'] ?? '')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isActive
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isActive ? '✅ Actif' : '❌ Inactif',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isActive
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message:
                                isActive
                                    ? (isArabic ? 'تعطيل' : 'Désactiver')
                                    : (isArabic ? 'تفعيل' : 'Activer'),
                            child: IconButton(
                              icon: Icon(
                                isActive ? Icons.block : Icons.check_circle,
                                color:
                                    isActive
                                        ? Colors.orange.shade700
                                        : Colors.green.shade700,
                                size: 20,
                              ),
                              onPressed:
                                  _isProcessing
                                      ? null
                                      : () => _toggleUserStatus(
                                        user['id'],
                                        isActive,
                                      ),
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
                                      : () => _deleteUser(user['id']),
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
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        // ✅ Correction: conversion int -> bool
        final isActive = (user['active'] ?? 1) == 1;
        final roleName = user['role_libelle'] ?? user['role_nom'] ?? 'N/A';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: isActive ? Colors.white : Colors.grey.shade50,
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
                        user['nom_prenom'] ?? 'Sans nom',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              isActive
                                  ? const Color(0xff0D443E)
                                  : Colors.grey[600],
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
                            isActive
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isActive ? '✅ Actif' : '❌ Inactif',
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              isActive
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        roleName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.phone_android,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(user['whatsapp'] ?? ''),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.email, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        user['email'] ?? '',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed:
                          _isProcessing
                              ? null
                              : () => _toggleUserStatus(user['id'], isActive),
                      icon: Icon(
                        isActive ? Icons.block : Icons.check_circle,
                        color:
                            isActive
                                ? Colors.orange.shade700
                                : Colors.green.shade700,
                        size: 18,
                      ),
                      label: Text(
                        isActive
                            ? (isArabic ? 'تعطيل' : 'Désactiver')
                            : (isArabic ? 'تفعيل' : 'Activer'),
                        style: TextStyle(
                          color:
                              isActive
                                  ? Colors.orange.shade700
                                  : Colors.green.shade700,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed:
                          _isProcessing ? null : () => _deleteUser(user['id']),
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
                              _loadUsers();
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
                              _loadUsers();
                            }
                            : null,
                  ),
                ],
              )
              : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_totalItems} ${isArabic ? 'مستخدم' : 'utilisateur(s)'}',
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
                                  _loadUsers();
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
                                  _loadUsers();
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
