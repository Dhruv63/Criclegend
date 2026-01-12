import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_provider.dart';
import 'scoring_repository.dart';

final scoringRepositoryProvider = Provider((ref) {
  return ScoringRepository(ref.watch(supabaseClientProvider));
});
