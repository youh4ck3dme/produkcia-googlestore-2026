import 'package:bizagent/features/tools/services/watched_companies_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/in_memory_supabase_store.dart';

void main() {
  late InMemorySupabaseStore store;
  late WatchedCompaniesService service;
  const testUid = 'user_123';

  setUp(() {
    store = InMemorySupabaseStore();
    service = WatchedCompaniesService(store, testUid);
  });

  test('watch adds company to watched_companies table', () async {
    await service.watch('12345678', 'Test s.r.o.');

    final rows = await store.select(
      'watched_companies',
      eq: {'user_id': testUid, 'ico': '12345678'},
    );

    expect(rows.length, 1);
    expect(rows.first['data']['name'], 'Test s.r.o.');
  });

  test('unwatch removes company', () async {
    await service.watch('12345678', 'Test s.r.o.');
    await service.unwatch('12345678');

    final rows = await store.select(
      'watched_companies',
      eq: {'user_id': testUid, 'ico': '12345678'},
    );

    expect(rows, isEmpty);
  });

  test('isWatched stream emits correct values', () async {
    expectLater(
      service.isWatched('12345678'),
      emitsInOrder([false, true, false]),
    );

    await Future.delayed(Duration.zero);
    await service.watch('12345678', 'Test s.r.o.');
    await Future.delayed(Duration.zero);
    await service.unwatch('12345678');
  });

  test('getWatchedCount returns correct count', () async {
    await service.watch('11111111', 'A s.r.o.');
    await service.watch('22222222', 'B s.r.o.');

    expect(await service.getWatchedCount(), 2);
  });
}