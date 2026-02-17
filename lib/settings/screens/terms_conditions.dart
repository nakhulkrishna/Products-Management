import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:products_catelogs/theme/widgets/app_components.dart';
import 'package:products_catelogs/theme/widgets/reference_scaffold.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget buildSection(String title, String content, IconData icon) {
      return AppSectionCard(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withAlpha(24),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
        ),
      );
    }

    return ReferenceScaffold(
      title: "Terms & Conditions",
      subtitle: "Usage and compliance",
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Last Updated: 27 Aug 2025", style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),

            buildSection(
              "Use of App",
              "The app is intended for managing sales, products, and customer records. "
                  "Do not use the app for illegal purposes.",
              Iconsax.document,
            ),

            buildSection(
              "Orders & Delivery",
              "This app is for record-keeping only. "
                  "No shipping or delivery is managed within the app.",
              Iconsax.box,
            ),

            buildSection(
              "Payments",
              "No payments or transactions are processed through the app. "
                  "All payments are managed outside the app.",
              Iconsax.money,
            ),

            buildSection(
              "Restrictions",
              "Users may not resell, redistribute, or misuse the app in any way.",
              Iconsax.warning_2,
            ),

            buildSection(
              "Disclaimer",
              "We are not liable for data loss or misuse caused by user negligence "
                  "or unauthorized third-party access.",
              Iconsax.shield,
            ),

            const SizedBox(height: 20),
            Center(
              child: Text(
                "© 2025 Red Rose Contract W.L.L",
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
