import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:products_catelogs/products/provider/products_management_pro.dart';
import 'package:products_catelogs/settings/provider/setting_provider.dart';
import 'package:products_catelogs/settings/screens/about_us.dart';
import 'package:products_catelogs/settings/screens/privacy_policy.dart';
import 'package:products_catelogs/settings/screens/terms_conditions.dart';
import 'package:products_catelogs/settings/screens/whatsapp_number.dart';
import 'package:provider/provider.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> settingsItems = [
      {
        "title": "Order WhatsApp Number",
        "icon": Iconsax.call,
        "onTap": () {
            Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WhatsAppSettingsScreen()),
          );
          // _showEditDialog(
          //   context,
          //   "Order WhatsApp Number",
          
          // );
        },
      },
      {
        "title": "About Us",
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
        "icon": Iconsax.brush_1,
        "onTap": () {
        context.read<ProductProvider>().deleteAllOrders();
        },
      },
      {
        "title": "More Settings",
        "icon": Iconsax.setting_2,
        "onTap": () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Coming Soon...")));
        },
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: settingsItems.length,
          itemBuilder: (context, index) {
            final item = settingsItems[index];
            return seetingsCard(
              context,
              title: item["title"],
              icon: item["icon"],
              onTap: item["onTap"],
            );
          },
        ),
      ),
    );
  }

  Widget seetingsCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.primaryColor,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            const Icon(Iconsax.arrow_right_3, size: 20),
          ],
        ),
      ),
    );
  }

// void _showEditDialog(BuildContext context, String title , ) {
//   final provider = Provider.of<WhatsAppNumberProvider>(context, listen: false);
//   final controller = TextEditingController(text: provider.number);

//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//     ),
//     builder: (context) => Padding(
//       padding: EdgeInsets.only(
//         left: 16,
//         right: 16,
//         top: 20,
//         bottom: MediaQuery.of(context).viewInsets.bottom + 20,
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(title, style: Theme.of(context).textTheme.headlineSmall),
//           const SizedBox(height: 15),
//           TextField(
//             controller: controller,
//             keyboardType: TextInputType.phone,
//             decoration: InputDecoration(
//               labelText: "WhatsApp Number",
//               prefixIcon: const Icon(Iconsax.call),
//               border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
//             ),
//           ),
//           const SizedBox(height: 20),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: () {
//                 final text = controller.text.trim();
//                 if (!provider.validateNumber(text)) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text("Invalid phone number")),
//                   );
//                   return;
//                 }
//                 provider.saveNumber(text);
//                 Navigator.pop(context);
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text("$title saved: ${provider.number}")),
//                 );
//               },
//               child: const Text("Save"),
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }

}
