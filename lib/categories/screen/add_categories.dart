import 'package:flutter/material.dart';
import 'package:products_catelogs/categories/provider/category_provider.dart';
import 'package:provider/provider.dart';


class AddCategoryScreen extends StatelessWidget {
  final bool isEdit;
  final Category? category;

  const AddCategoryScreen({super.key, this.isEdit = false, this.category});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController(text: category?.name ?? "");
    final provider = Provider.of<CategoryProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Category" : "Add Category"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Category Name",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: "Enter category name",
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;

                  if (isEdit && category != null) {
                    provider.editCategory(category!.id, name);
                  } else {
                    provider.addCategory(name);
                  }
                  Navigator.pop(context);
                },
                child: Text(
                  isEdit ? "Update Category" : "Save Category",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
