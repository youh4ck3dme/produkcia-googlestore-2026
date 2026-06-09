import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bizagent/core/supabase/supabase_functions_client.dart';

class FakeSupabaseFunctionsClient implements SupabaseFunctionsClient {
  FakeSupabaseFunctionsClient({
    this.isReady = true,
    this.responseData,
    this.statusCode,
    this.details,
  });

  @override
  bool isReady;

  Object? responseData;
  int? statusCode;
  Object? details;

  String? lastFunctionName;
  Map<String, dynamic>? lastBody;
  int invokeCount = 0;

  @override
  Future<FunctionResponse> invoke(
    String functionName, {
    Map<String, dynamic>? body,
  }) async {
    invokeCount++;
    lastFunctionName = functionName;
    lastBody = body;

    if (statusCode != null) {
      throw FunctionException(
        status: statusCode!,
        details: details,
      );
    }

    return FunctionResponse(data: responseData, status: 200);
  }
}
