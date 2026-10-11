import 'dart:async';
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
  Timer? _timer;
  Duration _remaining = const Duration(minutes: 15);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(generateQrProvider.notifier).generate(widget.orderId));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds <= 0) {
        _timer?.cancel();
      } else {
        setState(() => _remaining -= const Duration(seconds: 1));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    ref.read(generateQrProvider.notifier).reset();
    super.dispose();
  }

  String get _timeLabel {
    final m = _remaining.inMinutes;
    final s = _remaining.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final qrState = ref.watch(generateQrProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: AppColors.white,
        title: const Text('Express QR'),
      ),
      body: Center(
        child: qrState.when(
          loading: () => const CircularProgressIndicator(color: AppColors.white),
          error: (err, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not generate QR. It may no longer be pending.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.white),
            ),
          ),
          data: (order) {
            if (order == null) return const CircularProgressIndicator(color: AppColors.white);
            final expired = _remaining.inSeconds <= 0;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const Icon(Icons.local_gas_station, color: AppColors.white, size: 36),
                  const SizedBox(height: 8),
                  const Text('Show this to station staff', style: TextStyle(color: AppColors.white, fontSize: 15)),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(24)),
                    child: Column(
                      children: [
                        Text('Order #${order.orderId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('${order.liters.toStringAsFixed(1)}L ${order.fuelType} · ₱${order.amount.toStringAsFixed(2)}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 20),
                        Opacity(
                          opacity: expired ? 0.25 : 1,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.background, width: 2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: QrImageView(
                              data: order.qrCode ?? '',
                              size: 200,
                              backgroundColor: AppColors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: expired ? AppColors.error.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(expired ? Icons.error_outline : Icons.timer_outlined,
                                  size: 16, color: expired ? AppColors.error : AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                expired ? 'QR Expired — tap below to regenerate' : 'Expires in $_timeLabel',
                                style: TextStyle(
                                  color: expired ? AppColors.error : AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (expired) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() => _remaining = const Duration(minutes: 15));
                                ref.read(generateQrProvider.notifier).generate(widget.orderId);
                              },
                              child: const Text('Regenerate QR'),
                            ),
                          ),
                        ],
                      ],
                    ),
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