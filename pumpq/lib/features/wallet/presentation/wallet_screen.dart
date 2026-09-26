import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pumpq/core/constants/app_colors.dart';
import 'package:pumpq/features/auth/presentation/auth_provider.dart';
import 'package:pumpq/features/wallet/presentation/wallet_provider.dart';
import 'package:pumpq/models/wallet_model.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);
    final historyAsync = ref.watch(walletHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0, title: const Text('Wallet')),
      body: walletAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load wallet: $e')),
        data: (wallet) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _BalanceCard(wallet: wallet),
            const SizedBox(height: 24),
            const Text('Transaction History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ['All', 'Top Up', 'Order Payment'].map((c) {
                  final selected = _category == c;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: selected,
                      onSelected: (_) => setState(() => _category = c),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(color: selected ? AppColors.white : AppColors.textPrimary),
                      backgroundColor: AppColors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            historyAsync.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
              error: (_, __) => const Text('Could not load history'),
              data: (transactions) {
                final filtered = transactions.where((tx) {
                  if (_category == 'All') return true;
                  if (_category == 'Top Up') return tx.isTopUp;
                  return !tx.isTopUp;
                }).toList();
                if (filtered.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('No transactions yet', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  );
                }
                return Column(children: filtered.map((tx) => _TransactionTile(tx: tx)).toList());
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => const _TopUpSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Container(
      padding: const EdgeInsets.all(20),
      height: 190,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            bottom: -30,
            child: Container(
              width: 140, height: 140,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), shape: BoxShape.circle),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Text(
                '₱${wallet.balance.toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.white, fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      user?.fullName ?? '',
                      style: const TextStyle(color: AppColors.white, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 110,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.white,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onPressed: () => _showTopUpSheet(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Top Up', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx});
  final WalletTransactionModel tx;

  IconData get _icon {
    if (tx.transactionType.startsWith('topup_')) return Icons.arrow_downward;
    if (tx.transactionType == 'order_refund') return Icons.replay;
    return Icons.local_gas_station;
  }

  Color get _iconColor => tx.isTopUp ? AppColors.success : AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: _iconColor.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(_icon, color: _iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.displayLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '${tx.createdAt.month}/${tx.createdAt.day}/${tx.createdAt.year}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${tx.isTopUp ? '+' : '-'}₱${tx.amount.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: FontWeight.bold, color: _iconColor),
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

  static const _methods = [
    (value: 'gcash', label: 'GCash', icon: Icons.account_balance_wallet, color: Color(0xFF0072FF)),
    (value: 'maya', label: 'Maya', icon: Icons.payments, color: Color(0xFF00D6A3)),
    (value: 'qrph', label: 'QR Ph', icon: Icons.qr_code, color: Color(0xFF6E4CFF)),
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    await ref.read(topUpProvider.notifier).topUp(amount: amount, method: _method);
    if (!mounted) return;
    final state = ref.read(topUpProvider);
    if (state.success) {
      ref.read(topUpProvider.notifier).reset();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cash-in successful')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(topUpProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Text('Cash In', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Top up your PumpQ wallet', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            const Text('Amount', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '₱ ',
                prefixStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                hintText: '0.00',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 10),
            Row(
              children: _methods.map((m) {
                final selected = _method == m.value;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _method = m.value),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: selected ? m.color.withValues(alpha: 0.1) : AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: selected ? m.color : Colors.transparent, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          Icon(m.icon, color: m.color, size: 26),
                          const SizedBox(height: 6),
                          Text(m.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? m.color : AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (state.error != null) ...[
              const SizedBox(height: 16),
              Text(state.error!, style: const TextStyle(color: AppColors.error)),
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
                    : const Text('Confirm Cash-In'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}