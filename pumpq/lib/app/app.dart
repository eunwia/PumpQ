import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pumpq/app/routes.dart';
import 'package:pumpq/core/constants/app_strings.dart';
import 'package:pumpq/core/services/text_scale_provider.dart';
import 'package:pumpq/core/theme/app_theme.dart';

class PumpQApp extends ConsumerWidget {
  const PumpQApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final textScale = ref.watch(textScaleProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        );
      },
    );
  }
}