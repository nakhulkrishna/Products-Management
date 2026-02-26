import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:products_catelogs/core/constants/firestore_collections.dart';

enum _StaffStatus { active, onLeave, inactive }

enum _StaffFilter { all, active, onLeave, inactive }

class _Salesman {
  final String id;
  final String name;
  final String role;
  final String region;
  final String phone;
  final String email;
  final String? imageUrl;
  final int dealsClosed;
  final double monthlyTargetQar;
  final double achievedSalesQar;
  final _StaffStatus status;

  const _Salesman({
    required this.id,
    required this.name,
    required this.role,
    required this.region,
    required this.phone,
    required this.email,
    required this.imageUrl,
    required this.dealsClosed,
    required this.monthlyTargetQar,
    required this.achievedSalesQar,
    required this.status,
  });

  _Salesman copyWith({
    String? id,
    String? name,
    String? role,
    String? region,
    String? phone,
    String? email,
    String? imageUrl,
    bool clearImage = false,
    int? dealsClosed,
    double? monthlyTargetQar,
    double? achievedSalesQar,
    _StaffStatus? status,
  }) {
    return _Salesman(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      region: region ?? this.region,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      imageUrl: clearImage ? null : (imageUrl ?? this.imageUrl),
      dealsClosed: dealsClosed ?? this.dealsClosed,
      monthlyTargetQar: monthlyTargetQar ?? this.monthlyTargetQar,
      achievedSalesQar: achievedSalesQar ?? this.achievedSalesQar,
      status: status ?? this.status,
    );
  }
}

class StaffsTabPage extends StatefulWidget {
  const StaffsTabPage({super.key});

  @override
  State<StaffsTabPage> createState() => _StaffsTabPageState();
}

class _StaffsTabPageState extends State<StaffsTabPage> {
  static const int _rowsPerPage = 13;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_QA',
    symbol: 'QAR ',
    decimalDigits: 0,
  );

  String _query = '';
  _StaffFilter _statusFilter = _StaffFilter.all;
  int _currentPage = 1;
  bool _loading = true;
  String? _loadError;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _salesmenSub;
  final Set<String> _selectedIds = <String>{};

  static const List<_Salesman> _seedSalesmen = [
    _Salesman(
      id: 'SM-001',
      name: 'Ahmed Nasser',
      role: 'Senior Salesman',
      region: 'Doha',
      phone: '+974 5112 3301',
      email: 'ahmed@redrose.com',
      imageUrl: 'https://i.pravatar.cc/120?img=12',
      dealsClosed: 21,
      monthlyTargetQar: 95000,
      achievedSalesQar: 84200,
      status: _StaffStatus.active,
    ),
    _Salesman(
      id: 'SM-002',
      name: 'Fatima Saeed',
      role: 'Sales Supervisor',
      region: 'Al Rayyan',
      phone: '+974 5543 2207',
      email: 'fatima@redrose.com',
      imageUrl: 'https://i.pravatar.cc/120?img=32',
      dealsClosed: 19,
      monthlyTargetQar: 90000,
      achievedSalesQar: 80120,
      status: _StaffStatus.active,
    ),
    _Salesman(
      id: 'SM-003',
      name: 'Omar Khalid',
      role: 'Salesman',
      region: 'Lusail',
      phone: '+974 6681 4020',
      email: 'omar@redrose.com',
      imageUrl: 'https://i.pravatar.cc/120?img=51',
      dealsClosed: 15,
      monthlyTargetQar: 70000,
      achievedSalesQar: 56200,
      status: _StaffStatus.active,
    ),
    _Salesman(
      id: 'SM-004',
      name: 'Hassan Karim',
      role: 'Salesman',
      region: 'Al Wakrah',
      phone: '+974 6611 8853',
      email: 'hassan@redrose.com',
      imageUrl: 'https://i.pravatar.cc/120?img=47',
      dealsClosed: 11,
      monthlyTargetQar: 65000,
      achievedSalesQar: 38800,
      status: _StaffStatus.onLeave,
    ),
    _Salesman(
      id: 'SM-005',
      name: 'Maryam Adel',
      role: 'Senior Salesman',
      region: 'Al Khor',
      phone: '+974 5548 7195',
      email: 'maryam@redrose.com',
      imageUrl: null,
      dealsClosed: 13,
      monthlyTargetQar: 72000,
      achievedSalesQar: 51900,
      status: _StaffStatus.active,
    ),
    _Salesman(
      id: 'SM-006',
      name: 'Yousef Ali',
      role: 'Salesman',
      region: 'Umm Salal',
      phone: '+974 7774 9921',
      email: 'yousef@redrose.com',
      imageUrl: null,
      dealsClosed: 7,
      monthlyTargetQar: 55000,
      achievedSalesQar: 23100,
      status: _StaffStatus.inactive,
    ),
    _Salesman(
      id: 'SM-007',
      name: 'Salma Rafi',
      role: 'Salesman',
      region: 'Doha',
      phone: '+974 7009 1172',
      email: 'salma@redrose.com',
      imageUrl: null,
      dealsClosed: 10,
      monthlyTargetQar: 60000,
      achievedSalesQar: 44300,
      status: _StaffStatus.active,
    ),
    _Salesman(
      id: 'SM-008',
      name: 'Khalid Fares',
      role: 'Salesman',
      region: 'Al Daayen',
      phone: '+974 6655 0823',
      email: 'khalid@redrose.com',
      imageUrl: null,
      dealsClosed: 9,
      monthlyTargetQar: 58000,
      achievedSalesQar: 36200,
      status: _StaffStatus.onLeave,
    ),
    _Salesman(
      id: 'SM-009',
      name: 'Rana Waleed',
      role: 'Sales Supervisor',
      region: 'Doha',
      phone: '+974 5088 2711',
      email: 'rana@redrose.com',
      imageUrl: null,
      dealsClosed: 17,
      monthlyTargetQar: 88000,
      achievedSalesQar: 74450,
      status: _StaffStatus.active,
    ),
    _Salesman(
      id: 'SM-010',
      name: 'Nasser Hadi',
      role: 'Salesman',
      region: 'Al Wakrah',
      phone: '+974 6001 3358',
      email: 'nasser@redrose.com',
      imageUrl: null,
      dealsClosed: 8,
      monthlyTargetQar: 56000,
      achievedSalesQar: 27500,
      status: _StaffStatus.inactive,
    ),
    _Salesman(
      id: 'SM-011',
      name: 'Aisha Nabil',
      role: 'Senior Salesman',
      region: 'Lusail',
      phone: '+974 5539 1180',
      email: 'aisha@redrose.com',
      imageUrl: null,
      dealsClosed: 16,
      monthlyTargetQar: 76000,
      achievedSalesQar: 60840,
      status: _StaffStatus.active,
    ),
    _Salesman(
      id: 'SM-012',
      name: 'Majid Karim',
      role: 'Salesman',
      region: 'Al Rayyan',
      phone: '+974 6640 2874',
      email: 'majid@redrose.com',
      imageUrl: null,
      dealsClosed: 12,
      monthlyTargetQar: 62000,
      achievedSalesQar: 41920,
      status: _StaffStatus.active,
    ),
    _Salesman(
      id: 'SM-013',
      name: 'Noor Abdel',
      role: 'Salesman',
      region: 'Doha',
      phone: '+974 5562 9941',
      email: 'noor@redrose.com',
      imageUrl: null,
      dealsClosed: 6,
      monthlyTargetQar: 52000,
      achievedSalesQar: 19750,
      status: _StaffStatus.inactive,
    ),
  ];
  final List<_Salesman> _salesmen = [];

  @override
  void initState() {
    super.initState();
    _subscribeSalesmen();
  }

  @override
  void dispose() {
    _salesmenSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _subscribeSalesmen() {
    _salesmenSub?.cancel();
    setState(() {
      _loading = true;
      _loadError = null;
    });
    _salesmenSub = _firestore
        .collection(FirestoreCollections.staffSalesmen)
        .orderBy('nameLower')
        .snapshots()
        .listen(
          (snapshot) {
            final items = snapshot.docs
                .map(_salesmanFromDoc)
                .whereType<_Salesman>()
                .toList();
            if (items.isEmpty && _seedSalesmen.isNotEmpty) {
              // Keep reference to sample data for optional future seeding tools.
            }
            if (!mounted) return;
            setState(() {
              _salesmen
                ..clear()
                ..addAll(items);
              _selectedIds.removeWhere(
                (id) => !_salesmen.any((item) => item.id == id),
              );
              if (_currentPage > _totalPages) {
                _currentPage = _totalPages;
              }
              _loading = false;
              _loadError = null;
            });
          },
          onError: (error) {
            if (!mounted) return;
            setState(() {
              _loading = false;
              _loadError = '$error';
            });
          },
        );
  }

  _Salesman? _salesmanFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return null;
    final id = _stringOr(data['id'], fallback: doc.id).trim();
    if (id.isEmpty) return null;
    return _Salesman(
      id: id,
      name: _stringOr(data['name'], fallback: 'Unknown'),
      role: _stringOr(data['role'], fallback: 'Salesman'),
      region: _stringOr(data['region'], fallback: ''),
      phone: _stringOr(data['phone'], fallback: ''),
      email: _stringOr(data['email'], fallback: ''),
      imageUrl: _nullableString(data['imageUrl']),
      dealsClosed: _intOr(data['dealsClosed']),
      monthlyTargetQar: _doubleOr(data['monthlyTargetQar']),
      achievedSalesQar: _doubleOr(data['achievedSalesQar']),
      status: _statusFromString(_stringOr(data['status'], fallback: 'active')),
    );
  }

  Future<void> _createSalesman(_Salesman salesman) async {
    final docRef = _firestore
        .collection(FirestoreCollections.staffSalesmen)
        .doc(salesman.id);
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(docRef);
      if (existing.exists) {
        throw StateError('Salesman ID already exists.');
      }
      transaction.set(docRef, _salesmanToMap(salesman, create: true));
    });
  }

  Future<void> _updateSalesman(_Salesman salesman) async {
    final docRef = _firestore
        .collection(FirestoreCollections.staffSalesmen)
        .doc(salesman.id);
    await docRef.set(_salesmanToMap(salesman), SetOptions(merge: true));
  }

  Future<void> _deleteSalesmenByIds(Set<String> ids) async {
    if (ids.isEmpty) return;
    final batch = _firestore.batch();
    for (final id in ids) {
      batch.delete(
        _firestore.collection(FirestoreCollections.staffSalesmen).doc(id),
      );
    }
    await batch.commit();
  }

  Map<String, dynamic> _salesmanToMap(_Salesman salesman, {bool create = false}) {
    final now = FieldValue.serverTimestamp();
    return {
      'id': salesman.id,
      'name': salesman.name,
      'nameLower': salesman.name.toLowerCase(),
      'role': salesman.role,
      'region': salesman.region,
      'phone': salesman.phone,
      'email': salesman.email,
      'imageUrl': salesman.imageUrl,
      'dealsClosed': salesman.dealsClosed,
      'monthlyTargetQar': salesman.monthlyTargetQar,
      'achievedSalesQar': salesman.achievedSalesQar,
      'status': _statusToString(salesman.status),
      'updatedAt': now,
      if (create) 'createdAt': now,
    };
  }

  String _stringOr(dynamic value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }

  String? _nullableString(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  int _intOr(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  double _doubleOr(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  _StaffStatus _statusFromString(String raw) {
    switch (raw.toLowerCase()) {
      case 'on_leave':
      case 'onleave':
        return _StaffStatus.onLeave;
      case 'inactive':
        return _StaffStatus.inactive;
      default:
        return _StaffStatus.active;
    }
  }

  String _statusToString(_StaffStatus status) {
    switch (status) {
      case _StaffStatus.active:
        return 'active';
      case _StaffStatus.onLeave:
        return 'on_leave';
      case _StaffStatus.inactive:
        return 'inactive';
    }
  }

  List<_Salesman> get _filteredSalesmen {
    return _salesmen.where((salesman) {
      final matchesQuery =
          _query.isEmpty ||
          salesman.id.toLowerCase().contains(_query) ||
          salesman.name.toLowerCase().contains(_query) ||
          salesman.role.toLowerCase().contains(_query) ||
          salesman.region.toLowerCase().contains(_query) ||
          salesman.phone.toLowerCase().contains(_query) ||
          salesman.email.toLowerCase().contains(_query);

      final matchesStatus =
          _statusFilter == _StaffFilter.all ||
          (_statusFilter == _StaffFilter.active &&
              salesman.status == _StaffStatus.active) ||
          (_statusFilter == _StaffFilter.onLeave &&
              salesman.status == _StaffStatus.onLeave) ||
          (_statusFilter == _StaffFilter.inactive &&
              salesman.status == _StaffStatus.inactive);

      return matchesQuery && matchesStatus;
    }).toList();
  }

  int get _totalPages {
    final pages = (_filteredSalesmen.length / _rowsPerPage).ceil();
    return pages < 1 ? 1 : pages;
  }

  List<_Salesman> get _visibleSalesmen {
    final filtered = _filteredSalesmen;
    if (filtered.isEmpty) return const [];
    final safePage = _currentPage > _totalPages ? _totalPages : _currentPage;
    final start = (safePage - 1) * _rowsPerPage;
    final end = start + _rowsPerPage > filtered.length
        ? filtered.length
        : start + _rowsPerPage;
    return filtered.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSalesmen;
    final visible = _visibleSalesmen;
    final selectedCount = filtered
        .where((salesman) => _selectedIds.contains(salesman.id))
        .length;
    final isAllSelected =
        filtered.isNotEmpty && selectedCount == filtered.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 1200;
        final isNarrow = constraints.maxWidth < 880;
        final tableWidth = constraints.maxWidth < 1480
            ? 1480.0
            : constraints.maxWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isCompact),
            const SizedBox(height: 14),
            isNarrow
                ? Column(
                    children: [
                      _buildSearchField(),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _buildFilterButton(),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: _buildSearchField()),
                      const SizedBox(width: 10),
                      _buildFilterButton(),
                    ],
                  ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                IconButton(
                  onPressed: filtered.isEmpty
                      ? null
                      : () {
                          setState(() {
                            if (isAllSelected) {
                              for (final salesman in filtered) {
                                _selectedIds.remove(salesman.id);
                              }
                            } else {
                              for (final salesman in filtered) {
                                _selectedIds.add(salesman.id);
                              }
                            }
                          });
                        },
                  icon: Icon(
                    isAllSelected
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    color: const Color(0xFF2EA8A5),
                  ),
                ),
                Text(
                  '$selectedCount Selected',
                  style: const TextStyle(
                    color: Color(0xFF2EA8A5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: filtered.isEmpty
                      ? null
                      : () {
                          setState(() {
                            for (final salesman in filtered) {
                              _selectedIds.add(salesman.id);
                            }
                          });
                        },
                  child: const Text('Select All'),
                ),
                TextButton.icon(
                  onPressed: selectedCount == 0 ? null : _deactivateSelectedStaff,
                  icon: const Icon(Iconsax.user_minus, size: 16),
                  label: const Text('Deactivate'),
                ),
                TextButton.icon(
                  onPressed: selectedCount == 0 ? null : _deleteSelectedStaff,
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Delete Selected'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _loadError != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Failed to load salesmen from Firebase.',
                              style: TextStyle(
                                color: Color(0xFFB42318),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _loadError!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: _subscribeSalesmen,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : visible.isEmpty
                    ? const Center(
                        child: Text(
                          'No staff found.',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : isCompact
                    ? _buildCardList(visible)
                    : _buildDesktopTable(visible, tableWidth),
              ),
            ),
            const SizedBox(height: 12),
            _buildPaginationFooter(totalItems: filtered.length),
          ],
        );
      },
    );
  }

  Widget _buildHeader(bool compact) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Salesman List',
                style: TextStyle(
                  fontSize: 30,
                  height: 1.1,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Monitor staff salesmen performance, targets, and status.',
                style: TextStyle(
                  color: Color(0xFF8A94A6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (!compact)
          _headerActionButton(
            onTap: _addSalesman,
            icon: Icons.add_rounded,
            label: 'Add Salesman',
            highlighted: true,
          ),
      ],
    );
  }

  Widget _headerActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    bool highlighted = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: Border.all(
            color: highlighted
                ? const Color(0xFF111827)
                : const Color(0xFFDDE2EA),
            width: highlighted ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 19, color: const Color(0xFF111827)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _query = value.trim().toLowerCase();
          _currentPage = 1;
        });
      },
      decoration: InputDecoration(
        hintText: 'Search staff',
        prefixIcon: const Icon(Icons.search_rounded),
        fillColor: const Color(0xFFFFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE2EA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE2EA)),
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return PopupMenuButton<_StaffFilter>(
      onSelected: (value) {
        setState(() {
          _statusFilter = value;
          _currentPage = 1;
        });
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: _StaffFilter.all, child: Text('All Statuses')),
        PopupMenuItem(value: _StaffFilter.active, child: Text('Active')),
        PopupMenuItem(value: _StaffFilter.onLeave, child: Text('On Leave')),
        PopupMenuItem(value: _StaffFilter.inactive, child: Text('Inactive')),
      ],
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDE2EA)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tune_rounded, size: 18),
            const SizedBox(width: 8),
            Text(switch (_statusFilter) {
              _StaffFilter.all => 'All',
              _StaffFilter.active => 'Active',
              _StaffFilter.onLeave => 'On Leave',
              _StaffFilter.inactive => 'Inactive',
            }),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTable(List<_Salesman> salesmen, double width) {
    return Column(
      children: [
        _buildTableHeader(width),
        const Divider(height: 1, color: Color(0xFFE8EBF0)),
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            child: ListView.separated(
              itemCount: salesmen.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFE8EBF0)),
              itemBuilder: (context, index) {
                final salesman = salesmen[index];
                final selected = _selectedIds.contains(salesman.id);
                return _buildTableRow(salesman, selected, width);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(double width) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        color: const Color(0xFFF8FAFC),
        child: const Row(
          children: [
            SizedBox(width: 44),
            _HeaderCell(width: 114, text: 'Staff ID'),
            _HeaderCell(width: 210, text: 'Name'),
            _HeaderCell(width: 160, text: 'Role'),
            _HeaderCell(width: 130, text: 'Region'),
            _HeaderCell(width: 238, text: 'Contact'),
            _HeaderCell(width: 130, text: 'Deals Closed'),
            _HeaderCell(width: 152, text: 'Target (QAR)'),
            _HeaderCell(width: 160, text: 'Achieved (QAR)'),
            _HeaderCell(width: 132, text: 'Status'),
            _HeaderCell(width: 132, text: 'Action'),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(_Salesman salesman, bool selected, double width) {
    final statusStyle = _statusStyle(salesman.status);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        color: selected ? const Color(0xFFF3FAFA) : Colors.white,
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Checkbox(
                value: selected,
                onChanged: (_) {
                  setState(() {
                    if (selected) {
                      _selectedIds.remove(salesman.id);
                    } else {
                      _selectedIds.add(salesman.id);
                    }
                  });
                },
              ),
            ),
            _RowCell(width: 114, text: salesman.id),
            SizedBox(
              width: 210,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: const Color(0xFFE8EDF5),
                    backgroundImage: salesman.imageUrl == null
                        ? null
                        : NetworkImage(salesman.imageUrl!),
                    child: salesman.imageUrl == null
                        ? Text(
                            _initialsOf(salesman.name),
                            style: const TextStyle(
                              color: Color(0xFF4B5563),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      salesman.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _RowCell(width: 160, text: salesman.role),
            _RowCell(width: 130, text: salesman.region),
            SizedBox(
              width: 238,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    salesman.phone,
                    style: const TextStyle(
                      color: Color(0xFF2488B7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    salesman.email,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            _RowCell(width: 130, text: salesman.dealsClosed.toString()),
            _RowCell(
              width: 152,
              text: _currency.format(salesman.monthlyTargetQar),
            ),
            _RowCell(
              width: 160,
              text: _currency.format(salesman.achievedSalesQar),
              color: const Color(0xFF1F8A70),
            ),
            SizedBox(
              width: 132,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusStyle.$1,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: statusStyle.$3),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 7, color: statusStyle.$2),
                      const SizedBox(width: 6),
                      Text(
                        statusStyle.$4,
                        style: TextStyle(
                          color: statusStyle.$2,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 132,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _editSalesman(salesman),
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Color(0xFF374151),
                    ),
                  ),
                  IconButton(
                    onPressed: salesman.imageUrl == null
                        ? null
                        : () => _removeStaffImage(salesman),
                    icon: const Icon(
                      Icons.image_not_supported_outlined,
                      size: 18,
                      color: Color(0xFFB08900),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _deleteStaff(salesman),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Color(0xFFE65A5A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardList(List<_Salesman> salesmen) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: salesmen.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final salesman = salesmen[index];
        final selected = _selectedIds.contains(salesman.id);
        final statusStyle = _statusStyle(salesman.status);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF3FAFA) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: selected,
                    onChanged: (_) {
                      setState(() {
                        if (selected) {
                          _selectedIds.remove(salesman.id);
                        } else {
                          _selectedIds.add(salesman.id);
                        }
                      });
                    },
                  ),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFFE8EDF5),
                    backgroundImage: salesman.imageUrl == null
                        ? null
                        : NetworkImage(salesman.imageUrl!),
                    child: salesman.imageUrl == null
                        ? Text(
                            _initialsOf(salesman.name),
                            style: const TextStyle(
                              color: Color(0xFF4B5563),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          salesman.name,
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          salesman.id,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusStyle.$1,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusStyle.$3),
                    ),
                    child: Text(
                      statusStyle.$4,
                      style: TextStyle(
                        color: statusStyle.$2,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _infoRow('Role', salesman.role),
              _infoRow('Region', salesman.region),
              _infoRow('Phone', salesman.phone),
              _infoRow('Email', salesman.email),
              _infoRow('Deals Closed', salesman.dealsClosed.toString()),
              _infoRow('Target', _currency.format(salesman.monthlyTargetQar)),
              _infoRow('Achieved', _currency.format(salesman.achievedSalesQar)),
              const SizedBox(height: 10),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _editSalesman(salesman),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: salesman.imageUrl == null
                        ? null
                        : () => _removeStaffImage(salesman),
                    icon: const Icon(Icons.image_not_supported_outlined, size: 16),
                    label: const Text('Delete Image'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _deleteStaff(salesman),
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text('Delete'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _toggleDeactivateStaff(salesman),
                    icon: const Icon(Iconsax.user_minus, size: 16),
                    label: Text(
                      salesman.status == _StaffStatus.inactive
                          ? 'Activate'
                          : 'Deactivate',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationFooter({required int totalItems}) {
    final totalPages = _totalPages;
    final safePage = _currentPage > totalPages ? totalPages : _currentPage;

    return Row(
      children: [
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDE2EA)),
          ),
          child: const Row(
            children: [
              Text(
                'Show: 13',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.swap_vert_rounded, size: 17),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$totalItems items',
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        _paginationButton(
          icon: Icons.arrow_back_rounded,
          enabled: safePage > 1,
          onTap: () {
            setState(() {
              if (_currentPage > 1) _currentPage--;
            });
          },
        ),
        const SizedBox(width: 8),
        Container(
          width: 42,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            safePage.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _paginationButton(
          icon: Icons.arrow_forward_rounded,
          enabled: safePage < totalPages,
          onTap: () {
            setState(() {
              if (_currentPage < totalPages) _currentPage++;
            });
          },
        ),
      ],
    );
  }

  Widget _paginationButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDE2EA)),
        ),
        child: Icon(
          icon,
          color: enabled ? const Color(0xFF111827) : const Color(0xFFBDC4D2),
        ),
      ),
    );
  }

  Future<void> _addSalesman() async {
    final created = await _showSalesmanEditorDialog();
    if (created == null) return;
    try {
      await _createSalesman(created);
      if (!mounted) return;
      setState(() => _currentPage = 1);
      _toast('Added ${created.name}.');
    } catch (error) {
      if (!mounted) return;
      _toast('Failed to add salesman: $error');
    }
  }

  Future<void> _editSalesman(_Salesman staff) async {
    final updated = await _showSalesmanEditorDialog(existing: staff);
    if (updated == null) return;
    try {
      await _updateSalesman(updated);
      if (!mounted) return;
      _toast('Updated ${updated.name}.');
    } catch (error) {
      if (!mounted) return;
      _toast('Failed to update salesman: $error');
    }
  }

  Future<void> _deactivateSelectedStaff() async {
    final ids = Set<String>.from(_selectedIds);
    if (ids.isEmpty) return;
    final confirmed = await _showRightSheet<bool>(
      title: 'Deactivate Selected',
      icon: Iconsax.user_minus,
      body: Text('Deactivate ${ids.length} selected staff member(s)?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Deactivate'),
        ),
      ],
    );
    if (confirmed != true) return;

    try {
      final batch = _firestore.batch();
      for (final id in ids) {
        batch.set(
          _firestore.collection(FirestoreCollections.staffSalesmen).doc(id),
          {
            'status': _statusToString(_StaffStatus.inactive),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
      await batch.commit();
      if (!mounted) return;
      _toast('Selected staff deactivated.');
    } catch (error) {
      if (!mounted) return;
      _toast('Failed to deactivate selected staff: $error');
    }
  }

  Future<void> _toggleDeactivateStaff(_Salesman staff) async {
    final shouldDeactivate = staff.status != _StaffStatus.inactive;
    final confirmed = await _showRightSheet<bool>(
      title: shouldDeactivate ? 'Deactivate Staff' : 'Activate Staff',
      icon: shouldDeactivate ? Iconsax.user_minus : Iconsax.user_add,
      body: Text(
        shouldDeactivate ? 'Deactivate ${staff.name}?' : 'Activate ${staff.name}?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(shouldDeactivate ? 'Deactivate' : 'Activate'),
        ),
      ],
    );
    if (confirmed != true) return;

    try {
      await _firestore
          .collection(FirestoreCollections.staffSalesmen)
          .doc(staff.id)
          .set({
            'status': _statusToString(
              shouldDeactivate ? _StaffStatus.inactive : _StaffStatus.active,
            ),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      if (!mounted) return;
      _toast(shouldDeactivate ? 'Staff deactivated.' : 'Staff activated.');
    } catch (error) {
      if (!mounted) return;
      _toast('Failed to update status: $error');
    }
  }

  Future<void> _deleteStaff(_Salesman staff) async {
    final confirmed = await _showRightSheet<bool>(
      title: 'Delete Salesman',
      icon: Icons.delete_outline_rounded,
      iconColor: const Color(0xFFE65A5A),
      body: Text(
        'Delete ${staff.name} from the salesman list?\n\nAny linked profile image will also be removed.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE65A5A)),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    );
    if (confirmed != true) return;

    try {
      await _deleteSalesmenByIds({staff.id});
      if (!mounted) return;
      _toast('Deleted ${staff.name}.');
    } catch (error) {
      if (!mounted) return;
      _toast('Failed to delete salesman: $error');
    }
  }

  Future<void> _deleteSelectedStaff() async {
    final ids = Set<String>.from(_selectedIds);
    if (ids.isEmpty) return;
    final count = ids.length;
    final confirmed = await _showRightSheet<bool>(
      title: 'Delete Selected',
      icon: Icons.delete_sweep_outlined,
      iconColor: const Color(0xFFE65A5A),
      body: Text(
        'Delete $count selected salesman account(s)?\n\nLinked images will also be removed.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE65A5A)),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    );
    if (confirmed != true) return;

    try {
      await _deleteSalesmenByIds(ids);
      if (!mounted) return;
      _toast('Deleted $count salesman account(s).');
    } catch (error) {
      if (!mounted) return;
      _toast('Failed to delete selected staff: $error');
    }
  }

  Future<void> _removeStaffImage(_Salesman staff) async {
    if (staff.imageUrl == null) return;
    final confirmed = await _showRightSheet<bool>(
      title: 'Delete Staff Image',
      icon: Icons.image_not_supported_outlined,
      iconColor: const Color(0xFFB08900),
      body: Text('Remove profile image for ${staff.name}?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete Image'),
        ),
      ],
    );
    if (confirmed != true) return;

    try {
      await _firestore
          .collection(FirestoreCollections.staffSalesmen)
          .doc(staff.id)
          .set({
            'imageUrl': null,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      if (!mounted) return;
      _toast('Image removed for ${staff.name}.');
    } catch (error) {
      if (!mounted) return;
      _toast('Failed to remove image: $error');
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  (Color, Color, Color, String) _statusStyle(_StaffStatus status) {
    switch (status) {
      case _StaffStatus.active:
        return (
          const Color(0xFFEFFAF3),
          const Color(0xFF21A453),
          const Color(0xFFD1F0DD),
          'Active',
        );
      case _StaffStatus.onLeave:
        return (
          const Color(0xFFFFF8E8),
          const Color(0xFFDD9C00),
          const Color(0xFFF8EAC6),
          'On Leave',
        );
      case _StaffStatus.inactive:
        return (
          const Color(0xFFFFEEF0),
          const Color(0xFFE44949),
          const Color(0xFFF7D5DA),
          'Inactive',
        );
    }
  }

  String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }

  Future<_Salesman?> _showSalesmanEditorDialog({_Salesman? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final roleController = TextEditingController(
      text: existing?.role ?? 'Salesman',
    );
    final regionController = TextEditingController(text: existing?.region ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final emailController = TextEditingController(text: existing?.email ?? '');
    final dealsController = TextEditingController(
      text: (existing?.dealsClosed ?? 0).toString(),
    );
    final targetController = TextEditingController(
      text: (existing?.monthlyTargetQar ?? 0).toStringAsFixed(0),
    );
    final achievedController = TextEditingController(
      text: (existing?.achievedSalesQar ?? 0).toStringAsFixed(0),
    );
    final imageUrlController = TextEditingController(
      text: existing?.imageUrl ?? '',
    );
    _StaffStatus status = existing?.status ?? _StaffStatus.active;
    final formKey = GlobalKey<FormState>();

    final result = await _showRightSheet<_Salesman>(
      title: existing == null ? 'Add Salesman' : 'Edit Salesman',
      icon: existing == null ? Icons.person_add_alt_1 : Icons.edit_outlined,
      body: StatefulBuilder(
        builder: (context, setDialogState) => Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5EAF1)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFE8EDF5),
                      backgroundImage: imageUrlController.text.trim().isEmpty
                          ? null
                          : NetworkImage(imageUrlController.text.trim()),
                      child: imageUrlController.text.trim().isEmpty
                          ? Text(
                              _initialsOf(
                                nameController.text.trim().isEmpty
                                    ? 'Staff'
                                    : nameController.text.trim(),
                              ),
                              style: const TextStyle(
                                color: Color(0xFF4B5563),
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nameController.text.trim().isEmpty
                                ? 'New Salesman'
                                : nameController.text.trim(),
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            emailController.text.trim().isEmpty
                                ? 'No email yet'
                                : emailController.text.trim(),
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _sheetSection(
                title: 'Identity',
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) =>
                          (value ?? '').trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: roleController,
                      decoration: const InputDecoration(labelText: 'Role'),
                      validator: (value) =>
                          (value ?? '').trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: regionController,
                      decoration: const InputDecoration(labelText: 'Region'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<_StaffStatus>(
                      initialValue: status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(
                          value: _StaffStatus.active,
                          child: Text('Active'),
                        ),
                        DropdownMenuItem(
                          value: _StaffStatus.onLeave,
                          child: Text('On Leave'),
                        ),
                        DropdownMenuItem(
                          value: _StaffStatus.inactive,
                          child: Text('Inactive'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => status = value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _sheetSection(
                title: 'Contact',
                child: Column(
                  children: [
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: emailController,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) {
                        final email = (value ?? '').trim();
                        if (email.isEmpty) return 'Required';
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                          return 'Invalid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: imageUrlController,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Image URL (optional)',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _sheetSection(
                title: 'Performance',
                child: Column(
                  children: [
                    TextFormField(
                      controller: dealsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Deals Closed'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: targetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Target (QAR)'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: achievedController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Achieved Sales (QAR)',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            if (!(formKey.currentState?.validate() ?? false)) return;
            final deals = int.tryParse(dealsController.text.trim()) ?? 0;
            final target = double.tryParse(targetController.text.trim()) ?? 0;
            final achieved = double.tryParse(achievedController.text.trim()) ?? 0;
            final imageUrl = imageUrlController.text.trim();
            final id = existing?.id ?? _nextSalesmanId();
            Navigator.of(context).pop(
              _Salesman(
                id: id,
                name: nameController.text.trim(),
                role: roleController.text.trim(),
                region: regionController.text.trim(),
                phone: phoneController.text.trim(),
                email: emailController.text.trim(),
                imageUrl: imageUrl.isEmpty ? null : imageUrl,
                dealsClosed: deals,
                monthlyTargetQar: target,
                achievedSalesQar: achieved,
                status: status,
              ),
            );
          },
          icon: Icon(
            existing == null ? Icons.person_add_alt_1 : Icons.check_rounded,
            size: 16,
          ),
          label: Text(existing == null ? 'Add' : 'Save'),
        ),
      ],
    );

    return result;
  }

  Widget _sheetSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EAF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  String _nextSalesmanId() {
    int maxId = 0;
    for (final salesman in _salesmen) {
      final match = RegExp(r'^SM-(\d+)$').firstMatch(salesman.id);
      if (match == null) continue;
      final value = int.tryParse(match.group(1) ?? '');
      if (value != null && value > maxId) {
        maxId = value;
      }
    }
    final next = maxId + 1;
    return 'SM-${next.toString().padLeft(3, '0')}';
  }

  Future<T?> _showRightSheet<T>({
    required String title,
    required IconData icon,
    required Widget body,
    required List<Widget> actions,
    Color iconColor = const Color(0xFF111827),
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierLabel: title,
      barrierDismissible: true,
      barrierColor: const Color(0x99000000),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.white,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
            child: SizedBox(
              width: MediaQuery.of(context).size.width > 620
                  ? 540
                  : MediaQuery.of(context).size.width * 0.92,
              height: double.infinity,
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 10, 12),
                      child: Row(
                        children: [
                          Icon(icon, size: 20, color: iconColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE5E8EE)),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                        child: body,
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE5E8EE)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: actions,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final double width;
  final String text;

  const _HeaderCell({required this.width, required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF4B5565),
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _RowCell extends StatelessWidget {
  final double width;
  final String text;
  final Color color;

  const _RowCell({
    required this.width,
    required this.text,
    this.color = const Color(0xFF1F2937),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
