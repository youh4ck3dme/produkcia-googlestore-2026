import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ico_lookup_result.dart';
import 'icoatlas_service.dart';

final companyLookupServiceProvider = Provider<CompanyLookupService>((ref) {
  return CompanyLookupService(
    firestore: FirebaseFirestore.instance,
    remote: ref.read(icoAtlasServiceProvider),
  );
});

class CompanyLookupService {
  CompanyLookupService({
    required FirebaseFirestore firestore,
    required IcoAtlasService remote,
  })  : _db = firestore,
        _remote = remote;

  final FirebaseFirestore _db;
  final IcoAtlasService _remote;

  static const _ttl = Duration(hours: 24);

  /// PUBLIC API
  Future<IcoLookupResult> lookupByIco(String input) async {
    final icoNorm = _normalizeIco(input);
    if (icoNorm.isEmpty) {
      return IcoLookupResult.invalid();
    }

    final docRef = _db.collection('companies').doc(icoNorm); // Using 'companies' as per existing data, user suggested 'company_cache' but sticking to established schema is safer for now unless migration intended. Let's stick to 'companies' to match existing tests/data.
    final snap = await docRef.get();

    if (snap.exists) {
      final cached = IcoLookupResult.fromFirestore(snap.data()!);

      if (!_isExpired(cached)) {
        return cached;
      }

      // stale → return now + refresh in background
      unawaited(_refreshInBackground(icoNorm, docRef));
      return cached;
    }

    return _fetchFresh(icoNorm, docRef);
  }

  /// INTERNALS

  Future<IcoLookupResult> _fetchFresh(
    String ico,
    DocumentReference<Map<String, dynamic>> docRef,
  ) async {
    try {
      // Adapter: user skeleton calls _remote.lookup(ico) which returns IcoLookupResult.
      // Existing IcoAtlasService.publicLookup returns IcoLookupResult?.
      // We need to bridge this.
      final fresh = await _remote.publicLookup(ico);

      if (fresh == null) {
         return IcoLookupResult.invalid(); // Not found or error
      }
      
      if (!fresh.isValid) {
        return fresh; // Limit reached etc.
      }

      // Save using toFirestore which puts ServerTimestamp
      await docRef.set(fresh.toFirestore(), SetOptions(merge: true));
      return fresh;
    } on SocketException {
      return IcoLookupResult.offline();
    } catch (e) {
      return IcoLookupResult.invalid();
    }
  }

  Future<void> _refreshInBackground(
    String ico,
    DocumentReference<Map<String, dynamic>> docRef,
  ) async {
    try {
      final fresh = await _remote.publicLookup(ico);
      if (fresh != null && fresh.isValid) {
        await docRef.set(fresh.toFirestore(), SetOptions(merge: true));
      }
    } catch (_) {
      // silent background failure
    }
  }

  bool _isExpired(IcoLookupResult result) {
    final ts = result.cachedAt;
    if (ts == null) return true;
    return DateTime.now().difference(ts) > _ttl;
  }

  String _normalizeIco(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    return digits.length == 8 ? digits : '';
  }
}
