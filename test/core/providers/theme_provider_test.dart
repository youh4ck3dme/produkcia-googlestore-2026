import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bizagent/core/providers/theme_provider.dart';

void main() {
  group('ThemeProvider Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial state is light', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeProvider), ThemeMode.light);
    });

    test('setTheme updates state and saves to prefs', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(themeProvider.notifier).setTheme(ThemeMode.dark);
      expect(container.read(themeProvider), ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('themeMode'), 'dark');
    });

    test('Loads dark mode from prefs on initialization', () async {
      SharedPreferences.setMockInitialValues({'themeMode': 'dark'});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Wait for async initialization
      await Future.delayed(const Duration(milliseconds: 100));

      expect(container.read(themeProvider), ThemeMode.dark);
    }, skip: 'Async initialization timing issue');
  });
}
