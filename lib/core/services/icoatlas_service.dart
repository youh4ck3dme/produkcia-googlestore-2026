import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/company_info.dart';
import '../models/ico_lookup_result.dart';

/// Company data source: ONLY https://icoatlas.sk (single source of truth).
/// API key optional override via --dart-define=ICOATLAS_API_KEY=xxx.
final icoAtlasServiceProvider = Provider<IcoAtlasService>((ref) {
  const baseUrl = 'https://icoatlas.sk';

  const apiKey = String.fromEnvironment(
    'ICOATLAS_API_KEY',
    defaultValue: '',
  );

  final headers = <String, String>{
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
  if (apiKey.trim().isNotEmpty) {
    headers['X-Api-Key'] = apiKey;
  }

  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: headers,
  ));

  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(
      request: true,
      // Do NOT log headers; may contain X-Api-Key.
      requestHeader: false,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));
  }

  const gatewayBaseUrl = String.fromEnvironment('GATEWAY_BASE_URL', defaultValue: '');

  return IcoAtlasService(dio, gatewayBaseUrl: gatewayBaseUrl.isNotEmpty ? gatewayBaseUrl : null);
});

/// Company data: icoatlas.sk only. AI Verdict / lead magnet / monetization: Next.js gateway (optional).
class IcoAtlasService {
  final Dio _dio;
  final Dio? _gatewayDio;
  final String? _gatewayBaseUrl;

  IcoAtlasService(
    this._dio, {
    String? gatewayBaseUrl,
    Dio? gatewayDio,
  })  : _gatewayBaseUrl = gatewayBaseUrl,
        _gatewayDio = gatewayDio;

  /// Company factual data – ONLY icoatlas.sk. Single source of truth.
  Future<IcoLookupResult?> publicLookup(String ico) async {
    try {
      final response = await _dio.get('/api/company/$ico');

      if (response.statusCode == 200 && response.data != null) {
        final rawAny = response.data;
        if (rawAny is! Map<String, dynamic>) return null;
        final raw = rawAny;

        // Common backends sometimes return { ok: false, error: ... }
        if (raw['ok'] == false) return null;

        final data = raw['data'];
        if (data is Map<String, dynamic>) {
          final parsed = IcoLookupResult.fromIcoAtlasApi(data);
          return parsed.isValid ? parsed : null;
        }

        // Legacy test/back-compat: { ok: true, summary: { ico, name, status } }
        final summary = raw['summary'];
        if (summary is Map<String, dynamic>) {
          final parsed = IcoLookupResult(
            ico: (summary['ico'] ?? '').toString(),
            icoNorm: (summary['ico'] ?? '').toString(),
            name: (summary['name'] ?? '').toString(),
            status: (summary['status'] ?? '').toString(),
            city: '',
          );
          return parsed.isValid ? parsed : null;
        }

        // Back-compat formats.
        final parsed = IcoLookupResult.fromRealApi(raw);
        return parsed.isValid ? parsed : null;
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        final resetIn = e.response?.data?['resetIn'];
        return IcoLookupResult.rateLimited(
          resetIn: resetIn != null ? int.tryParse(resetIn.toString()) : null,
        );
      }
      debugPrint('IČO lookup failed: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('IČO lookup error: $e');
      return null;
    }
  }

  /// Background refresh – same source (icoatlas.sk).
  Future<IcoLookupResult> fetchByIco(String icoNorm) async {
    final result = await publicLookup(icoNorm);
    if (result == null || result.isRateLimited) {
      throw Exception('Refresh failed');
    }
    return result;
  }

  /// Full data + AI Verdict – Next.js gateway only (monetization, verdict). Requires GATEWAY_BASE_URL.
  Future<IcoLookupResult?> secureLookup(String ico, String? token) async {
    if (token == null) return null;

    final dio = _gatewayDio ??
        (_gatewayBaseUrl != null ? Dio(BaseOptions(baseUrl: _gatewayBaseUrl)) : null);
    if (dio == null) return null;

    try {
      final response = await dio.get(
        '/api/internal/ico/full',
        queryParameters: {'ico': ico},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data != null && response.data['ok'] == true) {
        final payload = response.data['payload'];
        if (payload is Map<String, dynamic>) {
          final parsed = IcoLookupResult.fromMap(payload);
          return parsed;
        }
        return null;
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        final resetIn = e.response?.data?['resetIn'];
        return IcoLookupResult.rateLimited(
          resetIn: resetIn != null ? int.tryParse(resetIn.toString()) : null,
        );
      }
      if (e.response?.statusCode == 402) {
        return IcoLookupResult.paymentRequired();
      }
      debugPrint('Secure lookup failed: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Secure lookup error: $e');
      return null;
    }
  }

  /// Company info for forms – uses icoatlas.sk only.
  Future<CompanyInfo?> lookupCompany(String ico) async {
    try {
      final result = await publicLookup(ico);

      if (result != null && !result.isRateLimited && result.name.isNotEmpty) {
        return CompanyInfo(
          name: result.name,
          ico: ico,
          address: result.fullAddress,
          dic: result.dic,
          icDph: result.icDph,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Autocomplete – Next.js gateway (public lead magnet API). Returns [] if gateway not configured.
  Future<List<Map<String, dynamic>>> autocomplete(String query) async {
    if (query.length < 2) return [];
    final dio = _gatewayDio ??
        (_gatewayBaseUrl != null ? Dio(BaseOptions(baseUrl: _gatewayBaseUrl)) : null);
    if (dio == null) return [];

    try {
      final response = await dio.get('/api/public/ico/autocomplete', queryParameters: {'q': query});

      if (response.statusCode == 200 && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
