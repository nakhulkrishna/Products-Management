import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:products_catelogs/settings/provider/setting_provider.dart';
import 'package:products_catelogs/theme/widgets/app_components.dart';
import 'package:products_catelogs/theme/widgets/reference_scaffold.dart';
import 'package:provider/provider.dart';

class WhatsAppSettingsScreen extends StatefulWidget {
  const WhatsAppSettingsScreen({super.key});

  @override
  State<WhatsAppSettingsScreen> createState() => _WhatsAppSettingsScreenState();
}

class _WhatsAppSettingsScreenState extends State<WhatsAppSettingsScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<WhatsAppNumberProvider>().number,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WhatsAppNumberProvider>();

    return ReferenceScaffold(
      title: "WhatsApp Number",
      subtitle: "Used for order sharing",
      body: AppSectionCard(
        title: "Order Contact",
        subtitle: "This number is used for customer order communication",
        child: Column(
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "WhatsApp Number",
                prefixIcon: Icon(Iconsax.call),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final number = _controller.text.trim();
                  if (provider.validateNumber(number)) {
                    provider.saveNumber(number);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Number saved successfully"),
                      ),
                    );
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Enter a valid number")),
                  );
                },
                child: const Text("Save Number"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
