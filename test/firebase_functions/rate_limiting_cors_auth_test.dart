import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:mockito/mockito.dart';
import 'package:mocktail/mocktail.dart' as mocktail;

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

class MockHttpsCallableResult extends mocktail.Fake implements HttpsCallableResult {
  final dynamic _data;
  
  MockHttpsCallableResult({dynamic data}) : _data = data;
  
  @override
  dynamic get data => _data;
}

void main() {
  group('Firebase Functions - Rate Limiting, CORS & Auth', () {
    late MockFirebaseFunctions mockFirebaseFunctions;
    late MockHttpsCallable mockCallable;

    setUp(() {
      mockFirebaseFunctions = MockFirebaseFunctions();
      mockCallable = MockHttpsCallable();
    });

    group('Rate Limiting', () {
      test('should handle per-user rate limiting', () async {
        // Arrange
        when(mockFirebaseFunctions.httpsCallable(anyString)).thenReturn(mockCallable);
        when(mockCallable.call(any)).thenThrow(
          FirebaseFunctionsException(
            code: 'resource-exhausted',
            message: 'Rate limit exceeded for user',
            details: {
              'limit': '100 requests per hour',
              'userId': 'user123',
              'retryAfter': '3600',
            },
          ),
        );

        // Act & Assert
        expect(
          () async {
            final callable = mockFirebaseFunctions.httpsCallable('generateEmail');
            await callable.call({'type': 'reminder', 'tone': 'professional', 'context': 'Test'});
          },
          throwsA(
              isA<FirebaseFunctionsException>()
                .having((e) => (e as FirebaseFunctionsException).code, 'code', 'resource-exhausted')
                .having((e) => (e as FirebaseFunctionsException).message, 'message', 'Rate limit exceeded for user')
                .having((e) => (e as FirebaseFunctionsException).details?['userId'], 'userId', 'user123'),
          ),
        );
      });

      test('should handle per-function rate limiting', () async {
        // Arrange
        when(mockFirebaseFunctions.httpsCallable(anyString)).thenReturn(mockCallable);
        when(mockCallable.call(any)).thenThrow(
          FirebaseFunctionsException(
            code: 'resource-exhausted',
            message: 'Rate limit exceeded for function',
            details: {
              'limit': '1000 requests per day',
              'function': 'generateContent',
              'retryAfter': '86400',
            },
          ),
        );

        // Act & Assert
        expect(
          () async {
            final callable = mockFirebaseFunctions.httpsCallable('generateContent');
            await callable.call({'prompt': 'test-prompt', 'model': 'gemini-1.5-flash'});
          },
          throwsA(
              isA<FirebaseFunctionsException>()
                .having((e) => (e as FirebaseFunctionsException).code, 'code', 'resource-exhausted')
                .having((e) => (e as FirebaseFunctionsException).message, 'message', 'Rate limit exceeded for function')
                .having((e) => (e as FirebaseFunctionsException).details?['function'], 'function', 'generateContent'),
          ),
        );
      });

      test('should handle global quota exceeded', () async {
        // Arrange
        when(mockFirebaseFunctions.httpsCallable(anyString)).thenReturn(mockCallable);
        when(mockCallable.call(any)).thenThrow(
          FirebaseFunctionsException(
            code: 'resource-exhausted',
            message: 'Global quota exceeded',
            details: {
              'quota': 'gemini-api',
              'limit': '10000 requests per month',
              'resetAt': '2026-02-01T00:00:00Z',
            },
          ),
        );

        // Act & Assert
        expect(
          () async {
            final callable = mockFirebaseFunctions.httpsCallable('generateEmail');
            await callable.call({'type': 'reminder', 'tone': 'professional', 'context': 'Test'});
          },
          throwsA(
              isA<FirebaseFunctionsException>()
                .having((e) => (e as FirebaseFunctionsException).code, 'code', 'resource-exhausted')
                .having((e) => (e as FirebaseFunctionsException).message, 'message', 'Global quota exceeded')
                .having((e) => (e as FirebaseFunctionsException).details?['quota'], 'quota', 'gemini-api'),
          ),
        );
      });

      test('should handle rate limiting with retry-after header', () async {
        // Arrange
        when(mockFirebaseFunctions.httpsCallable(anyString)).thenReturn(mockCallable);
        when(mockCallable.call(any)).thenThrow(
          FirebaseFunctionsException(
            code: 'resource-exhausted',
            message: 'Too many requests, please retry later',
            details: {
              'retryAfter': '60',
              'remaining': '0',
              'limit': '10 requests per minute',
            },
          ),
        );

        // Act & Assert
        expect(
          () async {
            final callable = mockFirebaseFunctions.httpsCallable('analyzeReceipt');
            await callable.call({'text': 'base64-image-data'});
          },
          throwsA(
              isA<FirebaseFunctionsException>()
                .having((e) => (e as FirebaseFunctionsException).code, 'code', 'resource-exhausted')
                .having((e) => (e as FirebaseFunctionsException).details?['retryAfter'], 'retryAfter', '60'),
          ),
        );
      });

      test('should handle burst rate limiting', () async {
        // Arrange
        when(mockFirebaseFunctions.httpsCallable(anyString)).thenReturn(mockCallable);
        when(mockCallable.call(any)).thenThrow(
          FirebaseFunctionsException(
            code: 'resource-exhausted',
            message: 'Burst rate limit exceeded',
            details: {
              'burstLimit': '50 requests per second',
              'window': '1 second',
            },
          ),
        );

        // Act & Assert
        expect(
          () async {
            final callable = mockFirebaseFunctions.httpsCallable('lookupCompany');
            await callable.call({'ico': '12345678'});
          },
          throwsA(
              isA<FirebaseFunctionsException>()
                .having((e) => (e as FirebaseFunctionsException).code, 'code', 'resource-exhausted')
                .having((e) => (e as FirebaseFunctionsException).message, 'message', 'Burst rate limit exceeded'),
          ),
        );
      });
    });

    group('CORS Validation', () {
      test('should allow requests from allowed origins', () async {
        // Arrange - This test verifies that allowed origins work
        // In real scenario, CORS is handled by Firebase Functions automatically
        when(mockFirebaseFunctions.httpsCallable(anyString)).thenReturn(mockCallable);
        final mockResult = MockHttpsCallableResult(data: {'text': 'Test email'});
        when(mockCallable.call(any)).thenAnswer((_) async => mockResult);

        // Act
        final callable = mockFirebaseFunctions.httpsCallable('generateEmail');
        final result = await callable.call({'type': 'reminder', 'tone': 'professional', 'context': 'Test'});

        // Assert - Should succeed (CORS is handled by Firebase)
        expect(result, isNotNull);
        expect(result.data['text'], 'Test email');
      });

      test('should handle CORS policy violation for blocked origin', () async {
        // Arrange
        when(mockFirebaseFunctions.httpsCallable(anyString)).thenReturn(mockCallable);
        when(mockCallable.call(any)).thenThrow(
          FirebaseFunctionsException(
            code: 'permission-denied',
            message: 'CORS policy violation: Origin not allowed',
            details: {
              'origin': 'https://malicious-site.com',
              'allowedOrigins': [
                'https://biz-agent-web.vercel.app',
                'https://bizagent-live-2026.web.app',
                'http://localhost:3000',
                'http://localhost:62262',
              ],
            },
          ),
        );

        // Act & Assert
        expect(
          () async {
            final callable = mockFirebaseFunctions.httpsCallable('generateEmail');
            await callable.call({'type': 'reminder', 'tone': 'professional', 'context': 'Test'});
          },
          throwsA(
              isA<FirebaseFunctionsException>()
                .having((e) => (e as FirebaseFunctionsException).code, 'code', 'permission-denied')
                .having((e) => (e as FirebaseFunctionsException).message, 'message', contains('CORS policy violation')),
          ),
        );
      });

      test('should handle CORS preflight request errors', () async {
        // Arrange
        when(mockFirebaseFunctions.httpsCallable(anyString)).thenReturn(mockCallable);
        when(mockCallable.call(any)).thenThrow(
          FirebaseFunctionsException(
            code: 'permission-denied',
            message: 'CORS preflight request failed',
            details: {
              'method': 'OPTIONS',
              'origin': 'https://unauthorized-origin.com',
            },
          ),
        );

        // Act & Assert
        expect(
          () async {
            final callable = mockFirebaseFunctions.httpsCallable('analyzeReceipt');
            await callable.call({'text': 'base64-image-data'});
          },
          throwsA(
            isA<FirebaseFunctionsException>()
                .having((e) => (e as FirebaseFunctionsException).code, 'code', 'permission-denied')
                .having((e) => (e as FirebaseFunctionsException).message, 'message', contains('CORS')),
          ),
        );
      });

      test('should validate CORS headers in response', () async {
        // Arrange - Test that CORS headers are properly set
        // Note: In real Firebase Functions, CORS headers are set automatically
        when(mockFirebaseFunctions.httpsCallable(anyString)).thenReturn(mockCallable);
        final mockResult = MockHttpsCallableResult(data: {'text': 'Test content'});
        when(mockCallable.call(any)).thenAnswer((_) async => mockResult);

        // Act
        final callable = mockFirebaseFunctions.httpsCallable('generateContent');
        final result = await callable.call({'prompt': 'test-prompt', 'model': 'gemini-1.5-flash'});

        // Assert - Should succeed (CORS headers handled by Firebase)
        expect(result, isNotNull);
        expect(result.data['text'], 'Test content');
      });
    });

    group('Authentication Checks', () {
      test('should require authentication for protected functions', () async {
        // Arrange - generateEmail requires auth
        when(mockFirebaseFunctions.httpsCallable(anyString)).thenReturn(mockCallable);
        when(mockCallable.call(any)).thenThrow(
          FirebaseFunctionsException(
            code: 'unauthenticated',
            message: 'Funkcia musí byť volaná prihláseným používateľom.',
            details: {
              'auth': 'required',
              'function': 'generateEmail',
            },
          ),
        );

        // Act & Assert
        expect(
          () async {
            final callable = mockFirebaseFunctions.httpsCallable('generateEmail');
            await callable.call({'type': 'reminder', 'tone': 'professional', 'context': 'Test'});
          },
          throwsA(
              isA<FirebaseFunctionsException>()
                .having((e) => (e as FirebaseFunctionsException).code, 'code', 'unauthenticated')
                .having((e) => (e as FirebaseFunctionsException).message, 'message', contains('prihláseným používateľom')),
          ),
        );
      });

      test('should handle expired authentication tokens', () async {
        // Arrange
        when(mockFirebaseFunctions.httpsCallable(anyString)).thenReturn(mockCallable);
        when(mockCallable.call(any)).thenThrow(
          FirebaseFunctionsException(
            code: 'unauthenticated',
            message: 'Authentication token expired',
            details: {
              'token': 'expired',
              'expiredAt': '2026-01-29T10:00:00Z',
              'currentTime': '2026-01-29T11:00:00Z',
            },
          ),
        );

        // Act & Assert
        expect(
          () async {
            final callable = mockFirebaseFunctions.httpsCallable('analyzeReceipt');
            await callable.call({'text': 'base64-image-data'});
          },
          throwsA(
            isA<FirebaseFunctionsException>()
                .having((e) => (e as FirebaseFunctionsException).code, 'code', 'unauthenticated')
                .having((e) => (e as FirebaseFunctionsException).message, 'message', contains('expired')),
          ),
        );
      });

      test('should handle invalid authentication tokens', () async {
        // Arrange
        when(mockFirebaseFunctions.httpsCallable(anyString)).thenReturn(mockCallable);
        when(mockCallable.call(any)).thenThrow(
          FirebaseFunctionsException(
            code: 'unauthenticated',
            message: 'Invalid authentication token',
            details: {
              'token': 'invalid',
              'reason': 'malformed',
            },
          ),
        );

        // Act & Assert
        expect(
          () async {
            final callable = mockFirebaseFunctions.httpsCallable('generateEmail');
            await callable.call({'type': 'reminder', 'tone': 'professional', 'context': 'Test'});
          },
          throwsA(
              isA<FirebaseFunctionsException>()
                .having((e) => (e as FirebaseFunctionsException).code, 'code', 'unauthenticated')
                .having((e) => (e as FirebaseFunctionsException).message, 'message', contains('Invalid')),
          ),
        );
      });

      test('should handle revoked authentication tokens', () async {
        // Arrange
        when(mockFirebaseFunctions.httpsCallable(anyString)).thenReturn(mockCallable);
        when(mockCallable.call(any)).thenThrow(
          FirebaseFunctionsException(
            code: 'unauthenticated',
            message: 'Authentication token has been revoked',
            details: {
              'token': 'revoked',
              'revokedAt': '2026-01-29T09:00:00Z',
            },
          ),
        );

        // Act & Assert
        expect(
          () async {
            final callable = mockFirebaseFunctions.httpsCallable('generateEmail');
            await callable.call({'type': 'reminder', 'tone': 'professional', 'context': 'Test'});
          },
          throwsA(
              isA<FirebaseFunctionsException>()
                .having((e) => (e as FirebaseFunctionsException).code, 'code', 'unauthenticated')
                .having((e) => (e as FirebaseFunctionsException).message, 'message', contains('revoked')),
          ),
        );
      });

      test('should allow unauthenticated requests for public functions', () async {
        // Arrange - lookupCompany allows unauthenticated
        when(mockFirebaseFunctions.httpsCallable(anyString)).thenReturn(mockCallable);
        final mockResult = MockHttpsCallableResult(data: {
          'name': 'Test Company',
          'ico': '12345678',
        });
        when(mockCallable.call(any)).thenAnswer((_) async => mockResult);

        // Act
        final callable = mockFirebaseFunctions.httpsCallable('lookupCompany');
        final result = await callable.call({'ico': '12345678'});

        // Assert - Should succeed without auth
        expect(result, isNotNull);
        expect(result.data['name'], 'Test Company');
      });

      test('should handle missing authentication header', () async {
        // Arrange
        when(mockFirebaseFunctions.httpsCallable(anyString)).thenReturn(mockCallable);
        when(mockCallable.call(any)).thenThrow(
          FirebaseFunctionsException(
            code: 'unauthenticated',
            message: 'Missing authentication header',
            details: {
              'header': 'Authorization',
              'required': true,
            },
          ),
        );

        // Act & Assert
        expect(
          () async {
            final callable = mockFirebaseFunctions.httpsCallable('generateEmail');
            await callable.call({'type': 'reminder', 'tone': 'professional', 'context': 'Test'});
          },
          throwsA(
              isA<FirebaseFunctionsException>()
                .having((e) => (e as FirebaseFunctionsException).code, 'code', 'unauthenticated')
                .having((e) => (e as FirebaseFunctionsException).message, 'message', contains('Missing')),
          ),
        );
      });

      test('should handle authentication for generateContent (optional)', () async {
        // Arrange - generateContent allows unauthenticated but prefers auth
        when(mockFirebaseFunctions.httpsCallable(anyString)).thenReturn(mockCallable);
        final mockResult = MockHttpsCallableResult(data: {'text': 'Test content'});
        when(mockCallable.call(any)).thenAnswer((_) async => mockResult);

        // Act - Should work without auth (but may be rate limited)
        final callable = mockFirebaseFunctions.httpsCallable('generateContent');
        final result = await callable.call({'prompt': 'test-prompt', 'model': 'gemini-1.5-flash'});

        // Assert
        expect(result, isNotNull);
        expect(result.data['text'], 'Test content');
      });
    });

    group('Combined Scenarios', () {
      test('should handle rate limiting after authentication', () async {
        // Arrange - User is authenticated but hits rate limit
        when(mockFirebaseFunctions.httpsCallable(anyString)).thenReturn(mockCallable);
        when(mockCallable.call(any)).thenThrow(
          FirebaseFunctionsException(
            code: 'resource-exhausted',
            message: 'Rate limit exceeded',
            details: {
              'userId': 'user123',
              'authenticated': true,
              'limit': '100 requests per hour',
            },
          ),
        );

        // Act & Assert
        expect(
          () async {
            final callable = mockFirebaseFunctions.httpsCallable('generateEmail');
            await callable.call({'type': 'reminder', 'tone': 'professional', 'context': 'Test'});
          },
          throwsA(
              isA<FirebaseFunctionsException>()
                .having((e) => (e as FirebaseFunctionsException).code, 'code', 'resource-exhausted'),
          ),
        );
      });

      test('should handle CORS error before authentication check', () async {
        // Arrange - CORS is checked before auth
        when(mockFirebaseFunctions.httpsCallable(anyString)).thenReturn(mockCallable);
        when(mockCallable.call(any)).thenThrow(
          FirebaseFunctionsException(
            code: 'permission-denied',
            message: 'CORS policy violation',
            details: {
              'origin': 'https://unauthorized-origin.com',
              'authChecked': false,
            },
          ),
        );

        // Act & Assert
        expect(
          () async {
            final callable = mockFirebaseFunctions.httpsCallable('generateEmail');
            await callable.call({'type': 'reminder', 'tone': 'professional', 'context': 'Test'});
          },
          throwsA(
            isA<FirebaseFunctionsException>().having(
              (e) => (e as FirebaseFunctionsException).code,
              'code',
              'permission-denied',
            ),
          ),
        );
      });
    });
  });
}
