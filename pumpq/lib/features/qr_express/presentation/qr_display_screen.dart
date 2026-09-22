import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pumpq/core/constants/app_colors.dart';
import 'package:pumpq/features/pre_order/presentation/order_provider.dart';

class QrDisplayScreen extends ConsumerStatefulWidget {
  const QrDisplayScreen({super.key, required this.orderId});
  final int orderId;

  @override
  ConsumerState<QrDisplayScreen> createState() => _QrDisplayScreenState();
}

class _QrDisplayScreenState extends ConsumerState<QrDisplayScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(generateQrProvider.notifier).generate(widget.orderId),
    );
  }

  @override
  void dispose() {
    ref.read(generateQrProvider.notifier).reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qrState = ref.watch(generateQrProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Express QR')),
      body: Center(
        child: qrState.when(
          loading: () => const CircularProgressIndicator(),
          error: (err, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not generate QR. It may no longer be pending.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
          data: (order) {
            if (order == null) return const CircularProgressIndicator();
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: QrImageView(
                      data: order.qrCode ?? '',
                      size: 240,
                      backgroundColor: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Order #${order.orderId}',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  const Text(
                    'Show this to station staff. Valid for 15 minutes.',
                    style: TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}