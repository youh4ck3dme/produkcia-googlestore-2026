# Backend migrácia — Firebase → Supabase

**Stav:** 2026-07-10 | Vetva `feat/supabase-backend-p0`

## Canonical (nové)

| Funkcia | Implementácia |
|---------|----------------|
| Auth | Supabase Auth (`lib/core/supabase/auth_backend.dart`) |
| User data | Postgres + RLS (`supabase/migrations/`) |
| Receipts storage | Bucket `receipts` — prefix `{user_id}/` |
| AI content | Edge `generate-content` |
| **Account deletion** | Edge **`delete-account`** |

### delete-account flow

1. Klient: `AuthRepository.deleteAccount()` → `invoke('delete-account')`
2. Edge function overí JWT, zmaže riadky v 8 tabuľkách, storage súbory, `auth.admin.deleteUser`
3. Klient: `signOut()`

Deploy:

```bash
supabase functions deploy delete-account
```

## Legacy (Firebase — nepre nových userov)

| Funkcia | Súbor | Status |
|---------|-------|--------|
| deleteUserData | `functions/index.js` | Legacy — Firebase Auth only |
| generateEmail, analyzeReceipt, lookupCompany | `functions/index.js` | Postupne nahradiť edge functions |
| Firestore rules | `firestore.rules` | Deprecated pre Supabase-only user |

## AGENT B závislosti

Po deploy `delete-account` musí B overiť:
- Settings → Delete account E2E
- Žiadne volanie `deleteUserData` z Flutteru

## CI

- `test.yml` + `android_release.yml`: `npm test` v `functions/`, `flutter test --dart-define=PLAY_MVP=false`