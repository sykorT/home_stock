import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  User? _user;

  User? get user => _user;

  Future<void> signIn(String email, String password) async {
    await _supabaseService.signIn(email, password);
    _user = Supabase.instance.client.auth.currentUser;
    notifyListeners();
  }

  Future<void> signUp(String email, String password) async {
    await _supabaseService.signUp(email, password);
    notifyListeners();
  }

  Future<void> signOut() async {
    await _supabaseService.signOut();
    _user = null;
    notifyListeners();
  }
}
