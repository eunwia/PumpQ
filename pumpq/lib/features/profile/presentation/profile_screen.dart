import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pumpq/app/route_names.dart';
import 'package:pumpq/core/constants/app_colors.dart';
import 'package:pumpq/core/services/text_scale_provider.dart';
import 'package:pumpq/features/auth/presentation/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user;
    final firstNameController = TextEditingController(text: user?.firstName ?? '');
    final lastNameController = TextEditingController(text: user?.lastName ?? '');
    final phoneController = TextEditingController(text: user?.phoneNumber ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: firstNameController, decoration: const InputDecoration(labelText: 'First name')),
            const SizedBox(height: 12),
            TextField(controller: lastNameController, decoration: const InputDecoration(labelText: 'Last name')),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final ok = await ref.read(authProvider.notifier).updateProfile(
                    firstName: firstNameController.text.trim(),
                    lastName: lastNameController.text.trim(),
                    phoneNumber: phoneController.text.trim(),
                  );
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? 'Profile updated' : 'Update failed')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              color: AppColors.primary,
              child: Column(
                children: [
                  const Text('Profile', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 16),
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white24,
                    child: Text(
                      (user?.firstName.isNotEmpty ?? false) ? user!.firstName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 32, color: AppColors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user?.fullName ?? '', style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(user?.email ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _circleAction(Icons.edit_outlined, 'Edit', () => _showEditDialog(context, ref)),
                      const SizedBox(width: 24),
                      _circleAction(Icons.receipt_long_outlined, 'Orders', () => context.goNamed(AppRoute.myOrders)),
                      const SizedBox(width: 24),
                      _circleAction(Icons.logout, 'Logout', () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) context.goNamed(AppRoute.login);
                      }),
                    ],
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Account Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    _infoCard([
                      _InfoRow(icon: Icons.email_outlined, label: 'Email', value: user?.email ?? '-'),
                      _InfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone number',
                        value: user?.phoneNumber?.isNotEmpty == true ? user!.phoneNumber! : 'Not set',
                      ),
                    ]),
                    const SizedBox(height: 24),
                    const Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    const _AppearanceCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48, height: 48,
            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.white, size: 20),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.white, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _infoCard(List<_InfoRow> rows) {
    return Container(
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final isLast = entry.key == rows.length - 1;
          final row = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(row.icon, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(row.label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(row.value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
}

class _AppearanceCard extends ConsumerWidget {
  const _AppearanceCard();

  static const _options = [
    (label: 'Small', scale: 0.9),
    (label: 'Normal', scale: 1.0),
    (label: 'Large', scale: 1.15),
    (label: 'Extra Large', scale: 1.3),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentScale = ref.watch(textScaleProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.text_fields, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('Text Size', style: TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _options.map((opt) {
              final selected = (currentScale - opt.scale).abs() < 0.01;
              return ChoiceChip(
                label: Text(opt.label),
                selected: selected,
                onSelected: (_) => ref.read(textScaleProvider.notifier).setScale(opt.scale),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(color: selected ? AppColors.white : AppColors.textPrimary, fontSize: 12),
                backgroundColor: AppColors.background,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}