import 'package:flutter/material.dart';
import '../models/storage.dart';
import '../models/inventory_item.dart';
import '../services/supabase_service.dart';

class StorageProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  List<Storage> _storages = [];

  List<Storage> get storages => _storages;

  Future<void> fetchStorages(String userId) async {
    final response = await _supabaseService.fetchStorages(userId);
    List<Storage> storages = [];

    for (var storage in response) {
      final itemsResponse = await _supabaseService.fetchItems(storage['id'], userId);
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
    notifyListeners();
  }
}
