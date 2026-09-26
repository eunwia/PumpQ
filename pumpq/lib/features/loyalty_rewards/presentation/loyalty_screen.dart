import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pumpq/core/constants/app_colors.dart';
import 'package:pumpq/features/loyalty_rewards/presentation/loyalty_provider.dart';
import 'package:pumpq/models/loyalty_model.dart';

class LoyaltyScreen extends ConsumerWidget {
  const LoyaltyScreen({super.key});

  void _showRedeemDialog(BuildContext context, WidgetRef ref, int balance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redeem Points'),
        content: Text('You have $balance points. Redeem in multiples of 100 (100 pts = ₱10 discount on your next order).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: balance < 100
                ? null
                : () async {
                    try {
                      final api = ref.read(loyaltyRepositoryProvider);
                      await api.redeem((balance ~/ 100) * 100);
                      ref.invalidate(loyaltyProvider);
                      ref.invalidate(loyaltyHistoryProvider);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Points redeemed!')));
                      }
                    } on DioException catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context);
                        final msg = (e.response?.data is Map) ? e.response?.data['message'] : 'Redeem failed';
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? 'Redeem failed')));
                      }
                    }
                  },
            child: const Text('Redeem All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loyaltyAsync = ref.watch(loyaltyProvider);
    final historyAsync = ref.watch(loyaltyHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0, title: const Text('Loyalty Rewards')),
      body: loyaltyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load loyalty info')),
        data: (loyalty) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _TierDonutCard(
              loyalty: loyalty,
              onRedeem: () => _showRedeemDialog(context, ref, loyalty.pointsBalance),
            ),
            const SizedBox(height: 24),
            const Text('Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Could not load history'),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Text('No activity yet', style: TextStyle(color: AppColors.textSecondary));
                }
                return Column(children: transactions.map((tx) => _ActivityTile(tx: tx)).toList());
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TierDonutCard extends StatelessWidget {
  const _TierDonutCard({required this.loyalty, required this.onRedeem});
  final LoyaltyModel loyalty;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 90, height: 90,
                child: CustomPaint(
                  painter: _DonutPainter(percent: loyalty.tier == 'Gold' ? 1.0 : loyalty.tierProgress, color: AppColors.white),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${loyalty.pointsBalance}', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                        const Text('pts', style: TextStyle(color: Colors.white70, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${loyalty.tier} Tier', style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      loyalty.tier == 'Gold' ? 'Highest tier reached!' : '${loyalty.pointsToNextTier} pts to next tier',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.white)),
              onPressed: onRedeem,
              child: const Text('Redeem Points', style: TextStyle(color: AppColors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.percent, required this.color});
  final double percent;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 7;
    final bgPaint = Paint()..color = Colors.white24..style = PaintingStyle.stroke..strokeWidth = 10..strokeCap = StrokeCap.round;
    final fgPaint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 10..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, 2 * math.pi * percent.clamp(0.0, 1.0), false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.percent != percent;
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.tx});
  final LoyaltyTransactionModel tx;

  @override
  Widget build(BuildContext context) {
    final isEarn = tx.pointsEarned > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: (isEarn ? AppColors.success : AppColors.primary).withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(isEarn ? Icons.add_circle : Icons.remove_circle, color: isEarn ? AppColors.success : AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEarn ? 'Points earned' : 'Points redeemed', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${tx.createdAt.month}/${tx.createdAt.day}/${tx.createdAt.year}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text(
            isEarn ? '+${tx.pointsEarned}' : '-${tx.pointsRedeemed}',
            style: TextStyle(fontWeight: FontWeight.bold, color: isEarn ? AppColors.success : AppColors.primary),
          ),
        ],
      ),
    );
  }
}