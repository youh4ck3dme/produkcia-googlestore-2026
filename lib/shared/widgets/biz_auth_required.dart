import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BizAuthRequired extends StatelessWidget {
  const BizAuthRequired({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prístup zamknutý')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 56),
              const SizedBox(height: 16),
              Text(
                'Nie si prihlásený',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message ??
                    'Pre export potrebuješ byť prihlásený. Prihlás sa a pokračuj.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Prihlásiť sa'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
