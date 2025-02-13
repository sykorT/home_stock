import 'package:flutter/material.dart';
import 'package:stock_scan_app/models/category.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategorySettingsPage extends StatefulWidget {
  final Function(List<Category>) onCategoriesUpdated;
  final user = Supabase.instance.client.auth.currentUser;
  final List<Category> userCategories;

  CategorySettingsPage({Key? key, required this.userCategories, required this.onCategoriesUpdated}) : super(key: key);

  @override
  _CategorySettingsPageState createState() => _CategorySettingsPageState();
}


class _CategorySettingsPageState extends State<CategorySettingsPage> {
  final TextEditingController _nameController = TextEditingController();
  late List<Category> editedUserCategories;

  @override
  void initState() {
    super.initState();
    editedUserCategories = List.from(widget.userCategories);
  }

  // Function to add a new category
  void _addUserCategory() async {
    if (_nameController.text.isNotEmpty) {
      try {
        final categoryData = await Supabase.instance.client.from('categories').insert({
          'user_id': widget.user!.id,
          'name': _nameController.text,
        }).select();

        final newCategory = Category(
          id: categoryData[0]['id'],
          name: categoryData[0]['name'],
        );

        setState(() {
          editedUserCategories.add(newCategory);
        });
        widget.onCategoriesUpdated(List.from(editedUserCategories)); // Pass updated list to parent
        _nameController.clear();
      } catch (e) {
        print('Error inserting category: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inserting category: $e')),
        );
      }
    }
  }

  // Function to rename a category
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
                await Supabase.instance.client.from('categories').update({
                  'name': _nameController.text,
                }).eq('id', category.id).eq('user_id', widget.user!.id);
                widget.onCategoriesUpdated(List.from(editedUserCategories)); // Pass updated list to parent
                Navigator.pop(context);
              },
              child: Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  // Function to delete a category
  void _deleteCategory(Category category) async {
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
                Navigator.pop(context);
                try {
                  await Supabase.instance.client
                      .from('categories')
                      .delete()
                      .eq('id', category.id)
                      .eq('user_id', widget.user!.id);

                  setState(() {
                    editedUserCategories.remove(category);
                  });
                  widget.onCategoriesUpdated(List.from(editedUserCategories)); // Pass updated list to parent
                } catch (e) {
                  print('Error deleting category: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting category: $e')),
                  );
                }
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Category Settings'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(26.0, 16.0, 26.0, 16.0),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Category name',
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addUserCategory,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              itemCount: editedUserCategories.length,
              itemBuilder: (context, index) {
                final category = editedUserCategories[index];
                return ListTile(
                  title: Text(category.name, style: Theme.of(context).textTheme.bodyMedium,),
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
