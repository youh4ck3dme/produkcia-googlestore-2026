# Firebase Functions Testy

Tento adresár obsahuje testy pre Firebase Cloud Functions.

## Súbory

- `error_handling_test.dart` - Základné testy pre error handling
- `rate_limiting_cors_auth_test.dart` - Rozšírené testy pre rate limiting, CORS a authentication

## Poznámka

Testy používajú `cloud_functions` package (nie `firebase_functions`). Uistite sa, že máte správne nastavené závislosti v `pubspec.yaml`:

```yaml
dependencies:
  cloud_functions: any
```

## Spustenie Testov

```bash
# Všetky Firebase Functions testy
flutter test test/firebase_functions/

# Konkrétny test
flutter test test/firebase_functions/rate_limiting_cors_auth_test.dart
```

## Pokrytie

### Rate Limiting
- ✅ Per-user rate limiting
- ✅ Per-function rate limiting
- ✅ Global quota exceeded
- ✅ Retry-after headers
- ✅ Burst rate limiting

### CORS Validation
- ✅ Allowed origins
- ✅ Blocked origins
- ✅ Preflight requests
- ✅ CORS headers validation

### Authentication Checks
- ✅ Required authentication for protected functions
- ✅ Expired tokens
- ✅ Invalid tokens
- ✅ Revoked tokens
- ✅ Missing authentication headers
- ✅ Optional authentication for public functions
