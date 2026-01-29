import 'package:bizagent/core/models/ico_lookup_result.dart';
import 'package:bizagent/core/services/company_lookup_service.dart';
import 'package:bizagent/core/services/icoatlas_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockIcoAtlasService extends Mock implements IcoAtlasService {}

void main() {
  late FakeFirebaseFirestore fakeDb;
  late MockIcoAtlasService mockRemote;
  late CompanyLookupService service;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    mockRemote = MockIcoAtlasService();
    service = CompanyLookupService(remote: mockRemote, firestore: fakeDb);
  });

  final sampleResult = IcoLookupResult(
    ico: '12345678',
    icoNorm: '12345678',
    name: 'Test Company',
    status: 'Active',
    city: 'Bratislava',
    cachedAt: DateTime.now(),
  );

  test('returns cached result if not expired', () async {
    // 1. Seed Cache
    await fakeDb.collection('companies').doc('12345678').set({
      ...sampleResult.toFirestore(),
      'cachedAt': Timestamp.fromDate(DateTime.now()), // Fresh
    });

    // 2. Call
    final result = await service.lookupByIco('12 345 678'); // Spaces should be stripped

    // 3. Verify
    expect(result.name, 'Test Company');
    verifyZeroInteractions(mockRemote); // Should NOT call remote
  });

  test('returns stale cache but triggers refresh in background', () async {
    // 1. Seed Stale Cache (2 days old)
    final staleDate = DateTime.now().subtract(const Duration(days: 2));
    await fakeDb.collection('companies').doc('12345678').set({
      ...sampleResult.toFirestore(),
      'cachedAt': Timestamp.fromDate(staleDate),
      'name': 'Old Name',
    });

    final freshResult = IcoLookupResult(
      ico: '12345678',
      icoNorm: '12345678',
      name: 'New Name',
      status: 'Active',
      city: 'Bratislava',
      cachedAt: DateTime.now(),
    );

    // Stub remote to return fresh data
    when(() => mockRemote.publicLookup('12345678')).thenAnswer((_) async => freshResult);

    // 2. Call
    final result = await service.lookupByIco('12345678');

    // 3. Verify immediate return is STALE (optimistic UI)
    expect(result.name, 'Old Name');

    // 4. Verify background refresh WAS triggered
    // Allow microtask queue to process
    await Future.delayed(const Duration(milliseconds: 50));
    verify(() => mockRemote.publicLookup('12345678')).called(1);
    
    // 5. Verify DB is updated
    final doc = await fakeDb.collection('companies').doc('12345678').get();
    expect(doc.data()?['name'], 'New Name');
  });

  test('calls remote if cache miss', () async {
    // 1. Stub remote
    when(() => mockRemote.publicLookup('12345678')).thenAnswer((_) async => sampleResult);

    // 2. Call
    final result = await service.lookupByIco('12345678');

    // 3. Verify
    expect(result.name, 'Test Company');
    
    // 4. Check it was saved to cache
    final doc = await fakeDb.collection('companies').doc('12345678').get();
    expect(doc.exists, true);
  });
}
