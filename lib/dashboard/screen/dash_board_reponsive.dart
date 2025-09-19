import 'package:flutter/material.dart';
import 'package:products_catelogs/dashboard/screen/dashboard_screen.dart';
import 'package:products_catelogs/dashboard/screen/dashboard_tablets.dart';

class ResponsiveDashboard extends StatelessWidget {
  const ResponsiveDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // Mobile
          return const DashboardScreen();
        } else {
          // Tablet
          return const DashboardTablets();
        }
      },
    );
  }
}
