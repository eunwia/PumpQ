import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pumpq/core/constants/app_colors.dart';
import 'package:pumpq/features/pre_order/presentation/order_provider.dart';

class PreOrderArgs {
  final int stationId;
  final String stationName;
  final String fuelType;
  final double pricePerLiter;

  const PreOrderArgs({
    required this.stationId,
    required this.stationName,
    required this.fuelType,
    required this.pricePerLiter,
  });
}

class PreOrderScreen extends ConsumerStatefulWidget {
  const PreOrderScreen({super.key, required this.args});
  final PreOrderArgs args;

  @override
  ConsumerState<PreOrderScreen> createState() => _PreOrderScreenState();
}

class _PreOrderScreenState extends ConsumerState<PreOrderScreen> {
  double _liters = 5;

  double get _total => _liters * widget.args.pricePerLiter;

  Future<void> _submit() async {
    final ok = await ref.read(createOrderProvider.notifier).submit(
          stationId: widget.args.stationId,
          fuelType: widget.args.fuelType,
          liters: _liters,
        );
    if (!mounted || !ok) return;
    final order = ref.read(createOrderProvider).order!;
    ref.read(createOrderProvider.notifier).reset();
    context.pop();
    context.pushNamed('orderDetail', pathParameters: {'orderId': order.orderId.toString()});
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createOrderProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0, title: const Text('Pre-order Fuel')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            Center(
              child: Image.asset('assets/images/pre_order_illus.png', height: 140),
            ),
            const SizedBox(height: 16),
            const Center(child: Text('Confirm Your Order', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            const SizedBox(height: 4),
            const Center(
              child: Text('Review the details before you generate your QR', style: TextStyle(color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                    child: Icon(
                      widget.args.fuelType == 'Diesel' ? Icons.local_gas_station : Icons.local_fire_department,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.args.fuelType, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(widget.args.stationName,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Text('₱${widget.args.pricePerLiter.toStringAsFixed(2)}/L',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Liters', style: TextStyle(color: AppColors.textSecondary)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              color: AppColors.primary,
                              onPressed: _liters > 1 ? () => setState(() => _liters--) : null,
                            ),
                            Text('${_liters.toInt()} L', style: const TextStyle(fontWeight: FontWeight.w600)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              color: AppColors.primary,
                              onPressed: _liters < 50 ? () => setState(() => _liters++) : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  _row('Price per liter', '₱${widget.args.pricePerLiter.toStringAsFixed(2)}'),
                  const Divider(height: 1),
                  _row('Station', widget.args.stationName),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('₱${_total.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (state.error != null) ...[
              const SizedBox(height: 16),
              Text(state.error!, style: const TextStyle(color: AppColors.error), textAlign: TextAlign.center),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26))),
                onPressed: state.isLoading ? null : _submit,
                child: state.isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                    : const Text('Place Pre-order'),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text('Payment can be arranged after confirming', style: TextStyle(color: AppColors.success, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}