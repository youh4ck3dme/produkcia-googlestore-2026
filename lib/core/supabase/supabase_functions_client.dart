import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

abstract class SupabaseFunctionsClient {
  bool get isReady;

  Future<FunctionResponse> invoke(
    String functionName, {
    Map<String, dynamic>? body,
  });

  factory SupabaseFunctionsClient.fromSupabase(SupabaseClient? client) {
    if (client == null) return _UnavailableSupabaseFunctionsClient();
    return _LiveSupabaseFunctionsClient(client);
  }
}

class _UnavailableSupabaseFunctionsClient implements SupabaseFunctionsClient {
  @override
  bool get isReady => false;

  @override
  Future<FunctionResponse> invoke(
    String functionName, {
    Map<String, dynamic>? body,
  }) async {
    throw StateError('Supabase functions not configured');
  }
}

class _LiveSupabaseFunctionsClient implements SupabaseFunctionsClient {
  _LiveSupabaseFunctionsClient(this._client);

  final SupabaseClient _client;

  @override
  bool get isReady => true;

  @override
  Future<FunctionResponse> invoke(
    String functionName, {
    Map<String, dynamic>? body,
  }) {
    return _client.functions.invoke(functionName, body: body);
  }
}

SupabaseFunctionsClient defaultFunctionsClient() =>
    SupabaseFunctionsClient.fromSupabase(
      SupabaseConfig.isReady ? SupabaseConfig.client : null,
    );
