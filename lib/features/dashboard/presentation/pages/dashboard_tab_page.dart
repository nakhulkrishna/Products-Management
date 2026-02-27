import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:products_catelogs/core/constants/firestore_collections.dart';

enum _SalesStatus { active, inactive }

enum _StatusFilter { all, active, inactive }

class _Salesman {
  final String id;
  final String name;
  final String region;
  final String email;
  final _SalesStatus status;
  final DateTime lastSaleDate;
  final int dealsClosed;
  final double totalSales;

  const _Salesman({
    required this.id,
    required this.name,
    required this.region,
    required this.email,
    required this.status,
    required this.lastSaleDate,
    required this.dealsClosed,
    required this.totalSales,
  });

  _Salesman copyWith({
    String? id,
    String? name,
    String? region,
    String? email,
    _SalesStatus? status,
    DateTime? lastSaleDate,
    int? dealsClosed,
    double? totalSales,
  }) {
    return _Salesman(
      id: id ?? this.id,
      name: name ?? this.name,
      region: region ?? this.region,
      email: email ?? this.email,
      status: status ?? this.status,
      lastSaleDate: lastSaleDate ?? this.lastSaleDate,
      dealsClosed: dealsClosed ?? this.dealsClosed,
      totalSales: totalSales ?? this.totalSales,
    );
  }
}

class _TrendingProduct {
  final String name;
  final int unitsSold;
  final double revenue;
  final double growthPercent;

  const _TrendingProduct({
    required this.name,
    required this.unitsSold,
    required this.revenue,
    required this.growthPercent,
  });
}

class _TrendAggregate {
  int units = 0;
  double revenue = 0;
  double growthTotal = 0;
  int growthCount = 0;
}

class _SalesmanOrderAggregate {
  int deals = 0;
  double totalSales = 0;
  DateTime? lastSaleDate;
}

class DashboardTabPage extends StatefulWidget {
  const DashboardTabPage({super.key});

  @override
  State<DashboardTabPage> createState() => _DashboardTabPageState();
}

class _DashboardTabPageState extends State<DashboardTabPage> {
  static const double _minTableWidth = 1324;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _searchController = TextEditingController();
  final _tableScrollController = ScrollController();
  final _currency = NumberFormat.currency(
    locale: 'en_QA',
    symbol: 'QAR ',
    decimalDigits: 0,
  );
  final _dateFormat = DateFormat('yyyy-MM-dd');

  String _query = '';
  _StatusFilter _statusFilter = _StatusFilter.all;
  final Set<String> _selectedIds = <String>{};
  bool _loadingSalesmen = true;
  bool _loadingOrders = true;
  String? _salesmenError;
  String? _ordersError;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _salesmenSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ordersSub;
  final List<Map<String, dynamic>> _orders = [];

  static final _seedSalesmen = <_Salesman>[
    _Salesman(
      id: 'SM-001',
      name: 'Ahmed Nasser',
      region: 'Doha',
      email: 'ahmed@redrose.com',
      status: _SalesStatus.active,
      lastSaleDate: DateTime(2026, 2, 24),
      dealsClosed: 12,
      totalSales: 42500,
    ),
    _Salesman(
      id: 'SM-002',
      name: 'Omar Khalid',
      region: 'Al Rayyan',
      email: 'omar@redrose.com',
      status: _SalesStatus.active,
      lastSaleDate: DateTime(2026, 2, 23),
      dealsClosed: 9,
      totalSales: 35900,
    ),
    _Salesman(
      id: 'SM-003',
      name: 'Yousef Ali',
      region: 'Lusail',
      email: 'yousef@redrose.com',
      status: _SalesStatus.inactive,
      lastSaleDate: DateTime(2026, 2, 10),
      dealsClosed: 6,
      totalSales: 22800,
    ),
    _Salesman(
      id: 'SM-004',
      name: 'Fatima Saeed',
      region: 'Al Wakrah',
      email: 'fatima@redrose.com',
      status: _SalesStatus.active,
      lastSaleDate: DateTime(2026, 2, 22),
      dealsClosed: 11,
      totalSales: 41200,
    ),
    _Salesman(
      id: 'SM-005',
      name: 'Hassan Karim',
      region: 'Umm Salal',
      email: 'hassan@redrose.com',
      status: _SalesStatus.active,
      lastSaleDate: DateTime(2026, 2, 19),
      dealsClosed: 8,
      totalSales: 30150,
    ),
    _Salesman(
      id: 'SM-006',
      name: 'Maryam Adel',
      region: 'Al Khor',
      email: 'maryam@redrose.com',
      status: _SalesStatus.inactive,
      lastSaleDate: DateTime(2026, 1, 30),
      dealsClosed: 4,
      totalSales: 16900,
    ),
  ];
  late final List<_Salesman> _salesmen;

  @override
  void initState() {
    super.initState();
    if (_seedSalesmen.isEmpty) {
      // Local seed list is retained only for optional manual migration.
    }
    _salesmen = [];
    _subscribeSalesmen();
    _subscribeOrders();
  }

  @override
  void dispose() {
    _salesmenSub?.cancel();
    _ordersSub?.cancel();
    _searchController.dispose();
    _tableScrollController.dispose();
    super.dispose();
  }

  void _subscribeSalesmen() {
    _salesmenSub?.cancel();
    setState(() {
      _loadingSalesmen = true;
      _salesmenError = null;
    });
    _salesmenSub = _firestore
        .collection(FirestoreCollections.staffSalesmen)
        .snapshots()
        .listen(
          (snapshot) {
            final items = snapshot.docs
                .map(_salesmanFromDoc)
                .whereType<_Salesman>()
                .toList();
            items.sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
            if (!mounted) return;
            setState(() {
              _salesmen
                ..clear()
                ..addAll(items);
              _selectedIds.removeWhere(
                (id) => !_salesmen.any((salesman) => salesman.id == id),
              );
              _loadingSalesmen = false;
              _salesmenError = null;
            });
          },
          onError: (error) {
            if (!mounted) return;
            setState(() {
              _loadingSalesmen = false;
              _salesmenError = '$error';
            });
          },
        );
  }

  void _subscribeOrders() {
    _ordersSub?.cancel();
    setState(() {
      _loadingOrders = true;
      _ordersError = null;
    });
    _ordersSub = _firestore
        .collection(FirestoreCollections.orders)
        .snapshots()
        .listen(
          (snapshot) {
            final items = snapshot.docs.map((doc) {
              final map = Map<String, dynamic>.from(doc.data());
              map['_docId'] = doc.id;
              return map;
            }).toList();
            if (!mounted) return;
            setState(() {
              _orders
                ..clear()
                ..addAll(items);
              _loadingOrders = false;
              _ordersError = null;
            });
          },
          onError: (error) {
            if (!mounted) return;
            setState(() {
              _loadingOrders = false;
              _ordersError = '$error';
            });
          },
        );
  }

  List<_Salesman> get _filteredSalesmen {
    return _salesmen.where((salesman) {
      final matchesQuery =
          _query.isEmpty ||
          salesman.name.toLowerCase().contains(_query) ||
          salesman.email.toLowerCase().contains(_query) ||
          salesman.region.toLowerCase().contains(_query) ||
          salesman.id.toLowerCase().contains(_query);

      final matchesStatus =
          _statusFilter == _StatusFilter.all ||
          (_statusFilter == _StatusFilter.active &&
              salesman.status == _SalesStatus.active) ||
          (_statusFilter == _StatusFilter.inactive &&
              salesman.status == _SalesStatus.inactive);

      return matchesQuery && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _salesmenWithLiveOrderMetrics(_filteredSalesmen);
    final trendingProducts = _trendingProductsFromOrders;
    final selectedCount = filtered
        .where((salesman) => _selectedIds.contains(salesman.id))
        .length;
    final isAllSelected =
        filtered.isNotEmpty && selectedCount == filtered.length;
    final totalSales = _orders
        .where(_isCompletedOrder)
        .fold<double>(
          0,
          (runningTotal, order) => runningTotal + _doubleOr(order['amountQar']),
        );
    final totalDeals = _orders.where(_isCompletedOrder).length;
    final activeSalesmen = _salesmen
        .where((salesman) => salesman.status == _SalesStatus.active)
        .length;
    final avgDealValue = totalDeals == 0 ? 0.0 : totalSales / totalDeals;
    final topPerformer = filtered.isEmpty
        ? null
        : (filtered.toList()
                ..sort((a, b) => b.totalSales.compareTo(a.totalSales)))
              .first;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 930;
        final isNarrow = constraints.maxWidth < 700;
        final tableWidth = constraints.maxWidth < _minTableWidth
            ? _minTableWidth
            : constraints.maxWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isCompact),
            const SizedBox(height: 12),
            if (_loadingSalesmen || _loadingOrders)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: LinearProgressIndicator(minHeight: 3),
              ),
            if (_salesmenError != null || _ordersError != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF4C7C4)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFB42318),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _salesmenError != null
                            ? 'Salesmen load failed: $_salesmenError'
                            : 'Orders load failed: $_ordersError',
                        style: const TextStyle(
                          color: Color(0xFFB42318),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _subscribeSalesmen();
                        _subscribeOrders();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            if (topPerformer != null) ...[
              _buildInsightBanner(
                topPerformer: topPerformer,
                isCompact: isCompact,
              ),
              const SizedBox(height: 12),
            ],
            _buildSummarySection(
              isCompact: isCompact,
              totalSales: totalSales,
              totalDeals: totalDeals,
              activeSalesmen: activeSalesmen,
              avgDealValue: avgDealValue,
            ),
            const SizedBox(height: 12),
            _buildTrendingProducts(
              isCompact: isCompact,
              isNarrow: isNarrow,
              products: trendingProducts,
            ),
            const SizedBox(height: 12),
            isCompact
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
            const SizedBox(height: 12),
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
                    color: const Color(0xFF27A8A4),
                  ),
                ),
                Text(
                  '$selectedCount Selected',
                  style: const TextStyle(
                    color: Color(0xFF27A8A4),
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
                  onPressed: selectedCount == 0 ? null : _deactivateSelected,
                  icon: const Icon(Iconsax.user_minus, size: 18),
                  label: const Text('Deactivate'),
                ),
                TextButton.icon(
                  onPressed: selectedCount == 0 ? null : _deleteSelected,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
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
                  border: Border.all(color: const Color(0xFFDDE2EA)),
                ),
                child: _loadingSalesmen
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'No salesmen found.',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : isCompact
                    ? _buildCardList(filtered)
                    : _buildDesktopTable(filtered, tableWidth),
              ),
            ),
          ],
        );
      },
    );
  }

  List<_TrendingProduct> get _trendingProductsFromOrders {
    final aggregates = <String, _TrendAggregate>{};

    for (final order in _orders) {
      if (!_isCompletedOrder(order)) continue;
      final amount = _doubleOr(order['amountQar']);
      final rawItems = order['items'];
      if (rawItems is List && rawItems.isNotEmpty) {
        for (final item in rawItems) {
          if (item is! Map) continue;
          final map = Map<String, dynamic>.from(item);
          final name = _stringOr(
            map['productName'] ?? map['name'] ?? map['title'],
            fallback: 'Unnamed Product',
          );
          final qty = _intOr(map['qty'] ?? map['quantity'] ?? map['count']);
          final lineRevenue = _doubleOr(
            map['totalQar'] ?? map['lineTotal'] ?? map['amount'] ?? map['revenue'],
          );
          final growth = _doubleOr(map['growthPercent']);
          final entry = aggregates.putIfAbsent(name, () => _TrendAggregate());
          entry.units += qty <= 0 ? 1 : qty;
          entry.revenue += lineRevenue > 0 ? lineRevenue : amount;
          if (growth != 0) {
            entry.growthTotal += growth;
            entry.growthCount += 1;
          }
        }
      } else {
        final name = _stringOr(order['productName'], fallback: 'Unassigned Product');
        final units = _intOr(order['itemsCount']);
        final entry = aggregates.putIfAbsent(name, () => _TrendAggregate());
        entry.units += units <= 0 ? 1 : units;
        entry.revenue += amount;
      }
    }

    final list = aggregates.entries.map((entry) {
      final aggregate = entry.value;
      final growth = aggregate.growthCount == 0
          ? 0.0
          : aggregate.growthTotal / aggregate.growthCount;
      return _TrendingProduct(
        name: entry.key,
        unitsSold: aggregate.units,
        revenue: aggregate.revenue,
        growthPercent: growth,
      );
    }).toList();

    list.sort((a, b) => b.revenue.compareTo(a.revenue));
    return list.take(4).toList();
  }

  _Salesman? _salesmanFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return null;
    final id = _stringOr(data['id'], fallback: doc.id).trim();
    if (id.isEmpty) return null;
    return _Salesman(
      id: id,
      name: _stringOr(data['name'], fallback: 'Unknown'),
      region: _stringOr(data['region'], fallback: ''),
      email: _stringOr(data['email'], fallback: ''),
      status: _salesStatusFromString(_stringOr(data['status'], fallback: 'active')),
      lastSaleDate: _dateOrNow(data['lastSaleDate']),
      dealsClosed: _intOr(data['dealsClosed']),
      totalSales: _doubleOr(data['totalSales']),
    );
  }

  _SalesStatus _salesStatusFromString(String raw) {
    switch (raw.toLowerCase()) {
      case 'inactive':
      case 'on_leave':
      case 'onleave':
        return _SalesStatus.inactive;
      default:
        return _SalesStatus.active;
    }
  }

  String _salesStatusToString(_SalesStatus status) {
    switch (status) {
      case _SalesStatus.active:
        return 'active';
      case _SalesStatus.inactive:
        return 'inactive';
    }
  }

  String _orderStatusString(Map<String, dynamic> order) {
    return _stringOr(order['orderStatus'], fallback: 'processing').toLowerCase();
  }

  bool _isCompletedOrder(Map<String, dynamic> order) {
    final status = _orderStatusString(order);
    return status == 'delivered' || status == 'completed' || status == 'complete';
  }

  List<_Salesman> _salesmenWithLiveOrderMetrics(List<_Salesman> source) {
    final aggregates = <String, _SalesmanOrderAggregate>{};
    for (final order in _orders) {
      if (!_isCompletedOrder(order)) continue;
      final salesmanName = _stringOr(order['salesmanName']);
      if (salesmanName.isEmpty) continue;
      final key = salesmanName.toLowerCase().trim();
      final entry = aggregates.putIfAbsent(key, () => _SalesmanOrderAggregate());
      entry.deals += 1;
      entry.totalSales += _doubleOr(order['amountQar']);
      final orderDate = _dateOrNull(order['orderDate']) ?? _dateOrNull(order['createdAt']);
      if (orderDate != null &&
          (entry.lastSaleDate == null || orderDate.isAfter(entry.lastSaleDate!))) {
        entry.lastSaleDate = orderDate;
      }
    }

    final hasSingleSalesmanFallback = source.length == 1 && aggregates.isNotEmpty;
    final fallbackDeals = aggregates.values.fold<int>(0, (a, b) => a + b.deals);
    final fallbackSales = aggregates.values.fold<double>(
      0,
      (a, b) => a + b.totalSales,
    );
    DateTime? fallbackLastSale;
    for (final value in aggregates.values) {
      final candidate = value.lastSaleDate;
      if (candidate == null) continue;
      if (fallbackLastSale == null || candidate.isAfter(fallbackLastSale)) {
        fallbackLastSale = candidate;
      }
    }

    return source.map((salesman) {
      final entry = aggregates[salesman.name.toLowerCase().trim()];
      if (entry == null && hasSingleSalesmanFallback) {
        return salesman.copyWith(
          dealsClosed: fallbackDeals > 0 ? fallbackDeals : salesman.dealsClosed,
          totalSales: fallbackSales > 0 ? fallbackSales : salesman.totalSales,
          lastSaleDate: fallbackLastSale ?? salesman.lastSaleDate,
        );
      }
      if (entry == null) return salesman;
      return salesman.copyWith(
        dealsClosed: entry.deals > 0 ? entry.deals : salesman.dealsClosed,
        totalSales: entry.totalSales > 0 ? entry.totalSales : salesman.totalSales,
        lastSaleDate: entry.lastSaleDate ?? salesman.lastSaleDate,
      );
    }).toList();
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

  DateTime? _dateOrNull(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Widget _buildInsightBanner({
    required _Salesman topPerformer,
    required bool isCompact,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F8A70), Color(0xFF2C7FB8)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: Colors.white.withValues(alpha: 0.22),
                child: Text(
                  _initialsOf(topPerformer.name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top Performer',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    topPerformer.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            '${_currency.format(topPerformer.totalSales)} revenue',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection({
    required bool isCompact,
    required double totalSales,
    required int totalDeals,
    required int activeSalesmen,
    required double avgDealValue,
  }) {
    final cards = [
      _SummaryCardData(
        title: 'Total Sales',
        value: _currency.format(totalSales),
        note: 'Net sales by visible team',
        color: const Color(0xFF1F8A70),
        icon: Iconsax.card,
      ),
      _SummaryCardData(
        title: 'Active Salesmen',
        value: activeSalesmen.toString(),
        note: 'Currently active reps',
        color: const Color(0xFF3B82F6),
        icon: Iconsax.user,
      ),
      _SummaryCardData(
        title: 'Deals Closed',
        value: totalDeals.toString(),
        note: 'Total closed deals',
        color: const Color(0xFF8B5CF6),
        icon: Iconsax.copy_success,
      ),
      _SummaryCardData(
        title: 'Avg Deal Value',
        value: _currency.format(avgDealValue),
        note: 'Average per closed deal',
        color: const Color(0xFFEF7D1A),
        icon: Iconsax.trend_up,
      ),
    ];

    if (isCompact) {
      return Column(
        children: [
          for (final card in cards) ...[
            _SummaryCard(data: card),
            const SizedBox(height: 10),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: _SummaryCard(data: cards[i])),
          if (i != cards.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _buildTrendingProducts({
    required bool isCompact,
    required bool isNarrow,
    required List<_TrendingProduct> products,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE2EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trending Products',
            style: TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No trending products available from backend orders.',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (products.isNotEmpty)
          SizedBox(
            height: isCompact ? (isNarrow ? 280 : 126) : 88,
            child: isNarrow
                ? Column(
                    children: [
                      for (int i = 0; i < products.length; i++) ...[
                        Expanded(
                          child: _buildTrendingCard(
                            product: products[i],
                            width: double.infinity,
                          ),
                        ),
                        if (i != products.length - 1)
                          const SizedBox(height: 8),
                      ],
                    ],
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      return _buildTrendingCard(
                        product: products[index],
                        width: isCompact ? 230 : 260,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingCard({
    required _TrendingProduct product,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${product.unitsSold} units sold',
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                _currency.format(product.revenue),
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8EE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '+${product.growthPercent.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Color(0xFF2FAD52),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() => _query = value.trim().toLowerCase());
      },
      decoration: const InputDecoration(
        hintText: 'Search salesmen',
        prefixIcon: Icon(Iconsax.search_normal),
        fillColor: Colors.white,
      ),
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
                'Dashboard',
                style: TextStyle(
                  fontSize: 30,
                  height: 1.1,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Track sales performance and manage salesmen activity.',
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

  Widget _buildFilterButton() {
    return PopupMenuButton<_StatusFilter>(
      onSelected: (value) {
        setState(() => _statusFilter = value);
      },
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 8,
      shadowColor: const Color(0x1A0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      offset: const Offset(0, 42),
      itemBuilder: (context) => const [
        PopupMenuItem(value: _StatusFilter.all, child: Text('All Statuses')),
        PopupMenuItem(value: _StatusFilter.active, child: Text('Active')),
        PopupMenuItem(value: _StatusFilter.inactive, child: Text('Inactive')),
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
            const Icon(Iconsax.filter4, size: 18),
            const SizedBox(width: 8),
            Text(
              _statusFilter == _StatusFilter.all
                  ? 'Filter'
                  : _statusFilter == _StatusFilter.active
                  ? 'Active'
                  : 'Inactive',
            ),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTable(List<_Salesman> filtered, double tableWidth) {
    return Column(
      children: [
        _buildTableHeader(tableWidth),
        const Divider(height: 1, color: Color(0xFFE8EBF0)),
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            controller: _tableScrollController,
            child: ListView.separated(
              controller: _tableScrollController,
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFE8EBF0)),
              itemBuilder: (context, index) {
                final salesman = filtered[index];
                final selected = _selectedIds.contains(salesman.id);
                return _buildTableRow(salesman, selected, tableWidth);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardList(List<_Salesman> filtered) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final salesman = filtered[index];
        final selected = _selectedIds.contains(salesman.id);
        final isActive = salesman.status == _SalesStatus.active;
        final statusBg = isActive
            ? const Color(0xFFE9FBEF)
            : const Color(0xFFFFECEA);
        final statusColor = isActive
            ? const Color(0xFF2FAD52)
            : const Color(0xFFD35D4B);

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
                    radius: 15,
                    backgroundColor: const Color(0xFFE5EAF3),
                    child: Text(
                      _initialsOf(salesman.name),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3D4A5D),
                      ),
                    ),
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
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _infoRow('Region', salesman.region),
              _infoRow('Email', salesman.email),
              _infoRow('Last Sale', _dateFormat.format(salesman.lastSaleDate)),
              _infoRow('Deals Closed', salesman.dealsClosed.toString()),
              _infoRow('Total Sales', _currency.format(salesman.totalSales)),
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
                    onPressed: () => _toggleSalesmanStatus(salesman),
                    icon: const Icon(Iconsax.user_minus, size: 16),
                    label: Text(
                      isActive ? 'Deactivate' : 'Activate',
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _deleteSalesman(salesman),
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text('Delete'),
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
            width: 100,
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
                color: Color(0xFF1F2937),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
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
            _HeaderCell(width: 94, text: 'Salesman ID'),
            _HeaderCell(width: 198, text: 'Salesman Name'),
            _HeaderCell(width: 130, text: 'Region'),
            _HeaderCell(width: 130, text: 'Status'),
            _HeaderCell(width: 240, text: 'Contact Info'),
            _HeaderCell(width: 140, text: 'Last Sale'),
            _HeaderCell(width: 140, text: 'Deals Closed'),
            _HeaderCell(width: 144, text: 'Total Sales (QAR)'),
            SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(_Salesman salesman, bool selected, double width) {
    final isActive = salesman.status == _SalesStatus.active;
    final statusBg = isActive
        ? const Color(0xFFE9FBEF)
        : const Color(0xFFFFECEA);
    final statusColor = isActive
        ? const Color(0xFF2FAD52)
        : const Color(0xFFD35D4B);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            _RowCell(width: 94, text: salesman.id),
            SizedBox(
              width: 198,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: const Color(0xFFE5EAF3),
                    child: Text(
                      _initialsOf(salesman.name),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3D4A5D),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      salesman.name,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            _RowCell(width: 130, text: salesman.region),
            SizedBox(
              width: 130,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _RowCell(
              width: 240,
              text: salesman.email,
              color: const Color(0xFF2488B7),
            ),
            _RowCell(
              width: 140,
              text: _dateFormat.format(salesman.lastSaleDate),
            ),
            _RowCell(width: 140, text: salesman.dealsClosed.toString()),
            _RowCell(width: 144, text: _currency.format(salesman.totalSales)),
            SizedBox(
              width: 48,
              child: PopupMenuButton<String>(
                color: Colors.white,
                surfaceTintColor: Colors.white,
                elevation: 8,
                shadowColor: const Color(0x1A0F172A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                offset: const Offset(0, 42),
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDDE2EA)),
                  ),
                  child: const Icon(
                    Iconsax.setting,
                    size: 18,
                    color: Color(0xFF4B5563),
                  ),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editSalesman(salesman);
                      break;
                    case 'toggle':
                      _toggleSalesmanStatus(salesman);
                      break;
                    case 'delete':
                      _deleteSalesman(salesman);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Iconsax.setting, size: 18, color: Color(0xFF374151)),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          isActive ? Iconsax.user_minus : Iconsax.user_add,
                          size: 18,
                          color: const Color(0xFF2EA8A5),
                        ),
                        const SizedBox(width: 10),
                        Text(isActive ? 'Deactivate' : 'Activate'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
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
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addSalesman() async {
    final created = await _showSalesmanEditorSheet();
    if (created == null) return;
    try {
      await _firestore
          .collection(FirestoreCollections.staffSalesmen)
          .doc(created.id)
          .set({
            'id': created.id,
            'name': created.name,
            'nameLower': created.name.toLowerCase(),
            'region': created.region,
            'email': created.email,
            'status': _salesStatusToString(created.status),
            'lastSaleDate': Timestamp.fromDate(created.lastSaleDate),
            'dealsClosed': created.dealsClosed,
            'totalSales': created.totalSales,
            'updatedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          });
      _toast('Salesman added.');
    } catch (error) {
      _toast('Failed to add salesman: $error');
    }
  }

  Future<void> _editSalesman(_Salesman salesman) async {
    final updated = await _showSalesmanEditorSheet(existing: salesman);
    if (updated == null) return;
    try {
      await _firestore
          .collection(FirestoreCollections.staffSalesmen)
          .doc(salesman.id)
          .set({
            'name': updated.name,
            'nameLower': updated.name.toLowerCase(),
            'region': updated.region,
            'email': updated.email,
            'status': _salesStatusToString(updated.status),
            'lastSaleDate': Timestamp.fromDate(updated.lastSaleDate),
            'dealsClosed': updated.dealsClosed,
            'totalSales': updated.totalSales,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      _toast('Salesman updated.');
    } catch (error) {
      _toast('Failed to update salesman: $error');
    }
  }

  Future<void> _toggleSalesmanStatus(_Salesman salesman) async {
    final isActive = salesman.status == _SalesStatus.active;
    final confirmed = await _showRightSheet<bool>(
      title: isActive ? 'Deactivate Salesman' : 'Activate Salesman',
      icon: isActive ? Iconsax.user_minus : Iconsax.user_add,
      body: Text(
        isActive
            ? 'Deactivate ${salesman.name}?'
            : 'Activate ${salesman.name}?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(isActive ? 'Deactivate' : 'Activate'),
        ),
      ],
    );
    if (confirmed != true) return;
    try {
      await _firestore
          .collection(FirestoreCollections.staffSalesmen)
          .doc(salesman.id)
          .set({
            'status': _salesStatusToString(
              isActive ? _SalesStatus.inactive : _SalesStatus.active,
            ),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      _toast(isActive ? 'Salesman deactivated.' : 'Salesman activated.');
    } catch (error) {
      _toast('Failed to update status: $error');
    }
  }

  Future<void> _deleteSalesman(_Salesman salesman) async {
    final confirmed = await _showRightSheet<bool>(
      title: 'Delete Salesman',
      icon: Icons.delete_outline_rounded,
      iconColor: const Color(0xFFE65A5A),
      body: Text('Delete ${salesman.name} from dashboard list?'),
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
      await _firestore
          .collection(FirestoreCollections.staffSalesmen)
          .doc(salesman.id)
          .delete();
      _selectedIds.remove(salesman.id);
      _toast('Salesman deleted.');
    } catch (error) {
      _toast('Failed to delete salesman: $error');
    }
  }

  Future<void> _deactivateSelected() async {
    final ids = Set<String>.from(_selectedIds);
    if (ids.isEmpty) return;
    final confirmed = await _showRightSheet<bool>(
      title: 'Deactivate Selected',
      icon: Iconsax.user_minus,
      body: Text('Deactivate ${ids.length} selected salesman(s)?'),
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
            'status': _salesStatusToString(_SalesStatus.inactive),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
      await batch.commit();
      _toast('Selected salesmen deactivated.');
    } catch (error) {
      _toast('Failed to deactivate selected: $error');
    }
  }

  Future<void> _deleteSelected() async {
    final ids = Set<String>.from(_selectedIds);
    if (ids.isEmpty) return;
    final confirmed = await _showRightSheet<bool>(
      title: 'Delete Selected',
      icon: Icons.delete_sweep_outlined,
      iconColor: const Color(0xFFE65A5A),
      body: Text('Delete ${ids.length} selected salesman(s)?'),
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
      final batch = _firestore.batch();
      for (final id in ids) {
        batch.delete(_firestore.collection(FirestoreCollections.staffSalesmen).doc(id));
      }
      await batch.commit();
      _selectedIds.clear();
      _toast('Selected salesmen deleted.');
    } catch (error) {
      _toast('Failed to delete selected: $error');
    }
  }

  Future<_Salesman?> _showSalesmanEditorSheet({_Salesman? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final regionController = TextEditingController(text: existing?.region ?? '');
    final emailController = TextEditingController(text: existing?.email ?? '');
    final dealsController = TextEditingController(
      text: (existing?.dealsClosed ?? 0).toString(),
    );
    final salesController = TextEditingController(
      text: (existing?.totalSales ?? 0).toStringAsFixed(0),
    );
    _SalesStatus status = existing?.status ?? _SalesStatus.active;
    final formKey = GlobalKey<FormState>();

    return _showRightSheet<_Salesman>(
      title: existing == null ? 'Add Salesman' : 'Edit Salesman',
      icon: existing == null ? Icons.person_add_alt_1 : Icons.edit_outlined,
      body: StatefulBuilder(
        builder: (context, setSheetState) => Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: regionController,
                decoration: const InputDecoration(labelText: 'Region'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: emailController,
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
                controller: dealsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Deals Closed'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: salesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total Sales (QAR)'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<_SalesStatus>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: _SalesStatus.active, child: Text('Active')),
                  DropdownMenuItem(
                    value: _SalesStatus.inactive,
                    child: Text('Inactive'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setSheetState(() => status = value);
                },
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
            final id = existing?.id ?? _nextSalesmanId();
            Navigator.of(context).pop(
              _Salesman(
                id: id,
                name: nameController.text.trim(),
                region: regionController.text.trim(),
                email: emailController.text.trim(),
                status: status,
                lastSaleDate: existing?.lastSaleDate ?? DateTime.now(),
                dealsClosed: int.tryParse(dealsController.text.trim()) ?? 0,
                totalSales: double.tryParse(salesController.text.trim()) ?? 0,
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
                  ? 520
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
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
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

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }
}

class _SummaryCardData {
  final String title;
  final String value;
  final String note;
  final Color color;
  final IconData icon;

  const _SummaryCardData({
    required this.title,
    required this.value,
    required this.note,
    required this.color,
    required this.icon,
  });
}

class _SummaryCard extends StatelessWidget {
  final _SummaryCardData data;

  const _SummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE2EA)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.value,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  data.note,
                  style: const TextStyle(
                    color: Color(0xFF9AA0AD),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
