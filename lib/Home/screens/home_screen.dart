import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:products_catelogs/categories/screen/categories_managment.dart';
import 'package:products_catelogs/products/screen/products_management.dart';


class HomeScreen extends StatelessWidget {
   HomeScreen({super.key});


  @override
  Widget build(BuildContext context) {

    // Data for the menu items
    final List<Map<String, dynamic>> menuItems = [
      {
        'title': 'Products',
        'icon': Iconsax.home,
        'color': Colors.purple,
        'screen':  ProductsScreen(),
      },
       {
        'title': 'Categories',
        'icon': Iconsax.category,
        'color': Colors.green,
        'screen': const CategoryListScreen(),
      },
      {
        'title': 'Vendors',
        'icon': Iconsax.user,
        'color': Colors.blue,
        'screen': const VendorsScreen(),
      },
      {
        'title': 'Coupons',
        'icon': Iconsax.discount_circle,
        'color': Colors.deepPurpleAccent,
        'screen': const CouponsScreen(),
      },
      {
        'title': 'Settings',
        'icon': Iconsax.setting_2,
        'color': Colors.pink,
        'screen': const SettingsScreen(),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Your Store'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          itemCount: menuItems.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final item = menuItems[index];
            return ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => item['screen']),
                );
              },
              tileColor: Colors.grey.shade100,
              leading: CircleAvatar(
                backgroundColor: item['color'],
                child: Icon(item['icon'], color: Colors.white),
              ),
              title: Text(item['title']),
              trailing: const Icon(Icons.arrow_forward_ios),
            );
          },
        ),
      ),
    );
  }
}

class VendorsScreen extends StatelessWidget {
  const VendorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendors')),
      body: const Center(child: Text('Vendors Screen')),
    );
  }
}

class CouponsScreen extends StatelessWidget {
  const CouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coupons')),
      body: const Center(child: Text('Coupons Screen')),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings Screen')),
    );
  }
}
