import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:products_catelogs/dashboard/provider/staff_provider.dart';
import 'package:products_catelogs/staff_management/screen/staff_management.dart';
import 'package:provider/provider.dart';

class SalesmanScreen extends StatelessWidget {
  const SalesmanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Salesmen"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddStaffScreen()),
              );
            },
            icon: Icon(Iconsax.add),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Consumer<StaffProvider>(
          builder: (context, staffProvider, child) {
            final salesmen =
                staffProvider.staffList; // Assuming this is a list of salesmen
            if (salesmen.isEmpty) {
              return const Center(child: Text("No salesmen found"));
            }
            return ListView.builder(
              itemCount: salesmen.length,
              itemBuilder: (context, index) {
                final salesman = salesmen[index];
                return buildSalesmanTile(
                  staffProvider,
                  context,
                  salesman['username'] ?? '',
                  salesman['email'] ?? '',
                  salesman['id'] ?? '',
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget buildSalesmanTile(
    StaffProvider provider,
    BuildContext context,
    String name,
    String email,
    String id,
  ) {
    final theme = Theme.of(context);
    return Container(
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
            child: const Icon(Iconsax.user, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(email, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              provider.deleteStaff(id);
            },
            icon: Icon(Iconsax.trash, color: Colors.red),
          ),
        ],
      ),
    );
  }
}
