import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

enum _OrderStatus { delivered, processing, cancelled }

enum _PaymentStatus { paid, pending, failed }

enum _OrderFilter { all, delivered, processing, cancelled }

class _Order {
  final String id;
  final String customerName;
  final String salesmanName;
  final DateTime orderDate;
  final int itemsCount;
  final String channel;
  final double amountQar;
  final _PaymentStatus paymentStatus;
  final _OrderStatus orderStatus;

  const _Order({
    required this.id,
    required this.customerName,
    required this.salesmanName,
    required this.orderDate,
    required this.itemsCount,
    required this.channel,
    required this.amountQar,
    required this.paymentStatus,
    required this.orderStatus,
  });
}

class OrdersTabPage extends StatefulWidget {
  const OrdersTabPage({super.key});

  @override
  State<OrdersTabPage> createState() => _OrdersTabPageState();
}

class _OrdersTabPageState extends State<OrdersTabPage> {
  static const int _rowsPerPage = 13;

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
  final Set<String> _selectedIds = <String>{};

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                  onPressed: selectedCount == 0 ? null : () {},
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
                child: visible.isEmpty
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
            onTap: () {},
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
      onSelected: (value) {
        setState(() {
          _statusFilter = value;
          _currentPage = 1;
        });
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: _OrderFilter.all, child: Text('All Statuses')),
        PopupMenuItem(value: _OrderFilter.delivered, child: Text('Delivered')),
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
              _OrderFilter.delivered => 'Delivered',
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
            _HeaderCell(width: 90, text: 'Action'),
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
            SizedBox(
              width: 90,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Color(0xFF374151),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
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
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: Color(0xFFE65A5A),
                    ),
                    label: const Text(
                      'Delete',
                      style: TextStyle(color: Color(0xFFE65A5A)),
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

  String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
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
          'Delivered',
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
