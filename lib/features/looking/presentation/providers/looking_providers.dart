import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/looking_repository.dart';
import '../../domain/looking_request_model.dart';

// Repository Provider
final lookingRepositoryProvider = Provider<LookingRepository>((ref) {
  return LookingRepository(Supabase.instance.client);
});

// Category Filter State
final selectedCategoryProvider = NotifierProvider<CategoryNotifier, String?>(
  CategoryNotifier.new,
);

class CategoryNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? value) => state = value;
}

// City Search State
final searchCityProvider = NotifierProvider<CitySearchNotifier, String?>(
  CitySearchNotifier.new,
);

class CitySearchNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? value) => state = value;
}

// Feed Provider (Auto-refreshes when filters change)
final lookingRequestsProvider =
    FutureProvider.autoDispose<List<LookingRequest>>((ref) async {
      final repo = ref.watch(lookingRepositoryProvider);
      final category = ref.watch(selectedCategoryProvider);
      final city = ref.watch(searchCityProvider);

      return repo.getRequests(category: category, city: city);
    });
