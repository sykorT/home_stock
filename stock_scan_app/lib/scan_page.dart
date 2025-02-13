import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:stock_scan_app/models/category.dart';
import 'package:stock_scan_app/models/storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Page for scanning barcodes
class ScanPage extends StatefulWidget {
  final List<Storage> storages;
  final List<Category> categories;
  final Function fetchDataFromDB;
  final user = Supabase.instance.client.auth.currentUser;

  ScanPage(
      {Key? key,
      required this.storages,
      required this.categories,
      required this.fetchDataFromDB})
      : super(key: key);

  @override
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  Map<String, String> _loadedBarcodeData = {
    'id': '',
    'barcode': 'No code scanned yet',
    'name': '',
    'brand': '',
    'package_size': '',
    'category': 'none',
    'new_id': '',
  };
  String? _selectedStorage;
  String _newBarcodeCategory = '';

  List<dynamic> _storageItemsCount = [];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _packageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.storages.isNotEmpty) {
      _selectedStorage = widget.storages[0].name;
    }
  }
  
    

  /// Function to start barcode scanning
  Future<void> scanBarcode() async {
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

    String scannedBarcode;
    try {
      scannedBarcode = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.DEFAULT);
    } catch (e) {
      scannedBarcode = 'Error scanning';
    }

    if (!mounted) return;
    //scannedBarcode = '66666';

    // Load barcode data from the database if it exists
    if (scannedBarcode != '-1' && scannedBarcode != 'Error scanning') {
      setState(() {
        _loadedBarcodeData['barcode'] = scannedBarcode;
      });

      final loadedBarcode = await Supabase.instance.client
      .rpc('get_all_barcodes', params: {
        'user_uuid': widget.user!.id,
        'barcode_selected': scannedBarcode
      });

      // If barcode exists in the database set values to display, load the item data
      if (loadedBarcode != null && loadedBarcode.isNotEmpty) {
        setState(() {
          _loadedBarcodeData['name'] =
              loadedBarcode[0]['name'] == "" ? "" : loadedBarcode[0]['name'];
          _loadedBarcodeData['brand'] =
              loadedBarcode[0]['brand'] == "" ? "" : loadedBarcode[0]['brand'];
          _loadedBarcodeData['package_size'] = loadedBarcode[0]['package_size'] == ""
              ? ""
              : loadedBarcode[0]['package_size'];
          if (loadedBarcode[0]['category_id'] != null) {
            _loadedBarcodeData['category'] = widget.categories
                .firstWhere((c) => c.id == loadedBarcode[0]['category_id'])
                .name;
          }
          _loadedBarcodeData['id'] = loadedBarcode[0]['id'];

          _nameController.text = _loadedBarcodeData['name']!;
          _brandController.text = _loadedBarcodeData['brand']!;
          _packageController.text = _loadedBarcodeData['package_size']!;
          _newBarcodeCategory = _loadedBarcodeData['category']!;
        });

        // Load item data in storages
        final response = await Supabase.instance.client
            .rpc('get_item_storage_counts', params: {
          'user_uuid': widget.user!.id,
          'barcode_selected': _loadedBarcodeData['id']
        });
        final storageItemsCount = response as List<dynamic>;

        if (storageItemsCount.isNotEmpty) {
          setState(() {
            _storageItemsCount = storageItemsCount;
          });
        }
      }
      // If barcode does not exist in the database, add it
      else {
        try {
            final response =
            await Supabase.instance.client.from('barcodes').insert({
            'barcode': _loadedBarcodeData['barcode'],
            }).select();

          setState(() {
            _loadedBarcodeData['id'] = response[0]['id'] as String;
          });

            await Supabase.instance.client.from('user_barcodes').insert({
            'id': _loadedBarcodeData['id'],
            'user_id': widget.user!.id,
            'barcode': _loadedBarcodeData['barcode'],
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Barcode added to database.')),
          );
        } catch (e) {
          print('Error inserting barcode: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error inserting barcode: $e')),
          );
        }
      }
    }
  }


  /// Function to save the scanned item
  Future<void> _saveItem(String operation) async {
    if (_loadedBarcodeData['barcode'] == 'No code scanned yet') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No barcode was scanned!')),
      );
      return;
    }

    if (_isBarcodeChanged() ){
      await _updateUserBarcode();
    }

    if (int.tryParse(_quantityController.text) == null ||
        int.parse(_quantityController.text) <= 0 ||
        _quantityController.text.contains(RegExp(r'[^0-9]'))) {
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
    String selectedStorageId =
        widget.storages.firstWhere((s) => s.name == _selectedStorage).id;

    var item = _storageItemsCount.firstWhere(
        (item) => item['storage_id'] == selectedStorageId,
        orElse: () => null);
    int new_value = 0;

    if (operation == "add") {
      if (item == null) {
        new_value = int.parse(_quantityController.text);
      } else {
        new_value = item['item_count'] + int.parse(_quantityController.text);
      }
    } else if (operation == "remove") {
      if (item == null) {
        return;
      } else {
        new_value = item['item_count'] - int.parse(_quantityController.text);
      }

      if (new_value < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot remove ${_quantityController.text}')),
        );
        return;
      }

      if (new_value == 0) {
        await Supabase.instance.client
            .from('items')
            .delete()
            .eq('barcode_id', _loadedBarcodeData['id']!)
            .eq('storage_id', selectedStorageId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item was successfully removed.')),
        );
        _storageItemsCount
            .removeWhere((item) => item['storage_id'] == selectedStorageId);
        await widget.fetchDataFromDB();
        return;
      }
    }

    if (item != null) {
      await Supabase.instance.client.from('items').upsert({
        'id': item['item_id'],
        'user_id': widget.user!.id,
        'storage_id': selectedStorageId,
        'barcode_id': _loadedBarcodeData['id'],
        'quantity': new_value,
      });
      setState(() {
        item['item_count'] = new_value;
      });
    } else {
      final new_item = await Supabase.instance.client.from('items').insert({
        'user_id': widget.user!.id,
        'storage_id': selectedStorageId,
        'barcode_id': _loadedBarcodeData['id'],
        'quantity': new_value,
      }).select();
      setState(() {
        _storageItemsCount.add({
          'item_id': new_item[0]['id'],
          'storage_id': selectedStorageId,
          'item_count': new_value,
        });
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Item was successfully saved.')),
    );

    // Call fetchDataFromDB to update storage data on the inventory page
    await widget.fetchDataFromDB();
  }

  Future<void> _updateUserBarcode() async {
    await Supabase.instance.client.from('user_barcodes').upsert({
      'user_id': widget.user!.id,
      'id': _loadedBarcodeData['id'],
      'barcode': _loadedBarcodeData['barcode'],
      'name': _nameController.text,
      'brand': _brandController.text,
      'package_size': _packageController.text,
      'category_id': widget.categories
          .firstWhere((c) => c.name == _newBarcodeCategory)
          .id,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Barcode was successfully saved.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(26.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'Last scanned: ',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              _loadedBarcodeData['barcode']!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 5),
            BarcodeNewNameBrand(),
            BarcodeNewSizeCategory(),
            SizedBox(height: 5),
            ElevatedButton.icon(
              onPressed: scanBarcode,
              icon:
                  Icon(Icons.camera_alt, color: Theme.of(context).primaryColor),
              label: Text(
                'Start scanning',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
            SizedBox(height: 5),
            SizedBox(
              height: 136.0, // Set the max height
              child: Column(
                children: [
                  Text(
                    "Item count in storages:",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  SizedBox(height: 5),
                  if (_storageItemsCount.isNotEmpty) ...[
                    SizedBox(
                      height: 130.0, // Set the max height
                      child: ListView.builder(
                        itemCount: _storageItemsCount.length,
                        itemBuilder: (context, index) {
                          var item = _storageItemsCount[index];
                          return Row(
                            children: [
                              Expanded(
                                child: Text(
                                    '${widget.storages.firstWhere((s) => s.id == item['storage_id']).name}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.center),
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
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                    ),
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
                SizedBox(width: 10), // Add spacing between elements
                DropdownButton<String>(
                  value: _selectedStorage,
                  items: widget.storages.map((Storage storage) {
                    return DropdownMenuItem<String>(
                      value: storage.name,
                      child: Text(
                        storage.name,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
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
                  child: Text(
                    'Remove Item',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _saveItem("add"),
                  child: Text(
                    'Add Item',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Row BarcodeNewSizeCategory() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _packageController, 
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
            value: _newBarcodeCategory.isNotEmpty ? _newBarcodeCategory : null,
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
            items: widget.categories.map((Category category) {
              return DropdownMenuItem<String>(
                value: category.name,
                child: Text(
                  category.name,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _newBarcodeCategory = newValue ?? '';
              });
            },
          ),
        ),
      ],
    );
  }


  Row BarcodeNewNameBrand() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Name',
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
          child: TextField(
            controller: _brandController,
            decoration: InputDecoration(
              labelText: 'Brand',
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
      ],
    );
  }
  
  bool _isBarcodeChanged() {
    return _nameController.text != _loadedBarcodeData['name'] ||
        _brandController.text != _loadedBarcodeData['brand'] ||
        _packageController.text != _loadedBarcodeData['package_size'] ||
        _newBarcodeCategory != _loadedBarcodeData['category'];
  }
}
