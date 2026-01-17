import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../teams/data/team_repository.dart';

// 1. Repository Provider
final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  return TeamRepository(Supabase.instance.client);
});

// 2. My Teams Provider (Fetch)
final myTeamsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(teamRepositoryProvider);
  return await repo.getMyTeams();
});

// 3. Team Members Provider (Family)
final teamMembersProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      teamId,
    ) async {
      final repo = ref.watch(teamRepositoryProvider);
      return await repo.getTeamMembers(teamId);
    });

// 4. Controller for Actions (Create, Add Member)
final teamControllerProvider = AsyncNotifierProvider<TeamController, void>(() {
  return TeamController();
});

class TeamController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // No state to load initially
  }

  Future<void> createTeam({required String name, required String city}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(teamRepositoryProvider);
      await repo.createTeam(name, city);
      // Refresh list
      ref.invalidate(myTeamsProvider);
    });
  }

  Future<void> addPlayer({
    required String teamId,
    required String userId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(teamRepositoryProvider);
      await repo.addPlayerToTeam(userId, teamId);
      // Refresh members
      ref.invalidate(teamMembersProvider(teamId));
    });
  }
}
