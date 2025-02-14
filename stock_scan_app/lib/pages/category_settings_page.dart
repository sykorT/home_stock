import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../providers/auth_provider.dart';

class CategorySettingsPage extends StatefulWidget {
  final List<Category> userCategories;
  final Function(List<Category>) onCategoriesUpdated;

  CategorySettingsPage({Key? key, required this.userCategories, required this.onCategoriesUpdated}) : super(key: key);

  @override
  _CategorySettingsPageState createState() => _CategorySettingsPageState();
}

class _CategorySettingsPageState extends State<CategorySettingsPage> {
  final TextEditingController _nameController = TextEditingController();
  late List<Category> _editableCategories;

  @override
  void initState() {
    super.initState();
    _editableCategories = List.from(widget.userCategories);
  }

  void _addCategory() async {
    if (_nameController.text.isNotEmpty) {
      try {
        final newCategory = await Provider.of<CategoryProvider>(context, listen: false)
            .addCategory(_nameController.text);
        setState(() {
          _editableCategories.add(newCategory);
        });
        widget.onCategoriesUpdated(List.from(_editableCategories));
        _nameController.clear();
      } catch (e) {
        _showErrorSnackBar('Error inserting category: $e');
      }
    }
  }

  void _renameCategory(Category category) {
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
                setState(() {
                  category.name = _nameController.text;
                });
                await Provider.of<CategoryProvider>(context, listen: false)
                    .updateCategoryName(category.id, _nameController.text);
                widget.onCategoriesUpdated(List.from(_editableCategories));
                Navigator.pop(context);
              },
              child: Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  void _deleteCategory(Category category) {
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
                setState(() {
                  _editableCategories.remove(category);
                });
                await Provider.of<CategoryProvider>(context, listen: false)
                    .deleteCategory(category.id);
                widget.onCategoriesUpdated(List.from(_editableCategories));
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Category Settings'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Category name',
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addCategory,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _editableCategories.length,
              itemBuilder: (context, index) {
                final category = _editableCategories[index];
                return ListTile(
                  title: Text(category.name, style: Theme.of(context).textTheme.bodyMedium),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.drive_file_rename_outline),
                        onPressed: () {
                          _renameCategory(category);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _deleteCategory(category);
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
    );
  }
}
