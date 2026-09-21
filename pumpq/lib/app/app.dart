import 'package:flutter/material.dart';
import 'package:pumpq/core/constants/app_strings.dart';
import 'package:pumpq/core/theme/app_theme.dart';

class PumpQApp extends StatelessWidget {
  const PumpQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: Text(
            AppStrings.appName,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
        ),
      ),
    );
  }
}