import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pumpq/core/constants/app_colors.dart';
import 'package:pumpq/features/wallet/presentation/wallet_provider.dart';
import 'package:pumpq/models/wallet_model.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);
    final historyAsync = ref.watch(walletHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('PumpQ Wallet')),
      body: walletAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load wallet')),
        data: (wallet) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _BalanceCard(wallet: wallet),
            const SizedBox(height: 24),
            Text('Transaction History', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Could not load history'),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Text('No transactions yet',
                      style: TextStyle(color: AppColors.textSecondary));
                }
                return Column(
                  children: transactions.map((tx) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        tx.isTopUp ? Icons.add_circle : Icons.remove_circle,
                        color: tx.isTopUp ? AppColors.success : AppColors.primary,
                      ),
                      title: Text(tx.displayLabel),
                      subtitle: Text(
                        '${tx.createdAt.month}/${tx.createdAt.day}/${tx.createdAt.year}',
                      ),
                      trailing: Text(
                        '${tx.isTopUp ? '+' : '-'}₱${tx.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: tx.isTopUp ? AppColors.success : AppColors.primary,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends ConsumerWidget {
  const _BalanceCard({required this.wallet});
  final WalletModel wallet;

  void _showTopUpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _TopUpSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Available Balance',
              style: TextStyle(color: AppColors.white, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            '₱${wallet.balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.primary,
              ),
              onPressed: () => _showTopUpSheet(context),
              child: const Text('Cash In'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopUpSheet extends ConsumerStatefulWidget {
  const _TopUpSheet();

  @override
  ConsumerState<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends ConsumerState<_TopUpSheet> {
  final _amountController = TextEditingController();
  String _method = 'gcash';

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    await ref.read(topUpProvider.notifier).topUp(amount: amount, method: _method);

    if (!mounted) return;
    final state = ref.read(topUpProvider);
    if (state.success) {
      ref.read(topUpProvider.notifier).reset();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cash-in successful')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(topUpProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cash In', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount (₱)'),
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'gcash', label: Text('GCash')),
              ButtonSegment(value: 'maya', label: Text('Maya')),
              ButtonSegment(value: 'qrph', label: Text('QR Ph')),
            ],
            selected: {_method},
            onSelectionChanged: (s) => setState(() => _method = s.first),
          ),
          if (state.error != null) ...[
            const SizedBox(height: 12),
            Text(state.error!, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.isLoading ? null : _submit,
              child: state.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirm Cash-In'),
            ),
          ),
        ],
      ),
    );
  }
}