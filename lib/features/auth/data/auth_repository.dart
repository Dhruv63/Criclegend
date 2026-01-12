import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  // Email Auth
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmail(String email, String password, {Map<String, dynamic>? data}) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  User? get currentUser => _supabase.auth.currentUser;

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Stream<AuthState> authStateChanges() => _supabase.auth.onAuthStateChange;

  Future<void> updateProfile({
    required String name,
    required String location,
    required String role,
    required bool isSeller,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final updates = {
      'profile_json': {
        'name': name,
        'location': location,
        'role': role,
      },
      'is_seller': isSeller,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _supabase.from('users').upsert({
      'id': user.id,
      ...updates,
    });
  }
}
