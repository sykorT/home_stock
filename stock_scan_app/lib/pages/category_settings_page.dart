import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';

class CategorySettingsPage extends StatefulWidget {

  CategorySettingsPage({Key? key}) : super(key: key);

  @override
  _CategorySettingsPageState createState() => _CategorySettingsPageState();
}

class _CategorySettingsPageState extends State<CategorySettingsPage> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  void _addCategory(CategoryProvider categoryProvider) async {
    if (_nameController.text.isNotEmpty) {
      try {
        await categoryProvider.addCategory(_nameController.text);
        _nameController.clear();
      } catch (e) {
        _showErrorSnackBar('Error inserting category: $e');
      }
    }
  }

  void _renameCategory(Category category, CategoryProvider categoryProvider) {
    _nameController.text = category.name;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Rename category'),
          content: TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'New category name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await categoryProvider.updateCategoryName(category.id, _nameController.text);
                Navigator.pop(context);
              },
              child: Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  void _deleteCategory(Category category, CategoryProvider categoryProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete category'),
          content: Text('Are you sure you want to delete this category?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                bool removed = await categoryProvider.deleteCategory(category.id);
                if (!removed) {
                  _showErrorSnackBar('Error deleting category');
                }
                Navigator.pop(context);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Category Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(26.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Category name',
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {_addCategory(categoryProvider);},
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: categoryProvider.userCategories.length,
                itemBuilder: (context, index) {
                  final category = categoryProvider.userCategories[index];
                  return ListTile(
                    title: Text(category.name, style: Theme.of(context).textTheme.bodyMedium),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.drive_file_rename_outline),
                          onPressed: () {
                            _renameCategory(category, categoryProvider);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            _deleteCategory(category, categoryProvider);
                          },
                        ),
                      ],
                    ),
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
