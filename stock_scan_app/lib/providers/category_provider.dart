import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/supabase_service.dart';

class CategoryProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  List<Category> _allCategories = [];
  List<Category> _userCategories = [];
  String? itemSelectedCategory = 'none';

  List<Category> get allCategories => _allCategories;
  List<Category> get userCategories => _userCategories;
  String? get scanSelectedCategory => itemSelectedCategory;

  Future<void> fetchAllCategories() async {
    final response = await _supabaseService.fetchAllCategories();
    _allCategories = response.map((category) => Category.fromMap(category)).toList();
    notifyListeners();
  }

  Future<void> fetchUserCategories(String userId) async {
    final response = await _supabaseService.fetchUserCategories(userId);
    _userCategories = response.map((category) => Category.fromMap(category)).toList();
    notifyListeners();
  }

  Future<Category> addCategory(String name) async {
    final response = await _supabaseService.addCategory(name);
    final newCategory = Category.fromMap(response);
    _userCategories.add(newCategory);
    _allCategories.add(newCategory);
    notifyListeners();
    return newCategory;
  }

  Future<void> updateCategoryName(String categoryId, String newName) async {
    await _supabaseService.updateCategoryName(categoryId, newName);
    var userCategory = _userCategories.firstWhere((category) => category.id == categoryId);
    var category = _allCategories.firstWhere((category) => category.id == categoryId);
    if (userCategory.name == itemSelectedCategory) {
      itemSelectedCategory = newName;
    }  
    userCategory.name = newName;
    category.name = newName;
    notifyListeners();
  }

  Future<bool> deleteCategory(String categoryId) async {
    try {
      await _supabaseService.deleteCategory(categoryId);
      var userCategory = _userCategories.firstWhere((category) => category.id == categoryId);
      if (userCategory.name == itemSelectedCategory) {
        itemSelectedCategory = 'none';
      }
      _userCategories.removeWhere((category) => category.id == categoryId);
      _allCategories.removeWhere((category) => category.id == categoryId);
      notifyListeners();    
      return true ;
    } catch (e) {
      print('Error deleting category: $e');
      return false;
    }

  }

  void setLoadedCategory(String? newValue) {
    itemSelectedCategory = newValue;
    notifyListeners();
  }
}
