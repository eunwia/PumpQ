import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pumpq/features/auth/presentation/auth_provider.dart';
import 'package:pumpq/features/pre_order/data/order_repository.dart';
import 'package:pumpq/models/order_model.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(apiServiceProvider));
});

class CreateOrderState {
  final bool isLoading;
  final String? error;
  final OrderModel? order;

  const CreateOrderState({this.isLoading = false, this.error, this.order});
}

class CreateOrderNotifier extends Notifier<CreateOrderState> {
  @override
  CreateOrderState build() => const CreateOrderState();

  Future<bool> submit({
    required int stationId,
    required String fuelType,
    required double liters,
  }) async {
    state = const CreateOrderState(isLoading: true);
    try {
      final order = await ref.read(orderRepositoryProvider).createOrder(
            stationId: stationId,
            fuelType: fuelType,
            liters: liters,
          );
      state = CreateOrderState(order: order);
      return true;
    } catch (e) {
      state = CreateOrderState(error: _readableError(e));
      return false;
    }
  }

  void reset() => state = const CreateOrderState();

  String _readableError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Cannot reach the server. Check your connection.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}

final createOrderProvider =
    NotifierProvider<CreateOrderNotifier, CreateOrderState>(CreateOrderNotifier.new);

final myOrdersProvider = FutureProvider<List<OrderModel>>((ref) {
  return ref.watch(orderRepositoryProvider).getOrders();
});

class GenerateQrNotifier extends Notifier<AsyncValue<OrderModel?>> {
  @override
  AsyncValue<OrderModel?> build() => const AsyncValue.data(null);

  Future<void> generate(int orderId) async {
    state = const AsyncValue.loading();
    try {
      final order = await ref.read(orderRepositoryProvider).generateQr(orderId);
      state = AsyncValue.data(order);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final generateQrProvider =
    NotifierProvider<GenerateQrNotifier, AsyncValue<OrderModel?>>(GenerateQrNotifier.new);