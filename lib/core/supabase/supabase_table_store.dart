import 'package:supabase_flutter/supabase_flutter.dart';

/// Tenká abstrakcia nad Supabase PostgREST pre testovateľné repozitáre.
abstract class SupabaseTableStore {
  bool get isAvailable;

  Future<List<Map<String, dynamic>>> select(
    String table, {
    Map<String, dynamic> eq = const {},
    String? orderColumn,
    bool ascending = false,
  });

  Future<Map<String, dynamic>?> selectMaybeSingle(
    String table, {
    required List<String> columns,
    Map<String, dynamic> eq = const {},
  });

  Stream<List<Map<String, dynamic>>> stream(
    String table, {
    required List<String> primaryKey,
    Map<String, dynamic> eq = const {},
    String? orderColumn,
    bool ascending = false,
  });

  Future<void> upsert(String table, Map<String, dynamic> row);

  Future<void> update(
    String table,
    Map<String, dynamic> values, {
    Map<String, dynamic> eq = const {},
  });

  Future<void> delete(
    String table, {
    Map<String, dynamic> eq = const {},
  });

  factory SupabaseTableStore.fromClient(SupabaseClient? client) {
    if (client == null) return _UnavailableSupabaseTableStore();
    return _SupabaseClientTableStore(client);
  }
}

class _UnavailableSupabaseTableStore implements SupabaseTableStore {
  @override
  bool get isAvailable => false;

  @override
  Future<void> delete(String table, {Map<String, dynamic> eq = const {}}) async {}

  @override
  Future<List<Map<String, dynamic>>> select(
    String table, {
    Map<String, dynamic> eq = const {},
    String? orderColumn,
    bool ascending = false,
  }) async =>
      [];

  @override
  Future<Map<String, dynamic>?> selectMaybeSingle(
    String table, {
    required List<String> columns,
    Map<String, dynamic> eq = const {},
  }) async =>
      null;

  @override
  Stream<List<Map<String, dynamic>>> stream(
    String table, {
    required List<String> primaryKey,
    Map<String, dynamic> eq = const {},
    String? orderColumn,
    bool ascending = false,
  }) =>
      const Stream.empty();

  @override
  Future<void> update(
    String table,
    Map<String, dynamic> values, {
    Map<String, dynamic> eq = const {},
  }) async {}

  @override
  Future<void> upsert(String table, Map<String, dynamic> row) async {}
}

class _SupabaseClientTableStore implements SupabaseTableStore {
  _SupabaseClientTableStore(this._client);

  final SupabaseClient _client;

  @override
  bool get isAvailable => true;

  dynamic _query(String table) => _client.from(table);

  dynamic _applyEq(dynamic query, Map<String, dynamic> eq) {
    var q = query;
    for (final entry in eq.entries) {
      q = q.eq(entry.key, entry.value);
    }
    return q;
  }

  @override
  Future<void> delete(
    String table, {
    Map<String, dynamic> eq = const {},
  }) async {
    await _applyEq(_query(table).delete(), eq);
  }

  @override
  Future<List<Map<String, dynamic>>> select(
    String table, {
    Map<String, dynamic> eq = const {},
    String? orderColumn,
    bool ascending = false,
  }) async {
    var query = _applyEq(_query(table).select(), eq);
    if (orderColumn != null) {
      query = query.order(orderColumn, ascending: ascending);
    }
    final rows = await query;
    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> selectMaybeSingle(
    String table, {
    required List<String> columns,
    Map<String, dynamic> eq = const {},
  }) async {
    final row = await _applyEq(
      _query(table).select(columns.join(',')),
      eq,
    ).maybeSingle();
    if (row == null) return null;
    return Map<String, dynamic>.from(row as Map);
  }

  @override
  Stream<List<Map<String, dynamic>>> stream(
    String table, {
    required List<String> primaryKey,
    Map<String, dynamic> eq = const {},
    String? orderColumn,
    bool ascending = false,
  }) {
    var query = _query(table).stream(primaryKey: primaryKey);
    query = _applyEq(query, eq);
    if (orderColumn != null) {
      query = query.order(orderColumn, ascending: ascending);
    }
    return query.map(
      (rows) => rows.map((row) => Map<String, dynamic>.from(row)).toList(),
    );
  }

  @override
  Future<void> update(
    String table,
    Map<String, dynamic> values, {
    Map<String, dynamic> eq = const {},
  }) async {
    await _applyEq(_query(table).update(values), eq);
  }

  @override
  Future<void> upsert(String table, Map<String, dynamic> row) async {
    await _query(table).upsert(row);
  }
}
