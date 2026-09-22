import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pumpq/core/constants/app_colors.dart';
import 'package:pumpq/features/loyalty_rewards/presentation/loyalty_provider.dart';
import 'package:pumpq/models/loyalty_model.dart';

class LoyaltyScreen extends ConsumerWidget {
  const LoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loyaltyAsync = ref.watch(loyaltyProvider);
    final historyAsync = ref.watch(loyaltyHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Loyalty Rewards')),
      body: loyaltyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load loyalty info')),
        data: (loyalty) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _TierCard(loyalty: loyalty),
            const SizedBox(height: 24),
            Text('History', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Could not load history'),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Text('No activity yet',
                      style: TextStyle(color: AppColors.textSecondary));
                }
                return Column(
                  children: transactions.map((tx) {
                    final isEarn = tx.pointsEarned > 0;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        isEarn ? Icons.add_circle : Icons.remove_circle,
                        color: isEarn ? AppColors.success : AppColors.primary,
                      ),
                      title: Text(isEarn
                          ? '+${tx.pointsEarned} points earned'
                          : '-${tx.pointsRedeemed} points redeemed'),
                      subtitle: Text(
                        '${tx.createdAt.month}/${tx.createdAt.day}/${tx.createdAt.year}',
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

class _TierCard extends StatelessWidget {
  const _TierCard({required this.loyalty});
  final LoyaltyModel loyalty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${loyalty.tier} Tier',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${loyalty.pointsBalance} points',
            style: const TextStyle(color: AppColors.white, fontSize: 16),
          ),
          const SizedBox(height: 16),
          if (loyalty.tier != 'Gold') ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: loyalty.tierProgress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: AppColors.white.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation(AppColors.white),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${loyalty.pointsToNextTier} points to next tier',
              style: const TextStyle(color: AppColors.white, fontSize: 13),
            ),
          ] else
            const Text(
              'Highest tier reached!',
              style: TextStyle(color: AppColors.white, fontSize: 13),
            ),
        ],
      ),
    );
  }
}