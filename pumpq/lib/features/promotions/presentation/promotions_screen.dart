import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pumpq/core/constants/app_colors.dart';
import 'package:pumpq/features/promotions/presentation/promotion_provider.dart';
import 'package:pumpq/models/promotion_model.dart';

class PromotionsScreen extends ConsumerStatefulWidget {
  const PromotionsScreen({super.key});

  @override
  ConsumerState<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends ConsumerState<PromotionsScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final promosAsync = ref.watch(promotionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0, title: const Text('Promotions')),
      body: promosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load promotions')),
        data: (promos) {
          final filtered = promos.where((p) {
            if (_filter == 'All') return true;
            if (_filter == 'Site-wide') return p.stationId == null;
            if (_filter == '% Off') return p.promoType == 'percentage';
            return p.promoType == 'flat';
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['All', '₱ Off', '% Off', 'Site-wide'].map((f) {
                      final selected = _filter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: selected,
                          onSelected: (_) => setState(() => _filter = f),
                          selectedColor: AppColors.textPrimary,
                          labelStyle: TextStyle(color: selected ? AppColors.white : AppColors.textPrimary),
                          backgroundColor: AppColors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No promotions match this filter', style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, i) => _PromoTicket(promo: filtered[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PromoTicket extends StatelessWidget {
  const _PromoTicket({required this.promo});
  final PromotionModel promo;

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: promo.couponCode));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied "${promo.couponCode}"')));
  }

  @override
  Widget build(BuildContext context) {
    final daysLeft = promo.expiresAt.difference(DateTime.now()).inDays;

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _copyCode(context),
        child: Row(
          children: [
            Container(
              width: 90,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_offer, color: AppColors.white, size: 22),
                  const SizedBox(height: 6),
                  Text(
                    promo.discountLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                          child: Text(promo.promoTag, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        ),
                        const Spacer(),
                        Text(
                          daysLeft <= 1 ? 'Expires today' : 'Expires in $daysLeft days',
                          style: TextStyle(fontSize: 10, color: daysLeft <= 3 ? AppColors.error : AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(promo.promoName, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      promo.stationName ?? 'Any partner station',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    DottedCodeChip(code: promo.couponCode),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DottedCodeChip extends StatelessWidget {
  const DottedCodeChip({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(code, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12)),
          const SizedBox(width: 6),
          const Icon(Icons.copy, size: 13, color: AppColors.primary),
        ],
      ),
    );
  }
}