# AGENT A — Report (feat/supabase-backend-p0)

**Dátum:** 2026-07-10  
**Vetva:** `feat/supabase-backend-p0`

## Hotové

| Úloha | Súbor | Stav |
|-------|-------|------|
| Edge `delete-account` | `supabase/functions/delete-account/index.ts` | ✅ |
| JWT verify config | `supabase/config.toml` | ✅ |
| Functions smoke test | `functions/test_functions.js` | ✅ |
| npm test script | `functions/package.json` | ✅ |
| CI PLAY_MVP=false | `.github/workflows/android_release.yml` | ✅ |
| CI functions test | `.github/workflows/test.yml` | ✅ |
| Backend docs | `docs/BACKEND_MIGRATION.md` | ✅ |

## Príkazy

```bash
cd functions && npm test          # ✅ smoke passed
supabase functions deploy delete-account   # manuálne pred produkciou
```

## Pre AGENT B

- `delete-account` existuje — môžeš testovať `AuthRepository.deleteAccount()`
- Nemeň `supabase/functions/delete-account/`
- Migrácia soft delete / export / watched companies je na tebe

## Deploy blocker

Edge function musí byť deploynutá na projekt `xitittqtaeyazcpaylsz` pred Play testom account deletion.