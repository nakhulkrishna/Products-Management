import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:products_catelogs/features/products/presentation/widgets/add_edit_product_form_view.dart';

class ProductDetailsData {
  final String id;
  final String name;
  final String category;
  final String description;
  final String baseUnit;
  final List<String> saleUnits;
  final List<SaleUnitConfig> saleUnitConfigs;
  final Map<String, List<MarketUnitPrice>> marketPricingByMarket;
  final double stockInBaseUnit;
  final double initialStockInput;
  final String initialStockInputUnit;
  final double priceQar;
  final double? offerPriceQar;
  final int sales;
  final String linkedMarketing;
  final bool isHidden;
  final String stockStatusLabel;
  final Color stockStatusColor;
  final Color stockStatusBackground;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String? imageUrl;
  final List<String> imageUrls;

  const ProductDetailsData({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.baseUnit,
    required this.saleUnits,
    required this.saleUnitConfigs,
    required this.marketPricingByMarket,
    required this.stockInBaseUnit,
    required this.initialStockInput,
    required this.initialStockInputUnit,
    required this.priceQar,
    required this.offerPriceQar,
    required this.sales,
    required this.linkedMarketing,
    required this.isHidden,
    required this.stockStatusLabel,
    required this.stockStatusColor,
    required this.stockStatusBackground,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.imageUrl,
    required this.imageUrls,
  });
}

class ProductDetailsView extends StatelessWidget {
  final ProductDetailsData data;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final String currencyCode;

  const ProductDetailsView({
    super.key,
    required this.data,
    required this.onBack,
    required this.onEdit,
    this.currencyCode = 'QAR',
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
              const SizedBox(height: 12),
              _buildMarketPricingCard(),
              if (data.imageUrls.length > 1) ...[
                const SizedBox(height: 12),
                _buildGalleryCard(),
              ],
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
            icon: const Icon(Iconsax.arrow_left_2),
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
                        _statusPill(
                          text: data.isHidden ? 'Hidden' : 'Visible',
                          color: data.isHidden
                              ? const Color(0xFF9A3412)
                              : const Color(0xFF166534),
                          background: data.isHidden
                              ? const Color(0xFFFFF7ED)
                              : const Color(0xFFECFDF3),
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
                icon: const Icon(Iconsax.arrow_left_2, size: 16),
                label: const Text('Back'),
              ),
              FilledButton.icon(
                onPressed: onEdit,
                icon: const Icon(Iconsax.edit, size: 16),
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
          _metricRow(
            label: 'Initial Stock',
            value:
                '${data.initialStockInput.toStringAsFixed(2)} ${data.initialStockInputUnit}',
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
            value: '$currencyCode ${data.priceQar.toStringAsFixed(2)}',
          ),
          const Divider(height: 14, color: Color(0xFFE9EDF3)),
          _metricRow(
            label: 'Offer Price',
            value: data.offerPriceQar == null
                ? 'N/A'
                : '$currencyCode ${data.offerPriceQar!.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }

  Widget _buildUnitsCard() {
    return _card(
      title: 'Units & Conversion',
      child: Column(
        children: [
          for (int i = 0; i < data.saleUnitConfigs.length; i++) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    data.saleUnitConfigs[i].unit,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '1 ${data.saleUnitConfigs[i].unit} = ${data.saleUnitConfigs[i].conversionToBaseUnit.toStringAsFixed(2)} ${data.baseUnit}',
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (i != data.saleUnitConfigs.length - 1)
              const Divider(height: 14, color: Color(0xFFE9EDF3)),
          ],
        ],
      ),
    );
  }

  Widget _buildMarketPricingCard() {
    final marketNames = data.marketPricingByMarket.keys.toList()..sort();
    return _card(
      title: 'Market Pricing',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < marketNames.length; i++) ...[
            _marketPricingBlock(
              marketName: marketNames[i],
              rows: data.marketPricingByMarket[marketNames[i]] ?? const [],
            ),
            if (i != marketNames.length - 1) const SizedBox(height: 14),
          ],
          if (marketNames.isEmpty)
            const Text(
              'No market pricing data available.',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _marketPricingBlock({
    required String marketName,
    required List<MarketUnitPrice> rows,
  }) {
    final byUnit = {for (final row in rows) row.unit: row};
    return Container(
      width: double.infinity,
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
            marketName,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < data.saleUnits.length; i++) ...[
            _unitPriceLine(
              unit: data.saleUnits[i],
              price: _resolvedUnitPrice(byUnit[data.saleUnits[i]]),
            ),
            if (i != data.saleUnits.length - 1)
              const Divider(height: 14, color: Color(0xFFE2E8F0)),
          ],
        ],
      ),
    );
  }

  Widget _unitPriceLine({required String unit, required double? price}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            unit,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          price == null ? 'N/A' : '$currencyCode ${price.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  double? _resolvedUnitPrice(MarketUnitPrice? row) {
    if (row == null) return null;
    return row.manualOfferPrice ??
        row.autoOfferPrice ??
        row.manualPrice ??
        row.autoPrice;
  }

  Widget _buildGalleryCard() {
    return _card(
      title: 'Images',
      child: SizedBox(
        height: 86,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: data.imageUrls.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            return Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE4E8F0)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                data.imageUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: Color(0xFFF3F4F6),
                  child: Icon(Iconsax.gallery_slash),
                ),
              ),
            );
          },
        ),
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
