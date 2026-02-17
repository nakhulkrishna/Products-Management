import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:products_catelogs/staff_management/provider/provider.dart';
import 'package:products_catelogs/staff_management/screen/staff_management.dart';
import 'package:products_catelogs/theme/widgets/app_components.dart';
import 'package:products_catelogs/theme/widgets/reference_scaffold.dart';
import 'package:provider/provider.dart';

class SalesmanScreen extends StatelessWidget {
  const SalesmanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReferenceScaffold(
      title: "Salesmen",
      subtitle: "Manage staff accounts",
      actions: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddStaffScreen()),
            );
          },
          icon: const Icon(Iconsax.add),
        ),
      ],
      bodyPadding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      body: Consumer<StaffProvider>(
        builder: (context, staffProvider, child) {
          final salesmen = staffProvider.staffList;
          if (salesmen.isEmpty) {
            return const AppEmptyState(
              assetPath: 'asstes/Image-2.png',
              title: "No salesmen found",
              subtitle: "Add staff to start assigning orders",
            );
          }

          return ListView(
            children: [
              AppSectionCard(
                title: "Team Members",
                subtitle: "${salesmen.length} active staff",
                child: Column(
                  children: [
                    for (final salesman in salesmen)
                      buildSalesmanTile(
                        staffProvider,
                        context,
                        salesman['username'] ?? '',
                        salesman['email'] ?? '',
                        salesman['id'] ?? '',
                      ),
                  ],
                ),
              ),
            ],
          );
        },
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
    return AppInfoTile(
      icon: Iconsax.user,
      title: name,
      subtitle: email,
      trailing: IconButton(
        onPressed: () {
          log(id);
          provider.deleteStaff(id);
        },
        icon: const Icon(Iconsax.trash, color: Colors.red),
      ),
    );
  }
}
