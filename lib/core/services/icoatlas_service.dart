import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/company_info.dart';
import '../models/ico_lookup_result.dart';

final icoAtlasServiceProvider = Provider<IcoAtlasService>((ref) {
  const isReal = String.fromEnvironment('ICO_MODE') == 'REAL';
  final baseUrl = isReal ? 'https://icoatlas.sk' : 'https://bizagent.sk';
  
  final headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  if (isReal) {
    // API Key from secure storage or env (hardcoded for now as per instructions)
    headers['X-Api-Key'] = 'ia_7b78c4d4ecfc53bf11599130dabfed3f36ea872b193f0eda';
  }

  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: null,
    receiveTimeout: null,
    headers: headers,
  ));

  // Logger only for development
  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));
  }

  const isDemo = String.fromEnvironment('ICO_MODE') != 'REAL';
  return IcoAtlasService(dio, isDemoMode: isDemo);
});

class IcoAtlasService {
  final Dio _dio;
  final bool isDemoMode;

  IcoAtlasService(this._dio, {this.isDemoMode = true});

  /// Performs a public IČO lookup via the secure gateway.
  /// Handles 200 (Success) and 429 (Rate Limited).
  Future<IcoLookupResult?> publicLookup(String ico) async {
    try {
      if (!isDemoMode) {
        // REAL MODE: Direct Access to icoatlas.sk
        final endpoint = '/api/company/$ico';
        final response = await _dio.get(endpoint);

        if (response.statusCode == 200 && response.data != null) {
          return IcoLookupResult.fromRealApi(response.data);
        }
        return null; 
      }

      // DEMO/GATEWAY MODE
      const endpoint = '/api/public/ico/lookup';
      final response = await _dio.get(endpoint, queryParameters: {'ico': ico});

      if (response.statusCode == 200 && response.data != null && response.data['ok'] == true) {
        return IcoLookupResult.fromMap(response.data['summary'] ?? {});
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        final resetIn = e.response?.data?['resetIn'];
        return IcoLookupResult.rateLimited(
          resetIn: resetIn != null ? int.tryParse(resetIn.toString()) : null,
        );
      }
      debugPrint('Public IČO lookup failed: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Public IČO lookup error: $e');
      return null;
    }
  }

  /// Fetches company data by normalized IČO.
  /// Used for background referesh logic.
  Future<IcoLookupResult> fetchByIco(String icoNorm) async {
    // Re-use public lookup logic but throw on failure for the background service
    final result = await publicLookup(icoNorm);
    if (result == null || result.isRateLimited) {
      throw Exception('Refresh failed');
    }
    return result;
  }

  /// Performs a secure IČO lookup for paid users (fetches full data + AI verdict).
  Future<IcoLookupResult?> secureLookup(String ico, String? token) async {
    if (token == null) return null;

    try {
      const endpoint = '/api/internal/ico/full';
      final response = await _dio.get(
        endpoint, 
        queryParameters: {'ico': ico},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data != null && response.data['ok'] == true) {
        // Map full data response to result model
        return IcoLookupResult.fromMap(response.data['payload'] ?? {});
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
      debugPrint('Secure IČO lookup failed: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Secure IČO lookup error: $e');
      return null;
    }
  }

  /// Looks up a company by its IČO (Legacy/Proxy method).
  Future<CompanyInfo?> lookupCompany(String ico) async {
    try {
      // Proxying through the public lookup for now as per architecture rules
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

  /// Provides company suggestions based on a search query.
  /// Note: This should also be gated or proxied if needed.
  Future<List<Map<String, dynamic>>> autocomplete(String query) async {
    if (query.length < 2) return [];
    
    try {
      // Assuming gateway might have an autocomplete proxy later
      final response = await _dio.get('/api/public/ico/autocomplete', queryParameters: {'q': query});
      
      if (response.statusCode == 200 && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
