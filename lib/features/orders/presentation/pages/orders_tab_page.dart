import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:products_catelogs/core/constants/firestore_collections.dart';

enum _OrderStatus { delivered, processing, cancelled }

enum _PaymentStatus { paid, pending, partial, failed }

enum _OrderFilter { all, delivered, processing, cancelled }

enum _OrderAction { updatePaid, updateStatus, view, delete }

class _Order {
  final String docId;
  final String id;
  final String customerName;
  final String salesmanName;
  final DateTime orderDate;
  final int itemsCount;
  final String channel;
  final double amountQar;
  final double collectedAmountQar;
  final String paymentMethod;
  final _PaymentStatus paymentStatus;
  final _OrderStatus orderStatus;

  const _Order({
    this.docId = '',
    required this.id,
    required this.customerName,
    required this.salesmanName,
    required this.orderDate,
    required this.itemsCount,
    required this.channel,
    required this.amountQar,
    this.collectedAmountQar = 0,
    this.paymentMethod = 'Not set',
    required this.paymentStatus,
    required this.orderStatus,
  });
}

class _CustomerRecord {
  final String id;
  final String name;

  const _CustomerRecord({required this.id, required this.name});
}

class _ProductRecordLite {
  final String code;
  final String name;
  final double availableQtyBaseUnit;
  final String baseUnit;
  final List<_SaleUnitLite> saleUnits;
  final Map<String, _PriceForUnit> priceByUnitKey;

  const _ProductRecordLite({
    required this.code,
    required this.name,
    required this.availableQtyBaseUnit,
    required this.baseUnit,
    required this.saleUnits,
    required this.priceByUnitKey,
  });
}

class _SaleUnitLite {
  final String name;
  final double conversionToBaseUnit;

  const _SaleUnitLite({required this.name, required this.conversionToBaseUnit});
}

class _PriceForUnit {
  final double? autoPriceQar;
  final double? autoOfferPriceQar;
  final double? manualPriceQar;
  final double? manualOfferPriceQar;

  const _PriceForUnit({
    required this.autoPriceQar,
    required this.autoOfferPriceQar,
    required this.manualPriceQar,
    required this.manualOfferPriceQar,
  });

  double resolvedPrice() {
    return manualOfferPriceQar ??
        autoOfferPriceQar ??
        manualPriceQar ??
        autoPriceQar ??
        0;
  }
}

class _OrderLineInput {
  _ProductRecordLite product;
  String unitName;
  double quantity;

  _OrderLineInput({
    required this.product,
    required this.unitName,
    this.quantity = 1,
  });
}

class _OrderDraftResult {
  final _CustomerRecord customer;
  final String channel;
  final String paymentMethod;
  final double collectedAmountQar;
  final List<_OrderLineInput> lines;

  const _OrderDraftResult({
    required this.customer,
    required this.channel,
    required this.paymentMethod,
    required this.collectedAmountQar,
    required this.lines,
  });
}

class OrdersTabPage extends StatefulWidget {
  const OrdersTabPage({super.key});

  @override
  State<OrdersTabPage> createState() => _OrdersTabPageState();
}

class _OrdersTabPageState extends State<OrdersTabPage> {
  static const int _rowsPerPage = 13;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_QA',
    symbol: 'QAR ',
    decimalDigits: 0,
  );
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  String _query = '';
  _OrderFilter _statusFilter = _OrderFilter.all;
  int _currentPage = 1;
  bool _loading = true;
  String? _loadError;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ordersSub;
  final Set<String> _selectedIds = <String>{};
  bool _creatingOrder = false;

  static final List<_Order> _orders = [
    _Order(
      id: 'ORD-5201',
      customerName: 'Al Noor Trading',
      salesmanName: 'Ahmed Nasser',
      orderDate: DateTime(2026, 2, 24),
      itemsCount: 8,
      channel: 'Website',
      amountQar: 48200,
      paymentStatus: _PaymentStatus.paid,
      orderStatus: _OrderStatus.delivered,
    ),
    _Order(
      id: 'ORD-5202',
      customerName: 'Modern Build Co.',
      salesmanName: 'Fatima Saeed',
      orderDate: DateTime(2026, 2, 24),
      itemsCount: 5,
      channel: 'WhatsApp',
      amountQar: 21950,
      paymentStatus: _PaymentStatus.pending,
      orderStatus: _OrderStatus.processing,
    ),
    _Order(
      id: 'ORD-5203',
      customerName: 'Qatar Fitout',
      salesmanName: 'Omar Khalid',
      orderDate: DateTime(2026, 2, 23),
      itemsCount: 11,
      channel: 'Sales Call',
      amountQar: 39600,
      paymentStatus: _PaymentStatus.paid,
      orderStatus: _OrderStatus.delivered,
    ),
    _Order(
      id: 'ORD-5204',
      customerName: 'Prime Interiors',
      salesmanName: 'Hassan Karim',
      orderDate: DateTime(2026, 2, 23),
      itemsCount: 4,
      channel: 'Instagram',
      amountQar: 12890,
      paymentStatus: _PaymentStatus.failed,
      orderStatus: _OrderStatus.cancelled,
    ),
    _Order(
      id: 'ORD-5205',
      customerName: 'Doha Smart Living',
      salesmanName: 'Maryam Adel',
      orderDate: DateTime(2026, 2, 22),
      itemsCount: 7,
      channel: 'Website',
      amountQar: 26400,
      paymentStatus: _PaymentStatus.pending,
      orderStatus: _OrderStatus.processing,
    ),
    _Order(
      id: 'ORD-5206',
      customerName: 'Vertex Projects',
      salesmanName: 'Ahmed Nasser',
      orderDate: DateTime(2026, 2, 22),
      itemsCount: 9,
      channel: 'Email',
      amountQar: 55840,
      paymentStatus: _PaymentStatus.paid,
      orderStatus: _OrderStatus.delivered,
    ),
    _Order(
      id: 'ORD-5207',
      customerName: 'Al Dana Contracting',
      salesmanName: 'Fatima Saeed',
      orderDate: DateTime(2026, 2, 21),
      itemsCount: 3,
      channel: 'Showroom',
      amountQar: 10900,
      paymentStatus: _PaymentStatus.paid,
      orderStatus: _OrderStatus.delivered,
    ),
    _Order(
      id: 'ORD-5208',
      customerName: 'Urban Form Studio',
      salesmanName: 'Omar Khalid',
      orderDate: DateTime(2026, 2, 21),
      itemsCount: 6,
      channel: 'Website',
      amountQar: 30250,
      paymentStatus: _PaymentStatus.pending,
      orderStatus: _OrderStatus.processing,
    ),
    _Order(
      id: 'ORD-5209',
      customerName: 'Pearl Residence',
      salesmanName: 'Hassan Karim',
      orderDate: DateTime(2026, 2, 20),
      itemsCount: 10,
      channel: 'Sales Call',
      amountQar: 41820,
      paymentStatus: _PaymentStatus.paid,
      orderStatus: _OrderStatus.delivered,
    ),
    _Order(
      id: 'ORD-5210',
      customerName: 'Blue Line Holding',
      salesmanName: 'Yousef Ali',
      orderDate: DateTime(2026, 2, 20),
      itemsCount: 2,
      channel: 'WhatsApp',
      amountQar: 7850,
      paymentStatus: _PaymentStatus.failed,
      orderStatus: _OrderStatus.cancelled,
    ),
    _Order(
      id: 'ORD-5211',
      customerName: 'Sahara Innovations',
      salesmanName: 'Maryam Adel',
      orderDate: DateTime(2026, 2, 19),
      itemsCount: 12,
      channel: 'Email',
      amountQar: 63900,
      paymentStatus: _PaymentStatus.pending,
      orderStatus: _OrderStatus.processing,
    ),
    _Order(
      id: 'ORD-5212',
      customerName: 'Apex Industrial',
      salesmanName: 'Ahmed Nasser',
      orderDate: DateTime(2026, 2, 19),
      itemsCount: 14,
      channel: 'Showroom',
      amountQar: 72220,
      paymentStatus: _PaymentStatus.paid,
      orderStatus: _OrderStatus.delivered,
    ),
    _Order(
      id: 'ORD-5213',
      customerName: 'Horizon Works',
      salesmanName: 'Fatima Saeed',
      orderDate: DateTime(2026, 2, 18),
      itemsCount: 5,
      channel: 'Website',
      amountQar: 18800,
      paymentStatus: _PaymentStatus.pending,
      orderStatus: _OrderStatus.processing,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _orders.clear();
    _subscribeOrders();
  }

  @override
  void dispose() {
    _ordersSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _subscribeOrders() {
    _ordersSub?.cancel();
    setState(() {
      _loading = true;
      _loadError = null;
    });

    _ordersSub = _firestore
        .collection(FirestoreCollections.orders)
        .snapshots()
        .listen(
          (snapshot) {
            final items = snapshot.docs
                .map(_orderFromDoc)
                .whereType<_Order>()
                .toList();
            items.sort((a, b) => b.orderDate.compareTo(a.orderDate));
            if (!mounted) return;
            setState(() {
              _orders
                ..clear()
                ..addAll(items);
              _selectedIds.removeWhere(
                (id) => !_orders.any((order) => order.id == id),
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

  List<_Order> get _filteredOrders {
    return _orders.where((order) {
      final matchesQuery =
          _query.isEmpty ||
          order.id.toLowerCase().contains(_query) ||
          order.customerName.toLowerCase().contains(_query) ||
          order.salesmanName.toLowerCase().contains(_query) ||
          order.channel.toLowerCase().contains(_query);

      final matchesStatus =
          _statusFilter == _OrderFilter.all ||
          (_statusFilter == _OrderFilter.delivered &&
              order.orderStatus == _OrderStatus.delivered) ||
          (_statusFilter == _OrderFilter.processing &&
              order.orderStatus == _OrderStatus.processing) ||
          (_statusFilter == _OrderFilter.cancelled &&
              order.orderStatus == _OrderStatus.cancelled);

      return matchesQuery && matchesStatus;
    }).toList();
  }

  int get _totalPages {
    final pages = (_filteredOrders.length / _rowsPerPage).ceil();
    return pages < 1 ? 1 : pages;
  }

  List<_Order> get _visibleOrders {
    final filtered = _filteredOrders;
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
    final filtered = _filteredOrders;
    final visible = _visibleOrders;
    final selectedCount = filtered
        .where((order) => _selectedIds.contains(order.id))
        .length;
    final isAllSelected =
        filtered.isNotEmpty && selectedCount == filtered.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 1200;
        final isNarrow = constraints.maxWidth < 880;
        final tableWidth = constraints.maxWidth < 1400
            ? 1400.0
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
                              for (final order in filtered) {
                                _selectedIds.remove(order.id);
                              }
                            } else {
                              for (final order in filtered) {
                                _selectedIds.add(order.id);
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
                            for (final order in filtered) {
                              _selectedIds.add(order.id);
                            }
                          });
                        },
                  child: const Text('Select All'),
                ),
                TextButton.icon(
                  onPressed: selectedCount == 0 ? null : _deleteSelectedOrders,
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
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Failed to load orders from Firebase.',
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
                              onPressed: _subscribeOrders,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : visible.isEmpty
                    ? const Center(
                        child: Text(
                          'No orders found.',
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
                'Order List',
                style: TextStyle(
                  fontSize: 30,
                  height: 1.1,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Track fulfillment, payment, and delivery operations in real time.',
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
            onTap: _creatingOrder ? () {} : _addOrder,
            icon: Icons.add_rounded,
            label: 'Add Order',
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
        hintText: 'Search orders',
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
    return PopupMenuButton<_OrderFilter>(
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
        PopupMenuItem(value: _OrderFilter.all, child: Text('All Statuses')),
        PopupMenuItem(value: _OrderFilter.delivered, child: Text('Completed')),
        PopupMenuItem(
          value: _OrderFilter.processing,
          child: Text('Processing'),
        ),
        PopupMenuItem(value: _OrderFilter.cancelled, child: Text('Cancelled')),
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
              _OrderFilter.all => 'All',
              _OrderFilter.delivered => 'Completed',
              _OrderFilter.processing => 'Processing',
              _OrderFilter.cancelled => 'Cancelled',
            }),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTable(List<_Order> orders, double width) {
    return Column(
      children: [
        _buildTableHeader(width),
        const Divider(height: 1, color: Color(0xFFE8EBF0)),
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            child: ListView.separated(
              itemCount: orders.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFE8EBF0)),
              itemBuilder: (context, index) {
                final order = orders[index];
                final selected = _selectedIds.contains(order.id);
                return _buildTableRow(order, selected, width);
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
            _HeaderCell(width: 124, text: 'Order ID'),
            _HeaderCell(width: 216, text: 'Customer'),
            _HeaderCell(width: 176, text: 'Salesman'),
            _HeaderCell(width: 132, text: 'Order Date'),
            _HeaderCell(width: 86, text: 'Items'),
            _HeaderCell(width: 136, text: 'Channel'),
            _HeaderCell(width: 128, text: 'Amount (QAR)'),
            _HeaderCell(width: 138, text: 'Payment'),
            _HeaderCell(width: 140, text: 'Order Status'),
            _HeaderCell(width: 110, text: 'Action'),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(_Order order, bool selected, double width) {
    final paymentStyle = _paymentStyle(order.paymentStatus);
    final orderStyle = _orderStyle(order.orderStatus);

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
                      _selectedIds.remove(order.id);
                    } else {
                      _selectedIds.add(order.id);
                    }
                  });
                },
              ),
            ),
            _RowCell(width: 124, text: order.id),
            SizedBox(
              width: 216,
              child: Text(
                order.customerName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              width: 176,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFFE8EDF5),
                    child: Text(
                      _initialsOf(order.salesmanName),
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.salesmanName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _RowCell(width: 132, text: _dateFormat.format(order.orderDate)),
            _RowCell(width: 86, text: order.itemsCount.toString()),
            _RowCell(
              width: 136,
              text: order.channel,
              color: const Color(0xFF2488B7),
            ),
            _RowCell(width: 128, text: _currency.format(order.amountQar)),
            SizedBox(
              width: 138,
              child: _statusChip(
                label: paymentStyle.$4,
                textColor: paymentStyle.$2,
                background: paymentStyle.$1,
                borderColor: paymentStyle.$3,
              ),
            ),
            SizedBox(
              width: 140,
              child: _statusChip(
                label: orderStyle.$4,
                textColor: orderStyle.$2,
                background: orderStyle.$1,
                borderColor: orderStyle.$3,
              ),
            ),
            SizedBox(width: 110, child: _buildOrderActionMenu(order)),
          ],
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 7, color: textColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardList(List<_Order> orders) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final order = orders[index];
        final selected = _selectedIds.contains(order.id);
        final paymentStyle = _paymentStyle(order.paymentStatus);
        final orderStyle = _orderStyle(order.orderStatus);

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
                          _selectedIds.remove(order.id);
                        } else {
                          _selectedIds.add(order.id);
                        }
                      });
                    },
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.id,
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          order.customerName,
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
              const SizedBox(height: 10),
              _infoRow('Salesman', order.salesmanName),
              _infoRow('Order Date', _dateFormat.format(order.orderDate)),
              _infoRow('Items', order.itemsCount.toString()),
              _infoRow('Channel', order.channel),
              _infoRow('Amount', _currency.format(order.amountQar)),
              _infoRow('Payment Method', order.paymentMethod),
              _infoRow('Collected', _currency.format(order.collectedAmountQar)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _statusChip(
                    label: paymentStyle.$4,
                    textColor: paymentStyle.$2,
                    background: paymentStyle.$1,
                    borderColor: paymentStyle.$3,
                  ),
                  _statusChip(
                    label: orderStyle.$4,
                    textColor: orderStyle.$2,
                    background: orderStyle.$1,
                    borderColor: orderStyle.$3,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: _buildOrderActionMenu(order),
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

  Widget _buildOrderActionMenu(_Order order) {
    return Align(
      alignment: Alignment.centerLeft,
      child: PopupMenuButton<_OrderAction>(
        tooltip: 'Order options',
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
        onSelected: (action) => _handleOrderAction(order, action),
        itemBuilder: (context) => [
          PopupMenuItem<_OrderAction>(
            value: _OrderAction.updatePaid,
            enabled: order.paymentStatus != _PaymentStatus.paid,
            child: const Row(
              children: [
                Icon(Iconsax.money, size: 18, color: Color(0xFF2277B8)),
                SizedBox(width: 10),
                Text('Update Paid'),
              ],
            ),
          ),
          const PopupMenuItem<_OrderAction>(
            value: _OrderAction.updateStatus,
            child: Row(
              children: [
                Icon(Iconsax.bill, size: 18, color: Color(0xFF2E9F95)),
                SizedBox(width: 10),
                Text('Update Status'),
              ],
            ),
          ),
          PopupMenuItem<_OrderAction>(
            value: _OrderAction.view,
            child: const Row(
              children: [
                Icon(Iconsax.monitor, size: 18, color: Color(0xFF2EA8A5)),
                SizedBox(width: 10),
                Text('View Details'),
              ],
            ),
          ),
          const PopupMenuItem<_OrderAction>(
            value: _OrderAction.delete,
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

  Future<void> _addOrder() async {
    if (_creatingOrder) return;
    setState(() => _creatingOrder = true);
    try {
      final customers = await _loadCustomers();
      if (customers.isEmpty) {
        _toast('No active customers found. Add customers first.');
        return;
      }
      final products = await _loadProducts();
      if (products.isEmpty) {
        _toast('No active products found. Add products first.');
        return;
      }
      if (!mounted) return;
      final draft = await _showCreateOrderSheet(
        customers: customers,
        products: products,
      );
      if (draft == null) return;
      await _createOrderWithStockDeduction(draft);
    } catch (error) {
      _toast('Failed to prepare order: $error');
    } finally {
      if (mounted) {
        setState(() => _creatingOrder = false);
      }
    }
  }

  Future<List<_CustomerRecord>> _loadCustomers() async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.customers)
        .where('status', isEqualTo: 'active')
        .orderBy('nameLower')
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return _CustomerRecord(
        id: _stringOr(data['id'], fallback: doc.id),
        name: _stringOr(data['name'], fallback: 'Unknown'),
      );
    }).toList();
  }

  Future<List<_ProductRecordLite>> _loadProducts() async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.products)
        .where('status', isEqualTo: 'active')
        .orderBy('productNameLower')
        .get();

    return snapshot.docs
        .map(_productFromDoc)
        .whereType<_ProductRecordLite>()
        .toList();
  }

  _ProductRecordLite? _productFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) return null;
    final code = _stringOr(data['productCode'], fallback: doc.id);
    final name = _stringOr(data['productName'], fallback: 'Unnamed Product');
    final inventory = _asMap(data['inventory']);
    final baseUnitMap = _asMap(data['baseUnit']);
    final saleUnitsRaw = data['saleUnits'];
    final saleUnits = <_SaleUnitLite>[];
    if (saleUnitsRaw is List) {
      for (final item in saleUnitsRaw) {
        final itemMap = _asMap(item);
        final unitName = _stringOr(itemMap['name']);
        if (unitName.isEmpty) continue;
        saleUnits.add(
          _SaleUnitLite(
            name: unitName,
            conversionToBaseUnit: _doubleOr(itemMap['conversionToBaseUnit']),
          ),
        );
      }
    }
    final baseUnit = _stringOr(baseUnitMap['name'], fallback: 'Piece');
    if (saleUnits.isEmpty) {
      saleUnits.add(_SaleUnitLite(name: baseUnit, conversionToBaseUnit: 1));
    }

    final pricing = _asMap(data['pricing']);
    final markets = _asMap(pricing['markets']);
    final defaultMarketKey = _stringOr(
      pricing['defaultMarketKey'],
      fallback: markets.keys.isEmpty ? '' : markets.keys.first,
    );
    final market = _asMap(markets[defaultMarketKey]);
    final pricesMap = _asMap(market['prices']);
    final priceByUnitKey = <String, _PriceForUnit>{};
    pricesMap.forEach((key, value) {
      final item = _asMap(value);
      priceByUnitKey[key.toString().toLowerCase()] = _PriceForUnit(
        autoPriceQar: _nullableDouble(item['autoPriceQar']),
        autoOfferPriceQar: _nullableDouble(item['autoOfferPriceQar']),
        manualPriceQar: _nullableDouble(item['manualPriceQar']),
        manualOfferPriceQar: _nullableDouble(item['manualOfferPriceQar']),
      );
    });

    return _ProductRecordLite(
      code: code,
      name: name,
      availableQtyBaseUnit: _doubleOr(inventory['availableQtyBaseUnit']),
      baseUnit: baseUnit,
      saleUnits: saleUnits,
      priceByUnitKey: priceByUnitKey,
    );
  }

  Future<_OrderDraftResult?> _showCreateOrderSheet({
    required List<_CustomerRecord> customers,
    required List<_ProductRecordLite> products,
  }) {
    var selectedCustomer = customers.first;
    var channel = 'Salesman App';
    var paymentMethod = 'Credit';
    var collectedAmount = 0.0;
    final lines = <_OrderLineInput>[
      _OrderLineInput(
        product: products.first,
        unitName: products.first.saleUnits.first.name,
        quantity: 1,
      ),
    ];
    String? errorText;

    double linePrice(_OrderLineInput line) {
      final key = _normalizeKey(line.unitName);
      final config = line.product.priceByUnitKey[key];
      return config?.resolvedPrice() ?? 0;
    }

    double lineBaseQty(_OrderLineInput line) {
      final unit = line.product.saleUnits.firstWhere(
        (e) => e.name == line.unitName,
        orElse: () =>
            _SaleUnitLite(name: line.product.baseUnit, conversionToBaseUnit: 1),
      );
      return line.quantity * unit.conversionToBaseUnit;
    }

    return showGeneralDialog<_OrderDraftResult>(
      context: context,
      barrierLabel: 'create-order',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, _, __) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final total = lines.fold<double>(
              0,
              (acc, line) => acc + (linePrice(line) * line.quantity),
            );
            final double effectiveCollected = collectedAmount < 0
                ? 0.0
                : (collectedAmount > total ? total : collectedAmount);
            final paymentStatus = _paymentStatusForAmount(
              totalQar: total,
              collectedQar: effectiveCollected,
            );
            return Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: Colors.white,
                child: SizedBox(
                  width: 560,
                  height: double.infinity,
                  child: SafeArea(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 14, 10),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Create Order',
                                  style: TextStyle(
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButtonFormField<_CustomerRecord>(
                                  initialValue: selectedCustomer,
                                  decoration: const InputDecoration(
                                    labelText: 'Customer',
                                  ),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setSheetState(
                                      () => selectedCustomer = value,
                                    );
                                  },
                                  items: customers
                                      .map(
                                        (customer) => DropdownMenuItem(
                                          value: customer,
                                          child: Text(
                                            '${customer.name} (${customer.id})',
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  initialValue: channel,
                                  onChanged: (value) => channel = value.trim(),
                                  decoration: const InputDecoration(
                                    labelText: 'Channel',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  initialValue: paymentMethod,
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setSheetState(() => paymentMethod = value);
                                  },
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Cash',
                                      child: Text('Cash'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Card',
                                      child: Text('Card'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Bank Transfer',
                                      child: Text('Bank Transfer'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Credit',
                                      child: Text('Credit'),
                                    ),
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Payment Method',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  initialValue: collectedAmount.toStringAsFixed(
                                    0,
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  onChanged: (value) {
                                    final parsed = double.tryParse(value);
                                    if (parsed == null) return;
                                    setSheetState(
                                      () => collectedAmount = parsed,
                                    );
                                  },
                                  decoration: const InputDecoration(
                                    labelText: 'Collected Amount (QAR)',
                                    hintText: '0',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Order Items',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                for (int i = 0; i < lines.length; i++) ...[
                                  _buildOrderLineEditor(
                                    line: lines[i],
                                    products: products,
                                    onChanged: () => setSheetState(() {}),
                                    onRemove: lines.length == 1
                                        ? null
                                        : () => setSheetState(
                                            () => lines.removeAt(i),
                                          ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                OutlinedButton.icon(
                                  onPressed: () {
                                    setSheetState(() {
                                      final product = products.first;
                                      lines.add(
                                        _OrderLineInput(
                                          product: product,
                                          unitName:
                                              product.saleUnits.first.name,
                                          quantity: 1,
                                        ),
                                      );
                                    });
                                  },
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Add Product'),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Total: ${_currency.format(total)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Payment Status: ${_paymentStyle(paymentStatus).$4} | Collected: ${_currency.format(effectiveCollected)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _paymentStyle(paymentStatus).$2,
                                  ),
                                ),
                                if (errorText != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    errorText!,
                                    style: const TextStyle(
                                      color: Color(0xFFB42318),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
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
                                    if (lines.isEmpty) {
                                      setSheetState(() {
                                        errorText = 'Add at least one product.';
                                      });
                                      return;
                                    }
                                    for (final line in lines) {
                                      if (line.quantity <= 0) {
                                        setSheetState(() {
                                          errorText =
                                              'Quantity must be greater than zero.';
                                        });
                                        return;
                                      }
                                      if (lineBaseQty(line) >
                                          line.product.availableQtyBaseUnit) {
                                        setSheetState(() {
                                          errorText =
                                              'Insufficient stock for ${line.product.name}.';
                                        });
                                        return;
                                      }
                                    }
                                    Navigator.of(context).pop(
                                      _OrderDraftResult(
                                        customer: selectedCustomer,
                                        channel: channel.isEmpty
                                            ? 'Salesman App'
                                            : channel,
                                        paymentMethod: paymentMethod,
                                        collectedAmountQar: effectiveCollected,
                                        lines: lines
                                            .map(
                                              (line) => _OrderLineInput(
                                                product: line.product,
                                                unitName: line.unitName,
                                                quantity: line.quantity,
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    );
                                  },
                                  child: const Text('Place Order'),
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

  Widget _buildOrderLineEditor({
    required _OrderLineInput line,
    required List<_ProductRecordLite> products,
    required VoidCallback onChanged,
    required VoidCallback? onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE4E9F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 5,
                child: DropdownButtonFormField<_ProductRecordLite>(
                  key: ValueKey(
                    'product-${line.hashCode}-${line.product.code}',
                  ),
                  initialValue: line.product,
                  decoration: const InputDecoration(labelText: 'Product'),
                  onChanged: (value) {
                    if (value == null) return;
                    line.product = value;
                    line.unitName = value.saleUnits.first.name;
                    line.quantity = 1;
                    onChanged();
                  },
                  items: products
                      .map(
                        (product) => DropdownMenuItem(
                          value: product,
                          child: Text(
                            '${product.name} (${product.code}) • ${product.availableQtyBaseUnit.toStringAsFixed(2)} ${product.baseUnit}',
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  key: ValueKey(
                    'unit-${line.hashCode}-${line.product.code}-${line.unitName}',
                  ),
                  initialValue: line.unitName,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  onChanged: (value) {
                    if (value == null) return;
                    line.unitName = value;
                    onChanged();
                  },
                  items: line.product.saleUnits
                      .map(
                        (unit) => DropdownMenuItem(
                          value: unit.name,
                          child: Text(unit.name),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  key: ValueKey(
                    'qty-${line.hashCode}-${line.product.code}-${line.unitName}-${line.quantity}',
                  ),
                  initialValue: line.quantity == line.quantity.toInt()
                      ? line.quantity.toInt().toString()
                      : line.quantity.toString(),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Qty'),
                  onChanged: (value) {
                    final parsed = double.tryParse(value);
                    if (parsed == null) return;
                    line.quantity = parsed;
                    onChanged();
                  },
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 6),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Available: ${line.product.availableQtyBaseUnit.toStringAsFixed(2)} ${line.product.baseUnit}',
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createOrderWithStockDeduction(_OrderDraftResult draft) async {
    try {
      final ordersRef = _firestore.collection(FirestoreCollections.orders);
      final orderDoc = ordersRef.doc();
      final orderCode =
          'ORD-${DateFormat('yyyyMMdd').format(DateTime.now())}-${orderDoc.id.substring(0, 4).toUpperCase()}';
      await _firestore.runTransaction((transaction) async {
        double total = 0;
        int itemsCount = 0;
        final items = <Map<String, dynamic>>[];

        for (final line in draft.lines) {
          final productDocRef = _firestore
              .collection(FirestoreCollections.products)
              .doc(_normalizeProductDocId(line.product.code));
          final snap = await transaction.get(productDocRef);
          final data = snap.data();
          if (!snap.exists || data == null) {
            throw StateError('Product ${line.product.code} no longer exists.');
          }

          final inventory = _asMap(data['inventory']);
          final currentAvailable = _doubleOr(inventory['availableQtyBaseUnit']);
          final unit = line.product.saleUnits.firstWhere(
            (e) => e.name == line.unitName,
            orElse: () => _SaleUnitLite(
              name: line.product.baseUnit,
              conversionToBaseUnit: 1,
            ),
          );
          final requestedBase = line.quantity * unit.conversionToBaseUnit;
          if (requestedBase <= 0) {
            throw StateError('Invalid quantity for ${line.product.name}.');
          }
          if (currentAvailable < requestedBase) {
            throw StateError(
              'Insufficient stock for ${line.product.name}. Available: ${currentAvailable.toStringAsFixed(2)} ${line.product.baseUnit}',
            );
          }
          final key = _normalizeKey(line.unitName);
          final linePrice =
              line.product.priceByUnitKey[key]?.resolvedPrice() ?? 0;
          final price = linePrice > 0
              ? linePrice
              : _doubleOr(_asMap(data['metrics'])['displayPriceQar']);

          final lineTotal = line.quantity * price;
          total += lineTotal;
          itemsCount += 1;
          items.add({
            'productCode': line.product.code,
            'productName': line.product.name,
            'unit': line.unitName,
            'qty': line.quantity,
            'conversionToBaseUnit': unit.conversionToBaseUnit,
            'qtyBase': requestedBase,
            'appliedPriceQar': price,
            'lineTotalQar': lineTotal,
          });

          transaction.set(productDocRef, {
            'inventory': {
              'availableQtyBaseUnit': currentAvailable - requestedBase,
            },
            'audit': {'updatedAt': FieldValue.serverTimestamp()},
          }, SetOptions(merge: true));
        }

        final double collected = draft.collectedAmountQar < 0
            ? 0.0
            : (draft.collectedAmountQar > total
                  ? total
                  : draft.collectedAmountQar);
        final paymentStatus = _paymentStatusForAmount(
          totalQar: total,
          collectedQar: collected,
        );

        transaction.set(orderDoc, {
          'id': orderCode,
          'customerId': draft.customer.id,
          'customerName': draft.customer.name,
          'salesmanName': _auth.currentUser?.displayName ?? 'Salesman',
          'orderDate': FieldValue.serverTimestamp(),
          'itemsCount': itemsCount,
          'channel': draft.channel,
          'amountQar': total,
          'paymentMethod': draft.paymentMethod,
          'collectedAmountQar': collected,
          'paymentStatus': _paymentStatusToString(paymentStatus),
          'orderStatus': 'processing',
          'items': items,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      if (!mounted) return;
      _toast('Order placed successfully and stock updated.');
    } catch (error) {
      if (!mounted) return;
      _toast('Failed to place order: $error');
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, v) => MapEntry(key.toString(), v));
    }
    return <String, dynamic>{};
  }

  double? _nullableDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  String _normalizeKey(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  String _normalizeProductDocId(String code) {
    return code.replaceAll('#', '').trim().toLowerCase();
  }

  _Order? _orderFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return null;
    final id = _stringOr(data['id'], fallback: doc.id).trim();
    if (id.isEmpty) return null;
    return _Order(
      docId: doc.id,
      id: id,
      customerName: _stringOr(
        data['customerName'],
        fallback: 'Unknown Customer',
      ),
      salesmanName: _stringOr(data['salesmanName'], fallback: 'Unknown'),
      orderDate: _dateOrNow(data['orderDate']),
      itemsCount: _intOr(data['itemsCount']),
      channel: _stringOr(data['channel'], fallback: 'Direct'),
      amountQar: _doubleOr(data['amountQar']),
      collectedAmountQar: _doubleOr(data['collectedAmountQar']),
      paymentMethod: _stringOr(data['paymentMethod'], fallback: 'Not set'),
      paymentStatus: _paymentStatusFromString(
        _stringOr(data['paymentStatus'], fallback: 'pending'),
      ),
      orderStatus: _orderStatusFromString(
        _stringOr(data['orderStatus'], fallback: 'processing'),
      ),
    );
  }

  Future<void> _markOrderAsPaid(_Order order) async {
    if (order.paymentStatus == _PaymentStatus.paid) {
      _toast('Order ${order.id} is already marked as paid.');
      return;
    }
    final shouldUpdate = await _showConfirmSideSheet(
      title: 'Mark Payment as Paid',
      message:
          'Set payment status to Paid for ${order.id}?\n'
          'This will set collected amount to ${_currency.format(order.amountQar)}.',
      confirmLabel: 'Mark Paid',
    );
    if (shouldUpdate != true) return;

    try {
      final docId = order.docId.isEmpty ? order.id : order.docId;
      await _firestore.collection(FirestoreCollections.orders).doc(docId).set({
        'paymentStatus': 'paid',
        'collectedAmountQar': order.amountQar,
        'paymentCollectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      _toast('Order ${order.id} payment updated to paid.');
    } catch (error) {
      if (!mounted) return;
      _toast('Failed to update payment: $error');
    }
  }

  Future<void> _updateOrderStatus(_Order order) async {
    final nextStatus = await showGeneralDialog<_OrderStatus>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Update order status',
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
                              'Update status for ${order.id}',
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
                          _statusOptionTile(
                            label: 'Processing',
                            active: order.orderStatus == _OrderStatus.processing,
                            onTap: () =>
                                Navigator.of(context).pop(_OrderStatus.processing),
                          ),
                          _statusOptionTile(
                            label: 'Completed',
                            active: order.orderStatus == _OrderStatus.delivered,
                            onTap: () =>
                                Navigator.of(context).pop(_OrderStatus.delivered),
                          ),
                          _statusOptionTile(
                            label: 'Cancelled',
                            active: order.orderStatus == _OrderStatus.cancelled,
                            onTap: () =>
                                Navigator.of(context).pop(_OrderStatus.cancelled),
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

    if (nextStatus == null || nextStatus == order.orderStatus) return;

    try {
      final docId = order.docId.isEmpty ? order.id : order.docId;
      await _firestore.collection(FirestoreCollections.orders).doc(docId).set({
        'orderStatus': _orderStatusStorageValue(nextStatus),
        'updatedAt': FieldValue.serverTimestamp(),
        if (nextStatus == _OrderStatus.delivered)
          'completedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      _toast('Order ${order.id} status updated.');
    } catch (error) {
      if (!mounted) return;
      _toast('Failed to update order status: $error');
    }
  }

  Widget _statusOptionTile({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE8F7F6) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? const Color(0xFF2EA8A5) : const Color(0xFFDDE2EA),
          ),
        ),
        child: Row(
          children: [
            Icon(
              active ? Iconsax.tick_circle : Iconsax.record_circle,
              size: 18,
              color: active ? const Color(0xFF2EA8A5) : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: active ? const Color(0xFF0F766E) : const Color(0xFF1F2937),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _viewOrder(_Order order) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Order details',
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
                              'Order ${order.id}',
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
                          _orderDetailRow('Customer', order.customerName),
                          _orderDetailRow('Salesman', order.salesmanName),
                          _orderDetailRow(
                            'Order Date',
                            _dateFormat.format(order.orderDate),
                          ),
                          _orderDetailRow('Items', order.itemsCount.toString()),
                          _orderDetailRow('Channel', order.channel),
                          _orderDetailRow(
                            'Amount',
                            _currency.format(order.amountQar),
                          ),
                          _orderDetailRow('Payment Method', order.paymentMethod),
                          _orderDetailRow(
                            'Collected',
                            _currency.format(order.collectedAmountQar),
                          ),
                          _orderDetailRow(
                            'Payment',
                            _paymentStyle(order.paymentStatus).$4,
                          ),
                          _orderDetailRow(
                            'Order Status',
                            _orderStyle(order.orderStatus).$4,
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

  Widget _orderDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 124,
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

  Future<void> _handleOrderAction(_Order order, _OrderAction action) async {
    switch (action) {
      case _OrderAction.updatePaid:
        await _markOrderAsPaid(order);
        break;
      case _OrderAction.updateStatus:
        await _updateOrderStatus(order);
        break;
      case _OrderAction.view:
        await _viewOrder(order);
        break;
      case _OrderAction.delete:
        await _deleteOrder(order);
        break;
    }
  }

  Future<void> _deleteOrder(_Order order) async {
    final shouldDelete = await _showConfirmSideSheet(
      title: 'Delete Order',
      message: 'Delete order ${order.id}?',
      confirmLabel: 'Delete',
    );
    if (shouldDelete != true) return;

    try {
      await _firestore
          .collection(FirestoreCollections.orders)
          .doc(order.docId.isEmpty ? order.id : order.docId)
          .delete();
      if (!mounted) return;
      _toast('Order ${order.id} deleted.');
    } catch (error) {
      if (!mounted) return;
      _toast('Failed to delete order: $error');
    }
  }

  Future<void> _deleteSelectedOrders() async {
    final ids = Set<String>.from(_selectedIds);
    if (ids.isEmpty) return;
    final shouldDelete = await _showConfirmSideSheet(
      title: 'Delete Selected Orders',
      message: 'Delete ${ids.length} selected order(s)?',
      confirmLabel: 'Delete',
    );
    if (shouldDelete != true) return;

    try {
      final batch = _firestore.batch();
      final targets = _orders.where((order) => ids.contains(order.id));
      for (final order in targets) {
        final docId = order.docId.isEmpty ? order.id : order.docId;
        batch.delete(
          _firestore.collection(FirestoreCollections.orders).doc(docId),
        );
      }
      await batch.commit();
      if (!mounted) return;
      setState(() => _selectedIds.clear());
      _toast('Deleted ${ids.length} order(s).');
    } catch (error) {
      if (!mounted) return;
      _toast('Failed to delete selected orders: $error');
    }
  }

  String _stringOr(dynamic value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
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

  DateTime _dateOrNow(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  _PaymentStatus _paymentStatusFromString(String raw) {
    switch (raw.toLowerCase()) {
      case 'paid':
        return _PaymentStatus.paid;
      case 'partial':
        return _PaymentStatus.partial;
      case 'failed':
        return _PaymentStatus.failed;
      default:
        return _PaymentStatus.pending;
    }
  }

  _PaymentStatus _paymentStatusForAmount({
    required double totalQar,
    required double collectedQar,
  }) {
    if (totalQar <= 0) return _PaymentStatus.pending;
    if (collectedQar <= 0) return _PaymentStatus.pending;
    if (collectedQar >= totalQar) return _PaymentStatus.paid;
    return _PaymentStatus.partial;
  }

  String _paymentStatusToString(_PaymentStatus status) {
    switch (status) {
      case _PaymentStatus.paid:
        return 'paid';
      case _PaymentStatus.pending:
        return 'pending';
      case _PaymentStatus.partial:
        return 'partial';
      case _PaymentStatus.failed:
        return 'failed';
    }
  }

  _OrderStatus _orderStatusFromString(String raw) {
    switch (raw.toLowerCase()) {
      case 'delivered':
      case 'completed':
      case 'complete':
        return _OrderStatus.delivered;
      case 'cancelled':
      case 'canceled':
        return _OrderStatus.cancelled;
      default:
        return _OrderStatus.processing;
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
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

  (Color, Color, Color, String) _paymentStyle(_PaymentStatus status) {
    switch (status) {
      case _PaymentStatus.paid:
        return (
          const Color(0xFFEFFAF3),
          const Color(0xFF21A453),
          const Color(0xFFD1F0DD),
          'Paid',
        );
      case _PaymentStatus.pending:
        return (
          const Color(0xFFFFF8E8),
          const Color(0xFFDD9C00),
          const Color(0xFFF8EAC6),
          'Pending',
        );
      case _PaymentStatus.partial:
        return (
          const Color(0xFFFFF5EE),
          const Color(0xFFE57828),
          const Color(0xFFF8DEC9),
          'Partial',
        );
      case _PaymentStatus.failed:
        return (
          const Color(0xFFFFEEF0),
          const Color(0xFFE44949),
          const Color(0xFFF7D5DA),
          'Failed',
        );
    }
  }

  (Color, Color, Color, String) _orderStyle(_OrderStatus status) {
    switch (status) {
      case _OrderStatus.delivered:
        return (
          const Color(0xFFEAF7FF),
          const Color(0xFF2277B8),
          const Color(0xFFCDE8FA),
          'Completed',
        );
      case _OrderStatus.processing:
        return (
          const Color(0xFFE8F7F6),
          const Color(0xFF2E9F95),
          const Color(0xFFCDEEEB),
          'Processing',
        );
      case _OrderStatus.cancelled:
        return (
          const Color(0xFFFFEEF0),
          const Color(0xFFE44949),
          const Color(0xFFF7D5DA),
          'Cancelled',
        );
    }
  }

  String _orderStatusStorageValue(_OrderStatus status) {
    switch (status) {
      case _OrderStatus.delivered:
        return 'delivered';
      case _OrderStatus.processing:
        return 'processing';
      case _OrderStatus.cancelled:
        return 'cancelled';
    }
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
