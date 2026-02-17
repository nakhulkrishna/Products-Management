import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:products_catelogs/authentication/provider/authentication_provider.dart';
import 'package:products_catelogs/authentication/screens/splash_screen.dart';
import 'package:products_catelogs/products/provider/products_management_pro.dart';
import 'package:products_catelogs/settings/screens/about_us.dart';
import 'package:products_catelogs/settings/screens/privacy_policy.dart';
import 'package:products_catelogs/settings/screens/terms_conditions.dart';
import 'package:products_catelogs/settings/screens/whatsapp_number.dart';
import 'package:products_catelogs/theme/widgets/app_components.dart';
import 'package:products_catelogs/theme/widgets/reference_scaffold.dart';
import 'package:provider/provider.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsItems = <Map<String, dynamic>>[
      {
        "title": "Order WhatsApp Number",
        "subtitle": "Update the shared order contact",
        "icon": Iconsax.call,
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WhatsAppSettingsScreen()),
          );
        },
      },
      {
        "title": "About Us",
        "subtitle": "Company and app overview",
        "icon": Iconsax.info_circle,
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AboutUsScreen()),
          );
        },
      },
      {
        "title": "Privacy Policy",
        "subtitle": "How user data is handled",
        "icon": Iconsax.shield_tick,
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
          );
        },
      },
      {
        "title": "Terms & Conditions",
        "subtitle": "Usage and legal terms",
        "icon": Iconsax.document_text,
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TermsAndConditionsScreen()),
          );
        },
      },
      {
        "title": "Clear Orders",
        "subtitle": "Delete all sales records",
        "icon": Iconsax.brush_1,
        "danger": true,
        "onTap": () async {
          final shouldClear = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Clear Orders"),
              content: const Text(
                "This will permanently remove all order records.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel"),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Clear"),
                ),
              ],
            ),
          );

          if (!context.mounted) return;
          if (shouldClear == true) {
            context.read<ProductProvider>().deleteAllOrders();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("All orders cleared")));
          }
        },
      },
      {
        "title": "Log Out",
        "subtitle": "Sign out from this device",
        "icon": Iconsax.logout,
        "danger": true,
        "onTap": () {
          context.read<UserProvider>().logout();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const SplashScreen()),
            (Route<dynamic> route) => false,
          );
        },
      },
    ];

    return ReferenceScaffold(
      title: "Settings",
      subtitle: "App preferences and account",
      bodyPadding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      body: ListView(
        children: [
          AppSectionCard(
            title: "General",
            subtitle: "Account and app-level controls",
            child: Column(
              children: settingsItems.map((item) {
                return AppInfoTile(
                  icon: item["icon"] as IconData,
                  title: item["title"] as String,
                  subtitle: item["subtitle"] as String?,
                  isDanger: (item["danger"] as bool?) ?? false,
                  onTap: item["onTap"] as VoidCallback,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
