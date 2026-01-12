import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import 'auth_providers.dart';

final userRoleProvider = FutureProvider<String>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  
  // Watch auth state changes to re-fetch role on login/logout
  ref.watch(authStateProvider);

  if (authRepo.currentUser == null) return 'guest';

  return await authRepo.getUserRole() ?? 'user';
});
