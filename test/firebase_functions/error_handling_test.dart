import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_functions/firebase_functions.dart';
import 'package:mockito/mockito.dart';
import 'package:bizagent/core/services/gemini_service.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {
  @override
  HttpsCallable httpsCallable(String name) {
    return super.noSuchMethod(
      Invocation.method(#httpsCallable, [name]),
      returnValue: MockHttpsCallable(),
    );
  }
}

class MockHttpsCallable extends Mock implements HttpsCallable {
  @override
  Future<HttpsCallableResult> call([Object? params]) async {
    return super.noSuchMethod(
      Invocation.method(#call, [params]),
      returnValue: HttpsCallableResult<Map<String, dynamic>>(data: {}),
    );
  }
}

void main() {
  group('Firebase Functions Error Handling', () {
    late MockFirebaseFunctions mockFirebaseFunctions;
    late GeminiService geminiService;

    setUp(() {
      mockFirebaseFunctions = MockFirebaseFunctions();
      geminiService = GeminiService(mockFirebaseFunctions);
    });

    group('generateEmail', () {
      test('should handle network timeout errors', () async {
        // Arrange
        final mockHttpsCallable = MockHttpsCallable();
        when(mockFirebaseFunctions.httpsCallable('generateEmail'))
            .thenReturn(mockHttpsCallable);
        when(mockHttpsCallable.call(any)).thenThrow(
          FirebaseFunctionsException(
            code: 'deadline-exceeded',
            message: 'Deadline exceeded',
            details: {'timeout': true},
          ),
        );

        // Act & Assert
        expect(
          () => geminiService.generateEmail(
            'Test client',
            'Test invoice',
            'Test message',
          ),
          throwsA(
            isA<FirebaseFunctionsException>()
                .having((e) => e.code, 'code', 'deadline-exceeded')
                .having((e) => e.message, 'message', 'Deadline exceeded'),
          ),
        );
      });

      test('should handle quota exceeded errors', () async {
        // Arrange
        final mockHttpsCallable = MockHttpsCallable();
        when(mockFirebaseFunctions.httpsCallable('generateEmail'))
            .thenReturn(mockHttpsCallable);
        when(mockHttpsCallable.call(any)).thenThrow(
          FirebaseFunctionsException(
            code: 'resource-exhausted',
            message: 'Quota exceeded for gemini function',
            details: {'quota': 'gemini'},
          ),
        );

        // Act & Assert
        expect(
          () => geminiService.generateEmail(
            'Test client',
            'Test invoice',
            'Test message',
          ),
          throwsA(
            isA<FirebaseFunctionsException>()
                .having((e) => e.code, 'code', 'resource-exhausted')
                .having((e) => e.message, 'message', 'Quota exceeded for gemini function'),
          ),
        );
      });

      test('should handle invalid parameters errors', () async {
        // Arrange
        final mockHttpsCallable = MockHttpsCallable();
        when(mockFirebaseFunctions.httpsCallable('generateEmail'))
            .thenReturn(mockHttpsCallable);
        when(mockHttpsCallable.call(any)).thenThrow(
          FirebaseFunctionsException(
            code: 'invalid-argument',
            message: 'Invalid parameters provided',
            details: {'field': 'clientName'},
          ),
        );

        // Act & Assert
        expect(
          () => geminiService.generateEmail(
            '',
            'Test invoice',
            'Test message',
          ),
          throwsA(
            isA<FirebaseFunctionsException>()
                .having((e) => e.code, 'code', 'invalid-argument')
                .having((e) => e.message, 'message', 'Invalid parameters provided'),
          ),
        );
      });

      test('should handle internal server errors', () async {
        // Arrange
        final mockHttpsCallable = MockHttpsCallable();
        when(mockFirebaseFunctions.httpsCallable('generateEmail'))
            .thenReturn(mockHttpsCallable);
        when(mockHttpsCallable.call(any)).thenThrow(
          FirebaseFunctionsException(
            code: 'internal',
            message: 'Internal server error',
            details: {'function': 'generateEmail'},
          ),
        );

        // Act & Assert
        expect(
          () => geminiService.generateEmail(
            'Test client',
            'Test invoice',
            'Test message',
          ),
          throwsA(
            isA<FirebaseFunctionsException>()
                .having((e) => e.code, 'code', 'internal')
                .having((e) => e.message, 'message', 'Internal server error'),
          ),
        );
      });

      test('should handle permission denied errors', () async {
        // Arrange
        final mockHttpsCallable = MockHttpsCallable();
        when(mockFirebaseFunctions.httpsCallable('generateEmail'))
            .thenReturn(mockHttpsCallable);
        when(mockHttpsCallable.call(any)).thenThrow(
          FirebaseFunctionsException(
            code: 'permission-denied',
            message: 'User does not have permission to call this function',
            details: {'user': 'test-user'},
          ),
        );

        // Act & Assert
        expect(
          () => geminiService.generateEmail(
            'Test client',
            'Test invoice',
            'Test message',
          ),
          throwsA(
            isA<FirebaseFunctionsException>()
                .having((e) => e.code, 'code', 'permission-denied')
                .having((e) => e.message, 'message', 'User does not have permission to call this function'),
          ),
        );
      });
    });

    group('analyzeReceipt', () {
      test('should handle image processing errors', () async {
        // Arrange
        final mockHttpsCallable = MockHttpsCallable();
        when(mockFirebaseFunctions.httpsCallable('analyzeReceipt'))
            .thenReturn(mockHttpsCallable);
        when(mockHttpsCallable.call(any)).thenThrow(
          FirebaseFunctionsException(
            code: 'failed-precondition',
            message: 'Invalid image format or corrupted file',
            details: {'fileType': 'pdf'},
          ),
        );

        // Act & Assert
        expect(
          () => geminiService.analyzeReceipt(
            'base64-image-data',
            'Test description',
          ),
          throwsA(
            isA<FirebaseFunctionsException>()
                .having((e) => e.code, 'code', 'failed-precondition')
                .having((e) => e.message, 'message', 'Invalid image format or corrupted file'),
          ),
        );
      });

      test('should handle OCR processing timeouts', () async {
        // Arrange
        final mockHttpsCallable = MockHttpsCallable();
        when(mockFirebaseFunctions.httpsCallable('analyzeReceipt'))
            .thenReturn(mockHttpsCallable);
        when(mockHttpsCallable.call(any)).thenThrow(
          FirebaseFunctionsException(
            code: 'deadline-exceeded',
            message: 'OCR processing timeout',
            details: {'processingTime': '30s'},
          ),
        );

        // Act & Assert
        expect(
          () => geminiService.analyzeReceipt(
            'base64-image-data',
            'Test description',
          ),
          throwsA(
            isA<FirebaseFunctionsException>()
                .having((e) => e.code, 'code', 'deadline-exceeded')
                .having((e) => e.message, 'message', 'OCR processing timeout'),
          ),
        );
      });
    });

    group('lookupCompany', () {
      test('should handle invalid ICO format', () async {
        // Arrange
        final mockHttpsCallable = MockHttpsCallable();
        when(mockFirebaseFunctions.httpsCallable('lookupCompany'))
            .thenReturn(mockHttpsCallable);
        when(mockHttpsCallable.call(any)).thenThrow(
          FirebaseFunctionsException(
            code: 'invalid-argument',
            message: 'Invalid ICO format',
            details: {'ico': 'invalid-ico'},
          ),
        );

        // Act & Assert
        expect(
          () => geminiService.lookupCompany('invalid-ico'),
          throwsA(
            isA<FirebaseFunctionsException>()
                .having((e) => e.code, 'code', 'invalid-argument')
                .having((e) => e.message, 'message', 'Invalid ICO format'),
          ),
        );
      });

      test('should handle company not found', () async {
        // Arrange
        final mockHttpsCallable = MockHttpsCallable();
        when(mockFirebaseFunctions.httpsCallable('lookupCompany'))
            .thenReturn(mockHttpsCallable);
        when(mockHttpsCallable.call(any)).thenThrow(
          FirebaseFunctionsException(
            code: 'not-found',
            message: 'Company not found in registry',
            details: {'ico': '12345678'},
          ),
        );

        // Act & Assert
        expect(
          () => geminiService.lookupCompany('12345678'),
          throwsA(
            isA<FirebaseFunctionsException>()
                .having((e) => e.code, 'code', 'not-found')
                .having((e) => e.message, 'message', 'Company not found in registry'),
          ),
        );
      });
    });

    group('generateContent', () {
      test('should handle content generation errors', () async {
        // Arrange
        final mockHttpsCallable = MockHttpsCallable();
        when(mockFirebaseFunctions.httpsCallable('generateContent'))
            .thenReturn(mockHttpsCallable);
        when(mockHttpsCallable.call(any)).thenThrow(
          FirebaseFunctionsException(
            code: 'internal',
            message: 'Content generation failed',
            details: {'prompt': 'test-prompt'},
          ),
        );

        // Act & Assert
        expect(
          () => geminiService.generateContent(
            'test-prompt',
            'email',
            'Test content',
          ),
          throwsA(
            isA<FirebaseFunctionsException>()
                .having((e) => e.code, 'code', 'internal')
                .having((e) => e.message, 'message', 'Content generation failed'),
          ),
        );
      });

      test('should handle rate limiting', () async {
        // Arrange
        final mockHttpsCallable = MockHttpsCallable();
        when(mockFirebaseFunctions.httpsCallable('generateContent'))
            .thenReturn(mockHttpsCallable);
        when(mockHttpsCallable.call(any)).thenThrow(
          FirebaseFunctionsException(
            code: 'resource-exhausted',
            message: 'Rate limit exceeded',
            details: {'limit': '100 requests per minute'},
          ),
        );

        // Act & Assert
        expect(
          () => geminiService.generateContent(
            'test-prompt',
            'email',
            'Test content',
          ),
          throwsA(
            isA<FirebaseFunctionsException>()
                .having((e) => e.code, 'code', 'resource-exhausted')
                .having((e) => e.message, 'message', 'Rate limit exceeded'),
          ),
        );
      });
    });

    group('CORS validation', () {
      test('should handle CORS errors', () async {
        // Arrange
        final mockHttpsCallable = MockHttpsCallable();
        when(mockFirebaseFunctions.httpsCallable('generateEmail'))
            .thenReturn(mockHttpsCallable);
        when(mockHttpsCallable.call(any)).thenThrow(
          FirebaseFunctionsException(
            code: 'permission-denied',
            message: 'CORS policy violation',
            details: {'origin': 'http://localhost:3000'},
          ),
        );

        // Act & Assert
        expect(
          () => geminiService.generateEmail(
            'Test client',
            'Test invoice',
            'Test message',
          ),
          throwsA(
            isA<FirebaseFunctionsException>()
                .having((e) => e.code, 'code', 'permission-denied')
                .having((e) => e.message, 'message', 'CORS policy violation'),
          ),
        );
      });
    });

    group('Authentication checks', () {
      test('should handle unauthenticated requests', () async {
        // Arrange
        final mockHttpsCallable = MockHttpsCallable();
        when(mockFirebaseFunctions.httpsCallable('generateEmail'))
            .thenReturn(mockHttpsCallable);
        when(mockHttpsCallable.call(any)).thenThrow(
          FirebaseFunctionsException(
            code: 'unauthenticated',
            message: 'User not authenticated',
            details: {'auth': 'required'},
          ),
        );

        // Act & Assert
        expect(
          () => geminiService.generateEmail(
            'Test client',
            'Test invoice',
            'Test message',
          ),
          throwsA(
            isA<FirebaseFunctionsException>()
                .having((e) => e.code, 'code', 'unauthenticated')
                .having((e) => e.message, 'message', 'User not authenticated'),
          ),
        );
      });

      test('should handle expired authentication tokens', () async {
        // Arrange
        final mockHttpsCallable = MockHttpsCallable();
        when(mockFirebaseFunctions.httpsCallable('generateEmail'))
            .thenReturn(mockHttpsCallable);
        when(mockHttpsCallable.call(any)).thenThrow(
          FirebaseFunctionsException(
            code: 'unauthenticated',
            message: 'Authentication token expired',
            details: {'token': 'expired'},
          ),
        );

        // Act & Assert
        expect(
          () => geminiService.generateEmail(
            'Test client',
            'Test invoice',
            'Test message',
          ),
          throwsA(
            isA<FirebaseFunctionsException>()
                .having((e) => e.code, 'code', 'unauthenticated')
                .having((e) => e.message, 'message', 'Authentication token expired'),
          ),
        );
      });
    });

    group('Network connectivity', () {
      test('should handle offline scenarios', () async {
        // Arrange
        final mockHttpsCallable = MockHttpsCallable();
        when(mockFirebaseFunctions.httpsCallable('generateEmail'))
            .thenReturn(mockHttpsCallable);
        when(mockHttpsCallable.call(any)).thenThrow(
          FirebaseFunctionsException(
            code: 'unavailable',
            message: 'Service unavailable',
            details: {'network': 'offline'},
          ),
        );

        // Act & Assert
        expect(
          () => geminiService.generateEmail(
            'Test client',
            'Test invoice',
            'Test message',
          ),
          throwsA(
            isA<FirebaseFunctionsException>()
                .having((e) => e.code, 'code', 'unavailable')
                .having((e) => e.message, 'message', 'Service unavailable'),
          ),
        );
      });
    });
  });
}