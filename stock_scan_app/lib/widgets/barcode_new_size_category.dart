import 'package:flutter/material.dart';
import 'package:stock_scan_app/models/category.dart';

class BarcodeNewSizeCategory extends StatelessWidget {
  final TextEditingController packageController;
  final List<Category> categories;
  final String newBarcodeCategory;
  final ValueChanged<String?> onCategoryChanged;
  final String loadedCategory;

  BarcodeNewSizeCategory({
    required this.packageController,
    required this.categories,
    required this.newBarcodeCategory,
    required this.onCategoryChanged,
    required this.loadedCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: packageController,
            decoration: InputDecoration(
              labelText: 'Size',
              border: InputBorder.none,
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    width: 0.0,
                    color: const Color.fromARGB(255, 194, 228, 224)),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(width: 0.0, color: Colors.white),
              ),
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            value: newBarcodeCategory.isNotEmpty ? newBarcodeCategory : loadedCategory,
            decoration: InputDecoration(
              labelText: 'Category',
              border: InputBorder.none,
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    width: 0.0,
                    color: const Color.fromARGB(255, 194, 228, 224)),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(width: 0.0, color: Colors.white),
              ),
            ),
            items: categories.map((Category category) {
              return DropdownMenuItem<String>(
                value: category.name,
                child: Text(
                  category.name,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }).toList(),
            onChanged: onCategoryChanged,
          ),
        ),
      ],
    );
  }
}
