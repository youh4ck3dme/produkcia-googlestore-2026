import 'dart:async';

import 'package:bizagent/core/supabase/supabase_table_store.dart';

/// In-memory fake pre unit testy repozitárov.
class InMemorySupabaseStore implements SupabaseTableStore {
  InMemorySupabaseStore({this.throwOnSelect = false});

  final Map<String, List<Map<String, dynamic>>> _tables = {};
  final Map<String, StreamController<List<Map<String, dynamic>>>> _streamControllers =
      {};

  /// Keď true, [select] hodí výnimku (test fallback na local cache).
  bool throwOnSelect;

  @override
  bool get isAvailable => true;

  List<Map<String, dynamic>> _rows(String table) =>
      _tables.putIfAbsent(table, () => []);

  StreamController<List<Map<String, dynamic>>> _controller(String table) {
    return _streamControllers.putIfAbsent(
      table,
      () => StreamController<List<Map<String, dynamic>>>.broadcast(),
    );
  }

  void _emit(String table) {
    final controller = _streamControllers[table];
    if (controller != null && !controller.isClosed) {
      controller.add(_rows(table).map((r) => Map<String, dynamic>.from(r)).toList());
    }
  }

  List<Map<String, dynamic>> _filtered(
    String table,
    Map<String, dynamic> eq,
  ) {
    return _rows(table).where((row) {
      for (final entry in eq.entries) {
        if (row[entry.key] != entry.value) return false;
      }
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> _sorted(
    List<Map<String, dynamic>> rows,
    String? orderColumn,
    bool ascending,
  ) {
    if (orderColumn == null) return rows;
    final copy = List<Map<String, dynamic>>.from(rows);
    copy.sort((a, b) {
      final av = a[orderColumn];
      final bv = b[orderColumn];
      final cmp = '$av'.compareTo('$bv');
      return ascending ? cmp : -cmp;
    });
    return copy;
  }

  @override
  Future<void> delete(
    String table, {
    Map<String, dynamic> eq = const {},
  }) async {
    _rows(table).removeWhere((row) {
      for (final entry in eq.entries) {
        if (row[entry.key] != entry.value) return false;
      }
      return true;
    });
    _emit(table);
  }

  @override
  Future<List<Map<String, dynamic>>> select(
    String table, {
    Map<String, dynamic> eq = const {},
    String? orderColumn,
    bool ascending = false,
  }) async {
    if (throwOnSelect) throw Exception('Simulated Supabase outage');
    final rows = _sorted(_filtered(table, eq), orderColumn, ascending);
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  @override
  Future<Map<String, dynamic>?> selectMaybeSingle(
    String table, {
    required List<String> columns,
    Map<String, dynamic> eq = const {},
  }) async {
    final rows = _filtered(table, eq);
    if (rows.isEmpty) return null;
    final row = Map<String, dynamic>.from(rows.first);
    if (columns.length == 1 && columns.first != '*') {
      return {columns.first: row[columns.first]};
    }
    return row;
  }

  @override
  Stream<List<Map<String, dynamic>>> stream(
    String table, {
    required List<String> primaryKey,
    Map<String, dynamic> eq = const {},
    String? orderColumn,
    bool ascending = false,
  }) {
    List<Map<String, dynamic>> snapshot() => _sorted(
          _filtered(table, eq),
          orderColumn,
          ascending,
        )
        .map((r) => Map<String, dynamic>.from(r))
        .toList();

    return Stream<List<Map<String, dynamic>>>.multi((controller) {
      controller.add(snapshot());
      final sub = _controller(table).stream.listen((_) {
        if (!controller.isClosed) controller.add(snapshot());
      });
      controller.onCancel = () => sub.cancel();
    });
  }

  @override
  Future<void> update(
    String table,
    Map<String, dynamic> values, {
    Map<String, dynamic> eq = const {},
  }) async {
    for (final row in _rows(table)) {
      var matches = true;
      for (final entry in eq.entries) {
        if (row[entry.key] != entry.value) {
          matches = false;
          break;
        }
      }
      if (matches) row.addAll(values);
    }
    _emit(table);
  }

  @override
  Future<void> upsert(String table, Map<String, dynamic> row) async {
    final rows = _rows(table);
    final idKeys = row.containsKey('id') ? ['id'] : ['user_id'];
    final index = rows.indexWhere((existing) {
      for (final key in idKeys) {
        if (existing[key] != row[key]) return false;
      }
      return true;
    });
    final copy = Map<String, dynamic>.from(row);
    if (index >= 0) {
      rows[index] = copy;
    } else {
      rows.add(copy);
    }
    _emit(table);
  }
}
