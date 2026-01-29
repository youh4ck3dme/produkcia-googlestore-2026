import 'package:bizagent/core/models/ico_lookup_result.dart';
import 'package:bizagent/core/services/company_lookup_service.dart';
import 'package:bizagent/core/services/icoatlas_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Needed for Timestamp
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// --- Mocks ---
class MockIcoAtlasService extends Mock implements IcoAtlasService {}

void main() {
  late FakeFirebaseFirestore fakeDb;
  late MockIcoAtlasService mockRemote;
  late CompanyLookupService service;

  // Real data sample
  const validIco = '35742364';
  const invalidIco = '00000000';
  
  final validResult = IcoLookupResult(
    ico: validIco,
    icoNorm: validIco,
    name: 'Telegrafia, a.s.',
    status: 'Active',
    city: 'Košice',
    cachedAt: DateTime.now(),
  );

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    mockRemote = MockIcoAtlasService();
    // Inject DB dependent on how service is constructed in previous steps
    service = CompanyLookupService(remote: mockRemote, firestore: fakeDb);
  });

  group('🔍 IČO Lookup Diagnostic Suite (5 Layers)', () {
    
    // -------------------------------------------------------------------------
    // Layer 1: Data Model (Mapping & Null Safety)
    // -------------------------------------------------------------------------
    test('Layer 1: Data Model - Should handle partial/malformed data gracefully', () {
      final badData = {
        'name': 'Broken Ltd.', 
        // Missing status, address, etc.
      };
      
      // Should not throw
      final result = IcoLookupResult.fromMap(badData);
      
      expect(result.name, 'Broken Ltd.');
      expect(result.status, ''); // Fallback default
      expect(result.city, '');   // Fallback default
    });

    test('Layer 1: Data Model - Normalization logic check', () {
      final result = IcoLookupResult(name: 'Test', status: 'OK', city: 'BA', ico: ' 12 345 678 ');
      expect(result.icoNorm, '12345678');
    });

    // -------------------------------------------------------------------------
    // Layer 2: API (IcoAtlasService Integration)
    // -------------------------------------------------------------------------
    test('Layer 2: API - Should handle 404 (Not Found) correctly', () async {
      when(() => mockRemote.publicLookup(invalidIco))
          .thenAnswer((_) async => null); // Simulate 404/Empty return

      // Expect service to throw specific error or return null based on design
      // Current design throws "Company not found"
      final result = await service.lookupByIco(invalidIco);
      expect(result.isValid, false);
      // expect(result.status, 'Neplatné dáta'); // Optional verification
    });

    test('Layer 2: API - Should propagate Rate Limit status', () async {
      final limitedResult = IcoLookupResult.rateLimited(resetIn: 60);
      when(() => mockRemote.publicLookup(any()))
          .thenAnswer((_) async => limitedResult);

      final result = await service.lookupByIco('11111111');
      expect(result.isRateLimited, true);
      expect(result.resetIn, 60);
    });

    // -------------------------------------------------------------------------
    // Layer 3: Cache (Firestore)
    // -------------------------------------------------------------------------
    test('Layer 3: Cache - Should return cached data if available', () async {
      await fakeDb.collection('companies').doc(validIco).set({
        ...validResult.toFirestore(),
        'name': 'Cached Name',
        'cachedAt': Timestamp.fromDate(DateTime.now()),
      });

      final result = await service.lookupByIco(validIco);
      expect(result.name, 'Cached Name');
      verifyZeroInteractions(mockRemote);
    });

    test('Layer 3: Cache - Should save new API results to Firestore', () async {
      when(() => mockRemote.publicLookup(validIco)).thenAnswer((_) async => validResult);

      await service.lookupByIco(validIco);

      final doc = await fakeDb.collection('companies').doc(validIco).get();
      expect(doc.exists, true);
      expect(doc.data()!['name'], 'Telegrafia, a.s.');
    });

    // -------------------------------------------------------------------------
    // Layer 4: Service (Logic & TTL)
    // -------------------------------------------------------------------------
    test('Layer 4: Service - Should return STALE data but trigger Background Refresh', () async {
      // Old cache
      await fakeDb.collection('companies').doc(validIco).set({
        ...validResult.toFirestore(),
        'name': 'Old Name',
        'cachedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
      });

      // Remote has new data
      final freshResult = IcoLookupResult(
        ico: validIco, icoNorm: validIco, name: 'New Name', status: 'Active', city: 'KE'
      );
      when(() => mockRemote.publicLookup(validIco)).thenAnswer((_) async => freshResult);

      // Call
      final result = await service.lookupByIco(validIco);

      // Immediate result is STALE (optimistic UX)
      expect(result.name, 'Old Name'); 

      // Wait for background microtask (allow async gap to close)
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify db updated in background
      final updatedDoc = await fakeDb.collection('companies').doc(validIco).get();
      expect(updatedDoc.data()!['name'], 'New Name');
    });

    // -------------------------------------------------------------------------
    // Layer 5: UI Flow (Simulation)
    // -------------------------------------------------------------------------
    test('Layer 5: UI Flow - Input validation normalization', () async {
      // Simulating what the TextField controller logic does
      // Assuming service handles spaces
      when(() => mockRemote.publicLookup(validIco)).thenAnswer((_) async => validResult);
      
      final result = await service.lookupByIco(' 35 742 364 ');
      expect(result.icoNorm, validIco);
    });
  });
}
