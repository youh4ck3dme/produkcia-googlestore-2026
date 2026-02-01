import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bizagent/core/services/icoatlas_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // flutter_test installs an HttpOverrides that returns 400 for all requests.
    // We explicitly disable it for this "live" smoke test.
    HttpOverrides.global = null;
  });

  group('IcoAtlas live lookup (real IČO)', () {
    final hasApiKey = const String.fromEnvironment('ICOATLAS_API_KEY').trim().isNotEmpty;

    test(
      'lookup ESET (31333532) returns valid result',
      () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final svc = container.read(icoAtlasServiceProvider);

      final result = await svc.publicLookup('31333532');
      expect(result, isNotNull);
      expect(result!.icoNorm, equals('31333532'));
      expect(result.name.trim(), isNotEmpty);
      },
      skip: hasApiKey ? null : 'Set --dart-define=ICOATLAS_API_KEY=... to run live network tests.',
    );

    test(
      'lookup SLSP (00151653) returns valid result',
      () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final svc = container.read(icoAtlasServiceProvider);

      final result = await svc.publicLookup('00151653');
      expect(result, isNotNull);
      expect(result!.icoNorm, equals('00151653'));
      expect(result.name.trim(), isNotEmpty);
      },
      skip: hasApiKey ? null : 'Set --dart-define=ICOATLAS_API_KEY=... to run live network tests.',
    );
  });
}

