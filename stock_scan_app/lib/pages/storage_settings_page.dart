import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_scan_app/models/storage.dart';
import 'package:stock_scan_app/providers/storage_provider.dart';

class StorageSettingsPage extends StatefulWidget {

  StorageSettingsPage({Key? key}) : super(key: key);

  @override
  _StorageSettingsPageState createState() => _StorageSettingsPageState();
}

class _StorageSettingsPageState extends State<StorageSettingsPage> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  // Function to add a new storage
  
  void _addStorage(StorageProvider storageProvider) async {
    if (_nameController.text.isNotEmpty) {
      try {
        await storageProvider.addStorage(_nameController.text);
        _nameController.clear();
      } catch (e) {
        _showErrorSnackBar('Error inserting category: $e');
      }
    }
  }


  // Function to select an icon for a storage
  void _selectIcon(Storage storage, StorageProvider storageProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select an icon'),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 10,
              children: storageProvider.homeStorageIcons.entries.map((entry) {
                return IconButton(
                  icon: Icon(entry.value),
                  onPressed: () async {
                    setState(() {
                      storage.iconId = entry.key;
                    });
                    await storageProvider.updateStorageIcon(storage.id, entry.key);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // Function to rename a storage
  void _renameStorage(Storage storage, StorageProvider storageProvider) {
    _nameController.text = storage.name;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Rename storage'),
          content: TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'New storage name'),
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
                await storageProvider.updateStorageName(storage.id, _nameController.text);
                Navigator.pop(context);
              },
              child: Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  // Function to delete a storage
  void _deleteStorage(Storage storage, StorageProvider storageProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete storage'),
          content: Text('Do you really want to delete the storage ${storage.name} and all its items?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                bool removed = await storageProvider.deleteStorage(storage.id);
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
    final storageProvider = context.watch<StorageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Storage Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(26.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Storage name',
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    _addStorage(storageProvider);
                  },
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: storageProvider.storages.length,
                itemBuilder: (context, index) {
                  final storage = storageProvider.storages[index];
                  return ListTile(
                    leading: Icon(storageProvider.homeStorageIcons[storage.iconId] ?? Icons.storage),
                    title: Text(
                      storage.name,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            _selectIcon(storage, storageProvider);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.drive_file_rename_outline),
                          onPressed: () {
                            _renameStorage(storage, storageProvider);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            _deleteStorage(storage, storageProvider);
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
