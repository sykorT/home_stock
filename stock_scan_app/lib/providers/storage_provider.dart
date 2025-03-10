import 'package:flutter/material.dart';
import '../models/storage.dart';
import '../models/inventory_item.dart';
import '../services/supabase_service.dart';

class StorageProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  List<Storage> _storages = [];
  String? selectedStorage;

  List<Storage> get storages => _storages;
  String? get storage => selectedStorage;

  final Map<int, IconData> homeStorageIcons = {
    1: Icons.kitchen,
    2: Icons.ac_unit,
    3: Icons.shelves,
    4: Icons.archive,
    5: Icons.pets,
    6: Icons.garage,
    7: Icons.home_work,
    8: Icons.roofing,
    9: Icons.checkroom,
    10: Icons.local_laundry_service,
    11: Icons.bathroom,
    12: Icons.medical_services,
    13: Icons.menu_book,
    14: Icons.toys,
    15: Icons.build,
    16: Icons.grass,
    17: Icons.wine_bar,
    18: Icons.bed,
  };

  Future<void> fetchStorages(String userId) async {
    final response = await _supabaseService.fetchStorages(userId);
    List<Storage> storages = [];

    for (var storage in response) {
      final itemsResponse =
          await _supabaseService.fetchItems(storage['id'], userId);
      final items = itemsResponse.map((item) {
        return InventoryItem(
          storageID: item['storage_id'],
          productName: item['normalized_item_name'],
          quantity: item['total_quantity'],
          category: item['item_category'],
        );
      }).toList();

      storages.add(Storage(
        id: storage['id'],
        name: storage['name'],
        items: items,
        iconId: storage['icon_id'],
      ));
    }

    _storages = storages;
    if (_storages.isNotEmpty) {
      selectedStorage = _storages[0].name;
    }
    notifyListeners();
  }

  Future<Storage> addStorage(String name) async {
    final storageData = await _supabaseService.addStorage(name);

    final newStorage = Storage(
      id: storageData.id,
      name: storageData.name,
      iconId: storageData.iconId,
    );

    _storages.add(newStorage);
    notifyListeners();
    return newStorage;
  }

  Future<bool> deleteStorage(String storageId) async {
    try {
      await _supabaseService.deleteStorage(storageId);
      _storages.removeWhere((storage) => storage.id == storageId);
      if (_storages.isNotEmpty) {
        selectedStorage = _storages[0].name;
      } else {
        selectedStorage = null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting storage: $e');
      return false;
    }
  }

  Future<void> updateStorageName(String storageId, String newName) async {
    await _supabaseService.updateStorageName(storageId, newName);
    final storage = _storages.firstWhere((storage) => storage.id == storageId);
    if (storage.name == selectedStorage) {
      selectedStorage = newName;
    }    
    storage.name = newName;
    notifyListeners();
  }

  Future<void> updateStorageIcon(String storageId, int newIconId) async {
    await _supabaseService.updateStorageIcon(storageId, newIconId);
    final storage = _storages.firstWhere((storage) => storage.id == storageId);
    storage.iconId = newIconId;
    notifyListeners();
  }

  void setSelectedStorage(String? newValue) {
    selectedStorage = newValue;
    notifyListeners();
  }


}
