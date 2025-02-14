import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/supabase_service.dart';

class CategoryProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  List<Category> _allCategories = [];
  List<Category> _userCategories = [];

  List<Category> get allCategories => _allCategories;
  List<Category> get userCategories => _userCategories;

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
    notifyListeners();
    return newCategory;
  }

  Future<void> updateCategoryName(String categoryId, String newName) async {
    await _supabaseService.updateCategoryName(categoryId, newName);
    final category = _userCategories.firstWhere((category) => category.id == categoryId);
    category.name = newName;
    notifyListeners();
  }

  Future<void> deleteCategory(String categoryId) async {
    await _supabaseService.deleteCategory(categoryId);
    _userCategories.removeWhere((category) => category.id == categoryId);
    notifyListeners();
  }
}
