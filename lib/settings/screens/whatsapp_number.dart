import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:products_catelogs/settings/provider/setting_provider.dart';
import 'package:provider/provider.dart';

class WhatsAppSettingsScreen extends StatelessWidget {
  const WhatsAppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WhatsAppNumberProvider>(context);
    final theme = Theme.of(context);

    final TextEditingController controller =
        TextEditingController(text: provider.number);

    return Scaffold(
      appBar: AppBar(
        title: const Text("WhatsApp Number Settings"),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                labelText: "WhatsApp Number",
                labelStyle: theme.textTheme.bodySmall,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              onPressed: () {
                String number = controller.text.trim();
                if (provider.validateNumber(number)) {

                  print(number);
                                    provider.saveNumber(number); // saves only the number
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Number saved successfully!")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Enter a valid number")),
                  );
                }
              },
              child: const Text("Save Number"),
            ),
          ],
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
    );
  }
}
