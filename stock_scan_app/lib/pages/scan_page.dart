import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_scan_app/models/storage.dart';
import 'package:stock_scan_app/widgets/barcode_new_name_brand.dart';
import 'package:stock_scan_app/widgets/barcode_new_size_category.dart';
import '../providers/storage_provider.dart';
import '../providers/category_provider.dart';
import '../services/barcode_service.dart';
import '../services/supabase_service.dart';

/// Page for scanning barcodes
class ScanPage extends StatefulWidget {
  @override
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  String? _selectedStorage;
  String _newBarcodeCategory = 'none';
  List<dynamic> _storageItemsCount = [];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController =
      TextEditingController(text: '1');
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _packageController = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService();

  Map<String, String> _loadedBarcodeData = {
    'id': '',
    'barcode': 'No code scanned yet',
    'name': '',
    'brand': '',
    'package_size': '',
    'category': 'none',
    'new_id': '',
  };

  @override
  void initState() {
    super.initState();
    final storages =
        Provider.of<StorageProvider>(context, listen: false).storages;
    if (storages.isNotEmpty) {
      _selectedStorage = storages[0].name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final storages = Provider.of<StorageProvider>(context).storages;
    final categories = Provider.of<CategoryProvider>(context).allCategories;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(26.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text('Last scanned: ',
                style: Theme.of(context).textTheme.bodyLarge),
            Text(_loadedBarcodeData['barcode'] ?? '',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
            SizedBox(height: 5),
            BarcodeNewNameBrand(
                nameController: _nameController,
                brandController: _brandController),
            BarcodeNewSizeCategory(
              packageController: _packageController,
              categories: categories,
              newBarcodeCategory: _newBarcodeCategory,
              loadedCategory: _loadedBarcodeData['category'] ?? '',
              onCategoryChanged: (String? newValue) {
                setState(() {
                  _newBarcodeCategory = newValue ?? '';
                });
              },
            ),
            SizedBox(height: 5),
            ElevatedButton.icon(
              onPressed: () => _scanBarcode(),
              icon:
                  Icon(Icons.camera_alt, color: Theme.of(context).primaryColor),
              label: Text('Start scanning',
                  style: TextStyle(color: Theme.of(context).primaryColor)),
            ),
            SizedBox(height: 5),
            SizedBox(
              height: 130.0,
              child: Column(
                children: [
                  Text("Item count in storages:",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge),
                  SizedBox(height: 5),
                  if (_storageItemsCount.isNotEmpty)
                    SizedBox(
                      height: 90.0,
                      child: ListView.builder(
                        itemCount: _storageItemsCount.length,
                        itemBuilder: (context, index) {
                          var item = _storageItemsCount[index];
                          return Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${storages.firstWhere((s) => s.id == item['storage_id']).name}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text('${item['item_count']}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.center),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: () {
                    setState(() {
                      int currentQuantity =
                          int.tryParse(_quantityController.text) ?? 0;
                      if (currentQuantity > 1) {
                        _quantityController.text =
                            (currentQuantity - 1).toString();
                      }
                    });
                  },
                ),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _quantityController,
                    decoration: InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      int currentQuantity =
                          int.tryParse(_quantityController.text) ?? 0;
                      _quantityController.text =
                          (currentQuantity + 1).toString();
                    });
                  },
                ),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedStorage,
                  items: storages.map((Storage storage) {
                    return DropdownMenuItem<String>(
                      value: storage.name,
                      child: Text(storage.name,
                          style: Theme.of(context).textTheme.bodyMedium),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedStorage = newValue;
                    });
                  },
                  hint: Text('Select storage'),
                ),
              ],
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => _saveItem("remove"),
                  child: Text('Remove Item',
                      style: TextStyle(color: Theme.of(context).primaryColor)),
                ),
                ElevatedButton(
                  onPressed: () => _saveItem("add"),
                  child: Text('Add Item',
                      style: TextStyle(color: Theme.of(context).primaryColor)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _resetBarcodeData() {
    _storageItemsCount = [];
    _loadedBarcodeData = {
      'id': '',
      'barcode': 'No code scanned yet',
      'name': '',
      'brand': '',
      'package_size': '',
      'category': 'none',
      'new_id': '',
    };
    _nameController.text = '';
    _brandController.text = '';
    _packageController.text = '';
    _newBarcodeCategory = '';
    }

  bool _isBarcodeChanged() {
    return _nameController.text != _loadedBarcodeData['name'] ||
        _brandController.text != _loadedBarcodeData['brand'] ||
        _packageController.text != _loadedBarcodeData['package_size'] ||
        (_newBarcodeCategory != '') && (_newBarcodeCategory != _loadedBarcodeData['category']);
  }

  bool _isValidQuantity() {
    return int.tryParse(_quantityController.text) != null &&
        int.parse(_quantityController.text) > 0 &&
        !_quantityController.text.contains(RegExp(r'[^0-9]'));
  }

  Future<void> _saveItem(String operation) async {
    if (_loadedBarcodeData['barcode'] == 'No code scanned yet') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No barcode was scanned!')),
      );
      return;
    }

    if (_isBarcodeChanged()) {
      await _updateUserBarcode();
    }

    if (!_isValidQuantity()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quantity is 0')),
      );
      return;
    }

    if (_selectedStorage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Create a storage!')),
      );
      return;
    }

    await _updateItemQuantity(operation);
  }

  Future<void> _updateUserBarcode() async {
    final categories =
        Provider.of<CategoryProvider>(context, listen: false).allCategories;

    Map<String, dynamic> barcodeData = {
      'user_id': _supabaseService.supabase.auth.currentUser!.id,
      'id': _loadedBarcodeData['id'],
      'barcode': _loadedBarcodeData['barcode'],
      'name': _nameController.text,
      'brand': _brandController.text,
      'package_size': _packageController.text,
      'category_id': _newBarcodeCategory=='' ?  
      categories.firstWhere((c) => c.name == 'none').id
      : categories.firstWhere((c) => c.name == _newBarcodeCategory).id,
    };
    await _supabaseService.updateUserBarcode(barcodeData);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Barcode was successfully saved.')),
    );
  }

  int _calculateNewQuantity(String operation, dynamic item) {
    int new_value = 0;
    if (operation == "add") {
      new_value = item == null
          ? int.parse(_quantityController.text)
          : item['item_count'] + int.parse(_quantityController.text);
    } else if (operation == "remove") {
      new_value = item == null
          ? 0
          : item['item_count'] - int.parse(_quantityController.text);
    }
    return new_value;
  }

  Future<void> _updateItemQuantity(String operation) async {
    final storages =
        Provider.of<StorageProvider>(context, listen: false).storages;
    String selectedStorageId =
        storages.firstWhere((s) => s.name == _selectedStorage).id;
    var item = _storageItemsCount.firstWhere(
        (item) => item['storage_id'] == selectedStorageId,
        orElse: () => null);
    int new_value = _calculateNewQuantity(operation, item);

    if (new_value < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot remove ${_quantityController.text}')),
      );
      return;
    }

    if (new_value == 0 && operation == "remove") {
      await _removeItem(selectedStorageId);
      return;
    }

    await _upsertItem(selectedStorageId, item, new_value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Item was successfully saved.')),
    );

    await Provider.of<StorageProvider>(context, listen: false)
        .fetchStorages(_supabaseService.supabase.auth.currentUser!.id);
  }

  Future<void> _removeItem(String selectedStorageId) async {
    await _supabaseService.removeItem(
        _loadedBarcodeData['id']!, selectedStorageId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Item was successfully removed.')),
    );
    _storageItemsCount
        .removeWhere((item) => item['storage_id'] == selectedStorageId);
    await Provider.of<StorageProvider>(context, listen: false)
        .fetchStorages(_supabaseService.supabase.auth.currentUser!.id);
  }

  Future<void> _upsertItem(
      String selectedStorageId, dynamic item, int new_value) async {
    final user = _supabaseService.supabase.auth.currentUser;
    Map<String, dynamic> itemData = {
      'user_id': user!.id,
      'storage_id': selectedStorageId,
      'barcode_id': _loadedBarcodeData['id'],
      'quantity': new_value,
    };

    if (item != null) {
      itemData['id'] = item['item_id'];
      await _supabaseService.upsertItem(itemData);
      item['item_count'] = new_value;
    } else {
      await _supabaseService.upsertItem(itemData);
      _storageItemsCount.add({
        'item_id': itemData['id'],
        'storage_id': selectedStorageId,
        'item_count': new_value,
      });
    }
  }

  Future<void> _scanBarcode() async {
    setState(() {
      _resetBarcodeData();
    });
    //String scannedBarcode = await BarcodeService().scanBarcode();
    String? scannedBarcode = await BarcodeService.scan(context);
    //String scannedBarcode = '44';
    if (scannedBarcode != null) {
      setState(() {
        _loadedBarcodeData['barcode'] = scannedBarcode;
      });
      await _loadBarcodeData(scannedBarcode);
    } else {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to scan the barcode. Please try again.')),
      );
    }
  }

  Future<void> _loadBarcodeData(String scannedBarcode) async {
    final loadedBarcode =
        await _supabaseService.fetchBarcodeData(scannedBarcode);

    if (loadedBarcode.isNotEmpty) {
      _updateLoadedBarcodeData(loadedBarcode);
      await _loadItemStorageData();
    } else {
      await _addNewBarcode();
    }
  }

  Future<void> _addNewBarcode() async {
    try {
      final newBarcode = await _supabaseService
          .addBarcodeToDatabase(_loadedBarcodeData['barcode']!);
      _updateLoadedBarcodeData(newBarcode);

    } catch (e) {
      print('Error inserting barcode: $e');
    }
  }

  Future<void> _loadItemStorageData() async {
    final storageItems =
        await _supabaseService.fetchItemStorageData(_loadedBarcodeData['id']!);

    if (storageItems.isNotEmpty) {
    setState(() {
      _storageItemsCount = storageItems;
    });
    }
  }

  void _updateLoadedBarcodeData(loadedBarcode) {
    _loadedBarcodeData['id'] = loadedBarcode[0]['id'];
    _loadedBarcodeData['name'] = loadedBarcode[0]['name'];
    _loadedBarcodeData['brand'] = loadedBarcode[0]['brand'];
    _loadedBarcodeData['package_size'] = loadedBarcode[0]['package_size'];
    final categories =
        Provider.of<CategoryProvider>(context, listen: false).allCategories;
    _loadedBarcodeData['category'] = categories
        .firstWhere((c) => c.id == loadedBarcode[0]['category_id'])
        .name;


    _nameController.text = _loadedBarcodeData['name']!;
    _brandController.text = _loadedBarcodeData['brand']!;
    _packageController.text = _loadedBarcodeData['package_size']!;
    
  }
}
