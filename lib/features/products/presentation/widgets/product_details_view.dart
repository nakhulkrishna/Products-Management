import 'package:flutter/material.dart';

class ProductDetailsData {
  final String id;
  final String name;
  final String category;
  final String description;
  final String baseUnit;
  final List<String> saleUnits;
  final double stockInBaseUnit;
  final double priceQar;
  final double? offerPriceQar;
  final int sales;
  final String linkedMarketing;
  final String stockStatusLabel;
  final Color stockStatusColor;
  final Color stockStatusBackground;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String? imageUrl;

  const ProductDetailsData({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.baseUnit,
    required this.saleUnits,
    required this.stockInBaseUnit,
    required this.priceQar,
    required this.offerPriceQar,
    required this.sales,
    required this.linkedMarketing,
    required this.stockStatusLabel,
    required this.stockStatusColor,
    required this.stockStatusBackground,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.imageUrl,
  });
}

class ProductDetailsView extends StatelessWidget {
  final ProductDetailsData data;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  const ProductDetailsView({
    super.key,
    required this.data,
    required this.onBack,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 920;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isNarrow),
              const SizedBox(height: 12),
              _buildMainCard(isNarrow),
              const SizedBox(height: 12),
              isNarrow
                  ? Column(
                      children: [
                        _buildMetricsCard(),
                        const SizedBox(height: 12),
                        _buildPricingCard(),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildMetricsCard()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildPricingCard()),
                      ],
                    ),
              const SizedBox(height: 12),
              _buildUnitsCard(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isNarrow) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Product Details',
                style: TextStyle(
                  fontSize: 30,
                  height: 1.1,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Overview for ${data.id}',
                style: const TextStyle(
                  color: Color(0xFF8A94A6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (!isNarrow)
          OutlinedButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Back to List'),
          ),
      ],
    );
  }

  Widget _buildMainCard(bool isNarrow) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: data.iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: data.imageUrl == null
                    ? Icon(data.icon, color: data.iconColor, size: 28)
                    : Image.network(
                        data.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            Icon(data.icon, color: data.iconColor, size: 28),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${data.category} • Base Unit: ${data.baseUnit}',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _statusPill(
                          text: data.stockStatusLabel,
                          color: data.stockStatusColor,
                          background: data.stockStatusBackground,
                        ),
                        _statusPill(
                          text: data.id,
                          color: const Color(0xFF2277B8),
                          background: const Color(0xFFEAF4FF),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE9EDF3)),
          const SizedBox(height: 12),
          Text(
            data.description.isEmpty
                ? 'No description provided.'
                : data.description,
            style: const TextStyle(
              color: Color(0xFF374151),
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Back'),
              ),
              FilledButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit Product'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsCard() {
    return _card(
      title: 'Inventory & Sales',
      child: Column(
        children: [
          _metricRow(
            label: 'Stock (Base Unit)',
            value:
                '${data.stockInBaseUnit.toStringAsFixed(2)} ${data.baseUnit}',
          ),
          const Divider(height: 14, color: Color(0xFFE9EDF3)),
          _metricRow(label: 'Sales Count', value: data.sales.toString()),
          const Divider(height: 14, color: Color(0xFFE9EDF3)),
          _metricRow(label: 'Linked Marketing', value: data.linkedMarketing),
        ],
      ),
    );
  }

  Widget _buildPricingCard() {
    return _card(
      title: 'Pricing',
      child: Column(
        children: [
          _metricRow(
            label: 'Unit Price',
            value: 'QAR ${data.priceQar.toStringAsFixed(2)}',
          ),
          const Divider(height: 14, color: Color(0xFFE9EDF3)),
          _metricRow(
            label: 'Offer Price',
            value: data.offerPriceQar == null
                ? 'Auto / N/A'
                : 'QAR ${data.offerPriceQar!.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }

  Widget _buildUnitsCard() {
    return _card(
      title: 'Sale Units',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final unit in data.saleUnits)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE4E8F0)),
              ),
              child: Text(
                unit,
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _metricRow({required String label, required String value}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusPill({
    required String text,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
