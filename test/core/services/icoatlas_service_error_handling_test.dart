import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bizagent/core/services/icoatlas_service.dart';
import 'package:bizagent/core/models/ico_lookup_result.dart';
import 'package:bizagent/core/models/company_info.dart';

class MockDio extends Mock implements Dio {}

class MockResponse extends Mock implements Response {}

void main() {
  group('IcoAtlasService Error Handling', () {
    late MockDio mockDio;
    late IcoAtlasService service;

    setUp(() {
      mockDio = MockDio();
      service = IcoAtlasService(mockDio, isDemoMode: true);
    });

    group('publicLookup', () {
      test('should handle network timeout errors', () async {
        // Arrange
        when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/api/public/ico/lookup'),
              type: DioExceptionType.connectionTimeout,
              message: 'Connection timeout',
            ));

        // Act
        final result = await service.publicLookup('12345678');

        // Assert
        expect(result, isNull);
      });

      test('should handle connection errors', () async {
        // Arrange
        when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/api/public/ico/lookup'),
              type: DioExceptionType.connectionError,
              message: 'No internet connection',
            ));

        // Act
        final result = await service.publicLookup('12345678');

        // Assert
        expect(result, isNull);
      });

      test('should handle rate limiting (429)', () async {
        // Arrange
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(429);
        when(() => mockResponse.data).thenReturn({'resetIn': '60'});

        when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/api/public/ico/lookup'),
              response: mockResponse,
              type: DioExceptionType.badResponse,
            ));

        // Act
        final result = await service.publicLookup('12345678');

        // Assert
        expect(result, isNotNull);
        expect(result!.isRateLimited, isTrue);
        expect(result.resetIn, 60);
      });

      test('should handle rate limiting without resetIn', () async {
        // Arrange
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(429);
        when(() => mockResponse.data).thenReturn({});

        when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/api/public/ico/lookup'),
              response: mockResponse,
              type: DioExceptionType.badResponse,
            ));

        // Act
        final result = await service.publicLookup('12345678');

        // Assert
        expect(result, isNotNull);
        expect(result!.isRateLimited, isTrue);
        expect(result.resetIn, isNull);
      });

      test('should handle 404 Not Found', () async {
        // Arrange
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(404);
        when(() => mockResponse.data).thenReturn({'error': 'Company not found'});

        when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/api/public/ico/lookup'),
              response: mockResponse,
              type: DioExceptionType.badResponse,
            ));

        // Act
        final result = await service.publicLookup('99999999');

        // Assert
        expect(result, isNull);
      });

      test('should handle 500 Internal Server Error', () async {
        // Arrange
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(500);
        when(() => mockResponse.data).thenReturn({'error': 'Internal server error'});

        when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/api/public/ico/lookup'),
              response: mockResponse,
              type: DioExceptionType.badResponse,
            ));

        // Act
        final result = await service.publicLookup('12345678');

        // Assert
        expect(result, isNull);
      });

      test('should handle 401 Unauthorized', () async {
        // Arrange
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(401);
        when(() => mockResponse.data).thenReturn({'error': 'Unauthorized'});

        when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/api/public/ico/lookup'),
              response: mockResponse,
              type: DioExceptionType.badResponse,
            ));

        // Act
        final result = await service.publicLookup('12345678');

        // Assert
        expect(result, isNull);
      });

      test('should handle malformed JSON response', () async {
        // Arrange
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(200);
        when(() => mockResponse.data).thenReturn('invalid json');

        when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await service.publicLookup('12345678');

        // Assert
        expect(result, isNull);
      });

      test('should handle empty response data', () async {
        // Arrange
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(200);
        when(() => mockResponse.data).thenReturn(null);

        when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await service.publicLookup('12345678');

        // Assert
        expect(result, isNull);
      });

      test('should handle response with ok: false', () async {
        // Arrange
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(200);
        when(() => mockResponse.data).thenReturn({'ok': false, 'error': 'Invalid ICO'});

        when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await service.publicLookup('12345678');

        // Assert
        expect(result, isNull);
      });

      test('should handle response without summary field', () async {
        // Arrange
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(200);
        when(() => mockResponse.data).thenReturn({'ok': true});

        when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await service.publicLookup('12345678');

        // Assert
        // Note: Implementation uses ?? {} which creates empty map, resulting in IcoLookupResult with empty values
        expect(result, isNotNull);
        expect(result!.name, isEmpty);
        expect(result.status, isEmpty);
      });

      test('should handle generic exceptions', () async {
        // Arrange
        when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
            .thenThrow(Exception('Unexpected error'));

        // Act
        final result = await service.publicLookup('12345678');

        // Assert
        expect(result, isNull);
      });
    });

    group('fetchByIco', () {
      test('should throw when result is null', () async {
        // Arrange
        when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
            .thenAnswer((_) async {
          final mockResponse = MockResponse();
          when(() => mockResponse.statusCode).thenReturn(404);
          when(() => mockResponse.data).thenReturn(null);
          return mockResponse;
        });

        // Act & Assert
        expect(
          () => service.fetchByIco('12345678'),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Refresh failed'))),
        );
      });

      test('should throw when result is rate limited', () async {
        // Arrange
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(429);
        when(() => mockResponse.data).thenReturn({'resetIn': '60'});

        when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/api/public/ico/lookup'),
              response: mockResponse,
              type: DioExceptionType.badResponse,
            ));

        // Act & Assert
        expect(
          () => service.fetchByIco('12345678'),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Refresh failed'))),
        );
      });

      test('should return result when valid', () async {
        // Arrange
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(200);
        when(() => mockResponse.data).thenReturn({
          'ok': true,
          'summary': {
            'ico': '12345678',
            'name': 'Test Company',
            'status': 'Active',
          },
        });

        when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await service.fetchByIco('12345678');

        // Assert
        expect(result, isNotNull);
        expect(result.isValid, isTrue);
      });
    });

    group('secureLookup', () {
      test('should return null when token is null', () async {
        // Act
        final result = await service.secureLookup('12345678', null);

        // Assert
        expect(result, isNull);
        verifyNever(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')));
      });

      test('should handle rate limiting (429)', () async {
        // Arrange
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(429);
        when(() => mockResponse.data).thenReturn({'resetIn': '120'});

        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              options: any(named: 'options'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/api/internal/ico/full'),
          response: mockResponse,
          type: DioExceptionType.badResponse,
        ));

        // Act
        final result = await service.secureLookup('12345678', 'valid-token');

        // Assert
        expect(result, isNotNull);
        expect(result!.isRateLimited, isTrue);
        expect(result.resetIn, 120);
      });

      test('should handle payment required (402)', () async {
        // Arrange
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(402);
        when(() => mockResponse.data).thenReturn({'error': 'Payment required'});

        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              options: any(named: 'options'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/api/internal/ico/full'),
          response: mockResponse,
          type: DioExceptionType.badResponse,
        ));

        // Act
        final result = await service.secureLookup('12345678', 'valid-token');

        // Assert
        expect(result, isNotNull);
        expect(result!.isPaymentRequired, isTrue);
      });

      test('should handle 401 Unauthorized', () async {
        // Arrange
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(401);
        when(() => mockResponse.data).thenReturn({'error': 'Invalid token'});

        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              options: any(named: 'options'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/api/internal/ico/full'),
          response: mockResponse,
          type: DioExceptionType.badResponse,
        ));

        // Act
        final result = await service.secureLookup('12345678', 'invalid-token');

        // Assert
        expect(result, isNull);
      });

      test('should handle 403 Forbidden', () async {
        // Arrange
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(403);
        when(() => mockResponse.data).thenReturn({'error': 'Forbidden'});

        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              options: any(named: 'options'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/api/internal/ico/full'),
          response: mockResponse,
          type: DioExceptionType.badResponse,
        ));

        // Act
        final result = await service.secureLookup('12345678', 'token');

        // Assert
        expect(result, isNull);
      });

      test('should handle network timeout', () async {
        // Arrange
        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              options: any(named: 'options'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/api/internal/ico/full'),
          type: DioExceptionType.connectionTimeout,
          message: 'Timeout',
        ));

        // Act
        final result = await service.secureLookup('12345678', 'token');

        // Assert
        expect(result, isNull);
      });

      test('should handle response with ok: false', () async {
        // Arrange
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(200);
        when(() => mockResponse.data).thenReturn({'ok': false});

        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              options: any(named: 'options'),
            )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await service.secureLookup('12345678', 'token');

        // Assert
        expect(result, isNull);
      });

      test('should handle response without payload field', () async {
        // Arrange
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(200);
        when(() => mockResponse.data).thenReturn({'ok': true});

        when(() => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              options: any(named: 'options'),
            )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await service.secureLookup('12345678', 'token');

        // Assert
        // Note: Implementation uses ?? {} which creates empty map, resulting in IcoLookupResult with empty values
        expect(result, isNotNull);
        expect(result!.name, isEmpty);
        expect(result.status, isEmpty);
      });
    });

    group('lookupCompany', () {
      test('should return null when publicLookup returns null', () async {
        // Arrange
        when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
            .thenAnswer((_) async {
          final mockResponse = MockResponse();
          when(() => mockResponse.statusCode).thenReturn(404);
          when(() => mockResponse.data).thenReturn(null);
          return mockResponse;
        });

        // Act
        final result = await service.lookupCompany('99999999');

        // Assert
        expect(result, isNull);
      });

      test('should return null when result is rate limited', () async {
        // Arrange
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(429);
        when(() => mockResponse.data).thenReturn({'resetIn': '60'});

        when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/api/public/ico/lookup'),
              response: mockResponse,
              type: DioExceptionType.badResponse,
            ));

        // Act
        final result = await service.lookupCompany('12345678');

        // Assert
        expect(result, isNull);
      });

      test('should return null when result name is empty', () async {
        // Arrange
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(200);
        when(() => mockResponse.data).thenReturn({
          'ok': true,
          'summary': {
            'ico': '12345678',
            'name': '', // Empty name
            'status': 'Active',
          },
        });

        when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await service.lookupCompany('12345678');

        // Assert
        expect(result, isNull);
      });

      test('should handle exceptions gracefully', () async {
        // Arrange
        when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
            .thenThrow(Exception('Unexpected error'));

        // Act
        final result = await service.lookupCompany('12345678');

        // Assert
        expect(result, isNull);
      });
    });

    group('autocomplete', () {
      test('should return empty list for query shorter than 2 characters', () async {
        // Act
        final result = await service.autocomplete('a');

        // Assert
        expect(result, isEmpty);
        verifyNever(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')));
      });

      test('should return empty list for empty query', () async {
        // Act
        final result = await service.autocomplete('');

        // Assert
        expect(result, isEmpty);
      });

      test('should handle network errors', () async {
        // Arrange
        when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/api/public/ico/autocomplete'),
              type: DioExceptionType.connectionError,
              message: 'Network error',
            ));

        // Act
        final result = await service.autocomplete('test');

        // Assert
        expect(result, isEmpty);
      });

      test('should handle non-200 status codes', () async {
        // Arrange
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(500);
        when(() => mockResponse.data).thenReturn({'error': 'Server error'});

        when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/api/public/ico/autocomplete'),
              response: mockResponse,
              type: DioExceptionType.badResponse,
            ));

        // Act
        final result = await service.autocomplete('test');

        // Assert
        expect(result, isEmpty);
      });

      test('should handle non-list response data', () async {
        // Arrange
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(200);
        when(() => mockResponse.data).thenReturn({'error': 'Invalid format'});

        when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await service.autocomplete('test');

        // Assert
        expect(result, isEmpty);
      });

      test('should handle exceptions gracefully', () async {
        // Arrange
        when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
            .thenThrow(Exception('Unexpected error'));

        // Act
        final result = await service.autocomplete('test');

        // Assert
        expect(result, isEmpty);
      });
    });

    group('Real Mode (isDemoMode: false)', () {
      test('should handle errors in real mode', () async {
        // Arrange
        final realService = IcoAtlasService(mockDio, isDemoMode: false);
        when(() => mockDio.get(any()))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/api/company/12345678'),
              type: DioExceptionType.connectionTimeout,
              message: 'Timeout',
            ));

        // Act
        final result = await realService.publicLookup('12345678');

        // Assert
        expect(result, isNull);
      });

      test('should handle 404 in real mode', () async {
        // Arrange
        final realService = IcoAtlasService(mockDio, isDemoMode: false);
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(404);
        when(() => mockResponse.data).thenReturn(null);

        when(() => mockDio.get(any()))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await realService.publicLookup('99999999');

        // Assert
        expect(result, isNull);
      });

      test('should handle null response data in real mode', () async {
        // Arrange
        final realService = IcoAtlasService(mockDio, isDemoMode: false);
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(200);
        when(() => mockResponse.data).thenReturn(null);

        when(() => mockDio.get(any()))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await realService.publicLookup('12345678');

        // Assert
        expect(result, isNull);
      });
    });
  });
}
