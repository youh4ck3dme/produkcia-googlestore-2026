import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../supabase/supabase_config.dart';
import '../models/company_info.dart';
import '../models/ico_lookup_result.dart';

/// Company data source: icoatlas API (single source of truth).
/// Override host via --dart-define=ICOATLAS_BASE_URL=https://ico.bizagent.sk
/// API key optional via --dart-define=ICOATLAS_API_KEY=xxx.
final icoAtlasServiceProvider = Provider<IcoAtlasService>((ref) {
  const baseUrl = String.fromEnvironment(
    'ICOATLAS_BASE_URL',
    defaultValue: 'https://icoatlas.sk',
  );

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
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 12),
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

  /// Normalizuje IČO (iba číslice, pad na 8). Vráti null ak neplatné.
  static String? normalizeIco(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty || digits.length > 8) return null;
    return digits.padLeft(8, '0');
  }

  /// Company factual data – icoatlas API (ICOATLAS_BASE_URL). Single source of truth.
  Future<IcoLookupResult?> publicLookup(String ico) async {
    final normalized = normalizeIco(ico);
    if (normalized == null) return IcoLookupResult.invalid();

    if (kIsWeb && SupabaseConfig.isReady) {
      final proxied = await _publicLookupViaSupabaseProxy(normalized);
      if (proxied != null) return proxied;
    }

    try {
      final response = await _dio.get('/api/company/$normalized');

      if (response.statusCode == 200 && response.data != null) {
        final rawAny = response.data;
        if (rawAny is! Map<String, dynamic>) return null;
        final raw = rawAny;

        // Common backends sometimes return { ok: false, error: ... }
        if (raw['ok'] == false) return null;

        final data = raw['data'];
        if (data is Map<String, dynamic>) {
          // Laravel ico-atlas: { data: {...}, meta } — name môže byť null → not found
          if (data['source'] == 'not-found' ||
              ((data['name'] == null || '${data['name']}'.trim().isEmpty) &&
                  data['ico'] == null)) {
            return IcoLookupResult.notFound();
          }
          final parsed = await _enrichVatRegister(
            IcoLookupResult.fromIcoAtlasApi(data),
          );
          return parsed.isValid ? parsed : IcoLookupResult.notFound();
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
          return parsed.isValid ? parsed : IcoLookupResult.notFound();
        }

        // Back-compat formats.
        final parsed = await _enrichVatRegister(
          IcoLookupResult.fromRealApi(raw),
        );
        return parsed.isValid ? parsed : IcoLookupResult.notFound();
      }
      if (response.statusCode == 404) return IcoLookupResult.notFound();
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return IcoLookupResult.notFound();
      }
      if (e.response?.statusCode == 429) {
        final resetIn = e.response?.data?['resetIn'];
        return IcoLookupResult.rateLimited(
          resetIn: resetIn != null ? int.tryParse(resetIn.toString()) : null,
        );
      }
      if (_isNetworkFailure(e)) {
        debugPrint('IČO lookup offline/timeout: ${e.message}');
        return IcoLookupResult.offline();
      }
      debugPrint('IČO lookup failed: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('IČO lookup error: $e');
      return null;
    }
  }

  bool _isNetworkFailure(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown && e.error != null;
  }

  /// Background refresh – same source (ICOATLAS_BASE_URL).
  Future<IcoLookupResult> fetchByIco(String icoNorm) async {
    final result = await publicLookup(icoNorm);
    if (result == null || result.isRateLimited || !result.isValid) {
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

  /// Doplní IČ DPH z registra platiteľov FS, ak icoatlas vráti len RPO údaje.
  Future<IcoLookupResult> _enrichVatRegister(IcoLookupResult result) async {
    if (result.isVatPayer || result.icoNorm.isEmpty) return result;

    final icDph = await _fetchVatIcDphFromFsRegister(result.icoNorm);
    if (icDph == null || icDph.isEmpty) return result;

    return result.copyWith(icDph: icDph);
  }

  /// Register platiteľov DPH — Finančná správa (OpenData IZ).
  Future<String?> _fetchVatIcDphFromFsRegister(String icoNorm) async {
    try {
      final response = await Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: const {'Accept': 'application/json'},
      )).get(
        'https://iz.opendata.financnasprava.sk/api/vatpayers',
        queryParameters: {'ico': icoNorm},
      );

      if (response.statusCode != 200 || response.data == null) return null;

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final icDph = IcoLookupResult.pickNullableString(data, [
          'icDph',
          'ic_dph',
          'vatId',
          'vat_id',
        ]);
        if (icDph != null) return icDph;

        final items = data['items'] ?? data['data'] ?? data['results'];
        if (items is List && items.isNotEmpty) {
          final first = items.first;
          if (first is Map<String, dynamic>) {
            return IcoLookupResult.pickNullableString(first, [
              'icDph',
              'ic_dph',
              'vatId',
              'vat_id',
            ]);
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('FS DPH register lookup failed: $e');
      return null;
    }
  }

  /// Web: priamy fetch na icoatlas host blokuje CORS — proxy cez Supabase Edge Function.
  Future<IcoLookupResult?> _publicLookupViaSupabaseProxy(String ico) async {
    try {
      final res = await SupabaseConfig.client.functions.invoke(
        'ico-company',
        body: {'ico': ico},
      );

      final rawAny = res.data;
      if (rawAny is! Map<String, dynamic>) return null;
      final raw = rawAny;

      if (raw['ok'] == false) {
        final err = raw['error']?.toString() ?? '';
        if (err.contains('not_found')) return IcoLookupResult.notFound();
        return null;
      }

      final data = raw['data'];
      if (data is Map<String, dynamic>) {
        final parsed = await _enrichVatRegister(
          IcoLookupResult.fromIcoAtlasApi(data),
        );
        return parsed.isValid ? parsed : IcoLookupResult.notFound();
      }

      final parsed = await _enrichVatRegister(
        IcoLookupResult.fromRealApi(raw),
      );
      return parsed.isValid ? parsed : IcoLookupResult.notFound();
    } catch (e) {
      debugPrint('IČO web proxy lookup failed: $e');
      return IcoLookupResult.offline();
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
