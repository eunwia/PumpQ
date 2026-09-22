import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pumpq/features/auth/presentation/auth_provider.dart';
import 'package:pumpq/features/loyalty_rewards/data/loyalty_repository.dart';
import 'package:pumpq/models/loyalty_model.dart';

final loyaltyRepositoryProvider = Provider<LoyaltyRepository>((ref) {
  return LoyaltyRepository(ref.watch(apiServiceProvider));
});

final loyaltyProvider = FutureProvider<LoyaltyModel>((ref) {
  return ref.watch(loyaltyRepositoryProvider).getLoyalty();
});

final loyaltyHistoryProvider = FutureProvider<List<LoyaltyTransactionModel>>((ref) {
  return ref.watch(loyaltyRepositoryProvider).getHistory();
});