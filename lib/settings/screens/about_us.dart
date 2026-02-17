import 'package:flutter/material.dart';
import 'package:products_catelogs/theme/widgets/app_components.dart';
import 'package:products_catelogs/theme/widgets/reference_scaffold.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ReferenceScaffold(
      title: "About Us",
      subtitle: "Who we are",
      body: SingleChildScrollView(
        child: AppSectionCard(
          title: "Red Rose Contracting W.L.L",
          subtitle: "Wholesale dates and chocolates",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "We specialize in high-quality wholesale products built for reliable business operations and repeat customer trust.",
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
              const SizedBox(height: 14),
              Text(
                "Our vision",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Build long-term relationships by delivering consistent quality, reliability, and service excellence.",
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
              const SizedBox(height: 14),
              Text(
                "App purpose",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "This app helps your team manage products, categories, orders, and staff operations in one place.",
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
