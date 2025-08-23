import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:products_catelogs/categories/screen/add_categories.dart';


class Category {
  String name;
  String code;
  String image;
  bool selected;

  Category({
    required this.name,
    required this.code,
    required this.image,
    this.selected = false,
  });
}

class CategoryScreen extends StatefulWidget {
  final List<Category> categories;

  const CategoryScreen({super.key, required this.categories});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredCategories = widget.categories.where((category) {
      return category.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AddCategoryScreen(),));
            },
            icon: const Icon(Iconsax.folder_add),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🔎 Search bar only (no filter)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search categories...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 16),

            // Table headers
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.blueGrey.shade400,
                    ),
                    child: Row(
                      children: const [
                        SizedBox(width: 40, child: Text('')),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Name',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            'Actions',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),

            // Category list
            Expanded(
              child: ListView.separated(
                itemCount: filteredCategories.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final category = filteredCategories[index];
                  return Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Checkbox(
                          value: category.selected,
                          onChanged: (val) {
                            setState(() {
                              category.selected = val ?? false;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Image.asset(
                              category.image,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  category.code,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Action icons (Edit + Delete)
                      Row(
                        children: const [
                          Icon(Iconsax.edit, color: Colors.grey),
                          SizedBox(width: 8),
                          Icon(Iconsax.trash, color: Colors.red),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
