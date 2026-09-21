import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pumpq/app/route_names.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Login', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.goNamed(AppRoute.home),
                child: const Text('Go to Home (temporary)'),
              ),
              TextButton(
                onPressed: () => context.pushNamed(AppRoute.register),
                child: const Text('Create an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}