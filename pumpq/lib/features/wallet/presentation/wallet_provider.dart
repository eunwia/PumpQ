import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pumpq/features/auth/presentation/auth_provider.dart';
import 'package:pumpq/features/wallet/data/wallet_repository.dart';
import 'package:pumpq/models/wallet_model.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.watch(apiServiceProvider));
});

final walletProvider = FutureProvider<WalletModel>((ref) {
  return ref.watch(walletRepositoryProvider).getWallet();
});

final walletHistoryProvider = FutureProvider<List<WalletTransactionModel>>((ref) {
  return ref.watch(walletRepositoryProvider).getHistory();
});

class TopUpState {
  final bool isLoading;
  final String? error;
  final bool success;

  const TopUpState({this.isLoading = false, this.error, this.success = false});
}

class TopUpNotifier extends Notifier<TopUpState> {
  @override
  TopUpState build() => const TopUpState();

  Future<void> topUp({required double amount, required String method}) async {
    state = const TopUpState(isLoading: true);
    try {
      await ref.read(walletRepositoryProvider).topUp(amount: amount, method: method);
      state = const TopUpState(success: true);
      ref.invalidate(walletProvider);
      ref.invalidate(walletHistoryProvider);
    } catch (e) {
      state = TopUpState(error: _readableError(e));
    }
  }

  void reset() => state = const TopUpState();

  String _readableError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
    }
    return 'Something went wrong. Please try again.';
  }
}

final topUpProvider = NotifierProvider<TopUpNotifier, TopUpState>(TopUpNotifier.new);