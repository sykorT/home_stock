import 'package:flutter/material.dart';
import 'package:stock_scan_app/models/category.dart';
import 'package:stock_scan_app/models/inventory_item.dart';
import 'package:stock_scan_app/models/storage.dart';

/// Screen displaying a list of storages and their items
class InventoryPage extends StatefulWidget {
  final List<Storage> storages;
  final List<Category> categories;
  final Map<int, IconData> sampleIcons;

  const InventoryPage({
    Key? key,
    required this.storages,
    required this.sampleIcons,
    required this.categories,
  }) : super(key: key);

  @override
  _InventoryPageState createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  Storage? selectedStorage;
  String selectedCategory = 'All';
  bool showNames = false;

  @override
  void dispose() {
    // Deselect category when leaving the page
    selectedCategory = 'All';
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              flex:  showNames ? 3 : 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0,0,40.0,0),
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: widget.categories.any((category) => category.name == selectedCategory) ? selectedCategory : 'All',
                  items: <String>['All', ..._getSortedCategories()].map((String value) {
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
              // Left menu
              Expanded(
                flex: showNames ? 2 : 1,
                child: ListView.builder(
                  itemCount: widget.storages.length + 1,
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
                      final storage = widget.storages[index - 1];
                      return ListTile(
                        leading: Icon(widget.sampleIcons[storage.iconId] ?? Icons.storage),
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
              // List of items on the right
              Expanded(
                flex: showNames ? 3 : 4,
                child: ListView.builder(
                  itemCount: _getFilteredItems().length,
                  itemBuilder: (context, index) {
                    final item = _getFilteredItems()[index];
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
                          child: Text('${item.quantity}', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center,),
                          ),
                          Expanded(
                          flex: 1,
                          child: Row(
                            children: widget.storages
                              .where((storage) => storage.items.any((storageItem) => storageItem.productName == item.productName))
                              .map((storage) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                child: Icon(widget.sampleIcons[storage.iconId] ?? Icons.storage, size: 16),
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

  /// Get sorted list of categories by name
  List<String> _getSortedCategories() {
    final sortedCategories = widget.categories.map((category) => category.name).toList()..sort();
    return sortedCategories;
  }

  /// Get filtered list of items based on selected storage and category
  List<InventoryItem> _getFilteredItems() {
    final items = <InventoryItem>[];
    final Map<String, int> itemQuantityMap = {};

    String category_id = '0';
    if (selectedCategory != 'All') {
      try{
        category_id = widget.categories.firstWhere((s) => s.name == selectedCategory).id;
      } catch (e) {
        selectedCategory = 'All';
      }
    }
    
    if (selectedStorage == null) {
      for (var storage in widget.storages) {
        for (var item in storage.items) {
            if (selectedCategory == 'All' || item.category == category_id) {
            itemQuantityMap[item.productName] = (itemQuantityMap[item.productName] ?? 0) + item.quantity;
            }
        }
      }
    } else {
      for (var item in selectedStorage!.items) {
        if (selectedCategory == 'All' || item.category == category_id) {
          itemQuantityMap[item.productName] = (itemQuantityMap[item.productName] ?? 0) + item.quantity;
        }
      }
    }

    itemQuantityMap.forEach((productName, quantity) {
      final category = widget.storages
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
