import 'package:flutter/material.dart';
import 'package:stock_scan_app/models/storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageSettingsPage extends StatefulWidget {
  final List<Storage> storages;
  final Map<int, IconData> sampleIcons;
  final Function(List<Storage>) onStoragesUpdated;
  final user = Supabase.instance.client.auth.currentUser;

  StorageSettingsPage({Key? key, required this.storages, required this.sampleIcons, required this.onStoragesUpdated}) : super(key: key);

  @override
  _StorageSettingsPageState createState() => _StorageSettingsPageState();
}

class _StorageSettingsPageState extends State<StorageSettingsPage> {
  final TextEditingController _nameController = TextEditingController();
  late List<Storage> _editableStorages;

  @override
  void initState() {
    super.initState();
    _editableStorages = List.from(widget.storages); // Create a mutable copy
  }


  // Function to add a new storage
  void _addStorage() async {
    if (_nameController.text.isNotEmpty) {
      try {
        final storageData = await Supabase.instance.client.from('storages').insert({
          'user_id': widget.user!.id,
          'name': _nameController.text,
          'icon_id': 1, // Default icon ID
        }).select();

        final newStorage = Storage(
          id: storageData[0]['id'],
          name: storageData[0]['name'],
          iconId: storageData[0]['icon_id'],
        );

        setState(() {
          _editableStorages.add(newStorage);
        });
        widget.onStoragesUpdated(List.from(_editableStorages)); // Pass updated list to parent
        _nameController.clear();
      } catch (e) {
        print('Error inserting storage: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inserting storage: $e')),
        );
      }
    }
  }

  // Function to select an icon for a storage
  void _selectIcon(Storage storage, Map<int, IconData> sampleIcons) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select an icon'),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 10,
              children: sampleIcons.entries.map((entry) {
                return IconButton(
                  icon: Icon(entry.value),
                  onPressed: () async {
                    setState(() {
                      storage.iconId = entry.key;
                    });
                    await Supabase.instance.client.from('storages').update({
                      'icon_id': entry.key,
                    }).eq('id', storage.id).eq('user_id', widget.user!.id);
                    widget.onStoragesUpdated(_editableStorages);
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
  void _renameStorage(Storage storage) {
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
                setState(() {
                  storage.name = _nameController.text;
                });
                await Supabase.instance.client.from('storages').update({
                  'name': _nameController.text,
                }).eq('id', storage.id).eq('user_id', widget.user!.id);
                widget.onStoragesUpdated(_editableStorages);
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
  void _deleteStorage(Storage storage) {
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
                setState(() {
                  _editableStorages.remove(storage);
                });
                await Supabase.instance.client.from('storages').delete().eq('id', storage.id).eq('user_id', widget.user!.id);
                widget.onStoragesUpdated(List.from(_editableStorages));
                Navigator.pop(context);
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
        title: Text('Storage Settings'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Storage name',
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addStorage,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _editableStorages.length,
              itemBuilder: (context, index) {
                final storage = _editableStorages[index];
                return ListTile(
                  leading: Icon(widget.sampleIcons[storage.iconId] ?? Icons.storage),
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
                          _selectIcon(storage, widget.sampleIcons);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.drive_file_rename_outline),
                        onPressed: () {
                          _renameStorage(storage);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _deleteStorage(storage);
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
