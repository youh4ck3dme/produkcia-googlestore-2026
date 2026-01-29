import 'package:bizagent/features/tools/services/watched_companies_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late WatchedCompaniesService service;
  const testUid = 'user_123';

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    service = WatchedCompaniesService(fakeDb, testUid);
  });

  test('watch adds company to user collection', () async {
    await service.watch('12345678', 'Test s.r.o.');

    final doc = await fakeDb
        .collection('users')
        .doc(testUid)
        .collection('watched_companies')
        .doc('12345678')
        .get();

    expect(doc.exists, true);
    expect(doc.data()!['name'], 'Test s.r.o.');
  });

  test('unwatch removes company', () async {
    // Setup
    await service.watch('12345678', 'Test s.r.o.');
    
    // Act
    await service.unwatch('12345678');

    // Assert
    final doc = await fakeDb
        .collection('users')
        .doc(testUid)
        .collection('watched_companies')
        .doc('12345678')
        .get();

    expect(doc.exists, false);
  });

  test('isWatched stream emits correct values', () async {
    // Expect false initially
    expectLater(service.isWatched('12345678'), emitsInOrder([false, true, false]));

    // Act
    await Future.delayed(Duration.zero);
    await service.watch('12345678', 'Test s.r.o.');
    await Future.delayed(Duration.zero);
    await service.unwatch('12345678');
  });
}
