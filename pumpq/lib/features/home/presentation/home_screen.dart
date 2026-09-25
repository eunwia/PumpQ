import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pumpq/app/route_names.dart';
import 'package:pumpq/core/constants/app_colors.dart';
import 'package:pumpq/features/auth/presentation/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PumpQ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () => context.pushNamed(AppRoute.profile),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.goNamed(AppRoute.login);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, ${user?.firstName ?? 'there'}!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              const Text(
                'Where do you want to fuel up today?',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _FeatureCard(
                    icon: Icons.map,
                    label: 'Station Map',
                    onTap: () => context.pushNamed(AppRoute.stationMap),
                  ),
                  _FeatureCard(
                    icon: Icons.price_change,
                    label: 'Compare Prices',
                    onTap: () => context.pushNamed(AppRoute.priceComparison),
                  ),
                  _FeatureCard(
                    icon: Icons.qr_code,
                    label: 'QR Express',
                    onTap: () => context.pushNamed(AppRoute.myOrders),
                  ),
                  _FeatureCard(
                    icon: Icons.card_giftcard,
                    label: 'Loyalty Rewards',
                    onTap: () => context.pushNamed(AppRoute.loyaltyRewards),
                  ),
                  _FeatureCard(
                    icon: Icons.account_balance_wallet,
                    label: 'Wallet',
                    onTap: () => context.pushNamed(AppRoute.wallet),
                  ),
                  _FeatureCard(
                    icon: Icons.insights,
                    label: 'Insights',
                    onTap: () => context.pushNamed(AppRoute.insights),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$label coming soon')),
              );
            },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}