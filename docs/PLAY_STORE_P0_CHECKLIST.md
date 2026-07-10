# Play Store P0 Checklist — stav 2026-07-10

**Vetva:** `main` @ `fb218dc` (merge A+B)  
**Supabase live:** `kpsnwpuydqqojwmrnkdy` (`bizagent-app-2026`)

---

## P0 technické (kód + CI)

| # | Položka | Stav | Dôkaz |
|---|---------|------|-------|
| 1 | `delete-account` edge function existuje | ✅ | `supabase/functions/delete-account/index.ts` |
| 2 | `delete-account` deploynutá na live | ✅ | `supabase functions deploy` 2026-07-10 |
| 3 | Klient volá `delete-account` | ✅ | `auth_repository.dart` → `invokeFunction('delete-account')` |
| 4 | UI mazania účtu v nastaveniach | ✅ | `settings_screen.dart` — potvrdzovací dialóg |
| 5 | Soft delete → `trash_items` + `is_deleted` | ✅ | AGENT B |
| 6 | Export → Supabase | ✅ | `SupabaseExportDataSource` |
| 7 | Watched companies → Supabase | ✅ | `watched_companies` tabuľka |
| 8 | `FirebaseAuth` v user-data path | ✅ | 0× (len komentár v `firebase_login_screen.dart`) |
| 9 | `flutter test --dart-define=PLAY_MVP=false` | ✅ | **380 passed, 5 skipped, 0 failed** |
| 10 | `functions npm test` | ✅ | all smoke checks passed |
| 11 | CI `android_release.yml` PLAY_MVP=false | ✅ | workflow step 37 |
| 12 | `flutter analyze` bez error | ✅ | 0 errors (10 info) |
| 13 | AAB release build | ✅ | `app-release.aab` 141.5 MB — `flutter build appbundle --release` |

---

## P0 manuálne (Play Console + infra)

| # | Položka | Stav | Akcia |
|---|---------|------|-------|
| 14 | Google OAuth na novom Supabase | ⚠️ | Dashboard → Auth → Google → redirect `https://kpsnwpuydqqojwmrnkdy.supabase.co/auth/v1/callback` |
| 15 | Edge function secrets (MISTRAL/Gemini) | ⚠️ | Supabase Dashboard → Edge Functions → Secrets |
| 16 | Privacy Policy **verejná URL** | ⚠️ | Host `web/privacy.html` (Vercel/GitHub Pages/bizagent.sk) |
| 17 | Account deletion URL pre Play | ⚠️ | Host `web/delete-account.html` |
| 18 | Demo účet pre Play review | ⚠️ | `cp DEMO_ACCOUNT_SECRETS.txt.example DEMO_ACCOUNT_SECRETS.txt` + rotácia hesla |
| 19 | Live test account deletion | ⚠️ | Prihlás sa → Nastavenia → Zmazať účet (na `kpsnwpuydqqojwmrnkdy`) |
| 20 | Rotácia leaked secrets v git history | ⚠️ | Demo heslo + API keys boli v trackovaných súboroch |
| 21 | Firebase `google-services.json` pre `sk.bizagent.app` | ⚠️ | Firebase Console → bizagent-live-2026 |
| 22 | Play Console nový listing `sk.bizagent.app` | ⚠️ | Nie update `com.bizagent.live` |

---

## Firestore dlh (P1 — neblokuje internal testing)

| Súbor | Účel |
|-------|------|
| `company_lookup_service.dart` | IČO cache |
| `monitoring_service.dart` (2×) | Notifikácie |
| `notification_bell.dart` | Notifikácie UI |
| `firestore_invoice_numbering_repository.dart` | Číslovanie faktúr |
| `categorization_service.dart` | Kategórie výdavkov |
| `firestore_export_data_source.dart` | Legacy (nepoužívané) |

Detail: `docs/DATALAYER_DEBT.md`

---

## Manuálny QA (5 krokov pred uploadom)

1. **Registrácia / Google login** — nový Supabase projekt, OAuth nastavený
2. **Vytvor faktúru + výdavok** — sync do Postgres, offline cache OK
3. **Soft delete faktúry** → Kôš → Obnoviť → Natrvalo zmazať
4. **Export ZIP** — obdobie s dátami, ZIP sa stiahne
5. **Zmazať účet** — potvrdenie, odhlásenie, dáta preč v Supabase

---

## Readiness skóre

| Oblasť | Skóre |
|--------|-------|
| Kód + testy | **92/100** |
| Supabase infra | **75/100** (nový projekt, OAuth/secrets manuálne) |
| Play metadata | **55/100** (privacy URL, screenshots, demo account) |
| **Celkom P0** | **78/100** |