import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/auth_repository.dart';

// 1. Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

// 2. Auth Controller / User State Provider
// This stream listens to Auth State Changes (Sign In, Sign Out)
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// 3. Current User Provider
// Returns the current User object, updates automatically on auth state change
final userProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.session?.user ?? Supabase.instance.client.auth.currentUser;
});

// 4. Controller Class for Actions (SignOut etc)
final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref.read(authRepositoryProvider));
});

class AuthController {
  final AuthRepository _repo;

  AuthController(this._repo);

  Future<void> signOut() async {
    await _repo.signOut();
  }
  
  // Add other actions if needed
}
