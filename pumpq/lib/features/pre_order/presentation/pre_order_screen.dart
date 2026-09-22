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
  final _litersController = TextEditingController(text: '5');

  @override
  void dispose() {
    _litersController.dispose();
    super.dispose();
  }

  double get _liters => double.tryParse(_litersController.text) ?? 0;
  double get _total => _liters * widget.args.pricePerLiter;

  Future<void> _submit() async {
    if (_liters <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid number of liters')),
      );
      return;
    }

    final ok = await ref.read(createOrderProvider.notifier).submit(
          stationId: widget.args.stationId,
          fuelType: widget.args.fuelType,
          liters: _liters,
        );

    if (!mounted) return;

    if (ok) {
      final order = ref.read(createOrderProvider).order!;
      ref.read(createOrderProvider.notifier).reset();
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Order Placed'),
          content: Text(
            'Order #${order.orderId} · ${order.liters.toStringAsFixed(1)}L '
            '${order.fuelType} at ${widget.args.stationName}\n\n'
            'Total: ₱${order.amount.toStringAsFixed(2)}\nStatus: ${order.status}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createOrderProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pre-order Fuel')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.args.stationName,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(widget.args.fuelType,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              TextField(
                controller: _litersController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Liters'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Price per liter'),
                  Text('₱${widget.args.pricePerLiter.toStringAsFixed(2)}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '₱${_total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (state.error != null) ...[
                const SizedBox(height: 16),
                Text(state.error!, style: const TextStyle(color: AppColors.error)),
              ],
              const Spacer(),
              ElevatedButton(
                onPressed: state.isLoading ? null : _submit,
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Place Pre-order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}