import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import 'package:products_catelogs/dashboard/provider/staff_provider.dart';
import 'package:provider/provider.dart';

class AddCategories extends StatelessWidget {
  const AddCategories({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StaffProvider>(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Categories"),
        
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: "Categories",
                prefixIcon: const Icon(Iconsax.category),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: theme.cardColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: theme.cardColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                errorText: provider.submitted && provider.username.isEmpty
                    ? 'Username required'
                    : null,
              ),
              onChanged: provider.setUsername,
            ),

     
            Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                ),
                onPressed: () async {
                  provider.markSubmitted(); // set _submitted = true

                  if (!provider.validateFields()) return;

                  try {
                    await provider.submitStaff();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Staff Added Successfully')),
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },

                child: const Text(
                  "Add Categories",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
