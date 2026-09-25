import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pumpq/app/route_names.dart';
import 'package:pumpq/core/constants/app_colors.dart';
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
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(labelText: 'First name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(labelText: 'Last name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
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
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary,
              child: Text(
                (user?.firstName.isNotEmpty ?? false) ? user!.firstName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 32, color: AppColors.white),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              user?.fullName ?? '',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 24),
          _InfoTile(icon: Icons.email, label: 'Email', value: user?.email ?? '-'),
          _InfoTile(
            icon: Icons.phone,
            label: 'Phone',
            value: user?.phoneNumber?.isNotEmpty == true ? user!.phoneNumber! : 'Not set',
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showEditDialog(context, ref),
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.goNamed(AppRoute.login);
            },
            icon: const Icon(Icons.logout, color: AppColors.error),
            label: const Text('Logout', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      subtitle: Text(value, style: const TextStyle(fontSize: 15)),
    );
  }
}