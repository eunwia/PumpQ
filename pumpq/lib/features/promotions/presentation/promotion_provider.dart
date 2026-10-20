import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pumpq/features/auth/presentation/auth_provider.dart';
import 'package:pumpq/features/pre_order/presentation/order_provider.dart';
import 'package:pumpq/features/promotions/data/promotion_repository.dart';
import 'package:pumpq/models/promotion_model.dart';

final promotionRepositoryProvider = Provider<PromotionRepository>((ref) {
  return PromotionRepository(ref.watch(apiServiceProvider));
});

final promotionsProvider = FutureProvider.autoDispose<List<PromotionModel>>((ref) {
  return ref.watch(promotionRepositoryProvider).getPromotions();
});

class ApplyCouponState {
  final bool isLoading;
  final String? error;
  final bool success;

  const ApplyCouponState({this.isLoading = false, this.error, this.success = false});
}

class ApplyCouponNotifier extends Notifier<ApplyCouponState> {
  @override
  ApplyCouponState build() => const ApplyCouponState();

  Future<void> apply(int orderId, String code) async {
    state = const ApplyCouponState(isLoading: true);
    try {
      await ref.read(promotionRepositoryProvider).applyCoupon(orderId, code);
      state = const ApplyCouponState(success: true);
      ref.invalidate(myOrdersProvider);
    } catch (e) {
      String message = 'Could not apply coupon';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] is String) message = data['message'] as String;
      }
      state = ApplyCouponState(error: message);
    }
  }

  void reset() => state = const ApplyCouponState();
}

final applyCouponProvider = NotifierProvider<ApplyCouponNotifier, ApplyCouponState>(ApplyCouponNotifier.new);