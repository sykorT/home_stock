import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/storage.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;
  late final user;

  SupabaseService() {
    user = supabase.auth.currentUser;
  }

  Future<List<dynamic>> fetchStorages(String userId) async {
    return await supabase.from('storages').select().eq('user_id', userId);
  }

  Future<List<dynamic>> fetchItems(String storageId, String userId) async {
    return await supabase
        .from('storage_summary')
        .select('storage_id, total_quantity, item_category, normalized_item_name')
        .eq('storage_id', storageId)
        .eq('user_id', userId)
        .order('normalized_item_name', ascending: true);
  }

  Future<List<dynamic>> fetchAllCategories() async {
    return await supabase
        .from('categories')
        .select()
        .or('user_id.eq.${supabase.auth.currentUser!.id},user_id.is.null');
  }

  Future<List<dynamic>> fetchUserCategories(String userId) async {
    return await supabase.from('categories').select().eq('user_id', userId);
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  Future<void> signIn(String email, String password) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password) async {
    await supabase.auth.signUp(email: email, password: password, data: {'email': email});
  }

  Future<Storage> addStorage(String name) async {
    final user = supabase.auth.currentUser;
    final storageData = await supabase.from('storages').insert({
      'user_id': user!.id,
      'name': name,
      'icon_id': 1, // Default icon ID
    }).select();

    return Storage(
      id: storageData[0]['id'],
      name: storageData[0]['name'],
      iconId: storageData[0]['icon_id'],
    );
  }

  Future<void> updateStorageIcon(String storageId, int iconId) async {
    final user = supabase.auth.currentUser;
    await supabase.from('storages').update({
      'icon_id': iconId,
    }).eq('id', storageId).eq('user_id', user!.id);
  }

  Future<void> updateStorageName(String storageId, String name) async {
    final user = supabase.auth.currentUser;
    await supabase.from('storages').update({
      'name': name,
    }).eq('id', storageId).eq('user_id', user!.id);
  }

  Future<void> deleteStorage(String storageId) async {
    final user = supabase.auth.currentUser;
    await supabase.from('storages').delete().eq('id', storageId).eq('user_id', user!.id);
  }

  Future<Map<String, dynamic>> addCategory(String name) async {
    final response = await supabase.from('categories').insert({
      'name': name,
      'user_id': supabase.auth.currentUser!.id,
    }).select().single();
    return response;
  }

  Future<void> updateCategoryName(String categoryId, String newName) async {
    await supabase.from('categories').update({
      'name': newName,
    }).eq('id', categoryId);
  }

  Future<void> deleteCategory(String categoryId) async {
    await supabase.from('categories').delete().eq('id', categoryId).eq('user_id', supabase.auth.currentUser!.id);
  }

Future<List<dynamic>>  fetchBarcodeData(String barcode) async {
    final response = await supabase.rpc('get_all_barcodes', params: {
      'user_uuid': user.id,
      'barcode_selected': barcode
    });
    return response;
  }

  Future<List<dynamic>> addBarcodeToDatabase(String barcode) async {
    final category = await supabase.from('categories').select('id').eq('name', 'none').single();
    final newBarcode = await supabase.from('barcodes').insert({'barcode': barcode, 'category_id': category['id'] }).select();
    addBarcodeToUserDatabase(newBarcode[0]);
    return newBarcode;
  }

  Future<void> addBarcodeToUserDatabase(Map<String, dynamic> newBarcode) async {
    await supabase.from('user_barcodes').insert({'id': newBarcode['id'], 'user_id': user.id, 'barcode': newBarcode['barcode'] },  ).select();
  }


  Future<void> updateUserBarcode(Map<String, dynamic> barcodeData) async {
    await supabase.from('user_barcodes').upsert(barcodeData);
  }

  Future<List<dynamic>> fetchItemStorageData(String barcodeId) async {
    return await supabase.rpc('get_item_storage_counts', params: {
      'user_uuid': user.id,
      'barcode_selected': barcodeId
    });
  }

  Future<void> removeItem(String barcodeId, String storageId) async {
    await supabase.from('items').delete().eq('barcode_id', barcodeId).eq('storage_id', storageId);
  }

  Future<void> upsertItem(Map<String, dynamic> itemData) async {
    await supabase.from('items').upsert(itemData);
  }

  Future<List<dynamic>> insertItem(Map<String, dynamic> itemData) async {
    return await supabase.from('items').insert(itemData).select();
  }
}
