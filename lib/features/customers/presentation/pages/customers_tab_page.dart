import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:products_catelogs/core/constants/firestore_collections.dart';

enum _CustomerStatus { active, inactive }

enum _CustomerFilter { all, active, inactive }

enum _CustomerAction { view, edit, toggleStatus, delete }

class _Customer {
  final String id;
  final String name;
  final String phone;
  final String whatsapp;
  final String email;
  final String region;
  final String address;
  final _CustomerStatus status;

  const _Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.whatsapp,
    required this.email,
    required this.region,
    required this.address,
    required this.status,
  });

  _Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? whatsapp,
    String? email,
    String? region,
    String? address,
    _CustomerStatus? status,
  }) {
    return _Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      region: region ?? this.region,
      address: address ?? this.address,
      status: status ?? this.status,
    );
  }
}

class CustomersTabPage extends StatefulWidget {
  const CustomersTabPage({super.key});

  @override
  State<CustomersTabPage> createState() => _CustomersTabPageState();
}

class _CustomersTabPageState extends State<CustomersTabPage> {
  static const int _rowsPerPage = 12;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final List<_Customer> _customers = <_Customer>[];
  final Set<String> _selectedIds = <String>{};

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _customersSub;
  String _query = '';
  _CustomerFilter _statusFilter = _CustomerFilter.all;
  int _currentPage = 1;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _subscribeCustomers();
  }

  @override
  void dispose() {
    _customersSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _subscribeCustomers() {
    _customersSub?.cancel();
    setState(() {
      _loading = true;
      _loadError = null;
    });
    _customersSub = _firestore
        .collection(FirestoreCollections.customers)
        .orderBy('nameLower')
        .snapshots()
        .listen(
          (snapshot) {
            final items = snapshot.docs
                .map(_customerFromDoc)
                .whereType<_Customer>()
                .toList();
            if (!mounted) return;
            setState(() {
              _customers
                ..clear()
                ..addAll(items);
              _selectedIds.removeWhere(
                (id) => !_customers.any((customer) => customer.id == id),
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

  _Customer? _customerFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return null;
    final id = _stringOr(data['id'], fallback: doc.id).trim();
    if (id.isEmpty) return null;
    return _Customer(
      id: id,
      name: _stringOr(data['name'], fallback: 'Unknown Customer'),
      phone: _stringOr(data['phone']),
      whatsapp: _stringOr(data['whatsapp']),
      email: _stringOr(data['email']),
      region: _stringOr(data['region']),
      address: _stringOr(data['address']),
      status: _statusFromString(_stringOr(data['status'], fallback: 'active')),
    );
  }

  List<_Customer> get _filteredCustomers {
    return _customers.where((customer) {
      final matchesQuery =
          _query.isEmpty ||
          customer.id.toLowerCase().contains(_query) ||
          customer.name.toLowerCase().contains(_query) ||
          customer.phone.toLowerCase().contains(_query) ||
          customer.email.toLowerCase().contains(_query) ||
          customer.region.toLowerCase().contains(_query);

      final matchesStatus =
          _statusFilter == _CustomerFilter.all ||
          (_statusFilter == _CustomerFilter.active &&
              customer.status == _CustomerStatus.active) ||
          (_statusFilter == _CustomerFilter.inactive &&
              customer.status == _CustomerStatus.inactive);
      return matchesQuery && matchesStatus;
    }).toList();
  }

  int get _totalPages {
    final pages = (_filteredCustomers.length / _rowsPerPage).ceil();
    return pages < 1 ? 1 : pages;
  }

  List<_Customer> get _visibleCustomers {
    final filtered = _filteredCustomers;
    if (filtered.isEmpty) return const [];
    final safePage = _currentPage > _totalPages ? _totalPages : _currentPage;
    final start = (safePage - 1) * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCustomers;
    final visible = _visibleCustomers;
    final selectedCount = filtered
        .where((customer) => _selectedIds.contains(customer.id))
        .length;
    final isAllSelected =
        filtered.isNotEmpty && selectedCount == filtered.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 1180;
        final isNarrow = constraints.maxWidth < 860;
        final tableWidth = constraints.maxWidth < 1360
            ? 1360.0
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
                              for (final customer in filtered) {
                                _selectedIds.remove(customer.id);
                              }
                            } else {
                              for (final customer in filtered) {
                                _selectedIds.add(customer.id);
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
                TextButton.icon(
                  onPressed: selectedCount == 0 ? null : _deactivateSelected,
                  icon: const Icon(Iconsax.user_minus, size: 16),
                  label: const Text('Deactivate'),
                ),
                TextButton.icon(
                  onPressed: selectedCount == 0 ? null : _deleteSelected,
                  icon: const Icon(Iconsax.trash, size: 16),
                  label: const Text('Delete'),
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
                    ? _errorState()
                    : visible.isEmpty
                    ? const Center(
                        child: Text(
                          'No customers found.',
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
                'Customers',
                style: TextStyle(
                  fontSize: 30,
                  height: 1.1,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage customer directory from backend with full CRUD operations.',
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
            onTap: _addCustomer,
            icon: Icons.add_rounded,
            label: 'Add Customer',
            highlighted: true,
          ),
      ],
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
        hintText: 'Search customers',
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
    return PopupMenuButton<_CustomerFilter>(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 8,
      shadowColor: const Color(0x1A0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      offset: const Offset(0, 42),
      onSelected: (value) {
        setState(() {
          _statusFilter = value;
          _currentPage = 1;
        });
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: _CustomerFilter.all, child: Text('All Statuses')),
        PopupMenuItem(value: _CustomerFilter.active, child: Text('Active')),
        PopupMenuItem(value: _CustomerFilter.inactive, child: Text('Inactive')),
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
              _CustomerFilter.all => 'All',
              _CustomerFilter.active => 'Active',
              _CustomerFilter.inactive => 'Inactive',
            }),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTable(List<_Customer> customers, double width) {
    return Column(
      children: [
        _buildTableHeader(width),
        const Divider(height: 1, color: Color(0xFFE8EBF0)),
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            child: ListView.separated(
              itemCount: customers.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFE8EBF0)),
              itemBuilder: (context, index) {
                final customer = customers[index];
                final selected = _selectedIds.contains(customer.id);
                return _buildTableRow(customer, selected, width);
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
            _HeaderCell(width: 130, text: 'Customer ID'),
            _HeaderCell(width: 240, text: 'Name'),
            _HeaderCell(width: 250, text: 'Contact'),
            _HeaderCell(width: 140, text: 'Region'),
            _HeaderCell(width: 340, text: 'Address'),
            _HeaderCell(width: 130, text: 'Status'),
            _HeaderCell(width: 120, text: 'Action'),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(_Customer customer, bool selected, double width) {
    final statusStyle = _statusStyle(customer.status);
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
                      _selectedIds.remove(customer.id);
                    } else {
                      _selectedIds.add(customer.id);
                    }
                  });
                },
              ),
            ),
            _RowCell(width: 130, text: customer.id),
            SizedBox(
              width: 240,
              child: Text(
                customer.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              width: 250,
              child: Text(
                '${customer.phone} • ${customer.email}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            _RowCell(width: 140, text: customer.region),
            _RowCell(width: 340, text: customer.address),
            SizedBox(
              width: 130,
              child: _statusChip(
                label: statusStyle.$4,
                textColor: statusStyle.$2,
                background: statusStyle.$1,
                borderColor: statusStyle.$3,
              ),
            ),
            SizedBox(width: 120, child: _buildCustomerActionMenu(customer)),
          ],
        ),
      ),
    );
  }

  Widget _buildCardList(List<_Customer> customers) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: customers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final customer = customers[index];
        final selected = _selectedIds.contains(customer.id);
        final statusStyle = _statusStyle(customer.status);
        return Container(
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
                          _selectedIds.remove(customer.id);
                        } else {
                          _selectedIds.add(customer.id);
                        }
                      });
                    },
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          customer.id,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusChip(
                    label: statusStyle.$4,
                    textColor: statusStyle.$2,
                    background: statusStyle.$1,
                    borderColor: statusStyle.$3,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _infoRow('Phone', customer.phone),
              _infoRow('WhatsApp', customer.whatsapp),
              _infoRow('Email', customer.email),
              _infoRow('Region', customer.region),
              _infoRow('Address', customer.address),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: _buildCustomerActionMenu(customer),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomerActionMenu(_Customer customer) {
    final isInactive = customer.status == _CustomerStatus.inactive;
    return Align(
      alignment: Alignment.centerLeft,
      child: PopupMenuButton<_CustomerAction>(
        tooltip: 'Customer options',
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 8,
        shadowColor: const Color(0x1A0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        offset: const Offset(0, 42),
        icon: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFDDE2EA)),
          ),
          child: const Icon(Iconsax.setting, size: 18, color: Color(0xFF4B5563)),
        ),
        onSelected: (action) => _handleCustomerAction(customer, action),
        itemBuilder: (context) => [
          const PopupMenuItem<_CustomerAction>(
            value: _CustomerAction.view,
            child: Row(
              children: [
                Icon(Iconsax.monitor, size: 18, color: Color(0xFF2277B8)),
                SizedBox(width: 10),
                Text('View'),
              ],
            ),
          ),
          const PopupMenuItem<_CustomerAction>(
            value: _CustomerAction.edit,
            child: Row(
              children: [
                Icon(Iconsax.setting, size: 18, color: Color(0xFF374151)),
                SizedBox(width: 10),
                Text('Edit'),
              ],
            ),
          ),
          PopupMenuItem<_CustomerAction>(
            value: _CustomerAction.toggleStatus,
            child: Row(
              children: [
                Icon(
                  isInactive ? Iconsax.user_add : Iconsax.user_minus,
                  size: 18,
                  color: const Color(0xFF2EA8A5),
                ),
                const SizedBox(width: 10),
                Text(isInactive ? 'Activate' : 'Deactivate'),
              ],
            ),
          ),
          const PopupMenuItem<_CustomerAction>(
            value: _CustomerAction.delete,
            child: Row(
              children: [
                Icon(Iconsax.trash, size: 18, color: Color(0xFFE65A5A)),
                SizedBox(width: 10),
                Text('Delete'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCustomerAction(
    _Customer customer,
    _CustomerAction action,
  ) async {
    switch (action) {
      case _CustomerAction.view:
        await _viewCustomer(customer);
        break;
      case _CustomerAction.edit:
        await _editCustomer(customer);
        break;
      case _CustomerAction.toggleStatus:
        await _toggleCustomerStatus(customer);
        break;
      case _CustomerAction.delete:
        await _deleteCustomer(customer);
        break;
    }
  }

  Future<void> _viewCustomer(_Customer customer) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Customer details',
      barrierColor: const Color(0x400F172A),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, _, __) {
        final width = MediaQuery.of(context).size.width;
        final sheetWidth = width > 1080 ? 460.0 : (width > 720 ? 420.0 : width);
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.white,
            child: SafeArea(
              child: SizedBox(
                width: sheetWidth,
                height: double.infinity,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Customer ${customer.id}',
                              style: const TextStyle(
                                color: Color(0xFF111827),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Iconsax.close_circle, size: 20),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(18),
                        children: [
                          _customerDetailRow('Name', customer.name),
                          _customerDetailRow('Phone', customer.phone),
                          _customerDetailRow('WhatsApp', customer.whatsapp),
                          _customerDetailRow('Email', customer.email),
                          _customerDetailRow('Region', customer.region),
                          _customerDetailRow('Address', customer.address),
                          _customerDetailRow(
                            'Status',
                            _statusStyle(customer.status).$4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
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

  Widget _customerDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleCustomerStatus(_Customer customer) async {
    final activate = customer.status == _CustomerStatus.inactive;
    final next = activate ? _CustomerStatus.active : _CustomerStatus.inactive;
    final shouldProceed = await _showConfirmSideSheet(
      title: activate ? 'Activate Customer' : 'Deactivate Customer',
      message: '${activate ? 'Activate' : 'Deactivate'} customer ${customer.id}?',
      confirmLabel: activate ? 'Activate' : 'Deactivate',
    );
    if (shouldProceed != true) return;

    try {
      await _firestore
          .collection(FirestoreCollections.customers)
          .doc(customer.id)
          .set({
            'status': _statusToString(next),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      if (!mounted) return;
      _toast(
        activate
            ? 'Customer ${customer.id} activated.'
            : 'Customer ${customer.id} deactivated.',
      );
    } catch (error) {
      if (!mounted) return;
      _toast('Failed to update customer status: $error');
    }
  }

  Widget _buildPaginationFooter({required int totalItems}) {
    final totalPages = _totalPages;
    final safePage = _currentPage > totalPages ? totalPages : _currentPage;
    return Row(
      children: [
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

  Widget _statusChip({
    required String label,
    required Color textColor,
    required Color background,
    required Color borderColor,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Failed to load customers from Firebase.',
            style: TextStyle(
              color: Color(0xFFB42318),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _loadError ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _subscribeCustomers,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 88,
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

  Future<void> _addCustomer() async {
    final created = await _showCustomerEditor();
    if (created == null) return;
    try {
      await _createCustomer(created);
      if (!mounted) return;
      _toast('Customer ${created.id} created.');
    } catch (error) {
      if (!mounted) return;
      _toast('Failed to create customer: $error');
    }
  }

  Future<void> _editCustomer(_Customer customer) async {
    final updated = await _showCustomerEditor(initial: customer);
    if (updated == null) return;
    try {
      await _updateCustomer(updated);
      if (!mounted) return;
      _toast('Customer ${updated.id} updated.');
    } catch (error) {
      if (!mounted) return;
      _toast('Failed to update customer: $error');
    }
  }

  Future<void> _deleteCustomer(_Customer customer) async {
    final shouldDelete = await _showConfirmSideSheet(
      title: 'Delete Customer',
      message: 'Delete customer ${customer.id}?',
      confirmLabel: 'Delete',
    );
    if (shouldDelete != true) return;
    try {
      await _deleteCustomersByIds({customer.id});
      if (!mounted) return;
      _toast('Customer ${customer.id} deleted.');
    } catch (error) {
      if (!mounted) return;
      _toast('Failed to delete customer: $error');
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final ids = Set<String>.from(_selectedIds);
    final shouldDelete = await _showConfirmSideSheet(
      title: 'Delete Selected Customers',
      message: 'Delete ${ids.length} selected customer(s)?',
      confirmLabel: 'Delete',
    );
    if (shouldDelete != true) return;
    try {
      await _deleteCustomersByIds(ids);
      if (!mounted) return;
      setState(() => _selectedIds.clear());
      _toast('Deleted ${ids.length} customer(s).');
    } catch (error) {
      if (!mounted) return;
      _toast('Failed to delete selected customers: $error');
    }
  }

  Future<void> _deactivateSelected() async {
    final ids = Set<String>.from(_selectedIds);
    if (ids.isEmpty) return;
    try {
      final batch = _firestore.batch();
      for (final id in ids) {
        batch.set(
          _firestore.collection(FirestoreCollections.customers).doc(id),
          {'status': 'inactive', 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
      }
      await batch.commit();
      if (!mounted) return;
      _toast('Deactivated ${ids.length} customer(s).');
    } catch (error) {
      if (!mounted) return;
      _toast('Failed to deactivate selected customers: $error');
    }
  }

  Future<_Customer?> _showCustomerEditor({_Customer? initial}) async {
    final isEditing = initial != null;
    final idController = TextEditingController(text: initial?.id ?? '');
    final nameController = TextEditingController(text: initial?.name ?? '');
    final phoneController = TextEditingController(text: initial?.phone ?? '');
    final whatsappController = TextEditingController(
      text: initial?.whatsapp ?? '',
    );
    final emailController = TextEditingController(text: initial?.email ?? '');
    final regionController = TextEditingController(text: initial?.region ?? '');
    final addressController = TextEditingController(
      text: initial?.address ?? '',
    );
    var status = initial?.status ?? _CustomerStatus.active;

    return showGeneralDialog<_Customer>(
      context: context,
      barrierLabel: 'customer-editor',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, _, __) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: Colors.white,
                child: SizedBox(
                  width: 440,
                  height: double.infinity,
                  child: SafeArea(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 14, 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  isEditing ? 'Edit Customer' : 'Add Customer',
                                  style: const TextStyle(
                                    fontSize: 20,
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
                        const Divider(height: 1),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                TextField(
                                  controller: idController,
                                  enabled: !isEditing,
                                  decoration: const InputDecoration(
                                    labelText: 'Customer ID',
                                    hintText: 'CUST-1001',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Name',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: phoneController,
                                  decoration: const InputDecoration(
                                    labelText: 'Phone',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: whatsappController,
                                  decoration: const InputDecoration(
                                    labelText: 'WhatsApp',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: emailController,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: regionController,
                                  decoration: const InputDecoration(
                                    labelText: 'Region',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: addressController,
                                  maxLines: 2,
                                  decoration: const InputDecoration(
                                    labelText: 'Address',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<_CustomerStatus>(
                                  initialValue: status,
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setSheetState(() => status = value);
                                  },
                                  items: const [
                                    DropdownMenuItem(
                                      value: _CustomerStatus.active,
                                      child: Text('Active'),
                                    ),
                                    DropdownMenuItem(
                                      value: _CustomerStatus.inactive,
                                      child: Text('Inactive'),
                                    ),
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Status',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () {
                                    final id = idController.text.trim();
                                    final name = nameController.text.trim();
                                    if (id.isEmpty || name.isEmpty) {
                                      _toast(
                                        'Customer ID and Name are required.',
                                      );
                                      return;
                                    }
                                    Navigator.of(context).pop(
                                      _Customer(
                                        id: id,
                                        name: name,
                                        phone: phoneController.text.trim(),
                                        whatsapp: whatsappController.text
                                            .trim(),
                                        email: emailController.text.trim(),
                                        region: regionController.text.trim(),
                                        address: addressController.text.trim(),
                                        status: status,
                                      ),
                                    );
                                  },
                                  child: Text(isEditing ? 'Save' : 'Create'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (context, animation, _, child) {
        final offset = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(position: offset, child: child);
      },
    );
  }

  Future<void> _createCustomer(_Customer customer) async {
    final docRef = _firestore
        .collection(FirestoreCollections.customers)
        .doc(customer.id);
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(docRef);
      if (existing.exists) {
        throw StateError('Customer ID already exists.');
      }
      transaction.set(docRef, _customerToMap(customer, create: true));
    });
  }

  Future<void> _updateCustomer(_Customer customer) async {
    await _firestore
        .collection(FirestoreCollections.customers)
        .doc(customer.id)
        .set(_customerToMap(customer), SetOptions(merge: true));
  }

  Future<void> _deleteCustomersByIds(Set<String> ids) async {
    final batch = _firestore.batch();
    for (final id in ids) {
      batch.delete(
        _firestore.collection(FirestoreCollections.customers).doc(id),
      );
    }
    await batch.commit();
  }

  Map<String, dynamic> _customerToMap(
    _Customer customer, {
    bool create = false,
  }) {
    final now = FieldValue.serverTimestamp();
    return {
      'id': customer.id,
      'name': customer.name,
      'nameLower': customer.name.toLowerCase(),
      'phone': customer.phone,
      'whatsapp': customer.whatsapp,
      'email': customer.email,
      'region': customer.region,
      'address': customer.address,
      'status': _statusToString(customer.status),
      'updatedAt': now,
      if (create) 'createdAt': now,
    };
  }

  String _stringOr(dynamic value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }

  _CustomerStatus _statusFromString(String raw) {
    switch (raw.toLowerCase()) {
      case 'inactive':
        return _CustomerStatus.inactive;
      default:
        return _CustomerStatus.active;
    }
  }

  String _statusToString(_CustomerStatus status) {
    switch (status) {
      case _CustomerStatus.active:
        return 'active';
      case _CustomerStatus.inactive:
        return 'inactive';
    }
  }

  (Color, Color, Color, String) _statusStyle(_CustomerStatus status) {
    switch (status) {
      case _CustomerStatus.active:
        return (
          const Color(0xFFEFFAF3),
          const Color(0xFF21A453),
          const Color(0xFFD1F0DD),
          'Active',
        );
      case _CustomerStatus.inactive:
        return (
          const Color(0xFFFFEEF0),
          const Color(0xFFE44949),
          const Color(0xFFF7D5DA),
          'Inactive',
        );
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool?> _showConfirmSideSheet({
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: title,
      barrierColor: const Color(0x400F172A),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, _, __) {
        final width = MediaQuery.of(context).size.width;
        final sheetWidth = width > 1080 ? 460.0 : (width > 720 ? 420.0 : width);
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.white,
            child: SafeArea(
              child: SizedBox(
                width: sheetWidth,
                height: double.infinity,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Color(0xFF111827),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            icon: const Icon(Iconsax.close_circle, size: 20),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          message,
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(confirmLabel),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
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

  const _RowCell({required this.width, required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF1F2937),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
