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

  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
        // První řádek se vstupním polem a dropdownem
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search),
                    iconColor: Theme.of(context).primaryColor,
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          width: 0.0,
                          color: const Color.fromARGB(255, 194, 228, 224)),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(width: 0.0, color: Colors.white),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            ),
            SizedBox(
              height: 64,
              width: 15,
              child: VerticalDivider(
                color: Colors.grey, // Line color
                thickness: 1, // Line thickness
                indent: 2, // Top padding
                endIndent: 2, // Bottom padding
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: DropdownButton<String>(
                  isExpanded: true,
                  underline: SizedBox(),
                  value: categories
                          .any((category) => category.name == selectedCategory)
                      ? selectedCategory
                      : 'All',
                  items: <String>['All', ..._getSortedCategories(categories)]
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value,
                          style: Theme.of(context).textTheme.bodyMedium),
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
        Divider(
          color: Colors.grey, // Line color
          height: 2, // Spacing around the divider
          thickness: 1, // Line thickness
          indent: 2, // Top padding
          endIndent: 2, // Bottom padding
        ),

        // Druhý řádek s tlačítkem a seznamem

        Expanded(
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 5),
                child: SizedBox(
                  width: showNames ? 160 : 65,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Aligns children to the left
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4.0, 4, 0, 4),
                        child: IconButton(
                          alignment: Alignment.center,
                          onPressed: () {
                            setState(() {
                              showNames = !showNames;
                            });
                          },
                          icon: Icon(showNames
                              ? Icons.grid_view_outlined
                              : Icons.list_alt_outlined),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: storages.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return ListTile(
                                leading: Icon(Icons.storage),
                                selected: selectedStorage == null, 
                                shape: Border(
                                  top: BorderSide(
                                      color: Colors.grey,
                                      width: 0.5), // Top border
                                  bottom: BorderSide(
                                      color: Colors.grey,
                                      width: 0.5), // Bottom border
                                ),
                                title: showNames
                                    ? Text('All',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium)
                                    : null,
                                onTap: () {
                                  setState(() {
                                    selectedStorage = null;
                                  });
                                },
                              );
                            } else {
                              final storage = storages[index - 1];
                              return ListTile(
                                selected: selectedStorage == storage, 
                                leading: Icon(storageIcons[storage.iconId]),
                                shape: Border(
                                  top: BorderSide(color: Colors.grey, width: 0.5), // Top border
                                  bottom: BorderSide(color: Colors.grey, width: 0.5), // Bottom border
                                ),
                                title: showNames
                                    ? Text(storage.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium)
                                    : null,
                                onTap: () {
                                  setState(() {
                                    selectedStorage = storage;
                                  });
                                },
                                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16), // Adjust padding here
                  
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Další ListView (hlavní seznam položek)
              VerticalDivider(
                color: Colors.grey, // Line color
                width: 2, // Spacing around the divider
                thickness: 1, // Line thickness
                indent: 2, // Top padding
                endIndent: 2, // Bottom padding
              ),
              Expanded(
                //flex: showNames ? 3 : 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18.0, 12, 2, 12),
                  child: ListView.builder(
                    itemCount:
                        _getFilteredItems(storages, categories, _searchQuery)
                            .length,
                    itemBuilder: (context, index) {
                      final item = _getFilteredItems(
                          storages, categories, _searchQuery)[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(item.productName,
                                  style: Theme.of(context).textTheme.bodyMedium),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('${item.quantity}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center),
                            ),
                            Expanded(
                              flex: 1,
                              child: Row(
                                children: storages
                                    .where((storage) => storage.items.any(
                                        (storageItem) =>
                                            storageItem.productName ==
                                            item.productName))
                                    .map((storage) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 2.0),
                                          child: Icon(
                                              storageIcons[storage.iconId],
                                              size: 16),
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
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<String> _getSortedCategories(List<Category> categories) {
    final sortedCategories =
        categories.map((category) => category.name).toList()..sort();
    return sortedCategories;
  }

  List<InventoryItem> _getFilteredItems66(
      List<Storage> storages, List<Category> categories) {
    final items = <InventoryItem>[];
    final Map<String, int> itemQuantityMap = {};

    String categoryId = '0';
    if (selectedCategory != 'All') {
      try {
        categoryId =
            categories.firstWhere((s) => s.name == selectedCategory).id;
      } catch (e) {
        selectedCategory = 'All';
      }
    }

    if (selectedStorage == null) {
      for (var storage in storages) {
        for (var item in storage.items) {
          if (selectedCategory == 'All' || item.category == categoryId) {
            itemQuantityMap[item.productName] =
                (itemQuantityMap[item.productName] ?? 0) + item.quantity;
          }
        }
      }
    } else {
      for (var item in selectedStorage!.items) {
        if (selectedCategory == 'All' || item.category == categoryId) {
          itemQuantityMap[item.productName] =
              (itemQuantityMap[item.productName] ?? 0) + item.quantity;
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

  List<InventoryItem> _getFilteredItems(
      List<Storage> storages, List<Category> categories, String searchQuery) {
    final items = <InventoryItem>[];
    final Map<String, int> itemQuantityMap = {};

    String categoryId = '0';
    if (selectedCategory != 'All') {
      try {
        categoryId =
            categories.firstWhere((s) => s.name == selectedCategory).id;
      } catch (e) {
        selectedCategory = 'All';
      }
    }

    bool matchesSearch(String productName) {
      return searchQuery.isEmpty ||
          productName.toLowerCase().contains(searchQuery.toLowerCase());
    }

    if (selectedStorage == null) {
      for (var storage in storages) {
        for (var item in storage.items) {
          if ((selectedCategory == 'All' || item.category == categoryId) &&
              matchesSearch(item.productName)) {
            itemQuantityMap[item.productName] =
                (itemQuantityMap[item.productName] ?? 0) + item.quantity;
          }
        }
      }
    } else {
      for (var item in selectedStorage!.items) {
        if ((selectedCategory == 'All' || item.category == categoryId) &&
            matchesSearch(item.productName)) {
          itemQuantityMap[item.productName] =
              (itemQuantityMap[item.productName] ?? 0) + item.quantity;
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
