import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/storage_provider.dart';
import '../providers/category_provider.dart';
import '../models/storage.dart';
import '../models/category.dart';
import '../models/inventory_item.dart';

class InventoryPage extends StatefulWidget {
  @override
  _InventoryPageState createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  Storage? selectedStorage;
  String selectedCategory = 'All';
  bool showNames = false;

    @override
  void initState() {
    super.initState();
  }
  
  @override
  void dispose() {
    selectedCategory = 'All';
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().allCategories;
    final storages = context.watch<StorageProvider>().storages;
    final storageIcons = context.watch<StorageProvider>().homeStorageIcons;

    return Column(
      children: [
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: showNames ? 2 : 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7.0),
                child: IconButton(
                  alignment: Alignment.centerLeft,
                  onPressed: () {
                    setState(() {
                      showNames = !showNames;
                    });
                  },
                  icon: Icon(showNames ? Icons.grid_view_outlined : Icons.list_alt_outlined),
                ),
              ),
            ),
            Expanded(
              flex: showNames ? 3 : 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 40.0, 0),
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: categories.any((category) => category.name == selectedCategory) ? selectedCategory : 'All',
                  items: <String>['All', ..._getSortedCategories(categories)].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCategory = newValue!;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: showNames ? 2 : 1,
                child: ListView.builder(
                  itemCount: storages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return ListTile(
                        leading: Icon(Icons.storage),
                        iconColor: Theme.of(context).primaryColor,
                        title: showNames ? Text('All', style: Theme.of(context).textTheme.bodyMedium) : null,
                        onTap: () {
                          setState(() {
                            selectedStorage = null;
                          });
                        },
                      );
                    } else {
                      final storage = storages[index - 1];
                      return ListTile(
                        leading: Icon(storageIcons[storage.iconId]),
                        iconColor: Theme.of(context).primaryColor,
                        title: showNames ? Text(storage.name, style: Theme.of(context).textTheme.bodyMedium) : null,
                        onTap: () {
                          setState(() {
                            selectedStorage = storage;
                          });
                        },
                      );
                    }
                  },
                ),
              ),
              Expanded(
                flex: showNames ? 3 : 4,
                child: ListView.builder(
                  itemCount: _getFilteredItems(storages, categories).length,
                  itemBuilder: (context, index) {
                    final item = _getFilteredItems(storages, categories)[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(item.productName, style: Theme.of(context).textTheme.bodyMedium),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text('${item.quantity}', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                          ),
                          Expanded(
                            flex: 1,
                            child: Row(
                              children: storages
                                  .where((storage) => storage.items.any((storageItem) => storageItem.productName == item.productName))
                                  .map((storage) => Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                        child: Icon(storageIcons[storage.iconId], size: 16),
                                      ))
                                  .toList(),
                            ),
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
      ],
    );
  }

  List<String> _getSortedCategories(List<Category> categories) {
    final sortedCategories = categories.map((category) => category.name).toList()..sort();
    return sortedCategories;
  }

  List<InventoryItem> _getFilteredItems(List<Storage> storages, List<Category> categories) {
    final items = <InventoryItem>[];
    final Map<String, int> itemQuantityMap = {};

    String categoryId = '0';
    if (selectedCategory != 'All') {
      try {
        categoryId = categories.firstWhere((s) => s.name == selectedCategory).id;
      } catch (e) {
        selectedCategory = 'All';
      }
    }

    if (selectedStorage == null) {
      for (var storage in storages) {
        for (var item in storage.items) {
          if (selectedCategory == 'All' || item.category == categoryId) {
            itemQuantityMap[item.productName] = (itemQuantityMap[item.productName] ?? 0) + item.quantity;
          }
        }
      }
    } else {
      for (var item in selectedStorage!.items) {
        if (selectedCategory == 'All' || item.category == categoryId) {
          itemQuantityMap[item.productName] = (itemQuantityMap[item.productName] ?? 0) + item.quantity;
        }
      }
    }

    itemQuantityMap.forEach((productName, quantity) {
      final category = storages
          .expand((storage) => storage.items)
          .firstWhere((item) => item.productName == productName)
          .category;
      items.add(InventoryItem(
        productName: productName,
        quantity: quantity,
        category: category,
        storageID: "0",
      ));
    });

    return items;
  }
}
