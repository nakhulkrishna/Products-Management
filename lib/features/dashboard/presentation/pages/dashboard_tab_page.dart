import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

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

class DashboardTabPage extends StatefulWidget {
  const DashboardTabPage({super.key});

  @override
  State<DashboardTabPage> createState() => _DashboardTabPageState();
}

class _DashboardTabPageState extends State<DashboardTabPage> {
  final _searchController = TextEditingController();
  final _currency = NumberFormat.currency(
    locale: 'en_QA',
    symbol: 'QAR ',
    decimalDigits: 0,
  );
  final _dateFormat = DateFormat('yyyy-MM-dd');

  String _query = '';
  _StatusFilter _statusFilter = _StatusFilter.all;
  final Set<String> _selectedIds = <String>{};

  static final _salesmen = <_Salesman>[
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

  static const _trendingProducts = <_TrendingProduct>[
    _TrendingProduct(
      name: 'Ceramic Tiles - Premium',
      unitsSold: 420,
      revenue: 128000,
      growthPercent: 12.4,
    ),
    _TrendingProduct(
      name: 'Steel Frames - A12',
      unitsSold: 270,
      revenue: 96400,
      growthPercent: 9.8,
    ),
    _TrendingProduct(
      name: 'Plaster Mix - Pro',
      unitsSold: 510,
      revenue: 88750,
      growthPercent: 6.2,
    ),
    _TrendingProduct(
      name: 'Electrical Set - E45',
      unitsSold: 190,
      revenue: 74100,
      growthPercent: 4.1,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final filtered = _filteredSalesmen;
    final selectedCount = filtered
        .where((salesman) => _selectedIds.contains(salesman.id))
        .length;
    final isAllSelected =
        filtered.isNotEmpty && selectedCount == filtered.length;
    final totalSales = filtered.fold<double>(
      0,
      (sum, salesman) => sum + salesman.totalSales,
    );
    final totalDeals = filtered.fold<int>(
      0,
      (sum, salesman) => sum + salesman.dealsClosed,
    );
    final activeSalesmen = filtered
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
        final tableWidth = constraints.maxWidth < 1220
            ? 1220.0
            : constraints.maxWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            _buildTrendingProducts(isCompact, isNarrow),
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
                  onPressed: selectedCount == 0 ? null : () {},
                  icon: const Icon(Iconsax.user_minus, size: 18),
                  label: const Text('Deactivate'),
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
                child: filtered.isEmpty
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

  Widget _buildTrendingProducts(bool isCompact, bool isNarrow) {
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
          SizedBox(
            height: isCompact ? (isNarrow ? 280 : 126) : 88,
            child: isNarrow
                ? Column(
                    children: [
                      for (int i = 0; i < _trendingProducts.length; i++) ...[
                        Expanded(
                          child: _buildTrendingCard(
                            product: _trendingProducts[i],
                            width: double.infinity,
                          ),
                        ),
                        if (i != _trendingProducts.length - 1)
                          const SizedBox(height: 8),
                      ],
                    ],
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _trendingProducts.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      return _buildTrendingCard(
                        product: _trendingProducts[index],
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

  Widget _buildFilterButton() {
    return PopupMenuButton<_StatusFilter>(
      onSelected: (value) {
        setState(() => _statusFilter = value);
      },
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
            child: ListView.separated(
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
            const SizedBox(
              width: 40,
              child: Icon(Icons.more_horiz_rounded, color: Color(0xFF7A8190)),
            ),
          ],
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
