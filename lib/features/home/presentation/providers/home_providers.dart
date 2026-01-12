import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/home_repository.dart';
import '../../../scoring/domain/match_model.dart';
import '../../../../core/data/supabase_service.dart'; // fallback if needed, but repo handles it

// Repository Provider
final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository();
});

// Live/Upcoming Matches Provider
final liveMatchesProvider = FutureProvider<List<MatchModel>>((ref) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getLiveMatches();
});
